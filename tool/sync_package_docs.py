"""Keep public package archive docs equal to authoritative repository sources."""
import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMON = ['PROTOCOL.md', 'SECURITY_MODEL.md', 'MIGRATION.md', 'PLATFORM_MATRIX.md']
EXTRA = {'gnu_clacks': ['HTTP_INTEGRATIONS.md', 'FLUTTER_UI.md'], 'gnu_clacks_core': [], 'gnu_clacks_http': ['HTTP_INTEGRATIONS.md'],
         'gnu_clacks_dio': ['HTTP_INTEGRATIONS.md'], 'gnu_clacks_flutter': ['FLUTTER_UI.md']}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    stale = []
    for package, names in EXTRA.items():
        folder = ROOT / 'packages' / package / 'doc'
        for name in COMMON + names:
            source = (ROOT / 'docs' / name).read_bytes()
            target = folder / name
            if not target.exists() or target.read_bytes() != source:
                stale.append(str(target.relative_to(ROOT)))
                if not args.check:
                    folder.mkdir(exist_ok=True)
                    target.write_bytes(source)
        image = ROOT / 'docs/images/example_web.png'
        image_target = folder / 'images/example_web.png'
        if not image_target.exists() or image_target.read_bytes() != image.read_bytes():
            stale.append(str(image_target.relative_to(ROOT)))
            if not args.check:
                image_target.parent.mkdir(exist_ok=True)
                image_target.write_bytes(image.read_bytes())
        example = (ROOT / 'packages' / package / 'example' / (package + '_example.dart')).read_text().strip()
        readme = ROOT / 'packages' / package / 'README.md'
        content = readme.read_text()
        start_marker, end_marker = '<!-- EXAMPLE_BEGIN -->', '<!-- EXAMPLE_END -->'
        snippet = start_marker + '\n```dart\n' + example + '\n```\n' + end_marker
        if start_marker in content:
            before, remainder = content.split(start_marker, 1)
            _, after = remainder.split(end_marker, 1)
            updated = before + snippet + after
        else:
            updated = content + '\n' + snippet + '\n'
        if updated != content:
            stale.append(str(readme.relative_to(ROOT)))
            if not args.check:
                readme.write_text(updated)
    if args.check and stale:
        raise SystemExit('Stale package docs: ' + ', '.join(stale))
    print('Package archive docs are current.' if args.check else 'Package archive docs synchronised.')


if __name__ == '__main__':
    main()
