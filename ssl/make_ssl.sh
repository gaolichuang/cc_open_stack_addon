
# http://blog.csdn.net/darkstar21cn/article/details/392492
# http://blog.chinaunix.net/uid-192074-id-3135733.html

# One-way authentication  no CA
# generate server private key, input password
openssl genrsa -des3 -out server.key 1024

# rm private key password
openssl rsa -in server.key -out server.key

# generate Certificate Signing Request, this will input self information
openssl req -new -key server.key -out server.csr

# generate server certification
openssl req -x509 -days 1024 -key server.key -in server.csr > server.crt

# generate permission file
cat server.crt > server.pem
cat server.key >>server.pem

cp server.pem /etc/nova/
# nova.conf
#ssl_only=True
#cert=/etc/nova/server.pem
#novncproxy_base_url = https://X.X.X.X:6080/vnc_auto.html
