
# your own logic here
# modify libvirt.xml to libvirt_modify.xml, rm virtio drive
libvirt_dir=`dirname $libvirtxml`

if [ ! -f $libvirt_dir/libvirt_modify.xml ];then
  cp $libvirtxml $libvirt_dir/libvirt_modify.xml
fi

sed -i 's/bus="virtio" dev="vda"/bus="ide" dev="vda"/g' $libvirt_dir/libvirt_modify.xml
sed -i 's/dev="vda" bus="virtio"/bus="ide" dev="vda"/g' $libvirt_dir/libvirt_modify.xml
sed -i 's/model type="virtio"/model type="e1000"/g' $libvirt_dir/libvirt_modify.xml


sed -i 's/bus="virtio" dev="vdb"/bus="ide" dev="vdb"/g' $libvirt_dir/libvirt_modify.xml
sed -i 's/dev="vdb" bus="virtio"/bus="ide" dev="vdb"/g' $libvirt_dir/libvirt_modify.xml


#inject
delete /root/setup.bat
virt-copy-in -a $img_file $workpath/setup.bat "/root/"
#virt-copy-in -a $img_file $workpath/setup.bat "/Users/Administrator/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/"
echo "virt-copy-in -a $img_file $workpath/setup.bat \"/Users/Administrator/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/\""

