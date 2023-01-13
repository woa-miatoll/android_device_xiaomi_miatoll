#!/system/bin/sh
#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2019-2023 The OrangeFox Recovery Project
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

# This script is needed to automatically set device props.
load_curtana()
{
    resetprop "ro.product.model" "Redmi Note 9S"
    resetprop "ro.product.name" "curtana"
    resetprop "ro.build.product" "curtana"
    resetprop "ro.product.device" "curtana"
    resetprop "ro.vendor.product.device" "curtana"
}

load_joyeuse()
{
    resetprop "ro.product.model" "Redmi Note 9 Pro"
    resetprop "ro.product.name" "joyeuse"
    resetprop "ro.build.product" "joyeuse"
    resetprop "ro.product.device" "joyeuse"
    resetprop "ro.vendor.product.device" "joyeuse"
}

load_excalibur()
{
    resetprop "ro.product.model" "Redmi Note 9 Pro Max"
    resetprop "ro.product.name" "excalibur"
    resetprop "ro.build.product" "excalibur"
    resetprop "ro.product.device" "excalibur"
    resetprop "ro.vendor.product.device" "excalibur"
}

load_gram()
{
    resetprop "ro.product.model" "POCO M2 Pro"
    resetprop "ro.product.name" "gram"
    resetprop "ro.build.product" "gram"
    resetprop "ro.product.device" "gram"
    resetprop "ro.vendor.product.device" "gram"
}


project=$(getprop ro.boot.hwname)
echo $project

case $project in
    "curtana")
        load_curtana
        ;;
    "joyeuse")
        load_joyeuse
        ;;
    "excalibur")
        load_excalibur
        ;;
    "gram")
        load_gram
        ;;
    *)
        load_curtana
        ;;
esac

exit 0
