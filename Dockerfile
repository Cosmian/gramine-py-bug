FROM ubuntu:22.04

USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV TS=Etc/UTC
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONPYCACHEPREFIX "/tmp"
ENV PYTHONUNBUFFERED 1

RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker
RUN echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    git \
    build-essential \
    pkg-config \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    gnupg \
    ca-certificates \
    curl \
    tzdata \
    wget && \
    rm -rf /var/lib/apt/lists/*

# # Gramine APT repository
# RUN curl -fsSLo /usr/share/keyrings/gramine-keyring.gpg https://packages.gramineproject.io/gramine-keyring.gpg && \
#     echo "deb [arch=amd64 signed-by=/usr/share/keyrings/gramine-keyring.gpg] https://packages.gramineproject.io/ 1.5 main" \
#     | tee /etc/apt/sources.list.d/gramine.list

#
# Gramine compilation from source
#
ENV KERNEL_VERSION 6.2.0-39-generic

RUN apt-get update && apt-get install -y \
    linux-headers-$KERNEL_VERSION \
    autoconf \
    bison \
    gawk \
    nasm \
    ninja-build \
    meson \
    python3-click \
    python3-jinja2 \
    python3-pyelftools \
    python3-tomli \
    python3-tomli-w \
    libprotobuf-c-dev \
    protobuf-c-compiler \
    protobuf-compiler \
    python3-cryptography \
    python3-protobuf && \
    rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/gramineproject/gramine
RUN cd gramine/ && git checkout 0bea67b7b7c00ce351d8f308268c6a6979996d8c && \
    meson setup build/ --buildtype=release \
        -Ddirect=enabled \
        -Dsgx=enabled \
        -Dsgx_driver_include_path=/usr/src/linux-headers-$KERNEL_VERSION/arch/x86/include/uapi && \
    ninja -C build/ && \
    ninja -C build/ install

# Intel SGX APT repository
RUN curl -fsSLo /usr/share/keyrings/intel-sgx-deb.asc https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-sgx-deb.asc] https://download.01.org/intel-sgx/sgx_repo/ubuntu jammy main" \
    | tee /etc/apt/sources.list.d/intel-sgx.list

# Install Intel SGX dependencies and Gramine
RUN apt-get update && apt-get install -y \
    libsgx-launch \
    libsgx-urts \
    libsgx-quote-ex \
    libsgx-epid \
    libsgx-dcap-ql \
    libsgx-dcap-quote-verify \
    linux-base-sgx \
    libsgx-dcap-default-qpl \
    sgx-aesm-service \
    libsgx-aesm-quote-ex-plugin \
    # remove temporarly
    # gramine && \
    && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/intel

ARG SGX_SDK_VERSION=2.22
ARG SGX_SDK_INSTALLER=sgx_linux_x64_sdk_2.22.100.3.bin

# Install Intel SGX SDK
RUN curl -fsSLo $SGX_SDK_INSTALLER https://download.01.org/intel-sgx/sgx-linux/$SGX_SDK_VERSION/distro/ubuntu22.04-server/$SGX_SDK_INSTALLER \
    && chmod +x  $SGX_SDK_INSTALLER \
    && echo "yes" | ./$SGX_SDK_INSTALLER \
    && rm $SGX_SDK_INSTALLER

# Configure virtualenv
ENV GRAMINE_VENV=/opt/venv
RUN python3 -m venv $GRAMINE_VENV

# Update pip and setuptools
RUN . "$GRAMINE_VENV/bin/activate" && \
    python3 -m pip install -U pip setuptools

WORKDIR /root

RUN gramine-sgx-gen-private-key
COPY python/build_and_run.sh python/Makefile python/python.manifest.template /root/
COPY python/scripts/main.py python/scripts/args python/scripts/key.pem python/scripts/cert.pem /root/scripts/

ENTRYPOINT ["./build_and_run.sh"]
