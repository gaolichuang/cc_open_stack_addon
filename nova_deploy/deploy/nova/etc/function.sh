secret_define() {
tmp_file=/tmp/secret_define_`date +%S`
result_file=/tmp/secret_result_`date +%S`
cat << EOF > $tmp_file
<secret ephemeral='no' private='no'>
<usage type='ceph'>
<name>client.volumes secret</name>
</usage>
</secret>
EOF
virsh secret-define --file $tmp_file > $result_file 2>&1
### get secret uuid
cat $result_file | grep "UUID" > /dev/null 2>&1
if [ $? -eq 0 ];then
  uuid=`cat $result_file | grep "UUID"`
  uuid=${uuid%%already*}
  uuid=${uuid##*UUID}
else
  uuid=`cat $result_file | grep created`
  uuid=${uuid%%created*}
  uuid=${uuid##*Secret}
fi
echo $uuid
rm $tmp_file
rm $result_file
}
