#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 安装标题：Consul
# 软件名称：consul
# 软件大写名称：CONSUL
# 软件大写分组与简称：CSL
# 软件安装名称：consul
# 软件授权用户名称&组：consul/consul_group
#------------------------------------------------
local TMP_CSL_SETUP_CLUSTER_LEADER_ADDR="${LOCAL_HOST}"
local TMP_CSL_SETUP_CLUSTER_CHILDREN_ADDR="${LOCAL_HOST}"

# 1-配置环境
function set_environment()
{
    cd ${__DIR}

    soft_yum_check_action ""

	return $?
}

# 2-安装软件
function setup_consul()
{
	local TMP_CSL_SETUP_DIR=${1}
	local TMP_CSL_CURRENT_DIR=${2}

	## 直装模式
	cd `dirname ${TMP_CSL_CURRENT_DIR}`

	mv ${TMP_CSL_CURRENT_DIR} ${TMP_CSL_SETUP_DIR}

	# 创建日志软链
	local TMP_CSL_LNK_LOGS_DIR=${LOGS_DIR}/consul
	local TMP_CSL_LNK_DATA_DIR=${DATA_DIR}/consul
	local TMP_CSL_LOGS_DIR=${TMP_CSL_SETUP_DIR}/logs
	local TMP_CSL_DATA_DIR=${TMP_CSL_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_CSL_LOGS_DIR}
	rm -rf ${TMP_CSL_DATA_DIR}
	mkdir -pv ${TMP_CSL_LNK_LOGS_DIR}
	mkdir -pv ${TMP_CSL_LNK_DATA_DIR}
	
	ln -sf ${TMP_CSL_LNK_LOGS_DIR} ${TMP_CSL_LOGS_DIR}
	ln -sf ${TMP_CSL_LNK_DATA_DIR} ${TMP_CSL_DATA_DIR}

    cd ${TMP_CSL_SETUP_DIR}
    mkdir -pv bin

    mv consul bin/

	# 环境变量或软连接
	echo "CONSUL_HOME=${TMP_CSL_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$CONSUL_HOME/bin:$PATH' >> /etc/profile
	echo "export PATH CONSUL_HOME" >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

	return $?
}

