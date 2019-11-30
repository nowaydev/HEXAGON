# CHECK RAM
RAM=$(free -m | awk '/Mem:/{print $2}') 2>/dev/null

# SELINUX CENTER
if [ -e /sys/fs/selinux/enforce ]; then
  setenforce 0
  echo "0" > /sys/fs/selinux/enforce
fi;

# SWAP
swap_on() {
  if [ -e /dev/block/zram0 ]; then
    swapoff /dev/block/zram0
    echo "0" > /sys/block/zram0/disksize
    echo "1" > /sys/block/zram0/reset
    if [ "$RAM" -lt 2800 ]; then
      ZR=1932735283
    else
      ZR=1073741824
    fi;
    echo "$ZR" > /sys/block/zram0/disksize
    mkswap /dev/block/zram0
    swapon /dev/block/zram0
  fi;
}

if [ "$RAM" -gt 5900 ]; then
  swapoff /dev/block/zram0
else
  swap_on
fi;

if [ -e /sys/kernel/mm/ksm/run ]; then
  echo "0" > /sys/kernel/mm/ksm/run
  setprop ro.config.ksm.support false
fi;

# VM TWEAKS
sync;
chmod 0644 /proc/sys/* 2>/dev/null

sysctl -e -w vm.dirty_ratio=42 2>/dev/null
sysctl -e -w vm.dirty_background_ratio=9 2>/dev/null
sysctl -e -w vm.drop_caches=0 2>/dev/null
sysctl -e -w vm.vfs_cache_pressure=95 2>/dev/null
sysctl -e -w vm.block_dump=0 2>/dev/null
sysctl -e -w vm.overcommit_ratio=50 2>/dev/null
sysctl -e -w vm.oom_dump_tasks=0 2>/dev/null
sysctl -e -w vm.dirty_writeback_centisecs=2736 2>/dev/null
sysctl -e -w vm.dirty_expire_centisecs=270 2>/dev/null
sysctl -e -w vm.compact_unevictable_allowed=1 2>/dev/null
sysctl -e -w vm.page-cluster=0 2>/dev/null

# LOW MEMORY KILLER
FP=$((($RAM*3/100)*1024/4))
VP=$((($RAM*4/100)*1024/4))
SR=$((($RAM*5/100)*1024/4))
HP=$((($RAM*7/100)*1024/4))
CR=$((($RAM*11/100)*1024/4))
EP=$((($RAM*15/100)*1024/4))
ADJ1=0; ADJ2=352; ADJ3=470; ADJ4=588; ADJ5=705; ADJ6=1000

if [ -e /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk ]; then
  chmod 0644 /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
  echo "0" > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
  setprop lmk.autocalc false
fi;
if [ -e /sys/module/lowmemorykiller/parameters/debug_level ]; then
  chmod 0644 /sys/module/lowmemorykiller/parameters/debug_level
  echo "0" > /sys/module/lowmemorykiller/parameters/debug_level
fi;
if [ -e  /sys/module/lowmemorykiller/parameters/oom_reaper ]; then
  chmod 0644 /sys/module/lowmemorykiller/parameters/oom_reaper
  echo "1" >  /sys/module/lowmemorykiller/parameters/oom_reaper
fi;
if [ -e /sys/module/lowmemorykiller/parameters/trust_adj_chain ]; then
  chmod 0644 /sys/module/lowmemorykiller/parameters/trust_adj_chain
  echo "N" > /sys/module/lowmemorykiller/parameters/trust_adj_chain
fi;
if [ -e /sys/module/lowmemorykiller/parameters/adj_max_shift ]; then
  chmod 0644 /sys/module/lowmemorykiller/parameters/adj_max_shift
  echo "0" > /sys/module/lowmemorykiller/parameters/adj_max_shift
fi;
if [ -e /sys/module/lowmemorykiller/parameters/lmk_fast_run ]; then
  chmod 0644 /sys/module/lowmemorykiller/parameters/lmk_fast_run
  echo "0" > /sys/module/lowmemorykiller/parameters/lmk_fast_run
fi;
if [ -e /sys/module/lowmemorykiller/parameters/time_measure ]; then
  chmod 0644 /sys/module/lowmemorykiller/parameters/time_measure
  echo "0" > /sys/module/lowmemorykiller/parameters/time_measure
fi;
if [ -e /sys/module/lowmemorykiller/parameters/quick_select ]; then
  chmod 0644 /sys/module/lowmemorykiller/parameters/quick_select
  echo "0" > /sys/module/lowmemorykiller/parameters/quick_select
fi;
if [ -e /sys/module/lowmemorykiller/parameters/batch_kill ]; then
  chmod 0644 /sys/module/lowmemorykiller/parameters/batch_kill
  echo "0" > /sys/module/lowmemorykiller/parameters/batch_kill
fi;

chmod 0644 /sys/module/lowmemorykiller/parameters/adj
chmod 0644 /sys/module/lowmemorykiller/parameters/minfree
echo "$ADJ1,$ADJ2,$ADJ3,$ADJ4,$ADJ5,$ADJ6" > /sys/module/lowmemorykiller/parameters/adj
echo "$FP,$VP,$SR,$HP,$CR,$EP" > /sys/module/lowmemorykiller/parameters/minfree

MFK=$(($RAM*4))
MFK1=$(($MFK/2))

sysctl -e -w vm.min_free_kbytes=$MFK 2>/dev/null

if [ -e /proc/sys/vm/extra_free_kbytes ]; then
  sysctl -e -w vm.extra_free_kbytes=$MFK1 2>/dev/null
  setprop sys.sysctl.extra_free_kbytes $MFK1
fi;

# GPU OPTIMIZER
if [ -d /sys/class/kgsl/kgsl-3d0 ]; then
  GPU=/sys/class/kgsl/kgsl-3d0
else
  GPU=/sys/devices/soc/*.qcom,kgsl-3d0/kgsl/kgsl-3d0
fi;
if [ -e /sys/module/adreno_idler/parrameters/adreno_idler_downdifferential ]; then
  echo "20" > /sys/module/adreno_idler/parrameters/adreno_idler_downdifferential
fi;
if [ -e $GPU/max_pwrlevel ]; then 
  echo "0" > $GPU/max_pwrlevel
fi;
if [ -e /sys/module/simple_gpu_algorithm/parameters/simple_gpu_activate ]; then 
  echo "1" > /sys/module/simple_gpu_algorithm/parameters/simple_gpu_activate
  echo "Y" > /sys/module/simple_gpu_algorithm/parameters/simple_gpu_activate
fi;
if [ -e $GPU/throttling ]; then
  echo "0" > $GPU/throttling
fi;
if [ -e $GPU/devfreq/adrenoboost ]; then 
  echo "3" > $GPU/devfreq/adrenoboost
fi;
if [ -e $GPU/force_no_nap ]; then
  echo "0" > $GPU/force_no_nap
fi;
if [ -e $GPU/force_bus_on ]; then
  echo "0" > $GPU/force_bus_on
fi;
if [ -e $GPU/force_clk_on ]; then
  echo "0" > $GPU/force_clk_on
fi;
if [ -e $GPU/force_rail_on ]; then
  echo "0" > $GPU/force_rail_on
fi;
if [ -e $GPU/bus_split ]; then
  echo "1" > $GPU/bus_split
fi;

# NETWORK SPEED
sysctl -e -w net.ipv4.tcp_timestamps=0
sysctl -e -w net.ipv4.tcp_sack=1
sysctl -e -w net.ipv4.tcp_fack=1
sysctl -e -w net.ipv4.tcp_window_scaling=1
sysctl -e -w net.ipv4.tcp_rfc1337=1
sysctl -e -w net.ipv4.tcp_workaround_signed_windows=1
sysctl -e -w net.ipv4.tcp_low_latency=1
sysctl -e -w net.ipv4.ip_no_pmtu_disc=0
sysctl -e -w net.ipv4.tcp_mtu_probing=1
sysctl -e -w net.ipv4.tcp_frto=2

# RM LOG
rm -f /data/anr/* 2>/dev/null
rm -f /data/system/usagestats/*.log 2>/dev/null
rm -f /data/system/usagestats/*.txt 2>/dev/null
rm -f /data/tombstones/*.log 2>/dev/null
rm -f /data/tombstones/*.txt 2>/dev/null

exit 0
