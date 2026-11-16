"""Synchronise suite versions; optionally inspect or interactively publish copies."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]
PACKAGES = ['gnu_clacks_core', 'gnu_clacks_flutter', 'gnu_clacks_http',
            'gnu_clacks_dio', 'gnu_clacks']
CONTENTS = ['lib', 'example', 'doc', 'README.md', 'CHANGELOG.md', 'LICENSE', '.pubignore']
# Numeric prerelease identifiers must not have leading zeroes.
NUMBER = r'(?:0|[1-9][0-9]*)'
IDENTIFIER = r'(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)'
VERSION = re.compile(rf'{NUMBER}\.{NUMBER}\.{NUMBER}(?:-{IDENTIFIER}(?:\.{IDENTIFIER})*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?')


def update_versions(root, version):
    if not VERSION.fullmatch(version):
        raise ValueError('Expected a semantic version such as 0.1.0 or 0.2.0-dev.1')
    paths = [root / 'packages' / name / 'pubspec.yaml' for name in PACKAGES]
    paths.append(root / 'apps/gnu_clacks_example/pubspec.yaml')
    updates = {}
    for path in paths:
        content = path.read_text()
        # The example stays private but follows suite versions and constraints.
        content, count = re.subn(r'^version: .+$', 'version: ' + version, content, flags=re.M)
        if count != 1:
            raise ValueError(f'Expected one version in {path}')
        for name in PACKAGES:
            content = re.sub(rf'^(  {name}: )[^\n]+$', rf'\g<1>^{version}', content, flags=re.M)
        updates[path] = content
    for path, content in updates.items():
        path.write_text(content)


def candidates(root, stage):
    for name in PACKAGES:
        source = root / 'packages' / name
        target = stage / name
        target.mkdir()
        for item in CONTENTS:
            original = source / item
            if original.is_dir():
                shutil.copytree(original, target / item)
            elif original.exists():
                shutil.copy2(original, target / item)
        manifest = (source / 'pubspec.yaml').read_text()
        # Independent resolution proves hosted dependencies rather than workspace overrides.
        manifest = re.sub(r'^(?:#\s*)?publish_to: none\n|^resolution: workspace\n', '', manifest, flags=re.M)
        (target / 'pubspec.yaml').write_text(manifest)


def published(name, version):
    url = f'https://pub.dev/api/packages/{name}/versions/{quote(version, safe="")}'
    try:
        with urlopen(url, timeout=15) as response:
            return json.load(response).get('version') == version
    except HTTPError as error:
        if error.code == 404 or error.code == 429 or error.code >= 500:
            return False
        raise
    except (URLError, TimeoutError):
        return False


def wait_for(name, version, timeout=900, interval=15):
    deadline = time.monotonic() + timeout
    while not published(name, version):
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError(f'Timed out waiting for {name} {version} on pub.dev')
        print(f'Waiting for {name} {version} on pub.dev ({int(remaining)}s left)...', flush=True)
        time.sleep(min(interval, remaining))


def resolve(flutter, directory, retry, timeout, interval):
    deadline = time.monotonic() + timeout
    while True:
        try:
            subprocess.run([flutter, 'pub', 'get'], cwd=directory, check=True)
            return
        except subprocess.CalledProcessError:
            remaining = deadline - time.monotonic()
            if not retry or remaining <= 0:
                raise
            print('Dependency resolution failed; retrying within the registry wait limit.', flush=True)
            time.sleep(min(interval, remaining))


def verify_versions(root, version):
    if not VERSION.fullmatch(version):
        raise ValueError('Invalid semantic version')
    for name in PACKAGES:
        folder = root / 'packages' / name
        manifest = (folder / 'pubspec.yaml').read_text()
        if not re.search(rf'^version: {re.escape(version)}$', manifest, re.M):
            raise ValueError(f'{name}: version must match the release tag ({version})')
        for dependency in PACKAGES:
            match = re.search(rf'^  {dependency}: (.+)$', manifest, re.M)
            if match and match.group(1) != '^' + version:
                raise ValueError(f'{name}: {dependency} constraint must match {version}')
        if not re.search(rf'^## {re.escape(version)}(?:\s|$)', (folder / 'CHANGELOG.md').read_text(), re.M):
            raise ValueError(f'{name}: missing changelog entry for {version}')


def release(root, flutter, mode, start, timeout=900, interval=15, only=None, ci=False):
    with tempfile.TemporaryDirectory(prefix='gnu-clacks-publish-') as temporary:
        stage = Path(temporary)
        candidates(root, stage)
        selected = [only] if only else PACKAGES[PACKAGES.index(start):]
        for name in selected:
            directory = stage / name
            manifest = (directory / 'pubspec.yaml').read_text()
            version = re.search(r'^version: (.+)$', manifest, re.M).group(1)
            dependencies = [dependency for dependency in PACKAGES
                            if dependency != name and re.search(rf'^  {dependency}: ', manifest, re.M)]
            print(f'{mode}: {name}', flush=True)
            for dependency in dependencies:
                wait_for(dependency, version, timeout, interval)
            resolve(flutter, directory, bool(dependencies), timeout, interval)
            command = [flutter, 'pub', 'publish']
            if mode == 'dry-run':
                command.append('--dry-run')
            elif ci:
                # CI cannot prompt. Require clean validation before non-interactive upload.
                subprocess.run(command + ['--dry-run'], cwd=directory, check=True)
                command.append('--force')
            subprocess.run(command, cwd=directory, check=True)
            print(f'{name}: completed', flush=True)
            if mode == 'publish':
                wait_for(name, version, timeout, interval)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('version', help='Shared version for all five packages and the example')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--publish', action='store_true', help='Upload packages, with normal pub prompts')
    mode.add_argument('--dry-run', action='store_true', help='Validate independent candidates without upload')
    parser.add_argument('--start-at', choices=PACKAGES, default=PACKAGES[0],
                        help='Resume after earlier packages were published and are visible on pub.dev')
    parser.add_argument('--wait-timeout', type=int, default=900, help='Seconds per visibility/resolution wait (default: 900)')
    parser.add_argument('--poll-interval', type=int, default=15, help='Seconds between checks (default: 15)')
    parser.add_argument('--package', choices=PACKAGES, help='Publish or inspect only this package')
    parser.add_argument('--ci', action='store_true', help='Verify committed versions and use non-interactive publishing after a clean dry-run')
    args = parser.parse_args()
    if args.wait_timeout <= 0 or not 1 <= args.poll_interval <= 60:
        parser.error('Wait timeout must be positive and poll interval must be between 1 and 60 seconds')
    if args.ci and (not args.publish or not args.package):
        parser.error('--ci requires --publish and --package')
    try:
        if args.ci:
            expected = f'{args.package}-v{args.version}'
            if os.environ.get('GITHUB_REF') != 'refs/tags/' + expected or os.environ.get('GITHUB_EVENT_NAME') != 'push':
                raise ValueError('CI publishing requires a matching package tag push: ' + expected)
            verify_versions(ROOT, args.version)
        else:
            update_versions(ROOT, args.version)
            print('All suite versions and internal constraints updated to ' + args.version)
        if args.publish or args.dry_run:
            flutter = os.environ.get('GNU_CLACKS_FLUTTER') or shutil.which('flutter')
            if not flutter:
                raise ValueError('Flutter executable not found; set GNU_CLACKS_FLUTTER')
            release(ROOT, flutter, 'publish' if args.publish else 'dry-run', args.start_at,
                    args.wait_timeout, args.poll_interval, args.package, args.ci)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f'Release stopped: {error}\nNo later package was attempted. Local version edits, if any, remain; uploads already completed are not rolled back.\n')


if __name__ == '__main__':
    main()
