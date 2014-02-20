#!/bin/bash
corosync_conf=./corosync
ha_install() {
sudo apt-get install pacemaker corosync  cluster-glue  resource-agents
#### copy corosync conf  ####
rm -rf /etc/corosync/*
echo "cp -rf $corosync_conf/* /etc/corosync/"
cp -rf $corosync_conf/* /etc/corosync/
chmod 400 /etc/corosync/authkey

### enable /etc/default/corosync ###
sed -i 's/no/yes/g' /etc/default/corosync

### attention: the script below should run on all node
mkdir -p /usr/lib/ocf/resource.d/openstack
cd /usr/lib/ocf/resource.d/openstack
wget https://raw.github.com/madkiss/openstack-resource-agents/master/ocf/nova-api
chmod a+rx *
cd -
}
ha_service() {
service corosync $1
service pacemaker $1
}

ha_conf() {
### only run in one node
### basic config
#crm configure property no-quorum-policy="ignore" pe-warn-series-max="1000" pe-input-series-max="1000" pe-error-series-max="1000" cluster-recheck-interval="3min"

crm_attribute -t crm_config -n stonith-enabled -v false
### conf virtual ip
crm configure primitive p_nova_api-ip ocf:heartbeat:IPaddr2 \
    params ip="192.168.1.105" cidr_netmask="24" \
    op monitor interval="10s"
### conf ext virtual ip  attention netmask
crm configure primitive p_nova_api-ext-ip ocf:heartbeat:IPaddr2 \
    params ip="223.202.62.11" cidr_netmask="28" \
    op monitor interval="10s"
#### conf nova-api 
# attention: the username and tenant should use Service config
crm configure primitive p_nova-api ocf:openstack:nova-api \
params config="/etc/nova/nova.conf" additional_parameters="--log-file=/var/log/nova/nova-api.log" \
#params config="/etc/nova/nova.conf" os_password="123456" os_username="nova" os_tenant_name="service" keystone_get_token_url="http://192.168.8.30:5000/v2.0/tokens"  additional_parameters="--log-file=/var/log/nova/nova-api.log" \
op monitor interval="10s" timeout="10s"

crm configure group g_nova_api p_nova_api-ip p_nova_api-ext-ip p_nova-api 

echo "manual" > /etc/init/nova-api.override
}
ha_status() {
corosync-cfgtool -s
corosync-objctl runtime.totem.pg.mrp.srp.members
crm status
}
#ha_install
#ha_status
ha_conf

