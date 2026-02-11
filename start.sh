#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "Please use root privileges to execute!"
    exit 1
fi

PACKAGE_NAME="com.tencent.ig"
TMP_DIR="/data/local/tmp"

GAME_ABI=$(dumpsys package "$PACKAGE_NAME" | grep "primaryCpuAbi" | awk -F '=' '{print $2}')
DEVICE_ABI=$(getprop ro.product.cpu.abi)

if [ -z "$GAME_ABI" ]; then
    echo "Error: Unable to determine GAME_ABI!"
    exit 1
fi

case $DEVICE_ABI in
    "arm64-v8a"|"armeabi-v7a")
        ABI="$GAME_ABI"
        ;;
    "x86_64")
        if [[ "$GAME_ABI" == "armeabi-v7a" ]]; then
            ABI="x86"
        else
            ABI="$GAME_ABI"
        fi
        ;;
    "x86")
        ABI="x86"
        ;;
    *)
        echo "Device ABI not supported!"
        exit 1
        ;;
esac

if [ -z "$ABI" ]; then
    echo "Error: ABI not determined!"
    exit 1
fi

if [ ! -f "assets/$ABI/Inject" ] || [ ! -f "assets/$GAME_ABI/SakuraStub" ]; then
    echo "Error: Required files not found in assets!"
    exit 1
fi

cp -f "assets/$ABI/Inject" "$TMP_DIR/Inject"
chmod 777 "$TMP_DIR/Inject"

cp -f "assets/$GAME_ABI/SakuraStub" "$TMP_DIR/SakuraStub"
chmod 777 "$TMP_DIR/SakuraStub"

if [ ! -f "$TMP_DIR/Inject" ] || [ ! -f "$TMP_DIR/SakuraStub" ]; then
    echo "Error: Failed to copy files to $TMP_DIR!"
    exit 1
fi

folders="
/data/user/0/$PACKAGE_NAME/files/ano_tmp
/data/user/0/$PACKAGE_NAME/app_appcache
/data/user/0/$PACKAGE_NAME/app_crashrecord
/data/user/0/$PACKAGE_NAME/app_crashSight
/data/user/0/$PACKAGE_NAME/app_databases
/data/user/0/$PACKAGE_NAME/app_flutter
"

for folder in $folders; do
    if [ -d "$folder" ]; then
        chmod -R 000 "$folder"
        echo "Set permission 000 for: $folder"
    fi
done
clear

echo -e "\nGame ABI: $GAME_ABI"
echo "Device ABI: $DEVICE_ABI"

su -c "$TMP_DIR/Inject" -pkg "$PACKAGE_NAME" -lib "$TMP_DIR/SakuraStub" -dl_memfd -remap_hide -remap_solist 

rm -f "$TMP_DIR/Inject"
rm -f "$TMP_DIR/SakuraStub"