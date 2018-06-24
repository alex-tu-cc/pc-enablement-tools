#!/bin/bash
#set -x
set -e
CD_PATH="$PWD"
usage() {
cat << EOF
usage: $0 options --iso [ISO file]

** This script assume you only have one USB disk plugged, USB disk
   will be wipe.

This command will create a bootable usb disk by the ISO file,
It assume the iso file in the same folder where script be executed.
options:
    -h|--help   print this message
    -f|--folder the folder you would like to inject fish tarballs
                it assume the foler is in the same folder where
                script be executed.
    -i|--iso    the iso file which be used to create a bootable USB
                disk.
example:
    * create a USB which already be formated to FAT32 with foo.iso
    iso file.
    $ ./rsync_iso.sh --iso foo.iso

    * create a USB which already be formated to FAT32 with foo.iso
    iso file and also include the security fish tarball in folder
    "bar_folder"
    $ ./rsync_iso.sh --iso foo.iso --folder bar_folder
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
        -f |--folder)
            shift
            FOLDER=$1;
            if [ ! -d $FOLDER ];then
                echo "not exists $FOLDER"
                exit 1
            fi
            ;;
        -i | --iso)
            shift
            ISO=$1
            if [ ! -e "$ISO" ]; then
                echo "not exists $FOLDER"
                exit 1
            fi
            ;;
        *)
            usage
       esac
       shift
done

[ -z "$ISO" ] && usage

usb_list=$(mount | grep -e "sd[b-z]" | cut -d ' ' -f3)
mnt_folder=$(mktemp -d -p .)

if [ $(echo $list | wc -l) -gt 1 ];then
    echo "there are more than one usb...."
    echo $list
    exit
fi

target_folder="$usb_list"
[ -d "$target_folder" ] || exit 1
echo "press any key to wipe $target_folder and create bootable usb..... "
read
sudo mount -o loop $ISO $mnt_folder
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
    echo $project_name | tee project
    if [ -n $FOLDER ]; then
        for file in $(ls $CD_PATH/$FOLDER); do
             [ -z ${file##*.gz}] && tar xvf $CD_PATH/$FOLDER/$file
        done
    fi
popd

sudo umount $mnt_folder
rm -rf $mnt_folder
notify_local.sh "$0 $iso_name done"
