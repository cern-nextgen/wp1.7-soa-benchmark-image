#! /bin/bash

dnf install -y 'dnf-command(config-manager)'
dnf config-manager --set-enabled crb
dnf install -y epel-release
dnf install -y clang gcc g++ cmake google-benchmark-devel eigen3-devel wget
dnf install -y git # not strictly needed

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

# install python libraries
dnf install -y python3-pip
pip3 install --upgrade pip
pip3 install matplotlib pandas

dnf clean all
