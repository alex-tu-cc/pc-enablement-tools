#!/bin/bash
set -x

if [ ! -e $1 ];then
    echo "please specify what amdgpu tarball you want to test"
fi

test_folder=`mktemp -d -p .`
test_folder_in_container="/tmp/$test_folder"

pushd $test_folder
#wget https://www2.ati.com/drivers/linux/ubuntu/18.04/amdgpu-pro-18.20-606296.tar.xz

tar xvf $1
cd `ls | grep amdgpu`
cat << EOF > test.sh
set -x
cd $test_folder_in_container
ls -l
#apt-get upgrade -y
#tar xvf $test_folder_in_container/amdgpu-pro-18.20-606296.tar.xz
dpkg --add-architecture i386
apt-get update
export DEBIAN_FRONTEND=noninteractive
# to skip grub operation
rm /etc/kernel/postinst.d/zz-update-grub
yes|apt-get install -y --allow-change-held-packages linux-generic dkms
#dpkg -i core amdgpu-dkms
rm -rf /var/cache/apt/archives/*.deb
yes| ./amdgpu-pro-install -y --opencl=legacy,rocm --allow-unauthenticated
#yes| ./amdgpu-pro-install -y
tree /var/lib/dkms/amdgpu
mkdir amdgpu-out
cd amdgpu-out
tar zcf amdgpu.log.tar.gz /var/lib/dkms/amdgpu
ls -l /var/cache/apt/archives
tar zcf dependency.tar.gz /var/cache/apt/archives
EOF


#docker run --rm -v `pwd`:$test_folder_in_container ubuntu:18.04 bash $test_folder_in_container/test.sh
docker run --rm -v `pwd`:$test_folder_in_container bionic-base bash $test_folder_in_container/test.sh
popd
