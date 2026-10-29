from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import urlsplit, unquote
import json, mimetypes

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'godot/content/food-collection'
PAGE = ROOT / 'docs/design/food-collection/gallery-single-page.html'
PREFIX = '/godot/content/food-collection/'

class Handler(BaseHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control','no-store')
        super().end_headers()

    def do_GET(self):
        path = unquote(urlsplit(self.path).path)
        if path == '/health':
            self.send_response(200); self.send_header('Content-Type','text/plain'); self.end_headers(); self.wfile.write(b'food-collection-preview-v1'); return
        target = None
        if path in ('/', '/docs/design/food-collection/gallery-single-page.html'): target = PAGE
        elif path in (PREFIX+'content.json', PREFIX+'layout-single-page.json'): target = BASE / path.split('/')[-1]
        elif path.startswith(PREFIX+'images/'):
            name = path[len(PREFIX+'images/'):]
            if name and name == Path(name).name and '/' not in name and '\\' not in name:
                try: allowed={r['image'] for r in json.loads((BASE/'content.json').read_text(encoding='utf-8'))['items']}
                except (OSError,ValueError,KeyError,TypeError): allowed=set()
                candidate=(BASE/'images'/name).resolve()
                if name in allowed and candidate.parent==(BASE/'images').resolve(): target=candidate
        if not target or not target.is_file(): self.send_error(404); return
        data=target.read_bytes(); self.send_response(200); self.send_header('Content-Type',mimetypes.guess_type(target.name)[0] or 'application/octet-stream'); self.send_header('Content-Length',str(len(data))); self.end_headers(); self.wfile.write(data)

if __name__ == '__main__': HTTPServer(('127.0.0.1',8769),Handler).serve_forever()
