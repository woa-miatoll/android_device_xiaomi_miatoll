#!/system/bin/sh
#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2022 The OrangeFox Recovery Project
#
#	OrangeFox is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	any later version.
#
#	OrangeFox is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
# 	This software is released under GPL version 3 or any later version.
#	See <http://www.gnu.org/licenses/>.
#
# 	Please maintain this if you use this script or any part of it
#

# Deal with situations where the ROM doesn't support wrappedkey encryption;
# In such cases, remove the wrappedkey flag from the fstab file
#
# NOTE: this function is hard-coded for a handful of ROMs which, at the time of writing this script, 
# did not support wrappedkey; if any of them starts supporting wrappedkey, the function will need to be amended
fix_unwrap_decryption() {
local D=/tmp/system_prop;
local S=/dev/block/bootdevice/by-name/system;
local F=/tmp/build.prop;
local LOGF=/tmp/recovery.log;
    cd /tmp;
    echo "I:OrangeFox: running $0" >> $LOGF;
    mkdir -p $D;
    mount $S $D;
    cp $D/system/build.prop $F;
    umount $D;

    [ ! -e $F ] && { 
    	echo "$F does not exist. Quitting." >> $LOGF;
    	return;
    }

    local found=0;
    if [ -n "$(grep ro.potato $F)" ]; then
    	found=1;
    elif [ -n "$(grep org.pixelplusui $F)" ]; then
    	found=1;
    elif [ -n "$(grep org.evolution $F)" ]; then
    	found=1;
    elif [ -n "$(grep ro.pixys $F)" ]; then
    	found=1;
    elif [ -n "$(grep ro.streak $F)" ]; then
    	found=1;
    elif [ -n "$(grep org.pixelexperience $F)" ]; then
    	found=2;
    	# FBEv2 - fscrypt policy v2 is broken; try to remove /data from backup menu
    	echo "/data f2fs /dev/block/bootdevice/by-name/userdata flags=backup=0" >> /system/etc/twrp.flags;
    fi

    if [ "$found" = "1" ]; then
       echo "I:OrangeFox: this ROM does not support wrappedkey. Removing the wrappedkey flags from the fstab." >> $LOGF;
       sed -i -e "s/wrappedkey//g" /system/etc/recovery.fstab;
       #cp /etc/recovery-no-wrappedkey.fstab /etc/recovery.fstab;
    elif [ "$found" = "0" ]; then
       echo "I:OrangeFox: this ROM supports wrappedkey. Continuing with the default fstab" >> $LOGF;
    fi
}

fix_unwrap_decryption;
exit 0;
