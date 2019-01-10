#!/bin/bash
set -x
set -e
echo "usage: $0 \$target-iso-file.so"

if [ ! -e "$1" ]; then
    echo "iso file $1 not exist"
    exit 1
fi

usb_dev=$(mount | grep -e "\/sd[c-z]" | awk -F'type|on' '{print $1}')
#usb_dev="/dev/sda1"
mnt_folder=$(mktemp -d)

if [ $(echo $usb_dev | wc -l) -gt 1 ];then
    echo "there are more than one usb...."
    echo $list
    exit
fi

target_folder=$(mktemp -d)
sudo umount $usb_dev
sudo mount -t vfat -o gid=$UID,uid=$UID $usb_dev $target_folder

sudo mount -o loop $1 $mnt_folder
#target_folder="$usb_list"
[ -d "$(eval echo $target_folder)" ] || exit 1
ionice -c 3 rsync --delete -avP $mnt_folder/ "$target_folder"
#rm -rf "$target_folder"/*
#ionice -c 3 msrsync -p 2 -P -r "-av" $mnt_folder/ "$target_folder"
diff -qr "$target_folder" $mnt_folder
iso_name=$(grep "<iso" "$target_folder/bto.xml" | sed 's/<[^>]*>//g')
project_name=$(echo $iso_name | sed 's/.*xenial-\(.*\)-X.*/\1/')
echo ================================================================
echo $iso_name
echo ================================================================
pushd "$target_folder"
    #git clone https://github.com/alex-tu-cc/pc-tools-on-usb.git || true
    cp -rf /home/alextu/my-library/github/pc-tools-on-usb .
    echo $project_name | tee project

    pushd "pc-tools-on-usb"
        git remote add github https://github.com/alex-tu-cc/pc-tools-on-usb.git
        cp -r fish/* ../
    popd

popd

sudo umount $mnt_folder
sudo umount $target_folder
rm -rf $mnt_folder
notify_local.sh "$0 $iso_name done"
