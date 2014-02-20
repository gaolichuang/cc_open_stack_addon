

# your own logic here
#delete
for ethx in `ls $old_path/ifcfg-eth*`;do
eth=`basename $ethx`
delete /etc/sysconfig/network-scripts/$eth
#inject
rollback_inject /etc/sysconfig/network-scripts/$eth
done
