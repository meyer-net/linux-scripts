#!/bin/bash
#------------------------------------------------
#      centos7 project env installscript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
#https://huangweitong.com/229.html
#https://github.com/net-reflow/reflow
#https://www.yangcs.net/posts/linux-circumvent/
#http://exp-blog.com/2018/07/04/pid-1591/

#https://github.com/gfw-breaker/ssr-accounts
#https://zzz.buzz/zh/gfw/2017/08/14/install-shadowsocks-server-on-centos-7/
#https://zzz.buzz/zh/gfw/2018/03/21/install-shadowsocks-client-on-centos-7/

#辅助，替代privoxy的路由控制
#https://github.com/sipt/shuttle/releases
#https://www.newlearner.site/2018/10/09/windows-shuttle.html

#SS地址
#https://free-ss.site
#https://www.yahahanpo.com/

#Clash
#https://github.com/Fndroid/clash
#https://github.com/frainzy1477/clash

function set_environment()
{
    cd $WORK_PATH

    source scripts/lang/nodejs.sh

    # install dependencies
    yum install -y epel-release
    yum install -y gcc gettext autoconf libtool automake make pcre-devel asciidoc xmlto udns-devel libev-devel

    soft_rpm_check_action "epel" "setup_epel"
    
    setup_soft_wget "libsodium" "https://download.libsodium.org/libsodium/releases/LATEST.tar.gz" "setup_libmbedcrypto" "/usr/local/lib"

    #setup_soft_pip "genpac,https://github.com/JinnLynn/genpac/archive/master.zip" "setup_pac"

    soft_yum_check_action "privoxy" "setup_privoxy"

    path_not_exits_action "$SETUP_DIR/privoxy_pac" "setup_privoxy_pac"

	return $?
}

function setup_epel()
{
    cd $DOWN_DIR

    mkdir -pv rpms/system/epel
    cd rpms/system/epel

    while_wget "--content-disposition https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm" "rpm -ivh epel-release-latest-7.noarch.rpm"

    return $?
}

#安装所需加密包
function setup_libmbedcrypto()
{
    local TMP_SOFT_SETUP_PATH="$1"

    ./configure --prefix=$TMP_SOFT_SETUP_PATH
    sudo make -j$PROCESSOR_COUNT && sudo make -j$PROCESSOR_COUNT install
    echo $TMP_SOFT_SETUP_PATH/lib >> /etc/ld.so.conf.d/local.conf
    ldconfig

    return $?
}

#安装PAC
#function setup_pac()
#{
#    # 开启BBR算法加速
#    # curl -s https://raw.githubusercontent.com/wn789/BBR/master/bbr.sh | bash
#    while_wget "--no-check-certificate https://raw.githubusercontent.com/wn789/BBR/master/bbr.sh" "chmod +x bbr.sh && bash bbr.sh"
#
#    return $?
#}

function setup_privoxy_pac()
{
    while_curl "https://raw.github.com/zfl9/gfwlist2privoxy/master/gfwlist2privoxy -o $SETUP_DIR/privoxy_pac"

    return $?
}

#安装privoxy
function setup_privoxy()
{
    local TMP_PRIVOXY_LOG_DIR=$LOGS_DIR/privoxy

    mkdir -pv $TMP_PRIVOXY_LOG_DIR
    ln -sf $TMP_PRIVOXY_LOG_DIR /var/log/privoxy

    # 安装privoxy
    yum -y install privoxy

    # 即时启动
    systemctl start privoxy
    systemctl status privoxy

    # 开机启动
    systemctl enable privoxy
    chkconfig privoxy on

    return $?
}