# 3-设置软件
function conf_consul()
{
	local TMP_CSL_SETUP_DIR=${1}
	local TMP_CSL_DATA_DIR=${TMP_CSL_SETUP_DIR}/data

	cd ${TMP_CSL_SETUP_DIR}
    
	local TMP_CSL_LNK_ETC_DIR=${ATT_DIR}/consul
	local TMP_CSL_ETC_DIR=${TMP_CSL_SETUP_DIR}/etc
	rm -rf ${TMP_CSL_ETC_DIR}
	mkdir -pv ${TMP_CSL_LNK_ETC_DIR}
	ln -sf ${TMP_CSL_LNK_ETC_DIR} ${TMP_CSL_ETC_DIR}

    mkdir -pv ${TMP_CSL_ETC_DIR}/bootstrap
    mkdir -pv ${TMP_CSL_ETC_DIR}/server
    mkdir -pv ${TMP_CSL_ETC_DIR}/agent
    
    # 开始配置	    
    #-advertise：通知展现地址用来改变我们给集群中的其他节点展现的地址，一般情况下-bind地址就是展现地址
    #-bootstrap：用来控制一个server是否在bootstrap模式，在一个datacenter中只能有一个server处于bootstrap模式，当一个server处于bootstrap模式时，可以自己选举为raft leader。
    #-bootstrap-expect：在一个datacenter中期望提供的server节点数目，当该值提供的时候，consul一直等到达到指定sever数目的时候才会引导整个集群，该标记不能和bootstrap公用
    #-bind：该地址用来在集群内部的通讯，集群内的所有节点到地址都必须是可达的，默认是0.0.0.0
    #-client：consul绑定在哪个client地址上，这个地址提供HTTP、DNS、RPC等服务，默认是127.0.0.1
    #-config-file：明确的指定要加载哪个配置文件
    #-config-dir：配置文件目录，里面所有以.json结尾的文件都会被加载
    #-data-dir：提供一个目录用来存放agent的状态，所有的agent允许都需要该目录，该目录必须是稳定的，系统重启后都继续存在
    #-dc：该标记控制agent允许的datacenter的名称，默认是dc1
    #-encrypt：指定secret key，使consul在通讯时进行加密，key可以通过consul keygen生成，同一个集群中的节点必须使用相同的key
    #-join：加入一个已经启动的agent的ip地址，可以多次指定多个agent的地址。如果consul不能加入任何指定的地址中，则agent会启动失败，默认agent启动时不会加入任何节点。
    #-retry-join：和join类似，但是允许你在第一次失败后进行尝试。
    #-retry-interval：两次join之间的时间间隔，默认是30s
    #-retry-max：尝试重复join的次数，默认是0，也就是无限次尝试
    #-log-level：consul agent启动后显示的日志信息级别。默认是info，可选：trace、debug、info、warn、err。
    #-node：节点在集群中的名称，在一个集群中必须是唯一的，默认是该节点的主机名
    #-protocol：consul使用的协议版本
    #-rejoin：使consul忽略先前的离开，在再次启动后仍旧尝试加入集群中。
    #-server：定义agent运行在server模式，每个集群至少有一个server，建议每个集群的server不要超过5个
    #-syslog：开启系统日志功能，只在linux/osx上生效
    #-pid-file:提供一个路径来存放pid文件，可以使用该文件进行SIGINT/SIGHUP(关闭/更新)agent

    local TMP_CSL_SETUP_KEYGEN=`bin/consul keygen`
    input_if_empty "TMP_CSL_SETUP_KEYGEN" "Consul: Please Ender Cluster KeyGen Like '${TMP_CSL_SETUP_KEYGEN}'"
    echo "The Keygen Used：'${red}${TMP_CSL_SETUP_KEYGEN}${reset}', Please ${green}copy${reset} it use for other cluster host"
    echo 

    input_if_empty "TMP_CSL_SETUP_CLUSTER_LEADER_ADDR" "Consul.Cluster: Please ender cluster of ${green}leader host${reset}"

    exec_while_read "TMP_CSL_SETUP_CLUSTER_CHILDREN_ADDR" "Consul.Cluster: Please ender cluster child.\$I host like '${LOCAL_HOST}'" "%s" "
        echo \"Port of 8300 allowed for '\${CURRENT}'\"
        echo_soft_port 8300 \${CURRENT}
        echo \"Port of 8301 allowed for '\${CURRENT}'\"
        echo_soft_port 8301 \${CURRENT}
        echo \"Port of 8302 allowed for '\${CURRENT}'\"
        echo_soft_port 8302 \${CURRENT}
        echo \"Port of 8400 allowed for '\${CURRENT}'\"
        echo_soft_port 8400 \${CURRENT}
        echo \"Port of 8600 allowed for '\${CURRENT}'\"
        echo_soft_port 8600 \${CURRENT}
    "
    cat > ${TMP_CSL_ETC_DIR}/bootstrap/config.json <<EOF
{
	"ui" : true,
	"bootstrap": true,
	"server": true,
	"datacenter": "ost-svrs-ha",
    "node_name": "bootstrap-${LOCAL_ID}",
	"data_dir": "${TMP_CSL_DATA_DIR}",
	"advertise_addr": "${LOCAL_HOST}",
	"log_level": "INFO",
	"encrypt": "${TMP_CSL_SETUP_KEYGEN}",
	"addresses": {
        "http": "0.0.0.0"
    },
	"enable_syslog": true
}
EOF

    cat > ${TMP_CSL_ETC_DIR}/server/config.json <<EOF
{
	"ui" : true,
	"bootstrap": false,
	"server": true,
	"datacenter": "ost-svrs-ha",
    "node_name": "server-${LOCAL_ID}",
	"data_dir": "${TMP_CSL_DATA_DIR}",
	"advertise_addr": "${LOCAL_HOST}",
	"log_level": "INFO",
	"encrypt": "${TMP_CSL_SETUP_KEYGEN}",
	"addresses": {
        "http": "0.0.0.0"
    },
	"enable_syslog": true,
	"start_join": ["$TMP_CSL_SETUP_CLUSTER_CHILDREN_ADDR"]
}
EOF

    cat > ${TMP_CSL_ETC_DIR}/agent/config.json <<EOF
{
	"ui" : true,
	"server": false,
	"datacenter": "ost-svrs-ha",
    "node_name": "agent-${LOCAL_ID}",
	"data_dir": "${TMP_CSL_DATA_DIR}",
	"advertise_addr": "${LOCAL_HOST}",
	"log_level": "INFO",
	"encrypt": "${TMP_CSL_SETUP_KEYGEN}",
	"addresses": {
        "http": "0.0.0.0"
    },
	"enable_syslog": true,
	"start_join": ["${TMP_CSL_SETUP_CLUSTER_LEADER_ADDR}"]
}
EOF

	return $?
}

