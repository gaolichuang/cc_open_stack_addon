#!/bin/bash

Usage="bash service.sh start|stop|restart"

main() {
sudo service nova-consoleauth $1
sudo service nova-scheduler $1
sudo service nova-cert $1
sudo service nova-conductor $1
#sudo service nova-api $1
sudo service nova-novncproxy $1
sudo service nova-xvpvncproxy $1
}

if [ $# -ne 1 ];then
  echo $Usage
elif [ $1 == "stop" ];then
  main stop
elif [ $1 == "start" ];then
  main start
elif [ $1 == "restart" ];then
  main restart
else
  echo $Usage
fi
