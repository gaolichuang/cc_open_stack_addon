#!/bin/bash

source ./function.sh
Usage="bash install compute|controller"
_OK="\033[32m OK \033[0m"
_ERR="\033[31m ERROR \033[0m"
nova_conf=./nova
neutron_conf=./neutron
ceph_conf=./ceph
nova_ssh=./.ssh
apt_conf=./apt.conf
format_etc=./format_etc.sh
#ceph_key="AQCL/aVSYAxgCxAAIg/LHBGwlrL4cW/QILF9QA=="
ceph_key="AQDXntRSMKv8ExAAwp7QmmRbRHG9zZW6VS1kPA=="

common_check() {
### check cloud source is havana
if [ -f /etc/apt/sources.list.d/cloudarchive-havana.list ];then
  echo -e "Havana Version: $_OK"
else
  echo -e "Havana Version: $_ERR"
fi
if [ ! -f $format_etc ];then
  echo -e "$format_etc does not exist $_ERR"
else
  echo -e "$format_etc  exist $_OK"
fi
if [ ! -d $nova_conf ];then
  echo -e "$nova_conf does not exist $_ERR"
else
  echo -e "$nova_conf  exist $_OK"
fi
if [ ! -d $neutron_conf ];then
  echo -e "$neutron_conf does not exist $_ERR"
else
  echo -e "$neutron_conf  exist $_OK"
fi
if [ ! -d $ceph_conf ];then
  echo -e "$ceph_conf does not exist $_ERR"
else
  echo -e "$ceph_conf exist $_OK"
fi
if [ ! -f $apt_conf ];then
  echo -e "$apt_conf does not exist $_ERR"
else
  echo -e "$apt_conf exist $_OK"
fi
}

compute_check() {
common_check
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


common_install() {
### set proxy
echo "set apt proxy is :"
cat $apt_conf
while read -p "yes or no:" ;do
  if [ $REPLY == "yes" ];then
    break
  elif [ $REPLY == "no" ];then
    exit
  else
    continue
  fi
done
cp $apt_conf /etc/apt/
apt-get update
apt-get install python-software-properties
### run as root
if [ ! -f /etc/apt/sources.list.d/cloudarchive-havana.list ];then
  aptitude install python-software-properties -y
  add-apt-repository cloud-archive:havana
  aptitude update
  echo "put havana to sources list"
fi
echo "=========== common install ============"
sudo apt-get install sysstat nload lrzsz
sudo apt-get install python-ceilometerclient

sudo apt-get install ntp

}
compute_conf() {
echo "=========== copy conf  nova ============"
rm -rf /etc/nova/*
echo "rm -rf /etc/nova/*"
cp -rf $nova_conf/* /etc/nova/
echo "cp -rf $nova_conf/* /etc/nova/"
chown -R nova:nova /etc/nova
echo "chown -R nova:nova /etc/nova"
echo "=========== copy conf  neutron ============"
rm -rf /etc/neutron/*
echo "rm -rf /etc/neutron/*"
cp -rf $neutron_conf/* /etc/neutron/
echo "cp -rf $neutron_conf/* /etc/neutron/"
chown -R neutron:neutron /etc/neutron
echo "chown -R neutron:neutron /etc/neutron"
echo "=========== copy conf ceph ============"
mkdir -p /etc/ceph
rm -rf /etc/ceph/*
echo "rm -rf /etc/ceph/*"
cp -rf $ceph_conf/* /etc/ceph/
echo "cp -rf $ceph_conf/* /etc/ceph/"
chown -R nova:nova /etc/ceph
echo "chown -R nova:nova /etc/ceph"
echo "=========== set secert uuid for libvirt ============"
uuid=`secret_define`
echo "virsh secret-set-value --secret $uuid --base64 $ceph_key"
virsh secret-set-value --secret $uuid --base64 $ceph_key
echo "=========== replace conf nova & neutron ============"
bash $format_etc
}
reset_secert_uuid_libvirt() {
echo "=========== set secert uuid for libvirt ============"
uuid=`secret_define`
echo "virsh secret-set-value --secret $uuid --base64 $ceph_key"
virsh secret-set-value --secret $uuid --base64 $ceph_key
}
# run as root
compute_user_ssh_init() {
usermod -s /bin/bash nova 
echo "=========== copy ssh for nova ============"
rm -rf /var/lib/nova/.ssh
echo "rm -rf /var/lib/nova/.ssh"
cp -rf $nova_ssh /var/lib/nova 
echo "cp -rf $nova_ssh /var/lib/nova"
chown -R nova:nova /var/lib/nova/.ssh
echo "chown -R nova:nova /var/lib/nova/.ssh"
chmod 700 /var/lib/nova/.ssh
echo "chmod 700 /var/lib/nova/.ssh"
chmod 600 /var/lib/nova/.ssh/id_rsa /var/lib/nova/.ssh/authorized_keys
echo "chmod 600 /var/lib/nova/.ssh/id_rsa /var/lib/nova/.ssh/authorized_keys"
}
compute_install_pre(){
common_install
echo "=========== libvirt kvm install ============"
sudo apt-get install libvirt-bin qemu-kvm bridge-utils
sudo apt-get install guestfish libguestfs-tools
}
compute_install() {
echo "=========== nova compute kvm install ============"
sudo apt-get install nova-compute-kvm #python-guestfs
sudo chmod 0644 /boot/vmlinuz*
sudo rm /var/lib/nova/nova.sqlite
echo "=========== disable virb0 ============"
virsh net-destroy default
virsh net-undefine default
service libvirtd restart
ifconfig
echo "=========== ovs agent install ============"
sudo apt-get install -y neutron-plugin-openvswitch-agent openvswitch-datapath-dkms openvswitch-switch python-openvswitch
sudo modprobe openvswitch
sudo service  openvswitch-switch restart
echo "=========== rbd  install ============"
sudo apt-get install ceph-common sysfsutils
echo "=========== add bridge br-int ============"
ovs-vsctl add-br br-int
echo "=========== ovs-vsctl show ============"
ovs-vsctl show
}

compute_service_restart(){
service libvirt-bin  restart
service openvswitch-switch restart
service neutron-plugin-openvswitch-agent restart
service nova-compute restart
}
controller_service() {
sudo service nova-consoleauth $1
sudo service nova-scheduler $1
sudo service nova-cert $1
sudo service nova-conductor $1
sudo service nova-api $1
sudo service nova-novncproxy $1
sudo service nova-xvpvncproxy $1
}
controller_install() {
common_install
sudo apt-get install python-mysqldb python-sqlalchemy nova-novncproxy novnc nova-api \
  nova-consoleauth nova-ajax-console-proxy nova-cert nova-conductor nova-scheduler \
  python-novaclient nova-xvpvncproxy 
echo "=========== copy conf  nova ============"
rm -rf /etc/nova/*
echo "rm -rf /etc/nova/*"
cp -rf $nova_conf/* /etc/nova/
echo "cp -rf $nova_conf/* /etc/nova/"
chown -R nova:nova /etc/nova
echo "chown -R nova:nova /etc/nova"
echo "=========== replace conf nova & neutron ============"
bash $format_etc
}
compute(){
compute_install_pre
compute_check
while read -p "Continue? yes or no:" ;do
  if [ $REPLY == "yes" ];then
    break
  elif [ $REPLY == "no" ];then
    exit
  else
    continue
  fi
done

compute_install
compute_conf
compute_user_ssh_init
compute_service_restart
}
controller(){
controller_install
#controller_service restart
}

reset_secert_uuid_libvirt
