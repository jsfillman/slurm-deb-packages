ARG BASE_IMAGE=jsfillman/slurm-deb-base-mini
# ARG BASE_IMAGE=nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

FROM $BASE_IMAGE

ARG SLURM_VERSION=24.05.5
ARG DEBIAN_FRONTEND=noninteractive

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
    apt install openmpi=${OPENMPI_VERSION}-${OPENMPI_SUBVERSION}

ENV LD_LIBRARY_PATH=/lib/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda/targets/aarch64-linux/lib:/usr/mpi/gcc/openmpi-${OPENMPI_VERSION}/lib
ENV PATH=$PATH:/usr/mpi/gcc/openmpi-${OPENMPI_VERSION}/bin

# Build deb packages for Slurm
RUN cd /usr/src/slurm-${SLURM_VERSION} && \
    sed -i 's/--with-pmix\b/--with-pmix=\/usr\/lib\/aarch64-linux-gnu\/pmix2/' debian/rules && \
    mk-build-deps -i debian/control -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" && \
    debuild -b -uc -us

RUN cd /usr/src && \
    git clone https://github.com/NVIDIA/nccl-tests.git && \
    cd nccl-tests && \
    make

# Move deb files
RUN mkdir /usr/src/debs && \
    mv /usr/src/*.deb /usr/src/debs/

# Create tar.gz archive with NCCL-tests binaries
RUN cd /usr/src/nccl-tests/build && \
    tar -czvf nccl-tests-perf.tar.gz *_perf