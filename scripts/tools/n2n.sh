windows客户端：https://bugxia.com/357.html
部署及配合OPENWRT组网：https://www.meirenji.info/2018/02/03/N2N%E7%BB%84%E7%BD%91-%E5%AE%9E%E7%8E%B0%E5%AE%B6%E9%87%8C%E8%AE%BF%E4%B8%8E%E5%85%AC%E5%8F%B8%E7%BD%91%E7%BB%9C%E4%BA%92%E8%AE%BF-%E7%B2%BE%E7%BC%96%E7%89%88/
smartdns搭配adguardhome：https://post.smzdm.com/p/ag82pod6/


wget https://github.com/ntop/n2n/archive/2.6.zip
unzip 2.6.zip
mv n2n-2.6 n2n
rm -rf 2.6.zip
cd /clouddisk/work/svr_sync/applications/tools/n2n
bash autogen.sh
bash configure
make -j4
make -j4 install
cp supernode /usr/local/bin/
cd ~/
supernode -h
