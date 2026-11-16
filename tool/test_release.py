"""Release orchestration tests: no registry calls or uploads."""
import subprocess
from urllib.error import HTTPError, URLError
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import release


class ReleaseTest(unittest.TestCase):
    def setUp(self):
        waiter = patch('release.wait_for')
        self.waiter = waiter.start()
        self.addCleanup(waiter.stop)
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for name in release.PACKAGES:
            folder = self.root / 'packages' / name
            folder.mkdir(parents=True)
            (folder / 'CHANGELOG.md').write_text('## 0.0.1\n')
            (folder / 'pubspec.yaml').write_text(
                f'name: {name}\nversion: 0.0.1\npublish_to: none\nresolution: workspace\n'
                'dependencies:\n  gnu_clacks_core: ^0.0.1\n')
        app = self.root / 'apps/gnu_clacks_example'
        app.mkdir(parents=True)
        (app / 'pubspec.yaml').write_text('version: 0.0.1\n  gnu_clacks_core: ^0.0.1\n')

    def test_versions_and_constraints_including_example(self):
        release.update_versions(self.root, '1.2.3-dev.1+2')
        for path in self.root.rglob('pubspec.yaml'):
            text = path.read_text()
            self.assertIn('version: 1.2.3-dev.1+2', text)
            self.assertIn('gnu_clacks_core: ^1.2.3-dev.1+2', text)

    def test_invalid_version_does_not_mutate(self):
        for value in ['01.2.3', '1.2', '1.2.3-01', '1.2.3\npublish_to: evil']:
            with self.assertRaises(ValueError):
                release.update_versions(self.root, value)
        self.assertIn('version: 0.0.1', next(self.root.rglob('pubspec.yaml')).read_text())

    @patch('release.subprocess.run')
    def test_publish_order_standalone_and_source_guards(self, run):
        def inspect(command, cwd, check):
            self.assertNotIn('resolution:', (cwd / 'pubspec.yaml').read_text())
            self.assertNotIn('publish_to:', (cwd / 'pubspec.yaml').read_text())
        run.side_effect = inspect
        release.release(self.root, 'flutter', 'publish', release.PACKAGES[0])
        self.assertEqual([call.kwargs['cwd'].name for call in run.call_args_list[1::2]], release.PACKAGES)
        self.assertTrue(all(call.args[0] == ['flutter', 'pub', 'publish'] for call in run.call_args_list[1::2]))
        for path in (self.root / 'packages').glob('*/pubspec.yaml'):
            self.assertIn('publish_to: none', path.read_text())

    @patch('release.subprocess.run')
    def test_failure_stops_and_dry_run_never_uploads(self, run):
        run.side_effect = [None, subprocess.CalledProcessError(65, 'publish')]
        with self.assertRaises(subprocess.CalledProcessError):
            release.release(self.root, 'flutter', 'dry-run', release.PACKAGES[0])
        self.assertEqual(run.call_count, 2)
        self.assertIn('--dry-run', run.call_args.args[0])

    @patch('release.subprocess.run')
    def test_ci_dry_run_precedes_force(self, run):
        release.release(self.root, 'flutter', 'publish', 'gnu_clacks', only='gnu_clacks', ci=True)
        self.assertEqual(run.call_args_list[-2].args[0], ['flutter', 'pub', 'publish', '--dry-run'])
        self.assertEqual(run.call_args_list[-1].args[0], ['flutter', 'pub', 'publish', '--force'])

    @patch('release.subprocess.run')
    def test_ci_warning_blocks_upload(self, run):
        run.side_effect = [None, subprocess.CalledProcessError(65, 'dry-run')]
        with self.assertRaises(subprocess.CalledProcessError):
            release.release(self.root, 'flutter', 'publish', 'gnu_clacks', only='gnu_clacks', ci=True)
        self.assertEqual(run.call_count, 2)
        self.assertNotIn('--force', run.call_args.args[0])

    def test_ci_checks_versions_and_changelog(self):
        release.verify_versions(self.root, '0.0.1')
        with self.assertRaises(ValueError):
            release.verify_versions(self.root, '0.0.2')
        (self.root / 'packages/gnu_clacks/CHANGELOG.md').write_text('## Other')
        with self.assertRaises(ValueError):
            release.verify_versions(self.root, '0.0.1')

    @patch('release.subprocess.run')
    def test_resume_bundle_only(self, run):
        release.release(self.root, 'flutter', 'publish', 'gnu_clacks')
        self.assertEqual(run.call_count, 2)
        self.assertEqual(run.call_args.kwargs['cwd'].name, 'gnu_clacks')


class WaitTest(unittest.TestCase):
    @patch('release.urlopen')
    def test_registry_exact_version_and_transient_errors(self, open_url):
        response = open_url.return_value.__enter__.return_value
        response.read.return_value = b'{"version": "0.1.0"}'
        self.assertFalse(release.published('gnu_clacks_core', '0.2.0'))
        response.read.return_value = b'{"version": "0.2.0"}'
        self.assertTrue(release.published('gnu_clacks_core', '0.2.0'))
        for code in [404, 429, 503]:
            open_url.side_effect = HTTPError('url', code, 'error', {}, None)
            self.assertFalse(release.published('gnu_clacks_core', '0.2.0'))
        open_url.side_effect = URLError('offline')
        self.assertFalse(release.published('gnu_clacks_core', '0.2.0'))
        open_url.side_effect = HTTPError('url', 403, 'forbidden', {}, None)
        with self.assertRaises(HTTPError):
            release.published('gnu_clacks_core', '0.2.0')

    @patch('release.time.sleep')
    @patch('release.time.monotonic', side_effect=[0, 0, 10])
    @patch('release.subprocess.run', side_effect=subprocess.CalledProcessError(1, 'get'))
    def test_resolution_retry_timeout(self, run, clock, sleep):
        with self.assertRaises(subprocess.CalledProcessError):
            release.resolve('flutter', Path('/tmp'), True, 10, 1)
        self.assertEqual(run.call_count, 2)

    @patch('release.time.sleep')
    @patch('release.published', side_effect=[False, False, True])
    def test_eventual_visibility(self, published, sleep):
        release.wait_for('gnu_clacks_core', '0.2.0', timeout=10, interval=1)
        self.assertEqual(published.call_count, 3)
        self.assertEqual(sleep.call_count, 2)

    @patch('release.time.sleep')
    @patch('release.time.monotonic', side_effect=[0, 0, 10])
    @patch('release.published', return_value=False)
    def test_visibility_timeout(self, published, clock, sleep):
        with self.assertRaises(TimeoutError):
            release.wait_for('gnu_clacks_core', '0.2.0', timeout=10, interval=1)

    @patch('release.time.sleep')
    @patch('release.subprocess.run', side_effect=[subprocess.CalledProcessError(1, 'get'), None])
    def test_resolution_retry(self, run, sleep):
        release.resolve('flutter', Path('/tmp'), True, 10, 1)
        self.assertEqual(run.call_count, 2)

    @patch('release.subprocess.run', side_effect=subprocess.CalledProcessError(1, 'get'))
    def test_resolution_without_dependencies_fails_immediately(self, run):
        with self.assertRaises(subprocess.CalledProcessError):
            release.resolve('flutter', Path('/tmp'), False, 10, 1)
        self.assertEqual(run.call_count, 1)


if __name__ == '__main__':
    unittest.main()
