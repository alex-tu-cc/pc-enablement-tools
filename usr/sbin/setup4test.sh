#!/bin/bash
#
# This script creates an environment on remote platform. All operations are started from the host
# 
# Copyright © 2011 Canonical Ltd. 
# Author: Alex Wolfson awolfson (alex.wolfson@canonical.com), 2011
# License: GPL V2 or 3
#
# WHAT IT DOES:
#--------------
#
#Get remote credentials
#Install synergy, sshfs, hexr, checkbox, audio tools
#sshfs mount remote host
#setup synergy on remote and local Laptops
#
#TODO: is pctests/REMOTE_HOSTNAME is a good location for sshfs mount? may be just use a current directory or add a parameter?
#TODO: do we want to clean running synergies? this might change, if we decide to support testing more then 1 PC simultaneously
#    It will require more complicated conf file 
#TODO: fix setup checkbox
#TODO: clean up alsa, add more tools
# 
#TROUBLESHHOTING:
#---------------
#
# if you have a message, that remote host identification has been changed, run:
#------------------------------------------------------------------------------
# ssh-keygen -R remoteIP 
# and then rerun script
#
# To have a synergy running, after reboot:
#----------------------------------------
#on the host:
#synergys  -c pctests/REMOTE_HOSTNAME-synergy.conf 
#on the target 
#synergyc HOSTIP


USAGE(){
    echo -e "\nUsage: $(basename $0) {--localip|--lip} local_IP \n \
    {--remoteuser|--ru} remote_USER \n \
    {--remotepassword|--rp} remote_PASSWORD \n \
    {--remoteip|--rip} remote_IP \n \
    {--remotename|--rn} remote_NAME \n \
    [--alsa]  #install tools for debugging sound \n \
    [--hexr]  #install hexr \n \
    [--stap]  #install system tap \n \
    [--staprt] #install system tap runtime \nExample:\n \
    $(basename $0) --localip 10.0.1.123 --remoteuser u --rp u --rip 10.0.1.14"
}

if [ $# == 0 ] ; then USAGE; exit; fi

trap  cleanup 1 2 3 6

cleanup()
{
  echo "Caught Signal ... cleaning up."
  echo "Done cleanup ... quitting."
  exit 1
}


PCTESTS=~/pctests

#execute a command on the remote pc
remote_cmd(){
ssh -t $remote_user@$remote_ip $1
}
#local path, remote path 
cpto_cmd(){
scp $1 $remote_user@$remote_ip:$2 
}
checkbox=
alsa=
hexr=
stap=
staprt=
par=1
while [ "x$1" != "x" ]
do
  case "$1" in
    --lip|--localip) shift; local_ip=$1; echo -e "localip=$local_ip"; shift;;
    --ru|--remoteuser) shift; remote_user=$1; echo -e "remoteuser=$remote_user"; shift;;
    --rp|--remotepassword) shift; remote_password=$1; echo -e "remotepassword=$remote_password"; shift;;
    --rip|--remoteip) shift; remote_ip=$1; echo -e "remoteip=$remote_ip"; shift;;
    --rn|--remotename) shift; remote_name=$1; echo -e "remotename=$remote_name"; shift;;
    --cb|--checkbox) shift; checkbox=true; echo -e "checkbox=$checkbox, but it is not implemented yet";;
    --alsa) shift; alsa=true; echo -e "alsa=$alsa";;
    --hexr) shift; hexr=true; echo -e "hexr=$hexr";;
    --stap) shift; stap=true; echo -e "stap=$stap";;
    --staprt) shift; staprt=true; echo -e "staprt=$staprt";;
    -h|--help|--h) USAGE; exit 1 ;;
    *) echo -e "parameter $1 is not supported"; USAGE; exit 1;;
  esac
  par=par+1
done
if ! [ $local_ip -o $remote_user -o $remote_passwd -o $remote_ip ] ; then
    echo "One of the parameters is missing"
    USAGE
    exit 2
