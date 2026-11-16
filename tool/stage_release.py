"""Run only publish --dry-run against disposable candidates; never publish source."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PACKAGES = ['gnu_clacks_core', 'gnu_clacks_flutter', 'gnu_clacks_http', 'gnu_clacks_dio']


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--report', default='docs/RELEASE_DRY_RUN.json')
    args = parser.parse_args()
    dart = os.environ.get('GNU_CLACKS_DART') or shutil.which('dart')
    if not dart:
        raise SystemExit('Dart SDK executable not found.')
    results = []
    with tempfile.TemporaryDirectory(prefix='gnu-clacks-release-') as temporary:
        stage = Path(temporary)
        (stage / 'pubspec.yaml').write_text('name: gnu_clacks_release_stage\npublish_to: none\nenvironment:\n  sdk: ^3.13.3\nworkspace:\n' + ''.join(f'  - packages/{name}\n' for name in PACKAGES))
        (stage / 'analysis_options.yaml').write_text('include: package:lints/recommended.yaml\n')
        for name in PACKAGES:
            source = ROOT / 'packages' / name
            manifest = (source / 'pubspec.yaml').read_text()
            if 'publish_to: none\n' not in manifest:
                raise SystemExit('Source publish guard is absent: ' + name)
            destination = stage / 'packages' / name
            destination.mkdir(parents=True)
            for item in ['lib', 'example', 'doc', 'README.md', 'CHANGELOG.md', 'LICENSE', '.pubignore']:
                original = source / item
                if original.is_dir():
                    shutil.copytree(original, destination / item)
                elif original.exists():
                    shutil.copy2(original, destination / item)
            # Publication eligibility changes ONLY in this temporary copy.
            (destination / 'pubspec.yaml').write_text(manifest.replace('publish_to: none\n', ''))
        resolution = subprocess.run([dart, 'pub', 'get', '--offline'], cwd=stage,
                                    capture_output=True, text=True)
        if resolution.returncode:
            raise SystemExit('Staged offline resolution failed:\n' + resolution.stdout + resolution.stderr)
        for name in PACKAGES:
            process = subprocess.run([dart, 'pub', 'publish', '--dry-run'], cwd=stage / 'packages' / name,
                                     capture_output=True, text=True)
            output = process.stdout + process.stderr
            results.append({'package': name, 'exit_code': process.returncode, 'output': output})
            print(name + ': dry-run exit ' + str(process.returncode))
    report = {'mode': 'disposable staged publish --dry-run; no upload and no source guard removal',
              'version': '0.1.0-dev.1', 'results': results}
    target = ROOT / args.report
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(report, indent=2) + '\n')
    if any(result['exit_code'] for result in results):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