# 4-启动软件
function boot_consul()
{
	local TMP_CSL_SETUP_DIR=${1}

	cd ${TMP_CSL_SETUP_DIR}
	
	# 验证安装
    consul -v

    # 当前启动命令,判断如果是主节点
    if [ "${TMP_CSL_SETUP_CLUSTER_LEADER_ADDR}" = "${LOCAL_HOST}" ]; then
        echo "Consul：Exec bootstrap mode"
        start_bootstrap
    else
        local TMP_CSL_SETUP_BOOT_MODE=1
        exec_if_choice "TMP_CSL_SETUP_BOOT_MODE" "Consul: Please sure this server mode" "server,agent" "" "start_"
    fi

    # 验证启动
    lsof -i:8500

    # 添加端口许可
    echo_soft_port 8500

	return $?
}

function start_bootstrap()
{
	local TMP_CSL_SETUP_DIR=`pwd`
	local TMP_CSL_ETC_DIR=${TMP_CSL_SETUP_DIR}/etc

    local TMP_CSL_SETUP_CLUSTER_CHILDREN_ADDR_COUNT=`echo ${TMP_CSL_SETUP_CLUSTER_CHILDREN_ADDR} | grep -o "," | wc -l`
    nohup consul agent -config-dir ${TMP_CSL_ETC_DIR}/bootstrap -bootstrap-expect=${TMP_CSL_SETUP_CLUSTER_CHILDREN_ADDR_COUNT} > logs/boot.log 2>&1 &

	# 添加系统启动命令
    echo_startup_config "consul" "${TMP_CSL_SETUP_DIR}" "bin/consul agent -config-dir ${TMP_CSL_ETC_DIR}/bootstrap -bootstrap-expect=${TMP_CSL_SETUP_CLUSTER_CHILDREN_ADDR_COUNT}" "" "1"

    return $?
}

function start_server()
{
	local TMP_CSL_SETUP_DIR=`pwd`
	local TMP_CSL_ETC_DIR=${TMP_CSL_SETUP_DIR}/etc
    
    nohup consul agent -config-dir ${TMP_CSL_ETC_DIR}/server > logs/boot.log 2>&1 &

	# 添加系统启动命令
    echo_startup_config "consul" "${TMP_CSL_SETUP_DIR}" "bin/consul agent -config-dir ${TMP_CSL_ETC_DIR}/server" "" "1"

    return $?
}

function start_agent()
{
	local TMP_CSL_SETUP_DIR=`pwd`
	local TMP_CSL_ETC_DIR=${TMP_CSL_SETUP_DIR}/etc
    
    nohup consul agent -config-dir ${TMP_CSL_ETC_DIR}/agent > logs/boot.log 2>&1 &

	# 添加系统启动命令
    echo_startup_config "consul" "${TMP_CSL_SETUP_DIR}" "bin/consul agent -config-dir ${TMP_CSL_ETC_DIR}/agent" "" "1"
    
    return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_consul()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_consul()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_consul()
{
	local TMP_CSL_SETUP_DIR=${1}
	local TMP_CSL_CURRENT_DIR=`pwd`
    
	set_environment "${TMP_CSL_SETUP_DIR}"

	setup_consul "${TMP_CSL_SETUP_DIR}" "${TMP_CSL_CURRENT_DIR}"

	conf_consul "${TMP_CSL_SETUP_DIR}"

    # down_plugin_consul "${TMP_CSL_SETUP_DIR}"

	boot_consul "${TMP_CSL_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_consul()
{
    # https://www.consul.io/downloads
	local TMP_CSL_SETUP_NEWER="consul_1.10.0"
	local TMP_CSL_DOWN_URL_BASE="https://releases.hashicorp.com/consul/"
	set_url_list_newer_href_link_filename "TMP_CSL_SETUP_NEWER" "${TMP_CSL_DOWN_URL_BASE}" "consul_()"
    
	local TMP_CSL_SETUP_NEWER_FOLDER=`echo "${TMP_CSL_SETUP_NEWER}" | sed "s@consul_@@g"`
	exec_text_format "TMP_CSL_SETUP_NEWER" "${TMP_CSL_DOWN_URL_BASE}${TMP_CSL_SETUP_NEWER_FOLDER}/%s_linux_amd64.zip"
    setup_soft_wget "consul" "${TMP_CSL_SETUP_NEWER}" "exec_step_consul"
    
	return $?
}

#安装主体
setup_soft_basic "Consul" "down_consul"
