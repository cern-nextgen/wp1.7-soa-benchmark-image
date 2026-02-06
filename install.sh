#! /bin/bash

dnf install -y 'dnf-command(config-manager)'
dnf config-manager --set-enabled crb
dnf install -y epel-release
dnf install -y clang gcc g++ eigen3-devel vim wget unzip which

# install cmake
dnf install -y git openssl-devel
git clone --depth 1 --branch v4.1.0 https://github.com/Kitware/CMake.git
cd CMake
./bootstrap
make
make install
cd ..
rm -rf CMake

# install google-benchmark
git clone --depth 1 --branch v1.9.4 https://github.com/google/benchmark.git
cd benchmark
cmake -E make_directory "build"
cmake -E chdir "build" cmake -DBENCHMARK_DOWNLOAD_DEPENDENCIES=on -DCMAKE_BUILD_TYPE=Release ../
cmake --build "build" --config Release
cmake -E chdir "build" ctest --build-config Release
cmake --build "build" --config Release --target install

tee /etc/yum.repos.d/oneAPI.repo << 'EOF'
[oneAPI]
name=Intel® oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF

dnf install -y intel-oneapi-vtune

dnf clean all
dnf makecache

# install libfmt-devel
wget https://github.com/fmtlib/fmt/releases/download/11.1.4/fmt-11.1.4.zip
unzip fmt-11.1.4.zip
rm fmt-11.1.4.zip
cd fmt-11.1.4
cmake .
make install
cd ..
rm -rf fmt-11.1.4

# install CUDA development tools
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
dnf install -y cuda-cudart-devel-12-8 cuda-nvcc-12-8 cuda-profiler-api-12-8 cuda-nvrtc-devel-12-8

# install boost-wave from source to get devel files
wget https://archives.boost.io/release/1.82.0/source/boost_1_82_0.tar.gz
tar -xzf boost_1_82_0.tar.gz
rm boost_1_82_0.tar.gz
cd boost_1_82_0
./bootstrap.sh --with-libraries=wave
./b2
./b2 install
cd ..
rm -rf boost_1_82_0

# Check installation
grep -i "error" vtune_install.log || echo "VTune installed successfully"
ls /opt/intel/oneapi/vtune/latest/bin64/vtune || echo "VTune binary not found"

# Add VTune to PATH
echo 'export PATH=/opt/intel/oneapi/vtune/latest/bin64:$PATH' >> /etc/profile.d/vtune.sh
echo 'export VTUNE_INSTALL_DIR=/opt/intel/oneapi/vtune/latest' >> /etc/profile.d/vtune.sh

# install python libraries
dnf install -y python3-pip
pip3 install --upgrade pip
pip3 install matplotlib pandas

cd /root
git clone --depth 1 --branch p2996 https://github.com/bloomberg/clang-p2996.git 
cd clang-p2996 
dnf install -y lld 
mkdir build 
cmake -S llvm -B build -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=/usr/bin/clang -DLLVM_ENABLE_LLD=on 
        -DLLVM_BUILD_LLVM_DYLIB=ON -DLLVM_LINK_LLVM_DYLIB=on -DLLVM_APPEND_VC_REV=off -DLLVM_ENABLE_ASSERTIONS=on 
        -DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra;lld' -DLLVM_ENABLE_RUNTIMES="libc;libcxx;libcxxabi;libunwind"  
        -DCMAKE_INSTALL_PREFIX=/data/apps/clang-p2996/install -DCMAKE_BUILD_TYPE=Release -DLLVM_BUILD_DOCS=OFF      
        -DLLVM_BUILD_BENCHMARKS=OFF -DLIBCXX_INSTALL_MODULES=ON -DLLDB_ENABLE_PYTHON=0 
cmake --build build -j $(nproc) 
cd ../

dnf clean all
