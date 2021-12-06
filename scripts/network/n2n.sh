#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 相关参考：
#		  windows客户端：https://bugxia.com/357.html
#         部署及配合OPENWRT组网：https://www.meirenji.info/2018/02/03/N2N%E7%BB%84%E7%BD%91-%E5%AE%9E%E7%8E%B0%E5%AE%B6%E9%87%8C%E8%AE%BF%E4%B8%8E%E5%85%AC%E5%8F%B8%E7%BD%91%E7%BB%9C%E4%BA%92%E8%AE%BF-%E7%B2%BE%E7%BC%96%E7%89%88/
#
#------------------------------------------------
local TMP_N2N_SETUP_UDP_MAIN_PORT=17654
local TMP_N2N_SETUP_UDP_MGMT_PORT=15645
local TMP_N2N_SETUP_CHOICE_CONF="supernode"

local TMP_N2N_SETUP_EDGE_LOCAL_PART1=`echo ${LOCAL_HOST} | awk -F'.' '{print $1}'`
local TMP_N2N_SETUP_EDGE_LOCAL_PART2=`echo ${LOCAL_HOST} | awk -F'.' '{print $2}'`
local TMP_N2N_SETUP_EDGE_LOCAL_PART3=`echo ${LOCAL_HOST} | awk -F'.' '{print $3}'`
local TMP_N2N_SETUP_EDGE_LOCAL_PART4=`echo ${LOCAL_HOST} | awk -F'.' '{print $4}'`
local TMP_N2N_SETUP_EDGE_INTERFACE_HOST=`echo ${LOCAL_HOST} | sed "s@^${TMP_N2N_SETUP_EDGE_LOCAL_PART1}\.${TMP_N2N_SETUP_EDGE_LOCAL_PART2}@${TMP_N2N_SETUP_EDGE_LOCAL_PART1}.0@g" | sed "s@${TMP_N2N_SETUP_EDGE_LOCAL_PART3}\.${TMP_N2N_SETUP_EDGE_LOCAL_PART4}\\\$@${TMP_N2N_SETUP_EDGE_LOCAL_PART3}.${TMP_N2N_SETUP_EDGE_LOCAL_PART2}@g"`
local TMP_N2N_SETUP_EDGE_INTERFACE_MTU=1460

##########################################################################################################

