#!/bin/bash
#set -x
set -e
CD_PATH="$PWD"
usage() {
cat << EOF
usage: $0 options --iso [ISO file] | [file.iso]

**
This script assume you only have one USB disk plugged and it can be found in file manager,
 USB disk will be wipe.
**

This command will create a bootable usb disk by the ISO file,
It assume the iso file in the same folder where script be executed.
options:
    -h|--help   print this message
    -f|--folder the folder you would like to copy to root of target usb disk
    -i|--iso    the iso file which be used to create a bootable USB disk.
example:

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
            [ -z "${FOLDER##/*}" ] || [ -z "${FOLDER##~/*}" ] || FOLDER="$CD_PATH/$FOLDER"
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
            if [ -z ${i##*.iso} ]; then
                ISO=$1
            else
                usage
            fi
       esac
       shift
done

[ -z "$ISO" ] && usage
usb_list=$(mount | grep udisk | awk -F'type|on' '{print $1}')
if [ -z "$usb_list" ]; then
    echo "can not find any USB be insertted!"
    usage
fi

mnt_folder=$(mktemp -d -p .)

if [ $(echo $list | wc -l) -gt 1 ];then
    echo "there are more than one usb...."
    echo $list
    exit
fi

target_folder=$(mktemp -d -p .)
echo "press any key to wipe $usb_list and create bootable usb..... "
read
sudo umount $usb_list
sudo mount -t vfat -o gid=$UID,uid=$UID $usb_list $target_folder
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
        cp -r $FOLDER $target_folder
    fi
popd

sudo umount $mnt_folder
sudo umount $target_folder
rm -rf $mnt_folder
[ -e $(which zenity) ] && zenity --info --text="$0 $ISO done"

