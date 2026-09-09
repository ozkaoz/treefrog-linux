#!/bin/sh

sleep 5

udisk_path=""

if [ -d "/media/hdd" ]; then
    udisk_path="/media/hdd"
elif [ -d "/media/usb" ]; then
    udisk_path="/media/usb"
elif [ -d "/media/sda" ]; then
    udisk_path="/media/sda"
elif [ -d "/media/sda1" ]; then
    udisk_path="/media/sda1"
else
    udisk_path="/media/sdb1"
fi

echo "udisk_path=${udisk_path}"

/usr/bin/player ${udisk_path}/jiuzhaigou.mkv &
/usr/bin/memtester 10M &