# 1-配置环境
function set_env_n2n()
{
    cd ${__DIR}

    # soft_yum_check_setup ""

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_n2n()
{
	cd ${TMP_N2N_CURRENT_DIR}

	# 编译模式    
    bash autogen.sh
    bash configure

	make -j4 && make -j4 install

    # 安装不产生目录，所以手动创建
    local TMP_N2N_SETUP_BIN_DIR=${TMP_N2N_SETUP_DIR}/bin
    mkdir -pv ${TMP_N2N_SETUP_BIN_DIR}
    mv supernode ${TMP_N2N_SETUP_BIN_DIR}
    mv edge ${TMP_N2N_SETUP_BIN_DIR}

	cd ${TMP_N2N_SETUP_DIR}

	# 创建日志软链
	local TMP_N2N_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/n2n
	local TMP_N2N_SETUP_LOGS_DIR=${TMP_N2N_SETUP_DIR}/logs

	# 先清理文件，再创建文件
	rm -rf ${TMP_N2N_SETUP_LOGS_DIR}
	mkdir -pv ${TMP_N2N_SETUP_LNK_LOGS_DIR}

	ln -sf ${TMP_N2N_SETUP_LNK_LOGS_DIR} ${TMP_N2N_SETUP_LOGS_DIR}
	
	# 环境变量或软连接
	echo "N2N_HOME=${TMP_N2N_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$N2N_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH N2N_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

	# 授权权限，否则无法写入
	# create_user_if_not_exists n2n n2n
	# chown -R n2n:n2n ${TMP_N2N_SETUP_LNK_LOGS_DIR}
	# chown -R n2n:n2n ${TMP_N2N_SETUP_LNK_DATA_DIR}

	# 移除源文件
	rm -rf ${TMP_N2N_CURRENT_DIR}
	
    # 安装初始

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_n2n()
{
	cd ${TMP_N2N_SETUP_DIR}
	
	local TMP_N2N_SETUP_LNK_ETC_DIR=${ATT_DIR}/n2n
	local TMP_N2N_SETUP_ETC_DIR=${TMP_N2N_SETUP_DIR}/etc

	# ①-N：不存在配置文件：
	rm -rf ${TMP_N2N_SETUP_ETC_DIR}
	mkdir -pv ${TMP_N2N_SETUP_LNK_ETC_DIR}
	
	# 替换原路径链接（存在etc下时，不能作为软连接存在）
    ln -sf ${TMP_N2N_SETUP_LNK_ETC_DIR} ${TMP_N2N_SETUP_ETC_DIR} 

	# 授权权限，否则无法写入
	# chown -R n2n:n2n ${TMP_N2N_SETUP_LNK_ETC_DIR}

	# 开始配置
    set_if_choice "TMP_N2N_SETUP_CHOICE_CONF" "Please choice which n2n conf you want to use" "Conf_Supernode,Conf_Edge,Conf_All" "${TMP_SPLITER}"

    ${TMP_N2N_SETUP_CHOICE_CONF}

	return $?
}

function conf_supernode()
{
	cd ${TMP_N2N_SETUP_DIR}

	# 开始配置
	# general usage: supernode <config file> (see supernode.conf)
 
    #              	 or supernode [-p <local port>]
    #                             [-F <federation name>]
	# options for under-          [-l <supernode host:port>]
	# lying connection            [-M] [-V <version text>]

	# overlay network             [-c <community list file>]
	# configuration               [-a <net ip>-<net ip>/<cidr suffix>]

	# local options               [-f] [-t <management port>]
	# 						      [--management-password <pw>] [-v]
	# 						      [-u <numerical user id>][-g <numerical group id>]

	# meaning of the              [-M] disable MAC and IP address spoofing protection
	# flag options                [-f] do not fork but run in foreground
	# 						      [-v] make more verbose, repeat as required
    local TMP_N2N_SETUP_SUPERNODE_BOOT_COMMAND_PARAMS="-p ${TMP_N2N_SETUP_UDP_MAIN_PORT} -t ${TMP_N2N_SETUP_UDP_MGMT_PORT}"
    echo "${TMP_N2N_SETUP_SUPERNODE_BOOT_COMMAND_PARAMS}" > etc/supernode-default.conf
    echo
    echo "N2N.Supernode: Your n2n supernode boot command is '${green}supernode ${TMP_N2N_SETUP_SUPERNODE_BOOT_COMMAND_PARAMS}${reset}'"
    echo

	return $?
}

function conf_edge()
{
	cd ${TMP_N2N_SETUP_DIR}
	    
    local TMP_N2N_SETUP_EDGE_SUPERNODE_HOST="${LOCAL_HOST}"
    input_if_empty "TMP_N2N_SETUP_EDGE_SUPERNODE_HOST" "N2N.Edge: Please sure your ${red}supernode host${reset} for edge"
    set_if_equals "TMP_N2N_SETUP_EDGE_SUPERNODE_HOST" "LOCAL_HOST" "127.0.0.1"

    local TMP_N2N_SETUP_EDGE_SUPERNODE_PORT="${TMP_N2N_SETUP_UDP_MAIN_PORT}"
    input_if_empty "TMP_N2N_SETUP_EDGE_SUPERNODE_PORT" "N2N.Edge: Please sure your ${red}supernode host port${reset} of '${TMP_N2N_SETUP_EDGE_SUPERNODE_HOST}' for edge"

    # lower 3.0：edge -u 0 -g 0 -d n2n-c2 -a static:172.2.8.18 -s 255.255.255.0 -c cuckoo_tl -k 'qaz@321!@#' -l 1.1.1.1:12350 -r &
	# upper 3.0：edge -u 0 -g 0 -d n2n-c2 -a 172.2.8.100 -c cuckoo_hk -k 'qaz@3321!@#' -f -t 15645 -r -l 1.1.1.1:17654
	input_if_empty "TMP_N2N_SETUP_EDGE_INTERFACE_HOST" "N2N.Edge: Please sure your ${red}static internal vpn host${reset} for edge"
	
	input_if_empty "TMP_N2N_SETUP_EDGE_INTERFACE_MTU" "N2N.Edge: Please sure your ${red}MTU value${reset} for edge"

    # local TMP_N2N_SETUP_EDGE_INTERFACE_NETMASK="255.255.255.0"
    # input_if_empty "TMP_N2N_SETUP_EDGE_INTERFACE_NETMASK" "N2N.Edge: Please sure your ${red}internal vpn host netmask${reset} of '${TMP_N2N_SETUP_EDGE_INTERFACE_HOST}' for edge"
    
    local TMP_N2N_SETUP_EDGE_NET_GROUP_COMPONY="vsofo"
    input_if_empty "TMP_N2N_SETUP_EDGE_NET_GROUP_COMPONY" "N2N.Edge: Please sure your ${red}company${reset} for edge"
    local TMP_N2N_SETUP_EDGE_NET_GROUP_AREA="hk"
    input_if_empty "TMP_N2N_SETUP_EDGE_NET_GROUP_AREA" "N2N.Edge: Please sure your ${red}area${reset} of company '${TMP_N2N_SETUP_EDGE_NET_GROUP_COMPONY}' for edge"

    local TMP_N2N_SETUP_EDGE_NET_GROUP="${TMP_N2N_SETUP_EDGE_NET_GROUP_COMPONY}_${TMP_N2N_SETUP_EDGE_NET_GROUP_AREA}"
    local TMP_N2N_SETUP_EDGE_NET_PWD="n2n-${TMP_N2N_SETUP_EDGE_NET_GROUP}%NT^m${LOCAL_ID}~"
    # ???复杂的会被转义，待研究
    # local TMP_N2N_SETUP_EDGE_NET_PWD="qaz%${LOCAL_ID}!@#"
    input_if_empty "TMP_N2N_SETUP_EDGE_NET_PWD" "N2N.Edge: Please sure your ${red}network group password${reset} of group '${TMP_N2N_SETUP_EDGE_NET_GROUP}' for edge"

	# 开始配置
	# general usage: edge <config file> (see edge.conf)
 
    #             or edge                  -c <community name> -l <supernode host:port>
    #                                      [-p [<local bind ip address>:]<local port>]
	# 					                   [-T <type of service>] [-D]
	# options for under-                   [-i <registration interval>] [-L <registration ttl>]
	# lying connection                     [-k <key>] [-A<cipher>] [-H] [-z<compression>]
	# 					                   [-e <preferred local IP address>] [-S<level of solitude>]
	# 					                   [--select-rtt]
	
	# tap device and                       [-a [static:|dhcp:]<tap IP address>[/<cidr suffix>]]
	# overlay network                      [-m <tap MAC address>] [-d <tap device name>]
	# configuration                        [-M <tap MTU>] [-r] [-E] [-I <edge description>]
	# 					                   [-J <password>] [-P <public key>] [-R <rule string>]
	
	# local options                        [-f] [-t <management port>] [--management-password <pw>]
	# 					                   [-v] [-n <cidr:gateway>]
	# 					                   [-u <numerical user id>] [-g <numerical group id>]
	
	# environment N2N_KEY instead of 	   [-k <key>]
	# variables   N2N_COMMUNITY instead of -c <community>
	# 			  N2N_PASSWORD instead of  [-J <password>]
	
	# meaning of the                       [-D] enable PMTU discovery
	# flag options                         [-H] enable header encryption
	# 					                   [-r] enable packet forwarding through n2n community
	# 					                   [-E] accept multicast MAC addresses
	# 									   [--select-rtt] select supernode by round trip time
	# 									   [-f] do not fork but run in foreground
	# 									   [-v] make more verbose, repeat as required
	
	# -h shows this quick reference including all available options
	# --help gives a detailed parameter description
	# man files for n2n, edge, and superndode contain in-depth information
	# -s ${TMP_N2N_SETUP_EDGE_INTERFACE_NETMASK}
	local TMP_N2N_SETUP_EDGE_BOOT_COMMAND_PARAMS="-u 0 -g 0 -d n2n_edge_${TMP_N2N_SETUP_EDGE_NET_GROUP_AREA} -a ${TMP_N2N_SETUP_EDGE_INTERFACE_HOST} -M ${TMP_N2N_SETUP_EDGE_INTERFACE_MTU} -c ${TMP_N2N_SETUP_EDGE_NET_GROUP} -k '${TMP_N2N_SETUP_EDGE_NET_PWD}' -f -t ${TMP_N2N_SETUP_UDP_MGMT_PORT} -r -D -E -l ${TMP_N2N_SETUP_EDGE_SUPERNODE_HOST}:${TMP_N2N_SETUP_EDGE_SUPERNODE_PORT}"
    echo
    echo "N2N.Edge: Your n2n edge boot command is '${green}edge ${TMP_N2N_SETUP_EDGE_BOOT_COMMAND_PARAMS}${reset}'"
    echo

    echo "${TMP_N2N_SETUP_EDGE_BOOT_COMMAND_PARAMS}" > etc/edge-default.conf

	return $?
}

function conf_all()
{
    conf_supernode

    conf_edge
    
	return $?
}

##########################################################################################################
    
# 4-启动软件
function boot_n2n()
{
	cd ${TMP_N2N_SETUP_DIR}

	case ${TMP_N2N_SETUP_CHOICE_CONF} in
		"Conf_Supernode")
            boot_supernode
		;;
		"Conf_Edge")
            boot_edge
		;;
		*)
            boot_supernode
            echo
            boot_edge
	esac

	return $?
}

