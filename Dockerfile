ARG BASE_IMAGE=nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

FROM $BASE_IMAGE

ARG SLURM_VERSION=24.05.5
ARG DEBIAN_FRONTEND=noninteractive

# Install minimal dependencies
RUN apt-get update && \
    apt -y --no-install-recommends install \
        git \
        build-essential \
        devscripts \
        debhelper \
        fakeroot \
        wget \
        equivs \
        libssl-dev:arm64 \
        libpam0g-dev:arm64 \
        libtool \
        libjansson-dev:arm64 \
        libjson-c-dev:arm64 \
        munge \
        libmunge-dev \
        libjwt0:arm64 \
        libjwt-dev:arm64 \
        libhwloc-dev:arm64 \
        liblz4-dev:arm64 \
        flex \
        libevent-dev:arm64 \
        zlib1g-dev:arm64 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download Slurm source code
RUN cd /usr/src && \
    wget https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2 && \
    tar -xvf slurm-${SLURM_VERSION}.tar.bz2 && \
    rm -rf slurm-${SLURM_VERSION}.tar.bz2

# Prepare for building slurm-smd-client only
RUN cd /usr/src/slurm-${SLURM_VERSION} && \
    sed -i 's/--with-pmix\b/--with-pmix=\/usr\/lib\/aarch64-linux-gnu\/pmix2/' debian/rules && \
    sed -i 's/-flto=auto//g' debian/rules && \
    sed -i 's/-g -O2/-O2/' debian/rules && \
    dpkg --add-architecture arm64 && apt-get update && \
    mk-build-deps -i debian/control -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" || \
    (echo \"mk-build-deps failed\" && cat /var/log/apt/term.log && exit 1)

# Build only slurm-smd-client package
RUN cd /usr/src/slurm-${SLURM_VERSION} && \
    MAKEFLAGS="-j1" dpkg-buildpackage -us -uc -ui -b --target=binary-arch

# Move the resulting deb package
RUN mkdir /usr/src/debs && \
    mv /usr/src/slurm-smd-client_*.deb /usr/src/debs/

