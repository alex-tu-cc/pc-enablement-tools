#!/bin/bash

KERVER_VER=$(uname -r | cut -d '-' -f 1)


check_red_4_4(){
   modinfo iwlwifi | grep filename
   modinfo ath10k | grep filename
   dkms status | grep iwlwifi
   dkms status | grep ath10k
   dpkg -l | grep linux-firmware
   dpkg -l | grep wireless-regdb
}

check_red_4_13(){
   uname -r
   dpkg -l | grep linux-firmware
   dpkg -l | grep wireless-regdb
}

echo "== kernel: $KERVER_VER =="
if [ "$KERVER_VER" = "4.4.0" ];then
    check_red_4_4
elif [ "$KERVER_VER" = "4.13.0" ]; then
    check_red_4_13
    #statements
else
    echo "kernel not either 4.4 or 4.13, we should not be here."
fi
