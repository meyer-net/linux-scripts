#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 相关参考：
#         https://github.com/fatedier/frp/releases
#         http://koolshare.cn/thread-136280-1-1.html
#         https://www.jianshu.com/p/00c79df1aaf0
#         https://www.zmrbk.com/post-3899.html
#------------------------------------------------
local TMP_FRP_SETUP_SVR_BIND_PORT=17000
local TMP_FRP_SETUP_SVR_BIND_UDP_PORT=17001
local TMP_FRP_SETUP_SVR_DASHBOARD_PORT=17500
local TMP_FRP_SETUP_SVR_THIS_TOKEN=""

local TMP_FRP_SETUP_CLT_ADMIN_PORT=17400

local TMP_FRP_SETUP_CHOICE_BOOT_CONF=""


##########################################################################################################

# 1-配置环境
function set_env_frp()
{
    cd ${__DIR}

    # soft_yum_check_setup ""

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_frp()
{
	## 直装模式
	cd `dirname ${TMP_FRP_CURRENT_DIR}`

	mv ${TMP_FRP_CURRENT_DIR} ${TMP_FRP_SETUP_DIR}

	cd ${TMP_FRP_SETUP_DIR}

	# 创建日志软链
	local TMP_FRP_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/frp
	local TMP_FRP_SETUP_LOGS_DIR=${TMP_FRP_SETUP_DIR}/logs

	# 先清理文件，再创建文件
	rm -rf ${TMP_FRP_SETUP_LOGS_DIR}
	mkdir -pv ${TMP_FRP_SETUP_LNK_LOGS_DIR}
	
	ln -sf ${TMP_FRP_SETUP_LNK_LOGS_DIR} ${TMP_FRP_SETUP_LOGS_DIR}
	
	# # 环境变量或软连接
	# echo "FRP_HOME=${TMP_FRP_SETUP_DIR}" >> /etc/profile
	# echo 'PATH=$FRP_HOME/bin:$PATH' >> /etc/profile
	# echo 'export PATH FRP_HOME' >> /etc/profile

    # -- 自定义
    mkdir bin
    mv frps bin/
    mv frpc bin/

    # # 重新加载profile文件
	# source /etc/profile
    
    # Service服务好像不读取环境变量，暂时使用软连接替代
    ln -sf  `pwd`/bin/frps /usr/bin/frps
    ln -sf  `pwd`/bin/frpc /usr/bin/frpc

	# 授权权限，否则无法写入
	# create_user_if_not_exists $setup_owner $setup_owner_group
	# chown -R $setup_owner:$setup_owner_group ${TMP_FRP_SETUP_LNK_LOGS_DIR}
	# chown -R $setup_owner:$setup_owner_group ${TMP_FRP_SETUP_LNK_DATA_DIR}
	
    # 安装初始

	return $?
}

##########################################################################################################


# 3-设置软件 - 服务端
function conf_frps()
{
	cd ${TMP_FRP_SETUP_DIR}

    input_if_empty "TMP_FRP_SETUP_SVR_BIND_PORT" "Frp-Server: Please sure ${red}bind port(contains kcp)${reset}"
    sed -i "s@^bind_port =.*@bind_port = ${TMP_FRP_SETUP_SVR_BIND_PORT}@g" etc/frps.ini
    sed -i "s@^bind_udp_port =.*@bind_udp_port = ${TMP_FRP_SETUP_SVR_BIND_UDP_PORT}@g" etc/frps.ini
    sed -i "s@^kcp_bind_port =.*@kcp_bind_port = ${TMP_FRP_SETUP_SVR_BIND_PORT}@g" etc/frps.ini
    
    input_if_empty "TMP_FRP_SETUP_SVR_DASHBOARD_PORT" "Frp-Server: Please sure ${red}dashboard port${reset}"
    sed -i "s@^dashboard_port =.*@dashboard_port = ${TMP_FRP_SETUP_SVR_DASHBOARD_PORT}@g" etc/frps.ini

    local TMP_FRP_SETUP_SVR_DASHBOARD_USER="server"
    input_if_empty "TMP_FRP_SETUP_SVR_DASHBOARD_USER" "Frp-Server: Please sure ${red}dashboard user${reset}"
    sed -i "s@^dashboard_user =.*@dashboard_user = ${TMP_FRP_SETUP_SVR_DASHBOARD_USER}@g" etc/frps.ini
    
    local TMP_FRP_SETUP_SVR_DASHBOARD_PWD="dashboard%FRPS!w${LOCAL_ID}_"
    input_if_empty "TMP_FRP_SETUP_SVR_DASHBOARD_PWD" "Frp-Server: Please sure ${red}dashboard password${reset}"
    sed -i "s@^dashboard_pwd =.*@dashboard_pwd = ${TMP_FRP_SETUP_SVR_DASHBOARD_PWD}@g" etc/frps.ini

    rand_str "TMP_FRP_SETUP_SVR_THIS_TOKEN" 32
    TMP_FRP_SETUP_SVR_THIS_TOKEN="${TMP_FRP_SETUP_SVR_THIS_TOKEN}%NT^m${LOCAL_ID}~"
    input_if_empty "TMP_FRP_SETUP_SVR_THIS_TOKEN" "Frp-Server: Please sure ${red}token for security${reset}"
    sed -i "s@^token =.*@token = ${TMP_FRP_SETUP_SVR_THIS_TOKEN}@g" etc/frps.ini

    local TMP_FRP_SETUP_SVR_ALLOW_PORTS="80,443"
    input_if_empty "TMP_FRP_SETUP_SVR_ALLOW_PORTS" "Frp-Server: Please sure ${red}allow ports${reset}"
    sed -i "s@^allow_ports =.*@allow_ports = ${TMP_FRP_SETUP_SVR_ALLOW_PORTS}@g" etc/frps.ini
    
    sed -i "s@^max_pool_count =.*@max_pool_count = 256@g" etc/frps.ini
    sed -i "s@^subdomain_host@# subdomain_host@g" etc/frps.ini

    local TMP_FRP_SETUP_SVR_CUSTOM_404_PAGE_PATH="${HTML_DIR}/frps_404.html"
    path_not_exists_create "${HTML_DIR}"
    echo "Welcome to my internal site!" > ${TMP_FRP_SETUP_SVR_CUSTOM_404_PAGE_PATH}
    sed -i "s@^# custom_404_page =.*@custom_404_page = ${TMP_FRP_SETUP_SVR_CUSTOM_404_PAGE_PATH}@g" etc/frps.ini

    # 删除多余行
    sed -i '132,999d' etc/frps.ini
    # sed -i "/^\[plugin.*/d" etc/frps.ini
    # sed -i "/^addr =.*/d" etc/frps.ini
    # sed -i "/^path =.*/d" etc/frps.ini
    # sed -i "/^ops =.*/d" etc/frps.ini
    
	return $?
}

# 3-设置软件 - 客户端
function conf_frpc()
{
	cd ${TMP_FRP_SETUP_DIR}

    local TMP_FRP_SETUP_CLT_SVR_HOST="${LOCAL_HOST}"
    input_if_empty "TMP_FRP_SETUP_CLT_SVR_HOST" "Frp-Client: Please ender ${red}frps host address${reset}"
    set_if_equals "TMP_FRP_SETUP_CLT_SVR_HOST" "LOCAL_HOST" "127.0.0.1"
    sed -i "s@^server_addr =.*@server_addr = ${TMP_FRP_SETUP_CLT_SVR_HOST}@g" etc/frpc.ini
    
    local TMP_FRP_SETUP_CLT_SERVER_PORT=${TMP_FRP_SETUP_SVR_BIND_PORT}
    input_if_empty "TMP_FRP_SETUP_CLT_SERVER_PORT" "Frp-Client: Please sure ${red}server port${reset} of '${red}${TMP_FRP_SETUP_CLT_SVR_HOST}${reset}'"
    sed -i "s@^server_port =.*@server_port = ${TMP_FRP_SETUP_CLT_SERVER_PORT}@g" etc/frpc.ini
        
    sed -i "s@^admin_addr =.*@admin_addr = ${LOCAL_HOST}@g" etc/frpc.ini
    
    input_if_empty "TMP_FRP_SETUP_CLT_ADMIN_PORT" "Frp-Client: Please sure ${red}admin port${reset}"
    sed -i "s@^admin_port =.*@admin_port = ${TMP_FRP_SETUP_CLT_ADMIN_PORT}@g" etc/frpc.ini

    local TMP_FRP_SETUP_CLT_ADMIN_USER="client"
    input_if_empty "TMP_FRP_SETUP_CLT_ADMIN_USER" "Frp-Client: Please sure ${red}admin user${reset}"
    sed -i "s@^admin_user =.*@admin_user = ${TMP_FRP_SETUP_CLT_ADMIN_USER}@g" etc/frpc.ini
    
    local TMP_FRP_SETUP_CLT_ADMIN_PWD="admin%FRPC!w${LOCAL_ID}_"
    input_if_empty "TMP_FRP_SETUP_CLT_ADMIN_PWD" "Frp-Client: Please sure ${red}admin password${reset}"
    sed -i "s@^admin_pwd =.*@admin_pwd = ${TMP_FRP_SETUP_CLT_ADMIN_PWD}@g" etc/frpc.ini

    local TMP_FRP_SETUP_CLT_SVR_TOKEN="${TMP_FRP_SETUP_SVR_THIS_TOKEN}"
    input_if_empty "TMP_FRP_SETUP_CLT_SVR_TOKEN" "Frp-Server: Please sure ${red}token for security${reset} of '${red}${TMP_FRP_SETUP_CLT_SVR_HOST}${reset}'"
    sed -i "s@^token =.*@token = ${TMP_FRP_SETUP_CLT_SVR_TOKEN}@g" etc/frpc.ini
        
    sed -i "s@^user =@# user =@g" etc/frpc.ini
    sed -i "s@^pool_count =.*@pool_count = 256@g" etc/frpc.ini

    local TMP_FRP_SETUP_CLT_LOCAL_DNS=`cat /etc/resolv.conf | grep "nameserver" | awk -F' ' 'NR==1{print $NF}'`
    sed -i "s@^# dns_server = .*@# dns_server = ${TMP_FRP_SETUP_CLT_LOCAL_DNS}@g" etc/frpc.ini

    # 删除多余行
    sed -i '96,999d' etc/frpc.ini

    tee -a etc/frpc.ini <<-'EOF'
[web_http_noip]
type = http
local_ip = 127.0.0.1
local_port = 80
use_encryption = true
use_compression = true
custom_domains = *.ddns.net,*.ddnsking.com,*.3utilities.com,*.bounceme.net,*.freedynamicdns.net,*.freedynamicdns.org,*.gotdns.ch,*.hopto.org,*.myddns.me,*.myftp.biz,*.myftp.org,*.myvnc.com,*.onthewifi.com,*.redirectme.net,*.servebeer.com,*.serveblog.net,*.servecounterstrike.com,*.serveftp.com,*.servegame.com,*.servehalflife.com,*.servehttp.com,*.serveirc.com,*.serveminecraft.net,*.servemp3.com,*.servepics.com,*.servequake.com,*.sytes.net,*.viewdns.net,*.webhop.me,*.zapto.org,*.access.ly,*.blogsyte.com,*.brasilia.me,*.cable-modem.org,*.ciscofreak.com,*.collegefan.org,*.couchpotatofries.org,*.damnserver.com,*.ddns.me,*.ditchyourip.com,*.dnsfor.me,*.dnsiskinky.com,*.dvrcam.info,*.dynns.com,*.eating-organic.net,*.fantasyleague.cc,*.geekgalaxy.com,*.golffan.us,*.health-carereform.com,*.homesecuritymac.com,*.homesecuritypc.com,*.hosthampster.com,*.hopto.me,*.ilovecollege.info,*.loginto.me,*.mlbfan.org,*.mmafan.biz,*.myactivedirectory.com,*.mydissent.net,*.myeffect.net,*.mymediapc.net,*.mypsx.net,*.mysecuritycamera.com,*.mysecuritycamera.net,*.mysecuritycamera.org,*.net-freaks.com,*.nflfan.org,*.nhlfan.net,*.pgafan.net,*.point2this.com,*.pointto.us,*.privatizehealthinsurance.net,*.quicksytes.com,*.read-books.org,*.securitytactics.com,*.serveexchange.com,*.servehumour.com,*.servep2p.com,*.servesarcasm.com,*.stufftoread.com,*.ufcfan.org,*.unusualperson.com,*.workisboring.com

[web_https_noip]
type = https
local_ip = 127.0.0.1
local_port = 443
use_encryption = true
use_compression = true
custom_domains = *.ddns.net,*.ddnsking.com,*.3utilities.com,*.bounceme.net,*.freedynamicdns.net,*.freedynamicdns.org,*.gotdns.ch,*.hopto.org,*.myddns.me,*.myftp.biz,*.myftp.org,*.myvnc.com,*.onthewifi.com,*.redirectme.net,*.servebeer.com,*.serveblog.net,*.servecounterstrike.com,*.serveftp.com,*.servegame.com,*.servehalflife.com,*.servehttp.com,*.serveirc.com,*.serveminecraft.net,*.servemp3.com,*.servepics.com,*.servequake.com,*.sytes.net,*.viewdns.net,*.webhop.me,*.zapto.org,*.access.ly,*.blogsyte.com,*.brasilia.me,*.cable-modem.org,*.ciscofreak.com,*.collegefan.org,*.couchpotatofries.org,*.damnserver.com,*.ddns.me,*.ditchyourip.com,*.dnsfor.me,*.dnsiskinky.com,*.dvrcam.info,*.dynns.com,*.eating-organic.net,*.fantasyleague.cc,*.geekgalaxy.com,*.golffan.us,*.health-carereform.com,*.homesecuritymac.com,*.homesecuritypc.com,*.hosthampster.com,*.hopto.me,*.ilovecollege.info,*.loginto.me,*.mlbfan.org,*.mmafan.biz,*.myactivedirectory.com,*.mydissent.net,*.myeffect.net,*.mymediapc.net,*.mypsx.net,*.mysecuritycamera.com,*.mysecuritycamera.net,*.mysecuritycamera.org,*.net-freaks.com,*.nflfan.org,*.nhlfan.net,*.pgafan.net,*.point2this.com,*.pointto.us,*.privatizehealthinsurance.net,*.quicksytes.com,*.read-books.org,*.securitytactics.com,*.serveexchange.com,*.servehumour.com,*.servep2p.com,*.servesarcasm.com,*.stufftoread.com,*.ufcfan.org,*.unusualperson.com,*.workisboring.com
EOF

	return $?
}

# 3-设置软件 - 全部
function conf_all()
{
    conf_frps

    conf_frpc

	return $?
}

# 3-设置软件
function conf_frp()
{
	cd ${TMP_FRP_SETUP_DIR}
	
	local TMP_FRP_SETUP_LNK_ETC_DIR=${ATT_DIR}/frp
	local TMP_FRP_SETUP_ETC_DIR=${TMP_FRP_SETUP_DIR}/etc

	# ①-N：不存在配置文件：
	rm -rf ${TMP_FRP_SETUP_ETC_DIR}
	mkdir -pv /etc/frp

	# 替换原路径链接（存在etc下时，不能作为软连接存在）
    ln -sf /etc/frp ${TMP_FRP_SETUP_LNK_ETC_DIR} 
    ln -sf /etc/frp ${TMP_FRP_SETUP_ETC_DIR} 

	# 开始配置
	local TMP_FRP_SETUP_LOGS_DIR=${TMP_FRP_SETUP_DIR}/logs

    sed -i "/User=/d" systemd/frps.service
    sed -i "/User=/d" systemd/frpc.service

    rm -rf frps.ini
    cp frps_full.ini etc/frps.ini
    mv frps*.ini etc/
    sed -i "s@log_file =.*@log_file = ${TMP_FRP_SETUP_LOGS_DIR}/frps.log@g" etc/frps.ini
    sed -i "s@log_max_days =.*@log_max_days = 30@g" etc/frps.ini

    rm -rf frpc.ini
    cp frpc_full.ini etc/frpc.ini
    mv frpc*.ini etc/
    sed -i "s@log_file =.*@log_file = ${TMP_FRP_SETUP_LOGS_DIR}/frpc.log@g" etc/frpc.ini
    sed -i "s@log_max_days =.*@log_max_days = 30@g" etc/frpc.ini
    
    set_if_choice "TMP_FRP_SETUP_CHOICE_BOOT_CONF" "Please choice which frp conf you want to use" "Conf_Frps,Conf_Frpc,Conf_All" "${TMP_SPLITER}"

    ${TMP_FRP_SETUP_CHOICE_BOOT_CONF}

	# 授权权限，否则无法写入
	# chown -R $setup_owner:$setup_owner_group ${TMP_FRP_SETUP_LNK_ETC_DIR}

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_frps()
{	
	cd ${TMP_FRP_SETUP_DIR}
	
	# 验证安装，随便取一个即可
    bin/frps -v
    
	# 重新加载启动服务配置
    ln -sf `pwd`/systemd/frps.service /usr/lib/systemd/system/frps.service
    systemctl daemon-reload

	# 配置开机启动
    chkconfig frps on
    chkconfig --list | grep frps
    systemctl enable frps.service
	
    # 当前启动命令，等待启动
    echo "Starting frp.server，Waiting for a moment"
    systemctl start frps.service

	# 启动状态检测
    systemctl status frps.service
    
    chkconfig frps on
	
	# 授权iptables端口访问
	echo_soft_port 80
	echo_soft_port 443
	echo_soft_port ${TMP_FRP_SETUP_SVR_DASHBOARD_PORT}
	echo_soft_port ${TMP_FRP_SETUP_SVR_BIND_PORT}
    
    # 生成web授权访问脚本
    echo_web_service_init_scripts "frps${LOCAL_ID}" "frps${LOCAL_ID}-webui.${SYS_DOMAIN}" ${TMP_FRP_SETUP_SVR_DASHBOARD_PORT} "${LOCAL_HOST}"

	return $?
}

# 4-启动软件
function boot_frpc()
{
	cd ${TMP_FRP_SETUP_DIR}
	
	# 验证安装，随便取一个即可
    bin/frpc -v

	# 重新加载启动服务配置
    ln -sf `pwd`/systemd/frpc.service /usr/lib/systemd/system/frpc.service
    systemctl daemon-reload

	# 配置开机启动
    chkconfig frpc on
    chkconfig --list | grep frpc
    systemctl enable frpc.service
	
    # 当前启动命令，等待启动
    echo "Starting frp.client，Waiting for a moment"
    systemctl start frpc.service

	# 启动状态检测
    systemctl status frpc.service
    
    chkconfig frpc on

	# 授权iptables端口访问
	echo_soft_port ${TMP_FRP_SETUP_CLT_ADMIN_PORT}

    # 生成web授权访问脚本
    echo_web_service_init_scripts "frpc${LOCAL_ID}" "frpc${LOCAL_ID}-webui.${SYS_DOMAIN}" ${TMP_FRP_SETUP_CLT_ADMIN_PORT} "${LOCAL_HOST}"

	return $?
}

# 4-启动软件
function boot_frp()
{
	cd ${TMP_FRP_SETUP_DIR}
	
	case "${TMP_FRP_SETUP_CHOICE_BOOT_CONF}" in
		"Conf_Frps")
            boot_frps
		;;
		"Conf_Frpc")
            boot_frpc
		;;
		*)
            boot_frps
            boot_frpc
	esac
    
	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_frp()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_frp()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_frp()
{
	# 变量覆盖特性，其它方法均可读取
	local TMP_FRP_SETUP_DIR=${1}
	local TMP_FRP_CURRENT_DIR=`pwd`
    
	set_env_frp 

	setup_frp 

	conf_frp 

    # down_plugin_frp 
    # setup_plugin_frp 

	boot_frp 

	# reconf_frp 

	return $?
}

##########################################################################################################

# x1-下载软件
function down_frp()
{
	local TMP_FRP_SETUP_NEWER="0.37.0"
	set_github_soft_releases_newer_version "TMP_FRP_SETUP_NEWER" "fatedier/frp"
	exec_text_format "TMP_FRP_SETUP_NEWER" "https://github.com/fatedier/frp/releases/download/v%s/frp_%s_linux_amd64.tar.gz"
    setup_soft_wget "frp" "${TMP_FRP_SETUP_NEWER}" "exec_step_frp"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "Frp" "down_frp"
