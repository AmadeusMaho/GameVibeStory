"""Servidor local para jugar la versión web.

Uso (desde la carpeta del proyecto):  python web/serve.py
Luego abre http://localhost:8095/web/
Desactiva la caché para que los cambios se vean al recargar.
"""
import http.server
import os
import socketserver

PORT = 8095
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, *args):
        pass


socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("127.0.0.1", PORT), NoCacheHandler) as httpd:
    print(f"GameVibeStory en http://localhost:{PORT}/web/")
    httpd.serve_forever()
