#!/bin/bash
# make sure you have novaclient to run this monitor
DISABLE="disable"
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOW=3
#nova --os-username admin --os-password 57af19784cde8c7b --os-tenant-name admin --os-auth-url http://192.168.1.101:35357/v2.0 service-list|grep -v $DISABLE |awk -F"|"  '{print $6}' |while read line;do echo "XXX$line"; if [ "$line" == "down" ];then echo "ssss";fi done
nova --os-username admin --os-password 57af19784cde8c7b --os-tenant-name admin --os-auth-url http://192.168.1.101:35357/v2.0 service-list|grep -v $DISABLE |while read line;do if [ "$line" == "down" ];then echo "$line"; exit $STATE_CRITICAL;fi done
echo "Everything is Ok"
exit $STATE_OK
