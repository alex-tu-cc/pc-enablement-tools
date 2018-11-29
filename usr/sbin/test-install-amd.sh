#!/bin/bash
# reference:
# - How to Check MD5 Sums of Installed Packages in Debian/Ubuntu Linux (because AMD gpu used to mass up mesa files)
#  - https://www.tecmint.com/check-verify-md5sum-packages-files-in-linux/

set -x

usage() {
cat << EOF
usage: $0 options

    -h|--help   print this message
    --dry-run   dryrun
    --rootfs    target Ubuntu docker image
    --amdgpu    target amdgpu driver tarball
EOF
exit 1
}

while [ $# -gt 0 ]
do
    case "$1" in
        -h | --help)
            usage 0
            exit 0
            ;;
        --rootfs)
            shift
            ROOTFS=$1;
            ;;
        --amdgpu)
            shift
            AMDGPU=$1;
            ;;
        *)
        usage
       esac
       shift
done

if [ ! -e "$AMDGPU" ];then
    echo "please specify what amdgpu tarball you want to test"
    usage
fi

if [[ `docker images $ROOTFS | wc -l ` < 2 ]]; then
 echo "please specify an exists docker image";
 usage
fi

test_folder=`mktemp -d -p .`
test_folder_in_container="/tmp/$test_folder"

pushd $test_folder
#wget https://www2.ati.com/drivers/linux/ubuntu/18.04/amdgpu-pro-18.20-606296.tar.xz

tar xvf $AMDGPU
cd `ls | grep amdgpu`
cat << EOF > test.sh
set -x
cd $test_folder_in_container
mkdir -p amdgpu-out/deps
ls -l
dpkg --add-architecture i386
apt-get update
export DEBIAN_FRONTEND=noninteractive
# to skip grub operation
rm /etc/kernel/postinst.d/zz-update-grub
yes|apt-get install -y --allow-change-held-packages linux-generic dkms linux-oem tree
rm -rf /var/cache/apt/archives/*.deb
set +x
while [ 1 ]; do rsync /var/cache/apt/archives/*.deb $test_folder_in_container/amdgpu-out/deps/;sleep 10;done &
set -x
yes| ./amdgpu-pro-install -y --opencl=legacy,rocm --allow-unauthenticated
tar -C /var/lib/dkms/amdgpu -zcf $test_folder_in_container/amdgpu-out/amdgpu.log.tar.gz .
tar -C $test_folder_in_container/amdgpu-out/deps -zcf $test_folder_in_container/amdgpu-out/deps.tar.gz .
find /var/lib/dkms/amdgpu -name make.log | xargs grep -r Error && touch Fail
EOF


#docker run --rm -v `pwd`:$test_folder_in_container ubuntu:18.04 bash $test_folder_in_container/test.sh
docker run --rm -v `pwd`:$test_folder_in_container $ROOTFS bash $test_folder_in_container/test.sh
[ -e Fail ] && echo "FAILED"
popd
