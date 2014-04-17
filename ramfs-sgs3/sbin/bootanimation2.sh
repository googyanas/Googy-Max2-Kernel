#!/sbin/busybox sh

if [ -f /data/local/bootanimation2.bin ]; then
  /data/local/bootanimation2.bin
#  || [ -f /system/media/bootanimation2.zip ]
elif [ -f /data/local/bootanimation2.zip ]; then
  /sbin/bootanimation
else
  /system/bin/samsungani
fi;
