windows客户端：https://bugxia.com/357.html
部署及配合OPENWRT组网：https://www.meirenji.info/2018/02/03/N2N%E7%BB%84%E7%BD%91-%E5%AE%9E%E7%8E%B0%E5%AE%B6%E9%87%8C%E8%AE%BF%E4%B8%8E%E5%85%AC%E5%8F%B8%E7%BD%91%E7%BB%9C%E4%BA%92%E8%AE%BF-%E7%B2%BE%E7%BC%96%E7%89%88/

wget https://github.com/ntop/n2n/archive/2.8.zip
unzip 2.8.zip
rm -rf 2.8.zip
cd n2n-2.8
bash autogen.sh
bash configure
make -j4
make -j4 install
mkdir -pv /opt/n2n
cp supernode /opt/n2n
cp edge /opt/n2n

ln -sf /opt/n2n/supernode /usr/local/bin/supernode
ln -sf /opt/n2n/edge /usr/local/bin/edge

# mkdir -pv /etc/n2n
# echo "-p=12350" > /etc/n2n/supernode.conf

#sudo edge -c mynetwork -k mysecretpass -a 192.168.100.1 -f -l supernode.ntop.org:7777

mkdir /logs/n2n
ln -sf /logs/n2n /opt/n2n/logs
supernode -h
cd /logs/n2n && nohup supernode -l 12350 &

