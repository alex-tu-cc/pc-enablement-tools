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
ls -l
dpkg --add-architecture i386
apt-get update
export DEBIAN_FRONTEND=noninteractive
# to skip grub operation
rm /etc/kernel/postinst.d/zz-update-grub
yes|apt-get install -y --allow-change-held-packages linux-generic dkms linux-oem tree
rm -rf /var/cache/apt/archives/*.deb
yes| ./amdgpu-pro-install -y --opencl=legacy,rocm --allow-unauthenticated
tree /var/lib/dkms/amdgpu
mkdir amdgpu-out
cd amdgpu-out
tar zcf amdgpu.log.tar.gz /var/lib/dkms/amdgpu
ls -l /var/cache/apt/archives
tar zcf dependency.tar.gz /var/cache/apt/archives
find . -name make.log | xargs grep -r Error && touch Fail
EOF


#docker run --rm -v `pwd`:$test_folder_in_container ubuntu:18.04 bash $test_folder_in_container/test.sh
docker run --rm -v `pwd`:$test_folder_in_container $ROOTFS bash $test_folder_in_container/test.sh
[ -e Fail ] && echo "FAILED"
popd
