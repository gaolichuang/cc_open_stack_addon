#!/bin/bash
# vm_name new_img_file  img_file  libvirt.xml  rollback_version
vm_path=$1
new_img_file=$2
img_file=$3
libvirtxml=$4
rollback_version=$5

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
virt-copy-out -a $img_file $1  $old_path
fecho "Backup at $img_file from $1 to $old_path"
}
delete() {
guestfish -a $img_file -i rm $1
fecho "Delete at $img_file file $1"
}
copy_out() {
file_name=`basename $1`
dir_name=`dirname $1`
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
virt-copy-in -a $img_file $old_path/$file_name $dir_name
fecho "Inject at $img_file from $old_path/$file_name to $dir_name"
}

mkdir -p $old_path
mkdir -p $new_path

# your own logic here

