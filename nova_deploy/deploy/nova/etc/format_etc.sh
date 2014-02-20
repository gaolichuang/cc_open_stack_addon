#!/bin/bash

source ./function.sh
ip_addr=`/sbin/ifconfig eth0:0|grep 'inet '|awk -F'[: ]+' '{print $4}'`
if [ "X$ip_addr" == "X" ];then
  ip_addr=`/sbin/ifconfig eth1|grep 'inet '|awk -F'[: ]+' '{print $4}'`
fi
#readonly ip_ext_addr=`/sbin/ifconfig eth1|grep 'inet '|awk -F'[: ]+' '{print $4}'`
readonly uuid=`secret_define`

readonly nova_path="/etc/nova/"
readonly neutron_path="/etc/neutron"
#nova_path="./nova/"
#neutron_path="./neutron"

declare -A change_table
change_table=(
  ['_LOCAL_IP_']=$ip_addr
  ['_LOCAL_EXT_IP_']='X.X.X.X'
  ['_SEC_UUID_']=$uuid
  ['_AUTH_HOST_']="192.168.1.101"
  ['_RABBITMQ_HOSTS_']="192.168.1.109:5672"
  ['_RABBITMQ_PASSWD_']="iafChewdIk2"
  ['_MYSQL_HOST_']="192.168.1.108"
  ['_GLANCE_HOST_']="192.168.1.102"
  ['_NEUTRON_SERVER_']="192.168.1.106"
  ['_NEUTRON_METADATA_PROXY_SHARED_SECRET_']="m\$6R>bHjaB:7aN8"
  ['_NEUTRON_PASSWORD_']="41814bc6257a1085"
  ['_NOVA_PASSWORD_']="eba00218fa361219"
)

check_roll_back() {
  echo "Roll back Target path: $nova_path,$neutron_path"
  for key in ${!change_table[*]};do
    if [ "X${change_table[$key]}" == "X" ];then
      continue 
    fi
    echo "Change ${change_table[$key]} to $key"
  done
  result=0
  for value in ${change_table[@]};do
    grep -r "$value" $nova_path $neutron_path > /dev/null 2>&1
    ret=$?
    if [ $ret -eq 0 ];then
      echo -e "\033[31m Can Not roll Back, other result: \033[0m"
      grep -r "$value" $nova_path $neutron_path
      result=1
    fi
  done
  if [ $result -eq 0  ];then
      echo -e "\033[32m It can roll back \033[0m"
  fi
  return $result
}

check_roll_back
_roll_back=$?

change_conf() {
echo "Target path: $nova_path,$neutron_path"
for key in ${!change_table[*]};do
  if [ "X${change_table[$key]}" == "X" ];then
    continue 
  fi
  echo "Change $key to ${change_table[$key]}"
done
#interactive
while read -p "yes or no:" ;do
  if [ $REPLY == "yes" ];then
    break
  elif [ $REPLY == "no" ];then
    exit
  else
    continue
  fi
done
for _f in `find $nova_path $neutron_path  -regex  ".*\.\(ini\|conf\)"`;do
  for key in ${!change_table[*]};do
    if [ "X${change_table[$key]}" == "X" ];then
      continue 
    fi
    echo "sed -i \"s/$key/${change_table[$key]}/g\" $_f"
    sed -i "s/$key/${change_table[$key]}/g" $_f
  done
done
}
roll_back() {
echo "Roll back Target path: $nova_path,$neutron_path"
for key in ${!change_table[*]};do
  if [ "X${change_table[$key]}" == "X" ];then
    continue 
  fi
  echo "Change ${change_table[$key]} to $key"
done
for _f in `find $nova_path $neutron_path  -regex  ".*\.\(ini\|conf\)"`;do
  for key in ${!change_table[*]};do
    if [ "X${change_table[$key]}" == "X" ];then
      continue 
    fi
    echo "sed -i \"s/${change_table[$key]}/$key/g\" $_f"
    sed -i "s/${change_table[$key]}/$key/g" $_f
  done
done
}

if [ $# -eq 0 ];then
  change_conf
elif [ $1 == "rollback" ];then
  if [ $_roll_back -ne 0 ];then
    roll_back
  fi
fi
