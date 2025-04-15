#! /bin/bash

dnf install -y 'dnf-command(config-manager)'
dnf config-manager --set-enabled crb
dnf install -y epel-release
dnf install -y git clang gcc g++ cmake google-benchmark-devel eigen3-devel

# install boost-wave from source to get devel files
git clone --depth 1 --branch boost-1.88.0 https://github.com/boostorg/boost.git
cd boost
./bootstrap.sh --with-libraries=wave
./b2
./b2 install
cd ..
rm -rf boost

