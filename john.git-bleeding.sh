#!/bin/bash
git clone git://github.com/magnumripper/JohnTheRipper -b bleeding-jumbo john-bleeding-jumbo
# Need this if doing a GPU-accelerated build.  Note that the kernel version for the cuda driver should match the current kernel version
# apt-get -y install nvidia-cuda-dev nvidia-cuda-toolkit nvidia-kernel-3.14-kali1-amd64 nvidia-driver amd-opencl-dev
aptitude search "nvidia" 2>&1 | grep -q "^i"

if [ $? -eq 0 ]; then
	INSTALLLIST="libbz2-dev libpcap-dev nvidia-opencl-dev"
else
	# Don't install nvidia if nvidia isn't set up.
	INSTALLLIST="libbz2-dev libpcap-dev"
fi

apt-get -y install $INSTALLLIST
echo "Use ./configure && make to build."
echo "No make parameters or makefile changes are required to build with multi-core, opencl, and cuda support."

