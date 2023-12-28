#!/usr/bin/env python3

import logging
import ssl
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Optional
from pathlib import Path


EXIT_EVENT: threading.Event = threading.Event()


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


def serve(
    hostname: str,
    port: int,
    timeout: Optional[int],
    cert_path: Path,
    key_path: Path,
):
    httpd = HTTPServer((hostname, port), MyHTTPRequestHandler)

    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(
        certfile=str(cert_path.resolve()),
        keyfile=str(key_path.resolve()),
    )

    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)

    if timeout is not None:
        timer = threading.Timer(interval=timeout, function=kill)
        timer.start()

        threading.Thread(target=kill_event, args=(httpd, timer)).start()
    else:
        threading.Thread(target=kill_event, args=(httpd, None)).start()

    httpd.serve_forever()


def kill_event(httpd: HTTPServer, timer: Optional[threading.Timer]):
    while True:
        if EXIT_EVENT.is_set():
            logging.info("Stopping the configuration server...")

            if timer:
                timer.cancel()

            httpd.shutdown()
            return

        time.sleep(1)


def kill():
    EXIT_EVENT.set()


if __name__ == "__main__":
    root_path = Path(__file__).parent.resolve()
    key_path = root_path / Path("key.pem")
    cert_path = root_path / Path("cert.pem")
    serve("127.0.0.1", 4433, 30, cert_path, key_path)
