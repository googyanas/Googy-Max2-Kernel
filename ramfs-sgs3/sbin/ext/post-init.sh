#!/sbin/busybox sh
# Logging
#/sbin/busybox cp /data/user.log /data/user.log.bak
#/sbin/busybox rm /data/user.log
#exec >>/data/user.log
#exec 2>&1

mkdir /data/.googy
chmod 777 /data/.googy
 
. /res/customconfig/customconfig-helper

ccxmlsum=`md5sum /res/customconfig/customconfig.xml | awk '{print $1}'`
if [ "a${ccxmlsum}" != "a`cat /data/.googy/.ccxmlsum`" ];
then
  rm -f /data/.googy/*.profile
  echo ${ccxmlsum} > /data/.googy/.ccxmlsum
fi
[ ! -f /data/.googy/default.profile ] && cp /res/customconfig/default.profile /data/.googy
[ ! -f /data/.googy/battery.profile ] && cp /res/customconfig/battery.profile /data/.googy
[ ! -f /data/.googy/balanced.profile ] && cp /res/customconfig/balanced.profile /data/.googy
[ ! -f /data/.googy/performance.profile ] && cp /res/customconfig/performance.profile /data/.googy

read_defaults
read_config
# insmod /lib/modules/logger.ko

#cpu min & max frequencies
echo "${scaling_min_freq}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo "${scaling_max_freq}" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

#cpu undervolting
echo "${cpu_undervolting}" > /sys/devices/system/cpu/cpu0/cpufreq/vdd_levels

#dynamic fsync
if [ "$Dyn_fsync_active" == "on" ];then
echo 1 > /sys/kernel/dyn_fsync/Dyn_fsync_active
else
echo 0 > /sys/kernel/dyn_fsync/Dyn_fsync_active
fi


echo "${int_scheduler}" > /sys/block/mmcblk0/queue/scheduler
echo "${int_read_ahead_kb}" > /sys/block/mmcblk0/bdi/read_ahead_kb
echo "${ext_scheduler}" > /sys/block/mmcblk1/queue/scheduler
echo "${ext_read_ahead_kb}" > /sys/block/mmcblk1/bdi/read_ahead_kb

##### GGY Sammy ZRAM #####

if [ "$sammyzram" == "on" ];then
/system/bin/rtccd2 -a 300M
fi

##### GGY TouchWake #####

#if [ "$touchwake" == "on" ];then
#echo 1 > /sys/devices/virtual/misc/touchwake/enabled
#fi

#if [ "$touchwake" == "off" ];then
#echo 0 > /sys/devices/virtual/misc/touchwake/enabled
#fi

##### GGY TouchWake end #####

#mdnie sharpness tweak
#if [ "$mdniemod" == "on" ];then
#. /sbin/ext/mdnie-sharpness-tweak.sh
#fi

if [ "$logger" == "on" ];then
insmod /lib/modules/logger.ko
fi

# disable debugging on some modules
if [ "$logger" == "off" ];then
  rm -rf /dev/log
  echo 0 > /sys/module/ump/parameters/ump_debug_level
  echo 0 > /sys/module/mali/parameters/mali_debug_level
  echo 0 > /sys/module/kernel/parameters/initcall_debug
  echo 0 > /sys//module/lowmemorykiller/parameters/debug_level
  echo 0 > /sys/module/earlysuspend/parameters/debug_mask
  echo 0 > /sys/module/alarm/parameters/debug_mask
  echo 0 > /sys/module/alarm_dev/parameters/debug_mask
  echo 0 > /sys/module/binder/parameters/debug_mask
  echo 0 > /sys/module/xt_qtaguid/parameters/debug_mask
fi


# boeffla sound
#echo "1" > /sys/class/misc/boeffla_sound/boeffla_sound
#echo "${headphone_volume} ${headphone_volume}" > /sys/class/misc/boeffla_sound/headphone_volume
#echo "${speaker_volume} ${speaker_volume}" > /sys/class/misc/boeffla_sound/speaker_volume
#echo "${privacy_mode}" > /sys/class/misc/boeffla_sound/privacy_mode
#echo "${}" > /sys/class/misc/boeffla_sound/eq
#echo "12 8 3 -1 1" > /sys/class/misc/boeffla_sound/eq_gains
#echo "${}" > /sys/class/misc/boeffla_sound/dac_direct
#echo "${}" > /sys/class/misc/boeffla_sound/dac_oversampling
#echo "${}" > /sys/class/misc/boeffla_sound/fll_tuning
#echo "${}" > /sys/class/misc/boeffla_sound/stereo_expansion
#echo "${}" > /sys/class/misc/boeffla_sound/mono_downmix
#echo "${}" > /sys/class/misc/boeffla_sound/mic_level_general
#echo "${}" > /sys/class/misc/boeffla_sound/mic_level_call

# for ntfs automounting
insmod /lib/modules/fuse.ko
mount -o remount,rw /
mkdir -p /mnt/ntfs
chmod 777 /mnt/ntfs
mount -o mode=0777,gid=1000 -t tmpfs tmpfs /mnt/ntfs
mount -o remount,ro /

/sbin/busybox sh /sbin/ext/install.sh

/system/xbin/daemonsu --auto-daemon &

##### Early-init phase tweaks #####
/sbin/busybox sh /sbin/ext/tweaks.sh

/sbin/busybox mount -t rootfs -o remount,ro rootfs

##### EFS Backup #####
(
/sbin/busybox sh /sbin/ext/efs-backup.sh
) &

##### Custom Boot Animation #####
if [ "$custombootanim" == "on" ];then
/sbin/bootanimation.sh
fi

/sbin/tinyplay /sbin/silence.wav -D 0 -d 0 -p 880

cp /sbin/*.ogg /system/media/audio/ui/

# Activate fast charge
echo 2 > /sys/kernel/fast_charge/force_fast_charge
echo 1 > /sys/kernel/fast_charge/failsafe

# apply STweaks defaults
export CONFIG_BOOTING=1
/res/uci.sh apply
export CONFIG_BOOTING=

##### init scripts #####
/sbin/busybox sh /sbin/ext/run-init-scripts.sh

##### ABB settings #####

echo $arm_slice_1_volt > /sys/devices/system/abb/arm/arm_slice_1_volt
echo $arm_slice_2_volt > /sys/devices/system/abb/arm/arm_slice_2_volt
echo $arm_slice_3_volt > /sys/devices/system/abb/arm/arm_slice_3_volt
echo $arm_slice_4_volt > /sys/devices/system/abb/arm/arm_slice_4_volt

echo $g3d_slice_1_volt > /sys/devices/system/abb/g3d/g3d_slice_1_volt
echo $g3d_slice_2_volt > /sys/devices/system/abb/g3d/g3d_slice_2_volt
echo $g3d_slice_3_volt > /sys/devices/system/abb/g3d/g3d_slice_3_volt

echo $mif_slice_1_volt > /sys/devices/system/abb/mif/mif_slice_1_volt
echo $mif_slice_2_volt > /sys/devices/system/abb/mif/mif_slice_2_volt

echo $int_slice_1_volt > /sys/devices/system/abb/int/int_slice_1_volt
echo $int_slice_2_volt > /sys/devices/system/abb/int/int_slice_2_volt

##### CPU settings #####

case "$default_governor" in

  0)
        echo "pegasusq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo $pegasusq_cpu_down_freq > /sys/devices/system/cpu/cpufreq/pegasusq/cpu_down_freq
        echo $pegasusq_cpu_down_rate > /sys/devices/system/cpu/cpufreq/pegasusq/cpu_down_rate
        echo $pegasusq_cpu_up_freq > /sys/devices/system/cpu/cpufreq/pegasusq/cpu_up_freq
        echo $pegasusq_cpu_up_rate > /sys/devices/system/cpu/cpufreq/pegasusq/cpu_up_rate
        echo $pegasusq_down_differential > /sys/devices/system/cpu/cpufreq/pegasusq/down_differential
        echo $pegasusq_freq_for_responsiveness > /sys/devices/system/cpu/cpufreq/pegasusq/freq_for_responsiveness
        echo $pegasusq_freq_step > /sys/devices/system/cpu/cpufreq/pegasusq/freq_step
        echo $pegasusq_hotplug_freq_1_1 > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_1_1
        echo $pegasusq_hotplug_freq_2_0 > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_2_0
        echo $pegasusq_hotplug_freq_2_1 > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_2_1
        echo $pegasusq_hotplug_freq_3_0 > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_3_0
        echo $pegasusq_hotplug_freq_3_1 > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_3_1
        echo $pegasusq_hotplug_freq_4_0 > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_freq_4_0
        echo $pegasusq_hotplug_rq_1_1 > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_1_1
        echo $pegasusq_hotplug_rq_2_0 > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_2_0
        echo $pegasusq_hotplug_rq_2_1 > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_2_1
        echo $pegasusq_hotplug_rq_3_0 > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_3_0
        echo $pegasusq_hotplug_rq_3_1 > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_3_1
        echo $pegasusq_hotplug_rq_4_0 > /sys/devices/system/cpu/cpufreq/pegasusq/hotplug_rq_4_0
        echo $pegasusq_ignore_nice_load > /sys/devices/system/cpu/cpufreq/pegasusq/ignore_nice_load
        echo $pegasusq_io_is_busy > /sys/devices/system/cpu/cpufreq/pegasusq/io_is_busy
        echo $pegasusq_sampling_down_factor > /sys/devices/system/cpu/cpufreq/pegasusq/sampling_down_factor
        echo $pegasusq_sampling_rate > /sys/devices/system/cpu/cpufreq/pegasusq/sampling_rate
        echo $pegasusq_sampling_rate_min > /sys/devices/system/cpu/cpufreq/pegasusq/sampling_rate_min
        echo $pegasusq_up_nr_cpus > /sys/devices/system/cpu/cpufreq/pegasusq/up_nr_cpus
        echo $pegasusq_up_threshold > /sys/devices/system/cpu/cpufreq/pegasusq/up_threshold       
        echo $pegasusq_up_threshold_at_min_freq > /sys/devices/system/cpu/cpufreq/pegasusq/up_threshold_at_min_freq
        echo $min_cpu_lock > /sys/devices/system/cpu/cpufreq/pegasusq/min_cpu_lock
        echo $max_cpu_lock > /sys/devices/system/cpu/cpufreq/pegasusq/max_cpu_lock
  ;; 
  1)
        echo "lulzactiveq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo $lulzactiveq_cpu_down_rate > /sys/devices/system/cpu/cpufreq/lulzactiveq/cpu_down_rate
        echo $lulzactiveq_cpu_up_rate > /sys/devices/system/cpu/cpufreq/lulzactiveq/cpu_up_rate
        echo $lulzactiveq_dec_cpu_load > /sys/devices/system/cpu/cpufreq/lulzactiveq/dec_cpu_load
        echo $lulzactiveq_inc_cpu_load > /sys/devices/system/cpu/cpufreq/lulzactiveq/inc_cpu_load
        echo $lulzactiveq_down_sample_time > /sys/devices/system/cpu/cpufreq/lulzactiveq/down_sample_time
        echo $lulzactiveq_up_sample_time > /sys/devices/system/cpu/cpufreq/lulzactiveq/up_sample_time
        echo $lulzactiveq_freq_table > /sys/devices/system/cpu/cpufreq/lulzactiveq/freq_table
        echo $lulzactiveq_hispeed_freq > /sys/devices/system/cpu/cpufreq/lulzactiveq/hispeed_freq
        echo $lulzactiveq_hotplug_freq_1_1 > /sys/devices/system/cpu/cpufreq/lulzactiveq/hotplug_freq_1_1
        echo $lulzactiveq_hotplug_freq_2_0 > /sys/devices/system/cpu/cpufreq/lulzactiveq/hotplug_freq_2_0
        echo $lulzactiveq_hotplug_freq_2_1 > /sys/devices/system/cpu/cpufreq/lulzactiveq/hotplug_freq_2_1
        echo $lulzactiveq_hotplug_freq_3_0 > /sys/devices/system/cpu/cpufreq/lulzactiveq/hotplug_freq_3_0
        echo $lulzactiveq_hotplug_freq_3_1 > /sys/devices/system/cpu/cpufreq/lulzactiveq/hotplug_freq_3_1
        echo $lulzactiveq_hotplug_freq_4_0 > /sys/devices/system/cpu/cpufreq/lulzactiveq/hotplug_freq_4_0
        echo $lulzactiveq_hotplug_rq_1_1 > /sys/devices/system/cpu/cpufreq/lulzactiveq/hotplug_rq_1_1
        echo $lulzactiveq_hotplug_rq_2_0 > /sys/devices/system/cpu/cpufreq/lulzactiveq/hotplug_rq_2_0
        echo $lulzactiveq_hotplug_rq_2_1 > /sys/devices/system/cpu/cpufreq/lulzactiveq/hotplug_rq_2_1
        echo $lulzactiveq_hotplug_rq_3_0 > /sys/devices/system/cpu/cpufreq/lulzactiveq/hotplug_rq_3_0
        echo $lulzactiveq_hotplug_rq_3_1 > /sys/devices/system/cpu/cpufreq/lulzactiveq/hotplug_rq_3_1
        echo $lulzactiveq_hotplug_rq_4_0 > /sys/devices/system/cpu/cpufreq/lulzactiveq/hotplug_rq_4_0
        echo $lulzactiveq_hotplog_sampling_rate > /sys/devices/system/cpu/cpufreq/lulzactiveq/hotplog_sampling_rate
        echo $lulzactiveq_ignore_nice_load > /sys/devices/system/cpu/cpufreq/lulzactiveq/ignore_nice_load
        echo $lulzactiveq_pump_down_step > /sys/devices/system/cpu/cpufreq/lulzactiveq/pump_down_step
        echo $lulzactiveq_pump_up_step > /sys/devices/system/cpu/cpufreq/lulzactiveq/pump_up_step
        echo $lulzactiveq_screen_off_max_step > /sys/devices/system/cpu/cpufreq/lulzactiveq/screen_off_max_step
        echo $lulzactiveq_up_nr_cpus > /sys/devices/system/cpu/cpufreq/lulzactiveq/up_nr_cpus
        echo $min_cpu_lock > /sys/devices/system/cpu/cpufreq/lulzactiveq/min_cpu_lock
        echo $max_cpu_lock > /sys/devices/system/cpu/cpufreq/lulzactiveq/max_cpu_lock
  ;;
  2)  
        echo "smartassV2" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    ;;
  3)  
        echo "GoogyQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo $GoogyQ_up_threshold > /sys/devices/system/cpu/cpufreq/GoogyQ/up_threshold
        echo $GoogyQ_sampling_rate_min > /sys/devices/system/cpu/cpufreq/GoogyQ/sampling_rate_min
        echo $GoogyQ_sampling_rate > /sys/devices/system/cpu/cpufreq/GoogyQ/sampling_rate
        echo $GoogyQ_sampling_down_factor > /sys/devices/system/cpu/cpufreq/GoogyQ/sampling_down_factor
        echo $GoogyQ_powersave_bias > /sys/devices/system/cpu/cpufreq/GoogyQ/powersave_bias
        echo $GoogyQ_io_is_busy > /sys/devices/system/cpu/cpufreq/GoogyQ/io_is_busy
        echo $GoogyQ_ignore_nice_load > /sys/devices/system/cpu/cpufreq/GoogyQ/ignore_nice_load
        echo $GoogyQ_down_differential > /sys/devices/system/cpu/cpufreq/GoogyQ/down_differential
    ;;
  4)
        echo "zzmoove" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo "1" > /sys/devices/system/cpu/cpufreq/zzmoove/profile_number
    ;;
  5)
        echo "zzmoove" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo "2" > /sys/devices/system/cpu/cpufreq/zzmoove/profile_number
    ;;
  6)
        echo "zzmoove" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo "3" > /sys/devices/system/cpu/cpufreq/zzmoove/profile_number
    ;;
  7)
        echo "zzmoove" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo "4" > /sys/devices/system/cpu/cpufreq/zzmoove/profile_number
    ;;
  8)
        echo "zzmoove" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo "5" > /sys/devices/system/cpu/cpufreq/zzmoove/profile_number
    ;;
  9)
        echo "zzmoove" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo "6" > /sys/devices/system/cpu/cpufreq/zzmoove/profile_number
    ;;
  10)
        echo "zzmoove" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo "7" > /sys/devices/system/cpu/cpufreq/zzmoove/profile_number
    ;;
  11)
        echo "zzmoove" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo "8" > /sys/devices/system/cpu/cpufreq/zzmoove/profile_number
    ;;
  12)
        echo "zzmoove" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo "9" > /sys/devices/system/cpu/cpufreq/zzmoove/profile_number
    ;;
  13)
        echo "zzmoove" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo "10" > /sys/devices/system/cpu/cpufreq/zzmoove/profile_number
    ;;
  14)  
        echo "zzmoove" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
        echo $zzmoove_down_threshold > /sys/devices/system/cpu/cpufreq/zzmoove/down_threshold
        echo $zzmoove_down_threshold_hotplug1 > /sys/devices/system/cpu/cpufreq/zzmoove/down_threshold_hotplug1
        echo $zzmoove_down_threshold_hotplug2 > /sys/devices/system/cpu/cpufreq/zzmoove/down_threshold_hotplug2
        echo $zzmoove_down_threshold_hotplug3 > /sys/devices/system/cpu/cpufreq/zzmoove/down_threshold_hotplug3
        echo $zzmoove_down_threshold_hotplug_freq1 > /sys/devices/system/cpu/cpufreq/zzmoove/down_threshold_hotplug_freq1
        echo $zzmoove_down_threshold_hotplug_freq2 > /sys/devices/system/cpu/cpufreq/zzmoove/down_threshold_hotplug_freq2
        echo $zzmoove_down_threshold_hotplug_freq3 > /sys/devices/system/cpu/cpufreq/zzmoove/down_threshold_hotplug_freq3
        echo $zzmoove_down_threshold_sleep > /sys/devices/system/cpu/cpufreq/zzmoove/down_threshold_sleep
        echo $zzmoove_up_threshold > /sys/devices/system/cpu/cpufreq/zzmoove/up_threshold
        echo $zzmoove_up_threshold_hotplug1 > /sys/devices/system/cpu/cpufreq/zzmoove/up_threshold_hotplug1
        echo $zzmoove_up_threshold_hotplug2 > /sys/devices/system/cpu/cpufreq/zzmoove/up_threshold_hotplug2
        echo $zzmoove_up_threshold_hotplug3 > /sys/devices/system/cpu/cpufreq/zzmoove/up_threshold_hotplug3
        echo $zzmoove_up_threshold_hotplug_freq1 > /sys/devices/system/cpu/cpufreq/zzmoove/up_threshold_hotplug_freq1
        echo $zzmoove_up_threshold_hotplug_freq2 > /sys/devices/system/cpu/cpufreq/zzmoove/up_threshold_hotplug_freq2
        echo $zzmoove_up_threshold_hotplug_freq3 > /sys/devices/system/cpu/cpufreq/zzmoove/up_threshold_hotplug_freq3
        echo $zzmoove_up_threshold_sleep > /sys/devices/system/cpu/cpufreq/zzmoove/up_threshold_sleep
        echo $zzmoove_early_demand > /sys/devices/system/cpu/cpufreq/zzmoove/early_demand
        echo $zzmoove_grad_up_threshold > /sys/devices/system/cpu/cpufreq/zzmoove/grad_up_threshold
        echo $zzmoove_ignore_nice_load > /sys/devices/system/cpu/cpufreq/zzmoove/ignore_nice_load
        echo $zzmoove_smooth_up > /sys/devices/system/cpu/cpufreq/zzmoove/smooth_up
        echo $zzmoove_smooth_up_sleep > /sys/devices/system/cpu/cpufreq/zzmoove/smooth_up_sleep
        echo $zzmoove_sampling_rate > /sys/devices/system/cpu/cpufreq/zzmoove/sampling_rate
        echo $zzmoove_sampling_rate_min > /sys/devices/system/cpu/cpufreq/zzmoove/sampling_rate_min
        echo $zzmoove_sampling_rate_sleep_multiplier > /sys/devices/system/cpu/cpufreq/zzmoove/sampling_rate_sleep_multiplier
        echo $zzmoove_sampling_down_factor > /sys/devices/system/cpu/cpufreq/zzmoove/sampling_down_factor
        echo $zzmoove_sampling_down_max_momentum > /sys/devices/system/cpu/cpufreq/zzmoove/sampling_down_max_momentum
        echo $zzmoove_sampling_down_momentum_sensitivity > /sys/devices/system/cpu/cpufreq/zzmoove/sampling_down_momentum_sensitivity
        echo $zzmoove_freq_step > /sys/devices/system/cpu/cpufreq/zzmoove/freq_step
        echo $zzmoove_freq_step_sleep > /sys/devices/system/cpu/cpufreq/zzmoove/freq_step_sleep
        echo $zzmoove_disable_hotplug > /sys/devices/system/cpu/cpufreq/zzmoove/disable_hotplug
        echo $zzmoove_hotplug_sleep > /sys/devices/system/cpu/cpufreq/zzmoove/hotplug_sleep
        echo $zzmoove_legacy_mode > /sys/devices/system/cpu/cpufreq/zzmoove/legacy_mode
        echo $zzmoove_hotplug_idle_threshold > /sys/devices/system/cpu/cpufreq/zzmoove/hotplug_idle_threshold
        echo $zzmoove_hotplug_block_cycles > /sys/devices/system/cpu/cpufreq/zzmoove/hotplug_block_cycles
        echo $zzmoove_disable_hotplug_sleep > /sys/devices/system/cpu/cpufreq/zzmoove/disable_hotplug_sleep
        echo $zzmoove_freq_limit > /sys/devices/system/cpu/cpufreq/zzmoove/freq_limit
        echo $zzmoove_freq_limit_sleep > /sys/devices/system/cpu/cpufreq/zzmoove/freq_limit_sleep
        
        echo $zzmoove_early_demand_sleep > /sys/devices/system/cpu/cpufreq/zzmoove/early_demand_sleep
        echo $zzmoove_grad_up_threshold_sleep > /sys/devices/system/cpu/cpufreq/zzmoove/grad_up_threshold_sleep
        echo $zzmoove_hotplug_block_up_cycles > /sys/devices/system/cpu/cpufreq/zzmoove/hotplug_block_up_cycles
        echo $zzmoove_hotplug_block_down_cycles > /sys/devices/system/cpu/cpufreq/zzmoove/hotplug_block_down_cycles
        echo $zzmoove_hotplug_idle_freq > /sys/devices/system/cpu/cpufreq/zzmoove/hotplug_idle_freq
        echo $zzmoove_sampling_rate_idle > /sys/devices/system/cpu/cpufreq/zzmoove/sampling_rate_idle
        echo $zzmoove_sampling_rate_idle_delay > /sys/devices/system/cpu/cpufreq/zzmoove/sampling_rate_idle_delay
        echo $zzmoove_sampling_rate_idle_threshold > /sys/devices/system/cpu/cpufreq/zzmoove/sampling_rate_idle_threshold
        echo $zzmoove_scaling_block_cycles > /sys/devices/system/cpu/cpufreq/zzmoove/scaling_block_cycles
        echo $zzmoove_scaling_block_freq > /sys/devices/system/cpu/cpufreq/zzmoove/scaling_block_freq
        echo $zzmoove_scaling_block_threshold > /sys/devices/system/cpu/cpufreq/zzmoove/scaling_block_threshold
        echo $zzmoove_scaling_block_force_down > /sys/devices/system/cpu/cpufreq/zzmoove/scaling_block_force_down
    ;;
esac;

### Sound engine initialization ###

if [ "$soundengine" == "wolfson" ];then

  echo 0 > /sys/class/misc/scoobydoo_sound_control/enable
  echo 1 > /sys/class/misc/wolfson_control/switch_master
  
    echo "$switch_eq_speaker" > /sys/class/misc/wolfson_control/switch_eq_speaker
    echo "$eq_sp_gain_1" > /sys/class/misc/wolfson_control/eq_sp_gain_1
    echo "$eq_sp_gain_2" > /sys/class/misc/wolfson_control/eq_sp_gain_2
    echo "$eq_sp_gain_3" > /sys/class/misc/wolfson_control/eq_sp_gain_3
    echo "$eq_sp_gain_4" > /sys/class/misc/wolfson_control/eq_sp_gain_4
    echo "$eq_sp_gain_5" > /sys/class/misc/wolfson_control/eq_sp_gain_5
    echo "$speaker_left" > /sys/class/misc/wolfson_control/speaker_left
    echo "$speaker_right" > /sys/class/misc/wolfson_control/speaker_right
    echo "$speaker_boost_level" > /sys/class/misc/wolfson_control/speaker_boost_level
    echo "$switch_privacy_mode" > /sys/class/misc/wolfson_control/switch_privacy_mode
    echo "$switch_eq_headphone" > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo "$headphone_left" > /sys/class/misc/wolfson_control/headphone_left
    echo "$headphone_right" > /sys/class/misc/wolfson_control/headphone_right
    echo "$stereo_expansion" > /sys/class/misc/wolfson_control/stereo_expansion
    echo "$mic_level_general" > /sys/class/misc/wolfson_control/mic_level_general
    echo "$mic_level_camera" > /sys/class/misc/wolfson_control/mic_level_camera
    echo "$mic_level_call" > /sys/class/misc/wolfson_control/mic_level_call
    echo "$switch_fll_tuning" > /sys/class/misc/wolfson_control/switch_fll_tuning
    echo "$switch_oversampling" > /sys/class/misc/wolfson_control/switch_oversampling
    echo "$switch_dac_direct" > /sys/class/misc/wolfson_control/switch_dac_direct
    echo "$switch_mono_downmix" > /sys/class/misc/wolfson_control/switch_mono_downmix
         
if [ "$switch_eq_headphone" != "0" ];then

    echo "0" > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo "$switch_eq_headphone" > /sys/class/misc/wolfson_control/switch_eq_headphone

if [ "$eq_selection2" != "0" ];then

#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo "$eq_hp_gain_1" > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo "$eq_hp_gain_2" > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo "$eq_hp_gain_3" > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo "$eq_hp_gain_4" > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo "$eq_hp_gain_5" > /sys/class/misc/wolfson_control/eq_hp_gain_5
#    echo 0 > /sys/class/misc/wolfson_control/switch_eq_headphone
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone

else

case "$eq_preset2" in
  0)
#    echo 0 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo "0" > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo "0" > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo "0" > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo "0" > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo "0" > /sys/class/misc/wolfson_control/eq_hp_gain_5
#    echo 0 > /sys/class/misc/wolfson_control/switch_eq_headphone
    ;;
  1)
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo "12" > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo "8" > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo "3" > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo "-1" > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo "1" > /sys/class/misc/wolfson_control/eq_hp_gain_5
#    echo 0 > /sys/class/misc/wolfson_control/switch_eq_headphone
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    ;;
  2)
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo "10" > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo "7" > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo "0" > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo "2" > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo "5" > /sys/class/misc/wolfson_control/eq_hp_gain_5
#    echo 0 > /sys/class/misc/wolfson_control/switch_eq_headphone
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    ;;
  3)
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo "-5" > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo "1" > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo "0" > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo "4" > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo "3" > /sys/class/misc/wolfson_control/eq_hp_gain_5
#    echo 0 > /sys/class/misc/wolfson_control/switch_eq_headphone
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    ;;
  4)
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo "0" > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo "0" > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo "0" > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo "-3" > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo "-5" > /sys/class/misc/wolfson_control/eq_hp_gain_5
#    echo 0 > /sys/class/misc/wolfson_control/switch_eq_headphone
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    ;;
  5)
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo "8" > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo "3" > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo "-2" > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo "3" > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo "8" > /sys/class/misc/wolfson_control/eq_hp_gain_5
#    echo 0 > /sys/class/misc/wolfson_control/switch_eq_headphone
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    ;;
  6)
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo "12" > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo "8" > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo "4" > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo "2" > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo "3" > /sys/class/misc/wolfson_control/eq_hp_gain_5
#    echo 0 > /sys/class/misc/wolfson_control/switch_eq_headphone
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    ;;
  7)
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    echo "10" > /sys/class/misc/wolfson_control/eq_hp_gain_1
    echo "2" > /sys/class/misc/wolfson_control/eq_hp_gain_2
    echo "-1" > /sys/class/misc/wolfson_control/eq_hp_gain_3
    echo "2" > /sys/class/misc/wolfson_control/eq_hp_gain_4
    echo "10" > /sys/class/misc/wolfson_control/eq_hp_gain_5
#    echo 0 > /sys/class/misc/wolfson_control/switch_eq_headphone
#    echo 1 > /sys/class/misc/wolfson_control/switch_eq_headphone
    ;;
esac;

fi

fi

    echo "$switch_eq_headphone" > /sys/class/misc/wolfson_control/switch_eq_headphone

else

if [ "$soundengine" == "scoobydoo" ];then

  echo "1" > /sys/class/misc/scoobydoo_sound_control/enable
  echo "0" > /sys/class/misc/wolfson_control/switch_master
  
    echo $speaker_tuning > /sys/class/misc/scoobydoo_sound/speaker_tuning
    echo $speaker_offset > /sys/class/misc/scoobydoo_sound/speaker_offset
    echo $privacy_mode > /sys/class/misc/scoobydoo_sound/privacy_mode
    echo $headphone_amplifier_level > /sys/class/misc/scoobydoo_sound/headphone_amplifier_level
    echo $headphone_balance > /sys/class/misc/scoobydoo_sound/headphone_balance
    echo $stereo_expansion > /sys/class/misc/scoobydoo_sound/stereo_expansion
    echo $stereo_expansion_gain > /sys/class/misc/scoobydoo_sound/stereo_expansion_gain
    echo $fll_tuning > /sys/class/misc/scoobydoo_sound/fll_tuning
    echo $dac_osr128 > /sys/class/misc/scoobydoo_sound/dac_osr128
    echo $dac_direct > /sys/class/misc/scoobydoo_sound/dac_direct
    echo $mono_downmix > /sys/class/misc/scoobydoo_sound/mono_downmix
    echo $mic_level_general > /sys/class/misc/scoobydoo_sound/mic_level_general
    echo $mic_level_camera > /sys/class/misc/scoobydoo_sound/mic_level_camera
    echo $mic_level_call > /sys/class/misc/scoobydoo_sound/mic_level_call

echo -${digital_gain}000 > /sys/class/misc/scoobydoo_sound/digital_gain
#echo 1 A 0x0FBB > /sys/class/misc/scoobydoo_sound/headphone_eq_bands_values
#echo 1 B 0x0407 > /sys/class/misc/scoobydoo_sound/headphone_eq_bands_values
#echo 1 PG 0x0114 > /sys/class/misc/scoobydoo_sound/headphone_eq_bands_values
#echo 2 A 0x1F8C > /sys/class/misc/scoobydoo_sound/headphone_eq_bands_values
#echo 2 B 0xF073 > /sys/class/misc/scoobydoo_sound/headphone_eq_bands_values
#echo 2 C 0x040A > /sys/class/misc/scoobydoo_sound/headphone_eq_bands_values
#echo 2 PG 0x01C8 > /sys/class/misc/scoobydoo_sound/headphone_eq_bands_values

if [ "$eq_selection" != "0" ];then

    echo $eq_band1 > /sys/class/misc/scoobydoo_sound/headphone_eq_b1_gain
    echo $eq_band2 > /sys/class/misc/scoobydoo_sound/headphone_eq_b2_gain
    echo $eq_band3 > /sys/class/misc/scoobydoo_sound/headphone_eq_b3_gain
    echo $eq_band4 > /sys/class/misc/scoobydoo_sound/headphone_eq_b4_gain
    echo $eq_band5 > /sys/class/misc/scoobydoo_sound/headphone_eq_b5_gain
    echo 1 > /sys/class/misc/scoobydoo_sound/headphone_eq
    
else

case "$eq_preset" in
  0)
    echo 0 > /sys/class/misc/scoobydoo_sound/headphone_eq_b1_gain
    echo 0 > /sys/class/misc/scoobydoo_sound/headphone_eq_b2_gain
    echo 0 > /sys/class/misc/scoobydoo_sound/headphone_eq_b3_gain
    echo 0 > /sys/class/misc/scoobydoo_sound/headphone_eq_b4_gain
    echo 0 > /sys/class/misc/scoobydoo_sound/headphone_eq_b5_gain
    echo 1 > /sys/class/misc/scoobydoo_sound/headphone_eq
    echo 0 > /sys/class/misc/scoobydoo_sound/headphone_eq
    ;;
  1)
    echo 12 > /sys/class/misc/scoobydoo_sound/headphone_eq_b1_gain
    echo 8 > /sys/class/misc/scoobydoo_sound/headphone_eq_b2_gain
    echo 3 > /sys/class/misc/scoobydoo_sound/headphone_eq_b3_gain
    echo -1 > /sys/class/misc/scoobydoo_sound/headphone_eq_b4_gain
    echo 1 > /sys/class/misc/scoobydoo_sound/headphone_eq_b5_gain
    echo 1 > /sys/class/misc/scoobydoo_sound/headphone_eq
    ;;
  2)
    echo 10 > /sys/class/misc/scoobydoo_sound/headphone_eq_b1_gain
    echo 7 > /sys/class/misc/scoobydoo_sound/headphone_eq_b2_gain
    echo 0 > /sys/class/misc/scoobydoo_sound/headphone_eq_b3_gain
    echo 2 > /sys/class/misc/scoobydoo_sound/headphone_eq_b4_gain
    echo 5 > /sys/class/misc/scoobydoo_sound/headphone_eq_b5_gain
    echo 1 > /sys/class/misc/scoobydoo_sound/headphone_eq
    ;;
  3)
    echo -5 > /sys/class/misc/scoobydoo_sound/headphone_eq_b1_gain
    echo 1 > /sys/class/misc/scoobydoo_sound/headphone_eq_b2_gain
    echo 0 > /sys/class/misc/scoobydoo_sound/headphone_eq_b3_gain
    echo 4 > /sys/class/misc/scoobydoo_sound/headphone_eq_b4_gain
    echo 3 > /sys/class/misc/scoobydoo_sound/headphone_eq_b5_gain
    echo 1 > /sys/class/misc/scoobydoo_sound/headphone_eq
    ;;
  4)
    echo 0 > /sys/class/misc/scoobydoo_sound/headphone_eq_b1_gain
    echo 0 > /sys/class/misc/scoobydoo_sound/headphone_eq_b2_gain
    echo 0 > /sys/class/misc/scoobydoo_sound/headphone_eq_b3_gain
    echo -3 > /sys/class/misc/scoobydoo_sound/headphone_eq_b4_gain
    echo -5 > /sys/class/misc/scoobydoo_sound/headphone_eq_b5_gain
    echo 1 > /sys/class/misc/scoobydoo_sound/headphone_eq
    ;;
  5)
    echo 8 > /sys/class/misc/scoobydoo_sound/headphone_eq_b1_gain
    echo 3 > /sys/class/misc/scoobydoo_sound/headphone_eq_b2_gain
    echo -2 > /sys/class/misc/scoobydoo_sound/headphone_eq_b3_gain
    echo 3 > /sys/class/misc/scoobydoo_sound/headphone_eq_b4_gain
    echo 8 > /sys/class/misc/scoobydoo_sound/headphone_eq_b5_gain
    echo 1 > /sys/class/misc/scoobydoo_sound/headphone_eq
    ;;
  6)
    echo 12 > /sys/class/misc/scoobydoo_sound/headphone_eq_b1_gain
    echo 8 > /sys/class/misc/scoobydoo_sound/headphone_eq_b2_gain
    echo 4 > /sys/class/misc/scoobydoo_sound/headphone_eq_b3_gain
    echo 2 > /sys/class/misc/scoobydoo_sound/headphone_eq_b4_gain
    echo 3 > /sys/class/misc/scoobydoo_sound/headphone_eq_b5_gain
    echo 1 > /sys/class/misc/scoobydoo_sound/headphone_eq
    ;;
  7)
    echo 10 > /sys/class/misc/scoobydoo_sound/headphone_eq_b1_gain
    echo 2 > /sys/class/misc/scoobydoo_sound/headphone_eq_b2_gain
    echo -1 > /sys/class/misc/scoobydoo_sound/headphone_eq_b3_gain
    echo 2 > /sys/class/misc/scoobydoo_sound/headphone_eq_b4_gain
    echo 10 > /sys/class/misc/scoobydoo_sound/headphone_eq_b5_gain
    echo 1 > /sys/class/misc/scoobydoo_sound/headphone_eq
    ;;
esac;
fi

else

  echo "0" > /sys/class/misc/scoobydoo_sound_control/enable
  echo "0" > /sys/class/misc/wolfson_control/switch_master

fi

fi