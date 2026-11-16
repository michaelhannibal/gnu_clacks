"""Check public pub.dev advisories for a resolved `dart pub deps --json` inventory."""
import argparse
import concurrent.futures
import datetime
import json
from pathlib import Path
import re
import urllib.request


def audit(package):
    name, version = package['name'], package['version']
    if not re.fullmatch(r'[a-z_][a-z0-9_]*', name):
        raise ValueError('Invalid hosted package identifier')
    url = 'https://pub.dev/api/packages/' + name + '/advisories'
    result = {'package': name, 'version': version, 'url': url}
    try:
        request = urllib.request.Request(url, headers={'Accept': 'application/vnd.pub.v2+json'})
        with urllib.request.urlopen(request, timeout=12) as response:
            data = json.load(response)
        if not isinstance(data.get('advisories'), list):
            raise ValueError('Missing advisory list')
        result.update(status='checked', advisories_updated=data.get('advisoriesUpdated'),
                      matching_advisories=[entry['id'] for entry in data['advisories']
                                           if any(version in affected.get('versions', [])
                                                  for affected in entry.get('affected', []))])
    except Exception as error:
        result.update(status='unverified', error=str(error))
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--inventory', required=True)
    parser.add_argument('--output', default='docs/DEPENDENCY_AUDIT.json')
    args = parser.parse_args()
    inventory = json.loads(Path(args.inventory).read_text())
    packages = [p for p in inventory['packages'] if p.get('source') == 'hosted']
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        results = list(pool.map(audit, packages))
    report = {'checked_at_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
              'scope': 'Resolved hosted dependencies including development tools. SDK/OS dependencies excluded. Known-advisory matches only, not a security guarantee.',
              'packages': results}
    Path(args.output).write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'packages': len(results), 'checked': sum(p['status'] == 'checked' for p in results),
                      'unverified': sum(p['status'] == 'unverified' for p in results),
                      'matches': {p['package']: p.get('matching_advisories') for p in results
                                  if p.get('matching_advisories')}}))
    if any(p['status'] != 'checked' or p.get('matching_advisories') for p in results):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
