
# your own logic here
# modify libvirt.xml to libvirt_modify.xml, rm virtio drive
libvirt_dir=`dirname $libvirtxml`
cp $libvirtxml $libvirt_dir/libvirt_modify.xml
sed -i 's/bus="virtio" dev="vda"/bus="ide" dev="vda"/g' $libvirt_dir/libvirt_modify.xml
sed -i 's/dev="vda" bus="virtio"/bus="ide" dev="vda"/g' $libvirt_dir/libvirt_modify.xml
sed -i 's/model type="virtio"/model type="e1000"/g' $libvirt_dir/libvirt_modify.xml

#inject
virt-copy-in -a disk $workpath/net_modify.bat "/Users/Administrator/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/"

