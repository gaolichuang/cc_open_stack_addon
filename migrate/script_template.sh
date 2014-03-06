#!/bin/bash
# vm_name new_img_file  img_file  libvirt.xml  rollback_version
vm_path=$1
new_img_file=$2
img_file=$3
libvirtxml=$4
twodisk=$5
rollback_version=$6

workpath=`dirname $0`
log_file="$vm_path/log.txt"

fecho() {
    echo "$1"
    echo "$1" >> $log_file
}
if [ -z $rollback_version ];then
    rollback_version=old`date "+%Y-%m-%d_%H:%M:%S"`
fi
old_path=$vm_path/$rollback_version
new_path=$vm_path/new
backup(){
echo "virt-copy-out -a $img_file $1  $old_path"
virt-copy-out -a $img_file $1  $old_path
fecho "Backup at $img_file from $1 to $old_path"
}
delete() {
echo "guestfish -a $img_file -i rm $1"
guestfish -a $img_file -i rm $1
fecho "Delete at $img_file file $1"
}
copy_out() {
file_name=`basename $1`
dir_name=`dirname $1`
echo "virt-copy-out -a $new_img_file $1 $new_path"
virt-copy-out -a $new_img_file $1 $new_path
fecho "Copy out at $new_img_file from $1 to $new_path"
}
inject() {
file_name=`basename $1`
dir_name=`dirname $1`
if [ ! -f $new_path/$file_name ];then
fecho "Inject at $img_file from $new_path/$file_name to $dir_name \n $new_path/$file_name does not exist"
return
fi
echo "virt-copy-in -a $img_file $new_path/$file_name $dir_name"
virt-copy-in -a $img_file $new_path/$file_name $dir_name
fecho "Inject at $img_file from $new_path/$file_name to $dir_name"
}

rollback_inject() {
file_name=`basename $1`
dir_name=`dirname $1`
if [ ! -f $old_path/$file_name ];then
fecho "Inject at $img_file from $old_path/$file_name to $dir_name \n $old_path/$file_name does not exist"
return
fi
echo "virt-copy-in -a $img_file $old_path/$file_name $dir_name"
virt-copy-in -a $img_file $old_path/$file_name $dir_name
fecho "Inject at $img_file from $old_path/$file_name to $dir_name"
}

mkdir -p $old_path
mkdir -p $new_path

if [ $twodisk == "yes" ];then
  libvirt_dir=`dirname $libvirtxml`
  cp $libvirtxml $libvirt_dir/libvirt_modify.xml
  # add disk.local
  uuid=${libvirt_dir##*/}
  sed -i "s/<\/devices>/<disk type=\"file\" device=\"disk\">\n<driver name=\"qemu\" type=\"qcow2\" cache=\"none\"\/>\n <source file=\"\/var\/lib\/nova\/instances\/$uuid\/disk.local\"\/>\n <target bus=\"virtio\" dev=\"vdb\"\/> <\/disk>\n<\/devices>/g" $libvirt_dir/libvirt_modify.xml
fi

# your own logic here

