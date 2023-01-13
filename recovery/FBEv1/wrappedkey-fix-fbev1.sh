#!/system/bin/sh
#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2022-2023 The OrangeFox Recovery Project
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
#

# wrappedkey fix script for FBEv1
#

# the recovery log
LOGF=/tmp/recovery.log;

# do we want debug info?
DEBUG=1; # yes

# Deal with situations where the ROM doesn't support wrappedkey encryption;
# In such cases, remove the wrappedkey flag from the fstab file

# file_getprop <file> <property>
file_getprop() {
  local F=$(grep -m1 "^$2=" "$1" | cut -d= -f2);
  echo $F | sed 's/ *$//g';
}

# NOTE: this function is hard-coded for a handful of ROMs which, at the time of writing this script, 
# did not support wrappedkey; if any of them starts supporting wrappedkey, the function will need to be amended
fix_fstab_wrappedkey() {
local D=/FFiles/temp/system_prop;
local S=/dev/block/bootdevice/by-name/system;
local F=/FFiles/temp/system-build.prop;
local found=0;
PROCESSED=0;
    cd /FFiles/temp/;
    mkdir -p $D;
    mount -r $S $D;
    cp $D/system/build.prop $F;
    umount $D;
    rmdir $D;

    [ ! -e $F ] && {
    	echo "$F does not exist. Quitting." >> $LOGF;
    	return;
    }

    # check the ROM's SDK for >= A13
    SDK=$(file_getprop "$F" "ro.build.version.sdk");
    [ -z "$SDK" ] && SDK=$(file_getprop "$F" "ro.system.build.version.sdk");
    [ -z "$SDK" ] && SDK=$(file_getprop "$F" "ro.vendor.build.version.sdk");
    [ -z "$SDK" ] && SDK=31; # default to A12

    # assume for the moment that A13 ROMs don't support wrappedkey
    if [ $SDK -ge 33 ]; then
	found=1;
	echo "I:OrangeFox: ROM SDK=$SDK" >> $LOGF;

	# except these A13 ROMs (for now)
	if [ -n "$(grep ro.catalyst. $F)" ]; then
	 	found=0;
    	elif [ -n "$(grep ro.derp. $F)" ]; then
    		found=0;
    	elif [ -n "$(grep ro.cherish. $F)" ]; then
    		found=0;
    	elif [ -n "$(grep ro.xtended. $F)" ]; then
    		found=0;
    	fi
    	[ "$found" = "0" ] && PROCESSED=1;
    else
    	# miatoll A12 ROMs that don't support wrappedkey (as of the date of writing this script)
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
    	fi
    	[ "$found" = "1" ] && PROCESSED=1;
    fi

    if [ "$found" = "1" ]; then
       	sed -i -e "s/wrappedkey//g" /system/etc/recovery.fstab;
       	[ "$DEBUG" = "1" ] && echo "Debug:OrangeFox: this ROM does not support wrappedkey. Removing the wrappedkey flags from the fstab" >> $LOGF;
    elif [ "$found" = "0" ]; then
       	[ "$DEBUG" = "1" ] && echo "Debug:OrangeFox: this ROM supports wrappedkey. Continuing with the default fstab" >> $LOGF;
    fi

    # cleanup
    rm $F;
}

# a second check for wrappedkey, from the ROM's fstab.qcom
second_check() {
local D=/FFiles/temp/vendor_prop;
local S=/dev/block/bootdevice/by-name/vendor;
local F=/FFiles/temp/fstab.qcom;
    cd /FFiles/temp/;
    mkdir -p $D;
    mount -r $S $D;
    [ -e $D/etc/fstab.qcom ] && cp $D/etc/fstab.qcom $F || cp $D/etc/fstab.default $F;
    umount $D;
    rmdir $D;

    # if we've alreadty sorted this out, we only want a copy of the fstab.qcom, and then return
    [ "$PROCESSED" = "1" ] && return;
    
    # only continue with A13 or higher
    [ $SDK -lt 33 ] && return;

    [ ! -e $F ] && {
    	echo "$F does not exist. Quitting." >> $LOGF;
    	return;
    }

    # check for wrappedkey flags in userdata and metadata lines
    local wrap0=$(grep "/userdata" "$F" | grep "wrappedkey");
    local wrap1=$(grep "/metadata" "$F" | grep "wrappedkey");
    if [ -n "$wrap0" -a -n "$wrap1" ]; then
       cp /system/etc/recovery-fbev1.fstab /system/etc/recovery.fstab;
       [ "$DEBUG" = "1" ] && echo "Debug:OrangeFox: Actually, this ROM supports wrappedkey. Enabling wrappedkey..." >> $LOGF;
    fi
}

# ---
fix_fstab_wrappedkey;
second_check;
exit 0;
#