fi 
set -x
userid=$(id -un)

#sudo apt-get update
#sudo apt-get install sshfs openssh-server

#you shall already have on your Laptop 
#ssh-keygen -t rsa 
#setup keyless access on testpc
ssh-copy-id $remote_user@$remote_ip
if [ x${remote_name} != x ] ; then
    remote_hostname=${remote_name}
else
    remote_hostname=$(ssh $remote_user@$remote_ip hostname|cat -)
fi
local_hostname=$(hostname)
echo local_hostname=$local_hostname
echo remote_hostname=$remote_hostname

mkdir -p $PCTESTS/$remote_hostname

#install synergy and additional sw on testpc
remote_cmd "sudo apt-get install -y synergy mc sshfs"
fusermount -u $PCTESTS/$remote_hostname
sshfs $remote_user@$remote_ip:/ $PCTESTS/$remote_hostname
#Create conf files on Host. See:
#http://synergy2.sourceforge.net/configuration.html
cat > $PCTESTS/${remote_hostname}-synergy.cfg <<EOF
    section: screens
        $local_hostname:
        $remote_hostname:
    end

    section: aliases
        $remote_hostname:
            $remote_ip
    end

    section: links
    $local_hostname:
        left  = $remote_hostname
        right = $remote_hostname
    $remote_hostname:
        left  = $local_hostname
        right = $local_hostname
    end

    section: options
        screenSaverSync = false
    end
EOF
#start synergy on the host
killall synergys
synergys -c $PCTESTS/${remote_hostname}-synergy.cfg
#start synergy on the testpc
remote_cmd "killall synergyc"
remote_cmd "synergyc -n $remote_hostname $local_ip "
if [ $alsa ] ; then

    #audio debugging

    #get alsa-info.sh
    remote_cmd "wget -O alsa-info.sh http://www.alsa-project.org/alsa-info.sh"

    #setup x86 compatible device to debug alsa for hda audio

    #alsa tools
    #remote_cmd "sudo apt-add-repository ppa:diwic/maverick"
    #Crack of the day alsa-driver
    #remote_cmd "sudo add-apt-repository ppa:ubuntu-audio-dev/ppa"

    #remote_cmd sudo apt-get update
    #sound tools from ppa:diwic/maverick
    #sudo apt-get install alsamixertest snd-hda-tools
    #Crack of the day
    #sudo apt-get install linux-alsa-driver-modules-$(uname -r)
    #installing hda-analyzer

    remote_cmd "wget -O run.py http://www.alsa-project.org/hda-analyzer.py"
    remote_cmd "python run.py --help"
    remote_cmd "cp -r /dev/shm/hda-analyzer ."
fi
#setup checkbox
#if [ $checkbox ] ; then
    #remote_cmd "sudo python checkbox-oem-lazybone-install.py"
    #remote_cmd "checkbox-oem-gtk -W somerville-laptop" 
#fi

#setup hexr

if [ $hexr ] ; then
    remote_cmd "sudo apt-get install -y dmidecode pciutils usbutils"
    remote_cmd "wget -O upload-hw.py https://hexr.canonical.com/assets/upload-hw.py"
    remote_cmd "chmod +x upload-hw.py"
fi
if [ $stap ] ; then
    remote_cmd "mkdir -p systemtap"
    remote_cmd "sudo apt-get install -y systemtap systemtap-doc elfutils"
    cpto_cmd "stap-*.sh"  systemtap
fi
if [ x$staprt == xtrue -o x$stap == xtrue ] ; then
    #TODO currently supports oneiric only - provides system tap 1.6
    #TODO move to public place or preferable to oneiric repository
    remote_cmd "sudo add-apt-repository ppa:awolfson/systemtap; sudo apt-get update"
    remote_cmd "sudo apt-get install -y systemtap-runtime systemtap-client"
    remote_cmd "sudo usermod -a -G stapdev,stapusr $remote_user"
fi
