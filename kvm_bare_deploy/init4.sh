IP_ADDR="116.211.123.144"
ETHX="eth0"
HOST_NAME='MyHost'

GATE_WAY="61.240.134.1"
ifconfig $ETHX ${IP_ADDR} netmask 255.255.255.224
route add default gw ${GATE_WAY}
echo "nameserver 8.8.8.8" > /etc/resolve.conf
#sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
#service sshd restart

mkdir -p /data/cache1
mount /dev/vdb  /data/cache1


mkdir -p /data/proclog
mount /dev/vdf  /data/proclog
sed -i "s/HOSTNAME=localhost.localdomain.localdomain/HOSTNAME=${HOST_NAME}.localdomain.localdomain/g" /etc/sysconfig/network
hostname $HOST_NAME
#echo "127.0.1.1 CNC-LQ-A-3SI" >> /etc/hosts
echo "modify root passwd:Blueit_s_LQ or Blueit_s_JA"
passwd
