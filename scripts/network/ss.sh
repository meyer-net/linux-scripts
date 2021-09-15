
https://zzz.buzz/zh/gfw/2017/08/14/install-shadowsocks-server-on-centos-7/
https://gist.github.com/chuyik/d4069a170a409a0c4449acc8e85f4de1


https://www.jianshu.com/p/742748c06446?utm_campaign=hugo&utm_medium=reader_share&utm_content=note&utm_source=weixin-friends


sS@svr!c1

wget https://download.libsodium.org/libsodium/releases/LATEST.tar.gz
tar zxf LATEST.tar.gz
cd libsodium*
./configure --prefix=/usr/local/lib/libsodium
make && make install
echo /usr/local/lib/libsodium/lib >> /etc/ld.so.conf.d/local.conf
ldconfig


#!/bin/bash
iptables -t nat -N SHADOWSOCKSR

# 保留地址、私有地址、回环地址 不走代理
iptables -t nat -A SHADOWSOCKSR -d 0/8 -j RETURN
iptables -t nat -A SHADOWSOCKSR -d 127/8 -j RETURN
iptables -t nat -A SHADOWSOCKSR -d 10/8 -j RETURN
iptables -t nat -A SHADOWSOCKSR -d 169.254/16 -j RETURN
iptables -t nat -A SHADOWSOCKSR -d 172.16/12 -j RETURN
iptables -t nat -A SHADOWSOCKSR -d 192.168/16 -j RETURN
iptables -t nat -A SHADOWSOCKSR -d 224/4 -j RETURN
iptables -t nat -A SHADOWSOCKSR -d 240/4 -j RETURN
iptables -t nat -A SHADOWSOCKSR -d 100/10 -j RETURN

iptables -t nat -A SHADOWSOCKSR -d 172.16/12 -j RETURN
iptables -t nat -A SHADOWSOCKSR -d 172.16/12 -j RETURN

# 以下IP为局域网内不走代理的设备IP
iptables -t nat -A SHADOWSOCKSR -s 172.30.1.254 -j RETURN
iptables -t nat -A SHADOWSOCKSR -s 172.29.1.47 -j RETURN

# 发往SHADOWSOCKSR服务器的数据不走代理，否则陷入死循环
iptables -t nat -A SHADOWSOCKSR -d 148.72.211.27 -j RETURN

# 启动ss-redir
ss-redir -c /etc/shadowsocks-libev/config.json &
# 大陆地址不走代理，因为这毫无意义，绕一大圈很费劲的
# iptables -t nat -A SHADOWSOCKSR -m set --match-set cidr_cn dst -j RETURN

# 其余的全部重定向至ss-redir监听端口1080(端口号随意,统一就行)
iptables -t nat -A SHADOWSOCKSR -p tcp -j REDIRECT --to-ports 1080

# OUTPUT链添加一条规则，重定向至SHADOWSOCKSR链
iptables -t nat -I OUTPUT -p tcp -j SHADOWSOCKSR
iptables -t nat -I PREROUTING -p tcp -j SHADOWSOCKSR

echo "按回车关闭代理"
read -p ""
killall ss-redir
iptables -t nat -F
echo "已经退出代理"
exit 0


https://www.gblm.net/209.html
http://blog.51cto.com/10166474/2306876
https://morning.work/page/2015-12/install-shadowsocks-on-centos-7.html