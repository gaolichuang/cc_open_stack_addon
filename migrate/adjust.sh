#!/bin/bash

SUPPORT_OS_TYPE=("centos" "debian" "redhat" "ubuntu" "windows")


check_tools() {
which guestfish
if [ $? -ne 0 ];then
    echo "Install guestfish"
    sudo apt-get install guestfish
fi
which virt-copy-in
if [ $? -ne 0 ];then
    echo "Install libguestfs-tools"
    sudo apt-get install libguestfs-tools
fi
}

CMD="adjust.sh"
Usage="bash $CMD -t <os_type> -i <image_file> -v <virtual machine name> -x <libvirt.xml file>[-R]\n
           -t: os type(centos, ubuntu, windows)\n
           -i: image file which copy from old platform(Attention: will modify/update image file)\n
           -o: image file which create by new platform\n
           -v; virtual machine name\n
           -x: new plantform libvirt.xml file path(use to get hwaddr)\n
           -d: have too disk or not\n
           -R: use -R means roll back the image file adjust\n
       bash $CMD -h"

if [[ $0 == /* ]];then
    workpath=`dirname $0`
else
    relative_path=`dirname $0`
    workpath=`pwd`"/$relative_path"
fi

create_script() {
for ostype in ${SUPPORT_OS_TYPE[@]};do
   cat $workpath/script_template.sh $workpath/$ostype/migrate.p > $workpath/$ostype/migrate.sh
   chmod 755 $workpath/$ostype/migrate.sh
   cat $workpath/script_template.sh $workpath/$ostype/rollback.p > $workpath/$ostype/rollback.sh
   chmod 755 $workpath/$ostype/rollback.sh
done
}
if [ ! -f $workpath/script_template.sh ];then
  echo -e "ERROR"
  echo -e "\033[31m ERROR $workpath/script_template.sh does not exist. \033[0m"
  exit 1
fi

rollback="no"
twodisk="no"
while getopts "t:i:o:v:x:Rhd" opt;do
 case $opt in
  h ) echo -e $Usage
    exit 1
    ;;
  d ) twodisk="yes"
    ;;
  R) rollback="yes"
    ;;
  v) vm_name=$OPTARG
    ;;
  i) image_file=$OPTARG
    ;;
  o) new_image_file=$OPTARG
    ;;
  t) os_type=$OPTARG
    ;;
  x) hwaddr=$OPTARG
    ;;
  ? ) echo -e $Usage
    exit 1;;
 esac
done
echo "workpath=$workpath,os_type=$os_type,hwaddr=$hwaddr,image_file=$image_file,new_image_file=$image_file,vm_name=$vm_name,rollback:$rollback,twodisk:$twodisk"

###verify input params
if [ -z $os_type ];then
    echo "Assign os_type use -t"
    echo -e $Usage
    exit 1
fi
if [ "$os_type" == "logs" -o ! -d $workpath/$os_type ];then
    echo "os_type not support;os_type"
    echo -e $Usage
    exit 1
fi

if [ -z $image_file ];then
    echo "Assign image_file use -i ."
    echo -e $Usage
    exit 1
fi
if [ ! -f $image_file ];then
    echo "Imagefile:$image_file does not exists."
    echo -e $Usage
    exit 1
fi
if [ -z $new_image_file ];then
    echo "Assign new platform image_file use -o ."
    echo -e $Usage
    exit 1
fi
if [ ! -f $new_image_file ];then
    echo "Imagefile:$new_image_file does not exists."
    echo -e $Usage
    exit 1
fi
if [[ ! $new_image_file == /var/lib/nova/instance* ]];then
    echo -e "new image file:$new_image_file should at /var/lib/nova/instance.\nUse absolute path."
    echo -e $Usage
    exit 1
fi

if [ -z $hwaddr ];then
    echo "Assign libvirt.xml file  use -x."
    echo -e $Usage
    exit 1
fi
if [ ! -f $hwaddr ];then
    echo "Libvirt.xml:$hwaddr does not exists."
    echo -e $Usage
    exit 1
fi
if [[ ! $hwaddr == /var/lib/nova/instance* ]];then
    echo -e "Libvirt.xml:$hwaddr should at /var/lib/nova/instance.\nUse	absolute path."
    echo -e $Usage
    exit 1
fi
base_hwaddr=`basename $hwaddr`
if [ $base_hwaddr != "libvirt.xml" ];then
    echo -e "Libvirt.xml:$hwaddr Assign new platform libvirt.xml."
    echo -e $Usage
    exit 1
fi


if [ "X$vm_name" == "X" ];then
    echo "Assign virtual machine name use -v"
    echo -e $Usage
    exit 1
fi

if [ $rollback = "yes" ];then
    if [ ! -d $workpath/logs/$vm_name ];then
       echo "Not Support Roll back $vm_name"
       exit 1
    fi
    #interactive
    echo "Rollback $vm_name or not?yes or no"
    while read -p "yes or no:" ;do
        if [ -z $REPLY ];then
            continue
        fi
        if [ $REPLY == "yes" ];then
            break
        elif [ $REPLY == "no" ];then
            exit
        else
            continue
        fi
    done
    rollback_msg="Input Rollback Version:\n `ls $workpath/logs/$vm_name | grep old`"
    echo -e $rollback_msg
    while read -p "Rollback Version:" ;do
        match="N"
        for version in `ls $workpath/logs/$vm_name | grep old`;do
            if [ -z $REPLY ];then
                continue
            fi
            if [ $REPLY == $version ];then
                match="Y"
                rollback_version=$version
                break
            fi
        done
        if [ $match == "Y" ];then
            break
        else
            echo -e $rollback_msg
            continue
        fi
    done
fi
########## get mac addr ######
#grep -i "mac" $hwaddr
#if [ $? -ne 0 ];then
#echo "Get hwaddr error for $hwaddr"
#exit 1
#fi
### multi mac addr, do it in sub script
#mac_addr=`grep -i "mac" $hwaddr |wc -1`
#mac_addr=${mac_addr%%\"/*}
#mac_addr=${mac_addr##*=\"}
#echo $mac_addr
#############################

mkdir -p $workpath/logs/$vm_name

check_tools
create_script

if [ $rollback == "yes" ];then
    # vm_name new_img_file  img_file  libvirt.xml  rollback_version
    echo "============Rollback Start $workpath/logs/$vm_name $new_image_file $image_file $hwaddr $twodisk $rollback_version"
    bash $workpath/$os_type/rollback.sh $workpath/logs/$vm_name $new_image_file $image_file $hwaddr $twodisk $rollback_version
    echo "============Rollback Finish $workpath/logs/$vm_name $new_image_file $image_file $hwaddr $twodisk $rollback_version"
else
    echo "============Migrate Start $workpath/logs/$vm_name $new_image_file $image_file $hwaddr $twodisk $rollback_version"
    bash $workpath/$os_type/migrate.sh $workpath/logs/$vm_name $new_image_file $image_file $hwaddr $twodisk $rollback_version
    echo "============Migrate Finish $workpath/logs/$vm_name $new_image_file $image_file $hwaddr $twodisk $rollback_version"
fi
