#!/bin/bash


ksm_save() {
#### ksm run or not
#ps aux|grep ksmd |grep -v grep
### ksm save memory 
echo "KSM saved; $(($(cat /sys/kernel/mm/ksm/pages_sharing) * $(getconf PAGESIZE) / 1024 /1024))MB"
}
mem_check() {
### qemu use memory statistic
ps aux|grep qemu-system-x86_64|grep instance-|awk '{ sum+=$6 }END{ sum /=1000 ;print "There are "NR" qemu-system-x86_64 processes, Use memory "sum " MB"}'    
ksm_save
}
mem_check

