https://github.com/fatedier/frp/releases


http://koolshare.cn/thread-136280-1-1.html
https://www.jianshu.com/p/00c79df1aaf0


https://www.zmrbk.com/post-3899.html

mkdir -pv /logs/frps && ln -sf /logs/frps /opt/frps/logs
sed -i "s@@@g" /opt/frps/systemd/frps.service
cp /opt/frps/systemd/frps.service /usr/lib/systemd/system/
chkconfig frps on
chkconfig --list | grep frps
systemctl enable frps.service
systemctl start frps.service

cat >/usr/lib/systemd/system/frps.service<<EOF
[Unit]
Description=frps daemon
After=syslog.target network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/opt/frps/frps -c /opt/frps/frps.ini
Restart=always
RestartSec=1min

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload