#!/bin/bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOW=3
# $1 is binary, $2 is unique  $3 start script  $4 binary location
LOCAL_HOSTNAME=`hostname`
MONITOR_CMD="binary_monitor.sh"
Usage="bash $MONITOR_CMD -b <binary> [-u unique] [-s start_script] [-l binary_host]\nbash $MONITOR_CMD -h"

while getopts "b:u:s:l:h" opt;do
  case $opt in
    h ) echo $Usage
      exit $STATE_UNKNOW
      ;;
    b) binary=$OPTARG
      ;;
    u) unique=$OPTARG
      ;;
    s) start_script=$OPTARG
      ;;
    l) binary_host=$OPTARG
      ;;
    ? ) echo "error"
      exit $STATE_UNKNOW;;
  esac
done

#echo "binary=$binary,unique=$unique, start_script=$start_script,binary_host=$binary_host"

if [ -z $binary ];then
  echo -e "Assign -b binary\n$Usage"
  exit $STATE_CRITICAL
fi
# check run the right host
if [ ! -z "$binary_host" ];then
  if [ $LOCAL_HOSTNAME != $binary_host ];then
    echo "bash $MONITOR_CMD -b $binary -l $binary_host should Run at $LOCAL_HOSTNAME"
    exit $STATE_CRITICAL
  fi
fi

monitor() {
  ps aux|grep $binary | grep -v grep |grep -v $MONITOR_CMD|grep $unique > /dev/null 2>&1
  if [ $? -eq 0 ];then
    echo "Everything is Ok."
    exit $STATE_OK
  else
    if [ -z $start_script ];then
      echo "$binary is Gone. Not Restart"
      exit $STATE_CRITICAL
    else
      echo "$binary is Gone. Restart $start_script"
      $start_script
      exit $STATE_CRITICAL
    fi
  fi
}
monitor