function boot_supernode()
{
	cd ${TMP_N2N_SETUP_DIR}
	
	# 当前启动命令
    tee boot_supernode.sh <<-EOF
#!/bin/sh
#-------------------------------
#  Project Boot Script - for n2n
#-------------------------------
cat etc/supernode-default.conf | xargs -I {} bash -c "bin/supernode {}"
ps -ef | grep supernode
echo "Boot over"
EOF
	chmod +x boot_supernode.sh
	nohup bash boot_supernode.sh > logs/boot_supernode.log 2>&1 &
		
    # 等待启动
    echo "Starting n2n.supernode，Waiting for a moment"
    echo "--------------------------------------------"
    sleep 5

    cat logs/boot_supernode.log
    echo "--------------------------------------------"

	# 启动状态检测
	lsof -i:${TMP_N2N_SETUP_UDP_MAIN_PORT}
    lsof -i:${TMP_N2N_SETUP_UDP_MGMT_PORT}

	# 添加系统启动命令
    echo_startup_config "n2n_supernode_default" "${TMP_N2N_SETUP_DIR}" "bash boot_supernode.sh" "" "1"

	# 授权iptables端口访问
	echo_soft_port ${TMP_N2N_SETUP_UDP_MAIN_PORT} "" "udp"
    echo_soft_port ${TMP_N2N_SETUP_UDP_MGMT_PORT} "" "udp"

	return $?
}

