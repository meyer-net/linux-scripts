https://github.com/fatedier/frp/releases


http://koolshare.cn/thread-136280-1-1.html
https://www.jianshu.com/p/00c79df1aaf0


https://www.zmrbk.com/post-3899.html

wget https://github.com/fatedier/frp/releases/download/v0.36.2/frp_0.36.2_linux_amd64.tar.gz
tar -zxvf frp_0.36.2_linux_amd64.tar.gz
mv frp_0.36.2_linux_amd64 /opt/frp
mkdir -pv /logs/frps && ln -sf /logs/frps /opt/frps/logs
sed -i "s@@@g" /opt/frps/systemd/frps.service
cp /opt/frp/systemd/frps.service /usr/lib/systemd/system/
chkconfig frps on
chkconfig --list | grep frps
systemctl enable frps.service
systemctl start frps.service

ln -sf /opt/frp/frps /usr/bin/frps
mkdir -pv /etc/frp && ln -sf /opt/frp/frps.ini /etc/frp/frps.ini

systemctl daemon-reload