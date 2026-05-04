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

ENV EIGEN_SOURCE=/tmp/eigen
ENV EIGEN_BUILD=/tmp/eigen-build
ENV EIGEN_INSTALL_PREFIX=/opt/eigen

RUN dnf install -y gcc gcc-c++ git make cmake

WORKDIR ${EIGEN_SOURCE}

RUN git clone --depth 1 --branch 5.0.1 https://gitlab.com/libeigen/eigen.git ${EIGEN_SOURCE}

RUN cmake -S ${EIGEN_SOURCE} -B ${EIGEN_BUILD} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=${EIGEN_INSTALL_PREFIX} \
    && cmake --build ${EIGEN_BUILD} --target install


FROM registry.cern.ch/docker.io/nvidia/cuda:12.8.1-base-rockylinux9 as benchmark-builder

ENV BENCHMARK_SOURCE=/tmp/benchmark
ENV BENCHMARK_BUILD=/tmp/benchmark-build
ENV BENCHMARK_INSTALL_PREFIX=/opt/benchmark

RUN dnf install -y gcc gcc-c++ git make cmake

WORKDIR ${BENCHMARK_SOURCE}

RUN git clone --depth 1 --branch v1.9.5 https://github.com/google/benchmark.git ${BENCHMARK_SOURCE}

RUN cmake -B ${BENCHMARK_BUILD} -S ${BENCHMARK_SOURCE} \
        -DBENCHMARK_DOWNLOAD_DEPENDENCIES=ON \
        -DCMAKE_INSTALL_PREFIX=${BENCHMARK_INSTALL_PREFIX} \
        -DCMAKE_BUILD_TYPE=Release \
    && cmake --build ${BENCHMARK_BUILD} --config Release \
    && cmake -E chdir ${BENCHMARK_BUILD} \
        ctest --build-config Release --exclude-regex locale_impermeability_test \
    && cmake --build ${BENCHMARK_BUILD} --config Release --target install


FROM registry.cern.ch/docker.io/nvidia/cuda:12.8.1-base-rockylinux9

COPY --from=gcc-builder /opt/gcc /usr/local
COPY --from=clang-builder /opt/clang /usr/local
COPY --from=eigen-builder /opt/eigen /usr/local
COPY --from=benchmark-builder /opt/benchmark /usr/local

RUN dnf upgrade -y \
    && dnf install -y gcc-toolset-14 git which python3-pip cuda-cudart-devel-12-8 cuda-nvcc-12-8 \
    && dnf clean all \
    && python3 -m pip install cmake matplotlib --no-cache-dir \
    && echo "/usr/local/lib64" > /etc/ld.so.conf.d/local.conf \
    && echo "/usr/local/lib" >> /etc/ld.so.conf.d/local.conf \
    && ldconfig

ENV LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
ENV CC=gcc
ENV CXX=g++

