#!/bin/bash

SHELL_NAME=update_config.sh
CONF_DIR=./nova
HOST_LIST=conf/nova-compute.host
#HOST_LIST=conf/nova-controller.host
USER=cloud
D_USER=root
CONTROLLER=script/run_controller.sh
CONTROLLER_CMD=run_controller.sh
PASS_WORD=bt3ynacqad
PROJECT_NAME=tj0115
NOVA_CONF=production/$PROJECT_NAME/nova

usage()
{
  echo "Usage: $SHELL_NAME [ntp|apt|nova|hosts|conf]"
  exit
}
if [ $# -lt 1 ]; then
  usage
fi
interaction() {
echo "project name $PROJECT_NAME"
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

if [ "$1" = "ntp" ]; then
  multiexec -f $HOST_LIST -u $USER "rm -rf /tmp/ntp.conf"
  multicp -f $HOST_LIST -u $USER -r $CONF_DIR/etc/conf/ntp.conf /tmp/
  multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD | sudo -S date; sudo -u $D_USER cp -r /tmp/ntp.conf /etc/ntp.conf"
elif [ "$1" = "apt" ]; then
  multiexec -f $HOST_LIST -u $USER "rm -rf /tmp/apt.conf"
  multicp -f $HOST_LIST -u $USER -r $CONF_DIR/etc/conf/apt.conf /tmp/
  multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD | sudo -S date; sudo -u $D_USER cp -r /tmp/apt.conf /etc/apt/apt.conf"
elif [ "$1" = "nova" ]; then
  multiexec -f $HOST_LIST -u $USER "rm -rf /tmp/nova"
  multicp -f $HOST_LIST -u $USER -r $CONF_DIR /tmp/
  multiexec -f $HOST_LIST -u $USER "cp -r /tmp/nova ~/"
elif [ "$1" = "hosts" ]; then
  multiexec -f $HOST_LIST -u $USER "rm -rf /tmp/hosts"
  multicp -f $HOST_LIST -u $USER -r $CONF_DIR/etc/conf/hosts /tmp/
  multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD | sudo -S date; sudo -u $D_USER cp -r /tmp/hosts /etc/hosts"
elif [ "$1" = "conf" ]; then
  interaction
  multiexec -f $HOST_LIST -u $USER "rm /tmp/$CONTROLLER_CMD"
  multicp -f $HOST_LIST -u $USER -r $CONTROLLER /tmp
  multiexec -f $HOST_LIST -u $USER "rm -rf /tmp/nova"
  multicp -f $HOST_LIST -u $USER -r $NOVA_CONF /tmp/
  multiexec -f $HOST_LIST -u $USER "echo $PASS_WORD | sudo -S date; sudo -u $D_USER bash /tmp/$CONTROLLER_CMD nova_conf"
else
  usage
fi
