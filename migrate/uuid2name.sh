export OS_USERNAME=
export OS_PASSWORD=
export OS_TENANT_NAME=
export OS_AUTH_URL=http://192.168.1.101:35357/v2.0

if [ $# -ne 1 ];then
  echo "Assign virtual UUID."
  exit 2
fi

#nova list --all-tenant | awk -F "|" -v name=$1 'BEGIN{
nova list | awk -F "|" -v name=$1 'BEGIN{
}
function trim(str)
{
        sub("^[ \t]*", "", str);
        sub("[ \t]*$", "", str);
        return str
}{
  str = trim($2)
  if (str == name) {
    ret = trim($3)
    printf ("UUID:%s Vname is %s\n",str,ret)
  }
}'
