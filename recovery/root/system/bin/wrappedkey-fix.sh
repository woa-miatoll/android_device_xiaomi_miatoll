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

# the recovery log
LOGF=/tmp/recovery.log;

# Deal with situations where the ROM doesn't support wrappedkey encryption;
# In such cases, remove the wrappedkey flag from the fstab file

# file_getprop <file> <property>
file_getprop() {
  local F=$(grep -m1 "^$2=" "$1" | cut -d= -f2);
  echo $F | sed 's/ *$//g';
}

# get the ROM's shipping API level and FBE version
get_API() {
local D=/FFiles/temp/vendor_prop;
local S=/dev/block/bootdevice/by-name/vendor;
local F=/FFiles/temp/vendor-build.prop;
local found=0;
local FBEv2=0;
    cd /FFiles/temp/;
    mkdir -p $D;
    mount -r $S $D;
    cp $D/build.prop $F;
    cp $D/etc/fstab.qcom /FFiles/temp/;
    umount $D;
    rmdir $D;

    [ ! -e $F ] && {
    	echo "$F does not exist. Quitting." >> $LOGF;
    	return;
    }

    # FBEv2
    local v2_1=$(grep ":v2" "/FFiles/temp/fstab.qcom");
    local v2_2=$(file_getprop "$F" "ro.crypto.volume.options");
    local v2_3=$(file_getprop "$F" "ro.crypto.dm_default_key.options_format.version");
    if [ -n "$v2_1" -o "$v2_2" = "::v2" -o "$v2_3" = "2" ]; then
    	FBEv2=1;
    fi

    # API level (if >=30, then it points to FBEv2)
    found=$(file_getprop "$F" "ro.product.first_api_level");
    [ -z "$found" ] && found=$(file_getprop "$F" "ro.board.first_api_level");
    [ -z "$found" ] && found=$(file_getprop "$F" "ro.vendor.api_level");
    if [ -n "$found" ]; then
    	if [ $found -ge 30 ]; then
		FBEv2=1;
    	fi

	echo "I:OrangeFox: Android shipping API level=$found" >> $LOGF;
	if [ "$FBEv2" = "1"  ]; then
		echo "I:OrangeFox: this ROM probably has FBE v2" >> $LOGF;
		#[ $found -lt 30 ] && echo "I:OrangeFox: this ROM seems misconfigured!" >> $LOGF;
	else
		echo "I:OrangeFox: this ROM probably has FBE v1" >> $LOGF;
	fi
    else
    	echo "I:OrangeFox: this ROM does not have an API level prop!" >> $LOGF;
    fi

    # check for FBEv2 wrappedkey_v0 flags
    local wrap0=$(grep "/userdata" "/FFiles/temp/fstab.qcom" | grep "wrappedkey_v0");
    if [ -n "$wrap0" -a "$FBEv2" = "1" ]; then
       echo "I:OrangeFox: this FBEv2 ROM supports wrappedkey_v0. Correcting the fstab" >> $LOGF;
       cp /system/etc/recovery-fbev2-wrap0.fstab /system/etc/recovery.fstab;
    fi

    # cleanup
    rm -f $F;
    # rm -f "/FFiles/temp/fstab.qcom";
}

# NOTE: this function is hard-coded for a handful of ROMs which, at the time of writing this script, 
# did not support wrappedkey; if any of them starts supporting wrappedkey, the function will need to be amended
fix_unwrap_decryption() {
local D=/FFiles/temp/system_prop;
local S=/dev/block/bootdevice/by-name/system;
local F=/FFiles/temp/system-build.prop;
local found=0;
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
    local SDK=$(file_getprop "$F" "ro.build.version.sdk");
    [ -z "$SDK" ] && SDK=$(file_getprop "$F" "ro.system.build.version.sdk");
    [ -z "$SDK" ] && SDK=$(file_getprop "$F" "ro.vendor.build.version.sdk");

    # assume for the moment that A13 ROMs don't support wrappedkey
    if [ -n "$SDK" -a $SDK -ge 33 ]; then
	found=1;
	echo "I:OrangeFox: ROM SDK=$SDK" >> $LOGF;

	# except these A13 ROMs (for now)
	if [ -n "$(grep ro.catalyst. $F)" ]; then
	 	found=0;
    	elif [ -n "$(grep ro.cherish. $F)" ]; then
    		found=0;
    	elif [ -n "$(grep ro.xtended. $F)" ]; then
    		found=0;
    	fi
    fi

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

    if [ "$found" = "1" ]; then
       local wrap0=$(grep "/userdata" "/system/etc/recovery.fstab" | grep "wrappedkey_v0"); # check for FBEv2 wrappedkey_v0, and skip, if found
       if [ -z "$wrap0" ]; then
       	  echo "I:OrangeFox: this ROM does not support wrappedkey. Removing the wrappedkey flags from the fstab" >> $LOGF;
       	  sed -i -e "s/wrappedkey//g" /system/etc/recovery.fstab;
       fi
    elif [ "$found" = "0" ]; then
       echo "I:OrangeFox: this ROM supports wrappedkey. Continuing with the default fstab" >> $LOGF;
    fi

    # cleanup
    rm $F;
}

# ---
#echo "I:OrangeFox: running $0" >> $LOGF;
V=$(getprop "ro.orangefox.variant");

[ "$V" = "FBEv2" ] && get_API;

fix_unwrap_decryption;

[ "$V" != "FBEv2" ] && get_API;
exit 0;
