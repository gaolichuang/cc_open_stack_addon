
# your own logic here

virt-ls -a $img_file /etc/sysconfig/network-scripts/ | while read line;do
  if [[ $line == ifcfg-eth* ]];then
    #backup
    backup /etc/sysconfig/network-scripts/$line
    #delete
    delete /etc/sysconfig/network-scripts/$line
  fi
done

#inject

virt-ls -a $new_img_file /etc/sysconfig/network-scripts/ | while read line;do
  if [[ $line == ifcfg-eth* ]];then
    #backup
    copy_out /etc/sysconfig/network-scripts/$line
    #delete
    inject /etc/sysconfig/network-scripts/$line
  fi
done


#cp $workpath/iptables   $new_path 
#inject /etc/sysconfig/iptables
#sed "s/_MAC_ADDR_/$mac_addr/g" $workpath/70-persistent-net.rules  > $new_path/70-persistent-net.rules
#inject /etc/udev/rules.d/70-persistent-net.rules
#sed "s/_MAC_ADDR_/$mac_addr/g" $workpath/ifcfg-eth0  > $new_path/ifcfg-eth0
#inject /etc/sysconfig/network-scripts/ifcfg-eth0
