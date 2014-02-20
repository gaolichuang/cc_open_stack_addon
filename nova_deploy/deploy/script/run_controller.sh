#!/bin/bash

usage="usage: run_controller.sh (status|ksm|clearlog|nova_conf) "

if [ $# -lt 1 ]; then
  echo $usage
  exit -1
fi

operation=$1
param="$2"
status_check() {
if [ -f /etc/apt/sources.list.d/cloudarchive-havana.list ];then
  echo -e "Havana Version: $_OK"
else
  echo -e "Havana Version: $_ERR"
fi
##intel or amd
lscpu|grep "Vendor ID" |grep "GenuineIntel" > /dev/null 2>&1
if [ $? -eq 0 ];then
  vendor=intel
  vt=vmx
  mod=kvm_intel
  echo "X86 Platform: Intel"
else
  vendor=intel
  vt=svm
  mod=kvm_amd
echo "X86 Platform: AMD"
fi
## support vt or not?
cat /proc/cpuinfo |grep "$vt" > /dev/null 2>&1
if [ $? -eq 0 ];then
  echo -e "Support VT($vendor): $_OK"
else
  echo -e "Support VT($vendor): $_ERR"
  cat /proc/cpuinfo |grep "$vt"
fi
## load kvm module or not
lsmod|grep $mod > /dev/null 2>&1
if [ $? -eq 0 ];then
  echo -e "Load Kvm Module($vendor): $_OK"
else
  echo -e "Load Kvm Module($vendor): $_ERR"
  lsmod|grep $mod
fi
### kvm-ok
kvm-ok
### virsh version
virsh version
### set secret key or not
virsh secret-list
}
clearlog() {
for f in `ls /var/log/nova/*.log` ;do cat /dev/null > $f ;done
}
ceph_secertkey_reset() {
 echo 
}
ksm_save() {
#### ksm run or not
#ps aux|grep ksmd |grep -v grep
### ksm save memory 
echo "KSM saved; $(($(cat /sys/kernel/mm/ksm/pages_sharing) * $(getconf PAGESIZE) / 1024 /1024))MB"
}
ksm_check() {
### qemu use memory statistic
ps aux|grep qemu-system-x86_64|grep instance-|awk '{ sum+=$6 }END{ sum /=1000 ;print "There are "NR" qemu-system-x86_64 processes, Use memory "sum " MB"}'
ksm_save
}
nova_conf() {
mkdir -p /etc/nova.backup
rm -rf /etc/nova.backup/*
mv /etc/nova/* /etc/nova.backup/
cp -r /tmp/nova/* /etc/nova/
chown -R nova:nova /etc/nova
chown -R nova:nova /etc/nova.backup
}
if [ $operation == "status" ];then
  status_check
elif [ $operation == "clearlog" ];then
  clearlog
elif [ $operation == "ksm" ];then
  ksm_check
elif [ $operation == "nova_conf" ];then
  nova_conf
fi
