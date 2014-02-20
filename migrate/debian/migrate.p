
# your own logic here

#backup
backup /etc/network/interfaces
backup /etc/udev/rules.d/70-persistent-net.rules
#delete
delete /etc/network/interfaces
delete /etc/udev/rules.d/70-persistent-net.rules
#inject
copy_out /etc/udev/rules.d/70-persistent-net.rules
inject /etc/udev/rules.d/70-persistent-net.rules
copy_out /etc/network/interfaces
inject /etc/network/interfaces