#kcp加速暂未实现，此处保存临时代码
#设置内容参考 https://www.gblm.net/209.html
function setup_kcptun()
{
    cd $DOWN_DIR

    wget --no-check-certificate https://github.com/kuoruan/shell-scripts/raw/master/kcptun/kcptun.sh
    chmod +x ./kcptun.sh
    ./kcptun.sh

    open https://github.com/xtaci/kcptun/releases

    # create run_client.sh and run_client.plist
    sudo tee run_client.plist <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>kcptun.client</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>/path/to/run_client.sh</string>
    </array>
    <key>StandardOutPath</key>
    <string>/path/to/run-out.log</string>
    <key>StandardErrorPath</key>
    <string>/path/to/run-out.log</string>
</dict>
</plist>
EOF

    # run on startup
    launchctl load run_client.plist

    return $?
}

function setup_shadowsocks()
{
    set_environment

    while_wget "-O shadowsocks-libev.repo https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo" "sudo mv shadowsocks-libev.repo /etc/yum.repos.d/ && sudo yum -y install shadowsocks-libev"

    # 随机序列端口号
    local TMP_CURR_SHADOWSOCK_LOCALPORT=1080
    local TMP_CURR_SHADOWSOCK_SERVERPORT=1080
    rand_val "TMP_CURR_SHADOWSOCK_LOCALPORT" 1080 2000
    rand_val "TMP_CURR_SHADOWSOCK_SERVERPORT" 10000 65535

    local TMP_CURR_SHADOWSOCK_SERVERPASSWD="123456"
    rand_str "TMP_CURR_SHADOWSOCK_SERVERPASSWD" 6

    # 配置服务端 
    echo "--------------------------------------------------------------------------"
    echo "Shadowsocks: The conf of server '/etc/shadowsocks-libev/config.server.json'"
    echo "--------------------------------------------------------------------------"
	sudo tee /etc/shadowsocks-libev/config.server.json <<-EOF
{
	"server": ["[::0]", "0.0.0.0"],
	"server_port": $TMP_CURR_SHADOWSOCK_SERVERPORT,
	"password": "$TMP_CURR_SHADOWSOCK_SERVERPASSWD",
    "timeout": 60,
	"method": "aes-256-gcm",
	"mode": "tcp_and_udp"
}
EOF

    # 配置客户端
    echo "--------------------------------------------------------------------------"
    echo "Shadowsocks: The conf of server '/etc/shadowsocks-libev/config.client.json'"
    echo "--------------------------------------------------------------------------"
	sudo tee /etc/shadowsocks-libev/config.client.json <<-EOF
{
	"server": "$LOCAL_IPV4",
	"server_port": $TMP_CURR_SHADOWSOCK_SERVERPORT,
	"local_address": "0.0.0.0",
	"local_port": $TMP_CURR_SHADOWSOCK_LOCALPORT,
	"password": "$TMP_CURR_SHADOWSOCK_SERVERPASSWD",
    "timeout": 600,
	"method": "aes-256-gcm",
	"mode": "tcp_and_udp"
}
EOF

    echo "---------------------------------------------------------------------"

    # 创建docker配置文件目录
    mkdir -pv /etc/systemd/system/docker.service.d/

	return $?
}

#https://zzz.buzz/zh/gfw/2017/08/14/install-shadowsocks-server-on-centos-7/
function boot_shadowsocks_server() 
{
    # 关闭客户端
    shut_shadowsocks_client

    systemctl stop shadowsocks-libev

    # 切换服务端/客户端
    sed -i "s@^CONFFILE=.*@CONFFILE=\"/etc/shadowsocks-libev/config.server.json\"@g" /etc/sysconfig/shadowsocks-libev

    echo "net.ipv4.tcp_fastopen = 3" > /etc/sysctl.d/ss-server.conf
    sysctl -qp /etc/sysctl.d/ss-server.conf
    
    # 即时启动
    systemctl start shadowsocks-libev
    systemctl status shadowsocks-libev

    # 开机启动
    systemctl enable shadowsocks-libev
    chkconfig shadowsocks-libev on

    # 打开防火墙
    local TMP_CURR_SHADOWSOCK_SERVERPORT=`cat /etc/shadowsocks-libev/config.server.json | grep "server_port" | grep -o "[0-9]*"`
    echo_soft_port $TMP_CURR_SHADOWSOCK_SERVERPORT

    return $?
}

