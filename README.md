# Gramine Python Bug

## Overview

Minimal docker image to reproduce the bug with the following traceback:

```console
Traceback (most recent call last):
  File "/usr/lib/python3.10/ssl.py", line 1050, in _create
    self.getpeername()
OSError: [Errno 107] Transport endpoint is not connected

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "//scripts/main.py", line 42, in <module>
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
  File "/usr/lib/python3.10/ssl.py", line 513, in wrap_socket
    return self.sslsocket_class._create(
  File "/usr/lib/python3.10/ssl.py", line 1062, in _create
    notconn_pre_handshake_data = self.recv(1)
  File "/usr/lib/python3.10/ssl.py", line 1290, in recv
    return super().recv(buflen, flags)
PermissionError: [Errno 13] Permission denied
```

## Build

```console
$ sudo docker build . -t gramine-py-bug
```

## Run

```console
$ sudo docker run --device /dev/sgx_enclave --device /dev/sgx_provision -v /var/run/aesmd:/var/run/aesmd/ -it --rm gramine-py-bug
```
