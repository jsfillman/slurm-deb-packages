ARG BASE_IMAGE=nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

FROM $BASE_IMAGE

ARG SLURM_VERSION=24.05.5
ARG OPENMPI_VERSION=4.1.7a1
ARG OPENMPI_SUBVERSION=1.2310055
ARG OFED_VERSION=23.10-2.1.3.1

ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt -y --no-install-recommends install \
        git  \
        build-essential \
        devscripts \
        debhelper \
        fakeroot \
        wget \
        equivs \
        autoconf \
        pkg-config \
        libssl-dev \
        libpam0g-dev \
        libtool \
        libjansson-dev \
        libjson-c-dev \
        munge \
        libmunge-dev \
        libjwt0 \
        libjwt-dev \
        libhwloc-dev:arm64 \
        liblz4-dev \
        flex \
        libevent-dev \
        jq \
        squashfs-tools \
        zstd \
        zlib1g \
        zlib1g-dev \
        libpmix2:arm64 \
        libpmix-dev:arm64

# Download Slurm
RUN cd /usr/src && \
    wget https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2 && \
    tar -xvf slurm-${SLURM_VERSION}.tar.bz2 && \
    rm -rf slurm-${SLURM_VERSION}.tar.bz2

# Install Openmpi
RUN cd /etc/apt/sources.list.d && \
    wget https://linux.mellanox.com/public/repo/mlnx_ofed/${OFED_VERSION}/$(. /etc/os-release; echo $ID$VERSION_ID)/mellanox_mlnx_ofed.list && \
    wget -qO - https://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox | apt-key add - && \
    apt update && \
    apt install --no-install-recommends openmpi=${OPENMPI_VERSION}-${OPENMPI_SUBVERSION}

ENV LD_LIBRARY_PATH=/lib/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda/targets/aarch64-linux/lib:/usr/mpi/gcc/openmpi-${OPENMPI_VERSION}/lib
ENV PATH=$PATH:/usr/mpi/gcc/openmpi-${OPENMPI_VERSION}/bin

# Build deb packages for Slurm
RUN cd /usr/src/slurm-${SLURM_VERSION} && \
    sed -i 's/--with-pmix\b/--with-pmix=\/usr\/lib\/aarch64-linux-gnu\/pmix2/' debian/rules && \
    mk-build-deps -i debian/control -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" && \
    debuild -b -uc -us

################################################################
# RESULT
################################################################
# /usr/src/slurm-smd-client_24.05.5-1_arm64.deb
################################################################

RUN mkdir /usr/src/debs && \
    mv /usr/src/slurm-smd-client_*.deb /usr/src/debs/

