
# your own logic here
#delete
delete /etc/sysconfig/iptables
delete /etc/udev/rules.d/70-persistent-net.rules
rollback_inject /etc/sysconfig/iptables
rollback_inject /etc/udev/rules.d/70-persistent-net.rules
for ethx in `ls $old_path/ifcfg-eth*`;do
eth=`basename $ethx`
delete /etc/sysconfig/network-scripts/$eth
#inject
rollback_inject /etc/sysconfig/network-scripts/$eth
done
