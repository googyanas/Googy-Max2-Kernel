#!/sbin/busybox sh
# root installation helper by GM
rm /data/.googy/install-root > /dev/null 2>&1
exit
(
while : ; do
	# keep this running until we have root
	if [ -e /data/.googy/install-root ] ; then
		rm /data/.googy/install-root
		/sbin/busybox sh /sbin/ext/install.sh
		exit 0
	fi
	if [ -e /system/xbin/su ] ; then
		exit 0
	fi
	sleep 5
done
) &
