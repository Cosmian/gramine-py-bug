#!/usr/bin/env python3

import ssl
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


class MyHTTPRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        """GET /."""
        msg: bytes = b"Hello World!"
        self.send_response(200)
        self.send_header("Content-Length", str(len(msg)))
        self.end_headers()
        self.wfile.write(msg)

    def do_POST(self) -> None:
        """POST /."""
        content_length: int = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length)
        print(f"body: {body}")
        self.send_response_only(200)
        self.end_headers()


if __name__ == "__main__":
    root_path = Path(__file__).parent.resolve()
    key_path = root_path / Path("key.pem")
    cert_path = root_path / Path("cert.pem")

    (hostname, port) = "127.0.0.1", 4433

    httpd = HTTPServer((hostname, port), MyHTTPRequestHandler)

    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(
        certfile=str(cert_path.resolve()),
        keyfile=str(key_path.resolve()),
    )

    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)

    httpd.serve_forever()
