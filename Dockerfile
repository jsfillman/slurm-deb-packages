ARG BASE_IMAGE=jsfillman/slurm-deb-base-mini
# ARG BASE_IMAGE=nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

FROM $BASE_IMAGE

ARG SLURM_VERSION=24.05.5
ARG DEBIAN_FRONTEND=noninteractive

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

