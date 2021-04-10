#!/bin/bash
set -x
CD_PATH="$PWD"
JENKINS_B_NO="lastSuccessfulBuild"
usage() {
cat << EOF
usage:
$0 options --iso [ISO file] | [file.iso] [<options to get iso from jenkins artifacts>]
$0 options [<options to get iso from jenkins artifacts>] [-s][-f]

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
    -s          no interactive

options to get iso from jenkins artifacts:
    --jenkins-url           The url of target Jenkins
    --jenkins-job           The job of target Jenkins
    --jenkins-job-number   Tthe buile number of target Jenkins job
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
        -s)
            SILENCE="TRUE"
            ;;
        --jenkins-url)
            shift
            JENKINS_URL="$1"
            ;;
        --jenkins-job)
            shift
            JENKINS_JOB="$1"
            ;;
        --jenkins-job-number)
            shift
            JENKINS_B_NO="$1"
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

if [ -n "$JENKINS_URL" ] && [ -n "$JENKINS_JOB" ]; then
    img_jenkins_out_url="ftp://$JENKINS_URL/jenkins_host/jobs/$JENKINS_JOB/builds/$JENKINS_B_NO/archive/out"
    img_name="$(wget -q "$img_jenkins_out_url/" -O - | grep -o 'href=.*iso"' | awk -F/ '{print $NF}' | tr -d \")"
    wget "$img_jenkins_out_url/$img_name".md5sum
    md5sum -c "$img_name".md5sum || wget "$img_jenkins_out_url"/"$img_name"
    md5sum -c "$img_name".md5sum || usage
    ISO="$img_name"
fi

[ -z "$ISO" ] && usage
usb_mnt_list=$(mount | grep udisk | awk -F'type|on' '{print $1}' | sort)
usb_list=$(echo "$usb_mnt_list"| sed 's/[1-9]//' | uniq)
if [ -z "$usb_list" ]; then
    echo "can not find any USB be insertted!"
    usage
fi

if [ $(echo $usb_list | wc -l) -gt 1 ];then
    echo "there are more than one usb disk...."
    echo $usb_list
    exit
else
    usb_target=$(echo $usb_list | tr -d "[:blank:]")
fi

mnt_folder="$(mktemp -d -p "$PWD")"
sudo mount -o loop $ISO $mnt_folder

echo "press any key to wipe $usb_target and create bootable usb..... "
[ "$SILENCE" == "TRUE" ] || read
sudo umount $usb_mnt_list
sudo wipefs -a $usb_target 2>&1 || (echo "Wipefs failed"; usage)
sudo parted -s $usb_target mktable msdos || (echo "parted mktable failed."; usage)
sudo parted -s $usb_target mkpart primary  0% 100% || (echo "parted mkpart failed."; usage)
usb_target="${usb_target}1"
sleep 2
sudo mkfs.vfat -F 32  $usb_target

target_folder="$(mktemp -d -p "$PWD")"
sudo mount -t vfat -o gid=$UID,uid=$UID $usb_target $target_folder

echo "pless any keye to do ionice -c 3 rsync --delete -avP $mnt_folder/ "$target_folder""
[ "$SILENCE" == "TRUE" ] || read
ionice -c 3 rsync --delete -avP $mnt_folder/ "$target_folder"
#rm -rf "$target_folder"/*
#ionice -c 3 msrsync -p 2 -P -r "-av" $mnt_folder/ "$target_folder"
#diff -qr "$target_folder" $mnt_folder || echo "!!!! ERROR: diff failed !!!!"
iso_name=$(grep "<iso" "$target_folder/bto.xml" | sed 's/<[^>]*>//g')
project_name=$(echo $iso_name | sed 's/.*xenial-\(.*\)-X.*/\1/')
echo ================================================================
echo $iso_name
echo ================================================================
pushd "$target_folder" || exit 1
    echo $project_name | tee project
    if [ -n "$FOLDER" ] && [ -d "$FOLDER" ]; then
        echo "pless any keye to do ionice -c 3 rsync -avP $FOLDER/ ."
        [ "$SILENCE" == "TRUE" ] || read
        ionice -c 3 rsync -avP $FOLDER/ .
    fi
popd

sudo umount $mnt_folder
sudo umount $target_folder
rm -rf $mnt_folder
[ -e $(which zenity) ] && zenity --info --text="$0 $ISO done"

