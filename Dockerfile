FROM registry.cern.ch/docker.io/nvidia/cuda:12.8.1-base-rockylinux9 as gcc-builder

ENV GCC_SOURCE=/tmp/gcc
ENV GCC_BUILD=/tmp/gcc-build
ENV GCC_INSTALL_PREFIX=/opt/gcc

RUN dnf update -y \
    && dnf install -y \
    gcc gcc-c++ git make \
    bzip2 flex bison \
    gawk \
    diffutils patch \
    libzstd-devel \
    zlib-devel \
    glibc-devel glibc-headers \
    binutils \
    python3

RUN git clone --depth 1 https://gcc.gnu.org/git/gcc.git ${GCC_SOURCE}

WORKDIR ${GCC_SOURCE}

RUN ./contrib/download_prerequisites

WORKDIR ${GCC_BUILD}

RUN ${GCC_SOURCE}/configure \
        --prefix=${GCC_INSTALL_PREFIX} \
        --disable-multilib \
        --enable-languages=c,c++ \
        --enable-checking=release \
    && make -j $(nproc) \
    && make install


FROM registry.cern.ch/docker.io/nvidia/cuda:12.8.1-base-rockylinux9 as clang-builder

ENV CLANG_SOURCE=/tmp/clang
ENV CLANG_BUILD=/tmp/clang-build
ENV CLANG_INSTALL_PREFIX=/opt/clang

RUN dnf update -y \
    && dnf install -y \
    gcc gcc-c++ make lld \
    cmake \
    python3 python3-pip \
    git \
    libstdc++-devel \
    libxml2-devel \
    ncurses-devel \
    libedit-devel \
    xz-devel \
    elfutils-libelf-devel \
    binutils \
    glibc-devel \
    glibc-headers \
    && python3 -m pip install pyyaml

RUN git clone --depth 1 https://github.com/llvm/llvm-project.git ${CLANG_SOURCE}

WORKDIR ${CLANG_SOURCE}

RUN cmake -S ${CLANG_SOURCE}/llvm -B ${CLANG_BUILD} \
        -DCMAKE_C_COMPILER=gcc \
        -DCMAKE_CXX_COMPILER=g++ \
        -DLLVM_ENABLE_LLD=ON \
        -DLLVM_BUILD_LLVM_DYLIB=ON \
        -DLLVM_LINK_LLVM_DYLIB=ON \
        -DLLVM_APPEND_VC_REV=OFF \
        -DLLVM_ENABLE_ASSERTIONS=ON \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld" \
        -DLLVM_ENABLE_RUNTIMES="libc;libcxx;libcxxabi;libunwind" \
        -DCMAKE_INSTALL_PREFIX=${CLANG_INSTALL_PREFIX} \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_BUILD_DOCS=OFF \
        -DLLVM_BUILD_BENCHMARKS=OFF \
        -DLIBCXX_INSTALL_MODULES=ON \
        -DLIBCXX_ENABLE_INCOMPLETE_FEATURES=ON \
    && cmake --build ${CLANG_BUILD} --target install -j $(nproc)


FROM registry.cern.ch/docker.io/nvidia/cuda:12.8.1-base-rockylinux9 as eigen-builder

ENV EIGEN_VERSION=5.0.0
ENV EIGEN_SOURCE=/tmp/eigen
ENV EIGEN_INCLUDE=/opt/eigen

WORKDIR ${EIGEN_INCLUDE}

RUN mkdir ${EIGEN_SOURCE} \
    && curl -o ${EIGEN_SOURCE}/eigen-${EIGEN_VERSION}.tar.gz \
    https://gitlab.com/libeigen/eigen/-/archive/${EIGEN_VERSION}/eigen-${EIGEN_VERSION}.tar.gz \
    && tar -xf ${EIGEN_SOURCE}/eigen-${EIGEN_VERSION}.tar.gz -C ${EIGEN_SOURCE} --strip-components=1 \
    && mv ${EIGEN_SOURCE}/Eigen ${EIGEN_INCLUDE}/Eigen


FROM registry.cern.ch/docker.io/nvidia/cuda:12.8.1-base-rockylinux9

COPY --from=gcc-builder /opt/gcc /usr/local
COPY --from=clang-builder /opt/clang /usr/local
COPY --from=eigen-builder /opt/eigen /usr/local/include

# install CUDA development tools
RUN dnf upgrade -y \
    && dnf install -y git which \
    && dnf install -y python3-pip cuda-cudart-devel-12-8 cuda-nvcc-12-8 \
    && python3 -m pip install cmake google-benchmark matplotlib pandas \
    && echo "/usr/local/lib64" > /etc/ld.so.conf.d/local.conf \
    && echo "/usr/local/lib" >> /etc/ld.so.conf.d/local.conf \
    && ldconfig

ENV LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
ENV CC=gcc
ENV CXX=g++

