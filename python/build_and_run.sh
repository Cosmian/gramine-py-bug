#!/bin/bash

set -e

make clean &&
make SGX=1 DEBUG=1 && 
source /opt/venv/bin/activate &&
gramine-sgx ./python
