#!/bin/bash

HOST_LIST=conf/nova-compute.host
#HOST_LIST=conf/nova-controller.host
CONTROLLER=script/run_controller.sh
CONTROLLER_CMD=run_controller.sh
USER=cloud
PASS_WORD=bt3ynacqad
D_USER=root

usage()
{
  echo "Usage: $SHELL_NAME [start|stop|clearlog|check_bin|check_mem|check_disk|status] [ntp|nova-compute|nova-compute-all|nova-scheduler|nova-api]"
  echo "Usage: $SHELL_NAME [check_bin|check_mem|check_disk|status|ksm|date]"
  echo "Usage: $SHELL_NAME cmd <cmd str>"
  echo "Usage: $SHELL_NAME root_cmd <cmd str>"
  exit
}
interaction() {
echo "Interaction: $1"
while read -p "yes or no:" ;do
  if [ $REPLY == "yes" -o $REPLY = 'y' ];then
    break
  elif [ $REPLY == "no" ];then
    exit
  else
    continue
  fi
done
}


if [ $# -lt 1 ]; then
  usage
  exit
fi

if [ "$1" = "restart" -o "$1" = "stop" -o "$1" = "start" ]; then
  if [ "X$2" = "X" ];then
    usage
    exit
  fi
  if [ "$2" = "nova-api" -a "$1" = "stop" ];then
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER killall $2"
  elif [ "$2" = "nova-compute-all" ];then
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER service libvirtd $1"
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER service openvswitch-switch $1"
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER service neutron-plugin-openvswitch-agent $1"
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER service nova-compute $1"
  elif [ "$2" = "nova-controller-all" ];then
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER service nova-consoleauth $1"
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER service nova-scheduler $1"
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER service nova-cert $1"
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER service nova-conductor $1"
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER service nova-novncproxy $1"
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER service nova-xvpvncproxy $1"
  else
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER service $2 $1"
  fi
elif [ "$1" = "clearlog" ]; then
  if [ "$2" = "nova-controller" ];then
    multiexec -f $HOST_LIST -u $USER "rm /tmp/$CONTROLLER_CMD"
    multicp -f $HOST_LIST -u $USER -r $CONTROLLER /tmp
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER bash /tmp/$CONTROLLER_CMD clearlog"
  else
    multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u nova cat /dev/null > /var/log/nova/$2.log"
  fi
elif [ "$1" = "status" -o "$1" = "ksm" ]; then
  multiexec -f $HOST_LIST -u $USER "rm /tmp/$CONTROLLER_CMD"
  multicp -f $HOST_LIST -u $USER -r $CONTROLLER /tmp
  multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER bash /tmp/$CONTROLLER_CMD $1"
elif [ "$1" = "check_bin" ]; then
  multiexec -f $HOST_LIST -u $USER "ps aux|grep $2 |grep -v grep"
elif [ "$1" = "check_mem" ]; then
  multiexec -f $HOST_LIST -u $USER "free -m"
elif [ "$1" = "check_disk" ]; then
  multiexec -f $HOST_LIST -u $USER "df -h"
elif [ "$1" = "uptime" ]; then
  multiexec -f $HOST_LIST -u $USER "uptime"
elif [ "$1" = "uname" ]; then
  multiexec -f $HOST_LIST -u $USER "uname -a"
elif [ "$1" = "date" ]; then
  multiexec -f $HOST_LIST -u $USER "date"
elif [ "$1" = "cmd" ]; then
  multiexec -f $HOST_LIST -u $USER "$2"
elif [ "$1" = "root_cmd" ]; then
  interaction "run root cmd: $2"
  multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD|sudo -S date; sudo -u $D_USER $2"
else
  usage
fi
