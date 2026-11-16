"""Render an already-built web example with external DNS blocked. Local test only."""
import argparse
import functools
import http.server
import json
import pathlib
import subprocess
import tempfile
import threading


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--bundle', default='apps/gnu_clacks_example/build/web')
    parser.add_argument('--chrome', default='/opt/google/chrome/chrome')
    parser.add_argument('--screenshot', default='/tmp/gnu-clacks-example-web.png')
    args = parser.parse_args()
    requests = []

    class Handler(http.server.SimpleHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def do_GET(self):
            requests.append(self.path)
            super().do_GET()

    handler = functools.partial(Handler, directory=str(pathlib.Path(args.bundle).resolve()))
    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        with tempfile.TemporaryDirectory(prefix='gnu-clacks-browser-') as profile:
            result = subprocess.run([
                args.chrome, '--headless', '--disable-gpu', '--disable-background-networking',
                '--disable-component-update', '--disable-sync', '--no-first-run',
                '--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE 127.0.0.1, EXCLUDE localhost',
                '--window-size=1280,1000', '--hide-scrollbars', '--virtual-time-budget=12000',
                f'--user-data-dir={profile}', f'--screenshot={args.screenshot}',
                f'http://127.0.0.1:{server.server_port}/',
            ], capture_output=True, text=True, timeout=50)
            if result.returncode != 0:
                raise RuntimeError(result.stderr[-2500:])
            if not pathlib.Path(args.screenshot).exists():
                raise RuntimeError('Browser produced no screenshot')
            print(json.dumps({'exit_code': result.returncode, 'external_dns_blocked': True,
                              'local_requests': requests, 'screenshot': args.screenshot}))
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)


if __name__ == '__main__':
    main()