function boot_edge()
{
	cd ${TMP_N2N_SETUP_DIR}

	# 当前启动命令
    tee boot_edge.sh <<-EOF
#!/bin/sh
#-------------------------------
#  Project Boot Script - for n2n
#-------------------------------
cat etc/edge-default.conf | xargs -I {} bash -c "bin/edge {}"
EOF
	chmod +x boot_edge.sh
	nohup bash boot_edge.sh > logs/boot_edge.log 2>&1 &
	
    # 等待启动
    echo "Starting n2n.edge，Waiting for a moment"
    echo "--------------------------------------------"
    sleep 5

    cat logs/boot_edge.log
    echo "--------------------------------------------"

	# 启动状态检测
	ip addr | grep "${TMP_N2N_SETUP_EDGE_INTERFACE_HOST}"

	# 添加系统启动命令
    echo_startup_config "n2n_edge_default" "${TMP_N2N_SETUP_DIR}" "bash boot_edge.sh" "" "99"

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_n2n()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_n2n()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_n2n()
{
	# 变量覆盖特性，其它方法均可读取
	local TMP_N2N_SETUP_DIR=${1}
	local TMP_N2N_CURRENT_DIR=`pwd`
    
	set_env_n2n 

	setup_n2n 

	conf_n2n 

    # down_plugin_n2n 
    # setup_plugin_n2n 

	boot_n2n 

	# reconf_n2n 

	return $?
}

##########################################################################################################

# x1-下载软件
function down_n2n()
{
	local TMP_N2N_SETUP_NEWER="3.0"
	set_github_soft_releases_newer_version "TMP_N2N_SETUP_NEWER" "ntop/n2n"
	exec_text_format "TMP_N2N_SETUP_NEWER" "https://github.com/ntop/n2n/archive/%s.zip"
    setup_soft_wget "n2n" "${TMP_N2N_SETUP_NEWER}" "exec_step_n2n"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "N2N" "down_n2n"
