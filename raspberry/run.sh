echo 1000000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
echo 1000000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
echo 1000000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq
echo 1000000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq
echo 1000000 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_min_freq
echo 1000000 > /sys/devices/system/cpu/cpu2/cpufreq/scaling_max_freq
echo 1000000 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_min_freq
echo 1000000 > /sys/devices/system/cpu/cpu3/cpufreq/scaling_max_freq
echo -1 > /proc/sys/kernel/sched_rt_runtime_us
#echo 999999 > /proc/sys/kernel/sched_rt_runtime_us
export LD_LIBRARY_PATH=/usr/local/lib/arm-linux-gnueabihf/
./pc
