#!/sbin/busybox sh
if [ ! -f /data/.googy/efsbackup.tar.gz ];
then
  mkdir /data/.googy
  chmod 777 /data/.googy
  /sbin/busybox tar zcvf /data/.googy/efsbackup.tar.gz /efs
  /sbin/busybox cat /dev/block/mmcblk0p3 > /data/.googy/efsdev-mmcblk0p3.img
  /sbin/busybox gzip /data/.googy/efsdev-mmcblk0p3.img
  /sbin/busybox cp /data/.googy/efs* /data/media
  chmod 777 /data/media/efsdev-mmcblk0p3.img
  chmod 777 /data/media/efsbackup.tar.gz
fi

