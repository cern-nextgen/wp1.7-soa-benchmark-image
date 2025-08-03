#! /bin/bash

dnf install -y 'dnf-command(config-manager)'
dnf config-manager --set-enabled crb
dnf install -y epel-release
dnf install -y clang gcc g++ cmake google-benchmark-devel eigen3-devel vim wget unzip which
dnf install -y git # not strictly needed
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

dnf clean all
