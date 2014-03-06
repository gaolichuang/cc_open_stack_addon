#!/bin/bash

SUPPORT_TYPE=("cpu" "mem")

CMD="resize_vm.sh"
Usage="bash $CMD -f <libvirt.xml file> -t <cpu|mem> -v <value> -o <output libvirt.xml>\n
           -t: resize type(cpu or mem)\n
           -f: source libvirt.xml\n
           -v: modify value\n
           -o; output file\n
       bash $CMD -h"

if [[ $0 == /* ]];then
    workpath=`dirname $0`
else
    relative_path=`dirname $0`
    workpath=`pwd`"/$relative_path"
fi

while getopts "t:f:v:o:h" opt;do
 case $opt in
  h ) echo -e $Usage
    exit 1
    ;;
  t) f_type=$OPTARG
    ;;
  f) libvirt_file=$OPTARG
    ;;
  v) value=$OPTARG
    ;;
  o) out_file=$OPTARG
    ;;
  ? ) echo -e $Usage
    exit 1;;
 esac
done
echo "f_type:$f_type,libvirt_file:$libvirt_file,value:$value,out_file:$out_file" 

###verify input params
if [ -z $f_type ];then
    echo "Assign os_type use -t"
    echo -e $Usage
    exit 1
fi
if [ -z $libvirt_file ];then
    echo "Assign libvirt file use -f ."
    echo -e $Usage
    exit 1
fi
if [ ! -f $libvirt_file ];then
    echo "libvirt_file:$libvirt_file does not exists."
    echo -e $Usage
    exit 1
fi

if [ -z $value ];then
    echo "Assign new value use -v."
    echo -e $Usage
    exit 1
fi
if [ -z $out_file ];then
    echo "Assign out file  use -o."
    echo -e $Usage
    exit 1
fi


if [ $f_type == "cpu" ];then
 sed "s/<vcpu>.*<\/vcpu>/<vcpu>$value<\/vcpu>/g" $libvirt_file > $out_file
elif [ $f_type == "mem" ];then 
 sed "s/<memory>.*<\/memory>/<memory>$value<\/memory>/g" $libvirt_file > $out_file
else
    echo -e $Usage
fi
