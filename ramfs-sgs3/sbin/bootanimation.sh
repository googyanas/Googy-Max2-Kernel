#!/sbin/busybox sh

if [ -f /data/local/bootanimation.bin ]; then
  /data/local/bootanimation.bin
#  || [ -f /system/media/bootanimation.zip ]
elif [ -f /data/local/bootanimation.zip ]; then
  /sbin/bootanimation
else
  /system/bin/samsungani
fi;