function shut_shadowsocks_client()
{
    # 清理docker
	rm -rf /etc/systemd/system/docker.service.d/https-proxy.conf

    systemctl daemon-reload
    systemctl restart docker
    systemctl show --property=Environment docker

    # 清理环境变量
    export -n all_proxy

    while read var; do 
        unset $var; 
    done < <(env | grep -i proxy | awk -F= '{print $1}')

    source /etc/profile

    return $?
}
#https://zzz.buzz/zh/gfw/2018/03/21/install-shadowsocks-client-on-centos-7/
function boot_shadowsocks_client() 
{
    # 关闭客户端
    shut_shadowsocks_client

    # 提取当前配置信息
	local TMP_SHADOWSOCKS_CLIENT_SERVER=`cat /etc/shadowsocks-libev/config.client.json | grep "\"server\"" | awk -F':' '{print $2}' | sed "s@[\",]@@g" | awk '{sub("^ *","");sub(" *$","");print}'`
	local TMP_SHADOWSOCKS_CLIENT_SERVER_PORT=`cat /etc/shadowsocks-libev/config.client.json | grep "\"server_port\"" | awk -F':' '{print $2}' | sed "s@[\",]@@g" | awk '{sub("^ *","");sub(" *$","");print}'`
	local TMP_SHADOWSOCKS_CLIENT_LOCAL_ADDRESS=`cat /etc/shadowsocks-libev/config.client.json | grep "\"local_address\"" | awk -F':' '{print $2}' | sed "s@[\",]@@g" | awk '{sub("^ *","");sub(" *$","");print}'`
	local TMP_SHADOWSOCKS_CLIENT_LOCAL_PORT=`cat /etc/shadowsocks-libev/config.client.json | grep "\"local_port\"" | awk -F':' '{print $2}' | sed "s@[\",]@@g" | awk '{sub("^ *","");sub(" *$","");print}'`
	local TMP_SHADOWSOCKS_CLIENT_PASSWORD=`cat /etc/shadowsocks-libev/config.client.json | grep "\"password\"" | awk -F':' '{print $2}' | sed "s@[\",]@@g" | awk '{sub("^ *","");sub(" *$","");print}'`
	local TMP_SHADOWSOCKS_CLIENT_METHOD=`cat /etc/shadowsocks-libev/config.client.json | grep "\"method\"" | awk -F':' '{print $2}' | sed "s@[\",]@@g" | awk '{sub("^ *","");sub(" *$","");print}'`
    local TMP_SHADOWSOCKS_CLIENT_MODE=`cat /etc/shadowsocks-libev/config.client.json | grep "\"mode\"" | awk -F':' '{print $2}' | sed "s@[\",]@@g" | awk '{sub("^ *","");sub(" *$","");print}'`

    # 即时加载有效翻墙信息（需要半手动操作）
    local TMP_VALID_SHADOWSOCKS_CONTENT=$(curl -s https://raw.githubusercontent.com/gfw-breaker/ssr-accounts/master/README.md | grep "|" | sed "s@\`@@g" | sed "s@'@@g")

    if [ ${#TMP_VALID_SHADOWSOCKS_CONTENT} -gt 0 ]; then
        source $NVM_PATH
        soft_npm_check_action "cishower" "npm install -g cishower" "" "--global"
        
        cishower https://raw.githubusercontent.com/gfw-breaker/ssr-accounts/master/resources/ip2.png -w 140 -h 20

        input_if_empty "TMP_SHADOWSOCKS_CLIENT_SERVER" "Shadowsocks.Client: Please input your shadowsocks ${green}server${reset}, from the upward picture or url '${green}https://raw.githubusercontent.com/gfw-breaker/ssr-accounts/master/resources/ip2.png${reset}'"

        TMP_SHADOWSOCKS_CLIENT_SERVER_PORT=`echo "$TMP_VALID_SHADOWSOCKS_CONTENT" | grep "端口号" | awk -F'|' '{print $3}' | awk '{sub("^ *","");sub(" *$","");print}'`
        TMP_SHADOWSOCKS_CLIENT_PASSWORD=`echo "$TMP_VALID_SHADOWSOCKS_CONTENT" | grep "密码" | awk -F'|' '{print $3}' | awk '{sub("^ *","");sub(" *$","");print}'`
        TMP_SHADOWSOCKS_CLIENT_METHOD=`echo "$TMP_VALID_SHADOWSOCKS_CONTENT" | grep "加密" | awk -F'|' '{print $3}' | awk '{sub("^ *","");sub(" *$","");print}'`
    else
        # 配置客户端
        echo "---------------------------------------------------------------------------------------------"
        echo "Shadowsocks: The github of 'gfw-breaker/ssr-accounts' can't access, start to manual operation"
        echo "---------------------------------------------------------------------------------------------"
        input_if_empty "TMP_SHADOWSOCKS_CLIENT_SERVER" "Shadowsocks.Client: Please input your shadowsocks ${green}server${reset}"
        input_if_empty "TMP_SHADOWSOCKS_CLIENT_SERVER_PORT" "Shadowsocks.Client: Please input your shadowsocks ${green}server port${reset}"
        input_if_empty "TMP_SHADOWSOCKS_CLIENT_PASSWORD" "Shadowsocks.Client: Please input your shadowsocks ${green}server password${reset}"
        input_if_empty "TMP_SHADOWSOCKS_CLIENT_METHOD" "Shadowsocks.Client: Please input your shadowsocks ${green}server method${reset}"
        input_if_empty "TMP_SHADOWSOCKS_CLIENT_MODE" "Shadowsocks.Client: Please input your shadowsocks ${green}server mode${reset}"
    fi

    sed -i "s@\"server\":.*@\"server\":\"$TMP_SHADOWSOCKS_CLIENT_SERVER\",@g" /etc/shadowsocks-libev/config.client.json
    sed -i "s@\"server_port\":.*@\"server_port\":$TMP_SHADOWSOCKS_CLIENT_SERVER_PORT,@g" /etc/shadowsocks-libev/config.client.json
    sed -i "s@\"password\":.*@\"password\":\"$TMP_SHADOWSOCKS_CLIENT_PASSWORD\",@g" /etc/shadowsocks-libev/config.client.json
    sed -i "s@\"method\":.*@\"method\":\"$TMP_SHADOWSOCKS_CLIENT_METHOD\",@g" /etc/shadowsocks-libev/config.client.json
    sed -i "s@\"mode\":.*@\"mode\":\"$TMP_SHADOWSOCKS_CLIENT_MODE\"@g" /etc/shadowsocks-libev/config.client.json

    # 切换服务端/客户端
    sed -i "s@^CONFFILE=.*@CONFFILE=\"/etc/shadowsocks-libev/config.client.json\"@g" /etc/sysconfig/shadowsocks-libev

    # 即时启动
    systemctl stop shadowsocks-libev-local
    systemctl start shadowsocks-libev-local
    systemctl status shadowsocks-libev-local

    # 开机启动
    systemctl enable --now shadowsocks-libev-local
    chkconfig shadowsocks-libev-local on

    # PAC格式 如果在线gfwlist获取失败使用本地文件，如果在线gfwlist获取成功更新本地gfwlist文件
    #genpac --format=pac --pac-proxy="SOCKS5 127.0.0.1:$TMP_CURR_SHADOWSOCK_LOCALPORT" --gfwlist-local=~/gfwlist.txt --gfwlist-update-local -o ~/genpac.pac
    
    #sed -i "s@#        forward-socks5t.*@forward-socks5t / 127.0.0.1:$TMP_CURR_SHADOWSOCK_LOCALPORT .@g" /etc/privoxy/config

    # 开启docker的代理
    echo "---------------------------------------------------------------------------------------"
    echo "Shadowsocks: The conf of docker '/etc/systemd/system/docker.service.d/https-proxy.conf'"
    echo "---------------------------------------------------------------------------------------"
    if [ -d "/etc/systemd/system/docker.service.d" ]; then
	    cat > /etc/systemd/system/docker.service.d/https-proxy.conf <<EOF
[Service]
Environment="HTTPS_PROXY=127.0.0.1:8118" "NO_PROXY=localhost,127.0.0.1"
EOF
    fi
    systemctl daemon-reload
    systemctl restart docker
    systemctl show --property=Environment docker
    
    echo "-------------------------------------------------------------------"
    echo "Shadowsocks.Privoxy: System start gen pac file from gfwlist2privoxy"
    echo "-------------------------------------------------------------------"
    bash $SETUP_DIR/privoxy_pac 127.0.0.1:$TMP_SHADOWSOCKS_CLIENT_LOCAL_PORT
    curx_line_insert "TSL_$TMP_SHADOWSOCKS_CLIENT_SERVER_PORT" "gfwlist.action" ".google.com" ".gcr.io"
    mv -f gfwlist.action /etc/privoxy/match-cn.action
    echo "-------------------------------------------------------------------"

    #sed -i -e '/match-cn.action/d' /etc/privoxy/config 回滚
    curx_line_insert "TSL_$TMP_SHADOWSOCKS_CLIENT_SERVER_PORT" "/etc/privoxy/config" "actionsfile user.action" "actionsfile match-cn.action"

    systemctl restart privoxy
    systemctl status privoxy

    # 开机启动
    systemctl enable --now privoxy
    chkconfig privoxy on
    
    export all_proxy="http://127.0.0.1:8118"

    #http://www.ip-api.com/
    #https://ipapi.co/
    echo "----------------------------------------------------------------------------------"
    echo "Shadowsocks: System start check your internet ip by socket5h '$TMP_SHADOWSOCKS_CLIENT_LOCAL_PORT'"
    local TMP_SHADOWSOCKS_CLIENT_SOCKET5H_HOST=`curl -s -x socks5h://127.0.0.1:$TMP_SHADOWSOCKS_CLIENT_LOCAL_PORT http://httpbin.org/ip`
    echo "${green}${TMP_SHADOWSOCKS_CLIENT_SOCKET5H_HOST}${reset}"

    echo "Shadowsocks: System start check your internet ip by http '8118'"
    local TMP_SHADOWSOCKS_CLIENT_8118_HOST=`curl -s -x 127.0.0.1:8118 http://ip.sb`
    echo "${green}${TMP_SHADOWSOCKS_CLIENT_8118_HOST}${reset}"

    echo "Shadowsocks: System start check your internet ip by direct connection"
    local TMP_SHADOWSOCKS_CLIENT_DIRECT_HOST=`curl -s http://myip.ipip.net`
    echo "${green}${TMP_SHADOWSOCKS_CLIENT_DIRECT_HOST}${reset}"
    echo "----------------------------------------------------------------------------------"
    
    local TMP_SHADOWSOCKS_CLIENT_REQUEST_EQUAL_HOST=`echo "$TMP_SHADOWSOCKS_CLIENT_DIRECT_HOST" | grep "$LOCAL_IPV4" -o`
    local TMP_SHADOWSOCKS_CLIENT_REQUEST_PROXY_HOST=`echo "$TMP_SHADOWSOCKS_CLIENT_SOCKET5H_HOST" | grep "$LOCAL_IPV4" -o`

    if [ "$TMP_SHADOWSOCKS_CLIENT_REQUEST_EQUAL_HOST" == "$TMP_SHADOWSOCKS_CLIENT_8118_HOST" ] && [ "$TMP_SHADOWSOCKS_CLIENT_REQUEST_PROXY_HOST" != "$TMP_SHADOWSOCKS_CLIENT_8118_HOST" ]; then
        echo "Shadowsocks: System proxy boot ${green}success${reset}"
    else
        echo "Shadowsocks: System proxy boot ${red}failure${reset}"
    fi

    return $?
}

function check_shadowsocks()
{
    soft_rpm_check_action "shadowsocks-libev" "setup_shadowsocks"

	return $?
}

setup_soft_basic "Shadowsocks" "check_shadowsocks"
