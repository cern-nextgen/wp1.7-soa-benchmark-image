#! /bin/bash

dnf install -y 'dnf-command(config-manager)'
dnf config-manager --set-enabled crb
dnf install -y epel-release
dnf install -y clang gcc g++ cmake google-benchmark-devel eigen3-devel wget unzip which
dnf install -y git # not strictly needed

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

# install Intel VTune Profiler
VTUNE_VERSION="2024.1.0"
VTUNE_URL="https://registrationcenter-download.intel.com/akdlm/IRC_NAS/8fd43b33-e2fa-4ecf-96b3-3f927c9eb05c/l_oneapi_vtune_p_${VTUNE_VERSION}.offline.sh"

wget ${VTUNE_URL} -O vtune_installer.sh
chmod +x vtune_installer.sh
./vtune_installer.sh -s -a install --eula accept --components intel.oneapi.vtune --install-dir /opt/intel/oneapi
# Add VTune to PATH
echo 'export PATH=/opt/intel/oneapi/vtune/latest/bin64:$PATH' >> /etc/profile.d/vtune.sh
echo 'export VTUNE_INSTALL_DIR=/opt/intel/oneapi/vtune/latest' >> /etc/profile.d/vtune.sh

# install python libraries
dnf install -y python3-pip
pip3 install --upgrade pip
pip3 install matplotlib pandas

dnf clean all
