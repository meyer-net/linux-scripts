#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 安装标题：Kafka
# 相关命令：
# bash bin/kafka-topics.sh --create --zookeeper 192.168.1.100:12233,192.168.1.109:12233,192.168.1.110:12233 --replication-factor 2 --partitions 100 --topic test
# bash bin/kafka-topics.sh  --describe  --zookeeper  192.168.1.185:12233 –-topic test
# bash bin/kafka-console-producer.sh --broker-list 192.168.1.100:19092,192.168.1.109:19092,192.168.1.110:19092 --topic test
# bash bin/kafka-console-consumer.sh --bootstrap-server 192.168.1.100:19092,192.168.1.109:19092,192.168.1.110:19092 --topic test --from-beginning
#------------------------------------------------
local TMP_KFK_SETUP_ZK_PORT=12181
local TMP_KFK_SETUP_LISTENERS_PORT=19092
local TMP_KFK_SETUP_ZK_ADMIN_SERVER_PORT=18080
local TMP_KFK_SETUP_JMX_PORT=10000

local TMP_KFK_EGL_SETUP_WEBUI_PORT=18048
local TMP_KFK_EGL_SETUP_SERVER_PORT=18065
local TMP_KFK_EGL_SETUP_CONNECTOR_PORT=18069
local TMP_KFK_EGL_SETUP_MYSQL_PORT=13306

##########################################################################################################

# 1-配置环境
function set_env_kafka()
{
    cd ${__DIR}
	
    local TMP_IS_KFK_ZK_LOCAL=`lsof -i:${TMP_KFK_SETUP_ZK_PORT}`
    if [ -z "${TMP_IS_KFK_ZK_LOCAL}" ]; then 
    	exec_yn_action "setup_zookeeper" "Kafka: Please sure if u want to get ${green}zookeeper local${reset}?"
	fi

	return $?
}

function set_env_kafka_eagle()
{
    cd ${__DIR}

    source scripts/lang/java.sh
	
    local TMP_IS_KFK_EGL_MYSQL_LOCAL=`lsof -i:${TMP_KFK_EGL_SETUP_MYSQL_PORT}`
    if [ -z "${TMP_IS_KFK_EGL_MYSQL_LOCAL}" ]; then 
    	exec_yn_action "setup_mysql" "KafkaEagle: Please sure if u want to get ${green}mysql local${reset}?"
	fi

	return $?
}

##########################################################################################################

function setup_zookeeper()
{   
    source scripts/ha/zookeeper.sh

    return $?
}

function setup_mysql()
{   
    source scripts/database/mysql.sh

    return $?
}

# 2-安装软件
function setup_kafka()
{
	local TMP_KFK_SETUP_DIR=${1}
	local TMP_KFK_CURRENT_DIR=${2}

	## 直装模式
	cd `dirname ${TMP_KFK_CURRENT_DIR}`

	mv ${TMP_KFK_CURRENT_DIR} ${TMP_KFK_SETUP_DIR}

	# 创建日志软链
	local TMP_KFK_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/zookeeper/kafka
	local TMP_KFK_SETUP_LNK_DATA_DIR=${DATA_DIR}/zookeeper/kafka
	local TMP_KFK_SETUP_LOGS_DIR=${TMP_KFK_SETUP_DIR}/logs
	local TMP_KFK_SETUP_DATA_DIR=${TMP_KFK_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_KFK_SETUP_LOGS_DIR}
	rm -rf ${TMP_KFK_SETUP_DATA_DIR}
	mkdir -pv ${TMP_KFK_SETUP_LNK_LOGS_DIR}
	mkdir -pv ${TMP_KFK_SETUP_LNK_DATA_DIR}

	ln -sf ${TMP_KFK_SETUP_LNK_LOGS_DIR} ${TMP_KFK_SETUP_LOGS_DIR}
	ln -sf ${TMP_KFK_SETUP_LNK_DATA_DIR} ${TMP_KFK_SETUP_DATA_DIR}

	# 环境变量或软连接
	echo "KAFKA_HOME=${TMP_KFK_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$KAFKA_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH KAFKA_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

	return $?
}

function setup_kafka_eagle()
{
	local TMP_KFK_EGL_SETUP_DIR=${1}
	local TMP_KFK_EGL_CURRENT_DIR=${2}

	## 直装模式
	cd `dirname ${TMP_KFK_EGL_CURRENT_DIR}`

	mv ${TMP_KFK_EGL_CURRENT_DIR} ${TMP_KFK_EGL_SETUP_DIR}

	cd ${TMP_KFK_EGL_SETUP_DIR}

	# 创建日志软链
	local TMP_KFK_EGL_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/kafka_eagle
	local TMP_KFK_EGL_SETUP_LNK_DATA_DIR=${DATA_DIR}/kafka_eagle
	local TMP_KFK_EGL_SETUP_LOGS_DIR=${TMP_KFK_EGL_SETUP_DIR}/logs
	local TMP_KFK_EGL_SETUP_DATA_DIR=${TMP_KFK_EGL_SETUP_DIR}/db

	# 先清理文件，再创建文件
	mv ${TMP_KFK_EGL_SETUP_LOGS_DIR} ${TMP_KFK_EGL_SETUP_LNK_LOGS_DIR}
	mv ${TMP_KFK_EGL_SETUP_DATA_DIR} ${TMP_KFK_EGL_SETUP_LNK_DATA_DIR}
	
	ln -sf ${TMP_KFK_EGL_SETUP_LNK_LOGS_DIR} ${TMP_KFK_EGL_SETUP_LOGS_DIR}
	ln -sf ${TMP_KFK_EGL_SETUP_LNK_DATA_DIR} ${TMP_KFK_EGL_SETUP_DATA_DIR}

	# 环境变量或软连接
	echo "KE_HOME=${TMP_KFK_EGL_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$KE_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH KE_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_kafka()
{
	local TMP_KFK_SETUP_DIR=${1}

	cd ${TMP_KFK_SETUP_DIR}
	
	local TMP_KFK_SETUP_LNK_ETC_DIR=${ATT_DIR}/kafka
	local TMP_KFK_SETUP_ETC_DIR=${TMP_KFK_SETUP_DIR}/config

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mv ${TMP_KFK_SETUP_ETC_DIR} ${TMP_KFK_SETUP_LNK_ETC_DIR}

	# 替换原路径链接
	ln -sf ${TMP_KFK_SETUP_LNK_ETC_DIR} ${TMP_KFK_SETUP_ETC_DIR}
    ln -sf ${TMP_KFK_SETUP_LNK_ETC_DIR} /etc/kafka

	# 开始配置
	# - zookeeper 部分
	local TMP_KFK_SETUP_LOGS_DIR=${TMP_KFK_SETUP_DIR}/logs
	local TMP_KFK_SETUP_DATA_DIR=${TMP_KFK_SETUP_DIR}/data
    sed -i "s@^dataDir=.*@dataDir=${TMP_KFK_SETUP_DATA_DIR}@g" config/zookeeper.properties
    sed -i "s@^clientPort=.*@clientPort=${TMP_KFK_SETUP_ZK_PORT}@g" config/zookeeper.properties
    sed -i "s@^admin.enableServer=.*@admin.enableServer=true@g" config/zookeeper.properties
    sed -i "s@^# admin.serverPort=.*@admin.serverPort=${TMP_KFK_SETUP_ZK_ADMIN_SERVER_PORT}@g" config/zookeeper.properties

	# - socket server 部分
    local TMP_KFK_SETUP_BROKER="${LOCAL_ID}"
    input_if_empty "TMP_KFK_SETUP_BROKER" "Kafka: Please ender broker.id"
    sed -i "s@^broker.id=.*@broker.id=${TMP_KFK_SETUP_BROKER}@g" config/server.properties

    sed -i "s@^#listeners=.*@listeners=PLAINTEXT://:${TMP_KFK_SETUP_LISTENERS_PORT}@g" config/server.properties

	local TMP_KFK_SETUP_HOST="${LOCAL_HOST}"
    input_if_empty "TMP_KFK_SETUP_HOST" "Kafka: Please ender ${green}listener internal host address${reset}(${red}who can visit or '0.0.0.0'${reset})"
    if [ -n "${TMP_KFK_SETUP_HOST}" ]; then
        sed -i "s@^#advertised.listeners=.*@advertised.listeners=PLAINTEXT://${TMP_KFK_SETUP_HOST}:${TMP_KFK_SETUP_LISTENERS_PORT}@g" config/server.properties
    fi
    
	# socket的发送缓冲区，socket的调优参数SO_SNDBUFF
	sed -i "s@^socket.send.buffer.bytes=.*@socket.send.buffer.bytes=409600@g" config/server.properties

	# socket的接受缓冲区，socket的调优参数SO_RCVBUFF
    sed -i "s@^socket.receive.buffer.bytes=.*@socket.receive.buffer.bytes=409600@g" config/server.properties

	# socket请求的最大数值，防止serverOOM，message.max.bytes必然要小于socket.request.max.bytes，会被topic创建时的指定参数覆盖
    sed -i "s@^socket.request.max.bytes=.*@socket.request.max.bytes=419430400@g" config/server.properties

    sed -i "s@^log.dirs=.*@log.dirs=${TMP_KFK_SETUP_LOGS_DIR}@g" config/server.properties

    local TMP_KFK_SETUP_ZK_HOSTS="${LOCAL_HOST}"
    exec_while_read "TMP_KFK_SETUP_ZK_HOSTS" "Kafka.Zookeeper: Please ender zookeeper cluster address like '${green}${LOCAL_HOST}${reset}'" "%s:${TMP_KFK_SETUP_ZK_PORT}" "
        if [ \"\$CURRENT\" == \"\${LOCAL_HOST}\" ]; then
            echo_soft_port ${TMP_KFK_SETUP_LISTENERS_PORT} \"\$CURRENT\"
        else
            echo \"Please allow the port of '\${red}${TMP_KFK_SETUP_LISTENERS_PORT}\${reset}' for '\${red}\${LOCAL_HOST}\${reset}' from the zookeeper host '\$CURRENT'\"
        fi
    "

    sed -i "s@^zookeeper.connect=.*@zookeeper.connect=${TMP_KFK_SETUP_ZK_HOSTS}@g" config/server.properties

    sed -i "/export KAFKA_HEAP_OPTS=/a export JMX_PORT=\"${TMP_KFK_SETUP_JMX_PORT}\"" bin/kafka-server-start.sh

    echo "${TMP_KFK_SETUP_HOST} ${SYS_NAME}" >> /etc/hosts 

	return $?
}

function conf_kafka_eagle()
{
	local TMP_KFK_EGL_SETUP_DIR=${1}

	cd ${TMP_KFK_EGL_SETUP_DIR}
	
	local TMP_KFK_EGL_SETUP_LNK_ETC_DIR=${ATT_DIR}/kafka_eagle
	local TMP_KFK_EGL_SETUP_LNK_ETC_WEB_DIR=${TMP_KFK_EGL_SETUP_LNK_ETC_DIR}/web
	local TMP_KFK_EGL_SETUP_LNK_ETC_KMS_DIR=${TMP_KFK_EGL_SETUP_LNK_ETC_DIR}/kms
	local TMP_KFK_EGL_SETUP_ETC_WEB_DIR=${TMP_KFK_EGL_SETUP_DIR}/conf
	local TMP_KFK_EGL_SETUP_ETC_KMS_DIR=${TMP_KFK_EGL_SETUP_DIR}/kms/conf

	# ①-Y：存在配置文件：原路径文件放给真实路径
	path_not_exits_create "${TMP_KFK_EGL_SETUP_LNK_ETC_DIR}"
	mv ${TMP_KFK_EGL_SETUP_ETC_WEB_DIR} ${TMP_KFK_EGL_SETUP_LNK_ETC_WEB_DIR}
	mv ${TMP_KFK_EGL_SETUP_ETC_KMS_DIR} ${TMP_KFK_EGL_SETUP_LNK_ETC_KMS_DIR}

	# 替换原路径链接
	ln -sf ${TMP_KFK_EGL_SETUP_LNK_ETC_WEB_DIR} ${TMP_KFK_EGL_SETUP_ETC_WEB_DIR}
	ln -sf ${TMP_KFK_EGL_SETUP_LNK_ETC_KMS_DIR} ${TMP_KFK_EGL_SETUP_ETC_KMS_DIR}

	# 开始配置
    local TMP_KFK_SETUP_ZK_HOSTS="${LOCAL_HOST}"
    exec_while_read "TMP_KFK_SETUP_ZK_HOSTS" "KafkaEagle.Zookeeper: Please ender zookeeper cluster address like '${LOCAL_HOST}'，The client connection address of the zookeeper cluster is set here" "%s:${TMP_KFK_SETUP_ZK_PORT}"

    sed -i "s@^kafka.eagle.zk.cluster.alias=cluster.*@kafka.eagle.zk.cluster.alias=cluster1@g" conf/system-config.properties
    sed -i "s@^cluster1.zk.list=.*@cluster1.zk.list=${TMP_KFK_SETUP_ZK_HOSTS}@g" conf/system-config.properties
    sed -i "s@^cluster2@#cluster2@g" conf/system-config.properties
    sed -i "s@^cluster3@#cluster3@g" conf/system-config.properties
    sed -i "s@^kafka.eagle.webui.port=.*@^kafka.eagle.webui.port=${TMP_KFK_EGL_SETUP_WEBUI_PORT}@g" conf/system-config.properties
	
    sed -i "s@port=\"8065\"@port=\"${TMP_KFK_EGL_SETUP_SERVER_PORT}\"@g" kms/conf/server.xml
    sed -i "s@port=\"8069\"@port=\"${TMP_KFK_EGL_SETUP_CONNECTOR_PORT}\"@g" kms/conf/server.xml

    local TMP_KFK_SETUP_EAGLE_JMX_UNAME="server"
    local TMP_KFK_SETUP_EAGLE_JMX_PWD="ke\@SVR!m${LOCAL_ID}_"

	input_if_empty "TMP_KFK_SETUP_EAGLE_JMX_UNAME" "KafkaEagle.Jmx: Please ender ${red}jmx user name${reset}"
	input_if_empty "TMP_KFK_SETUP_EAGLE_JMX_PWD" "KafkaEagle.Jmx: Please ender ${red}jmx password${reset}"

    sed -i "s@^cluster1.kafka.eagle.jmx.user=.*@cluster1.kafka.eagle.jmx.user=${TMP_KFK_SETUP_EAGLE_JMX_UNAME}@g" conf/system-config.properties
    sed -i "s@^cluster1.kafka.eagle.jmx.password=.*@cluster1.kafka.eagle.jmx.password=${TMP_KFK_SETUP_EAGLE_JMX_PWD}@g" conf/system-config.properties
    sed -i "s@^cluster1.kafka.eagle.jmx.truststore.password=.*@cluster1.kafka.eagle.jmx.truststore.password=${TMP_KFK_SETUP_EAGLE_JMX_PWD}tst@g" conf/system-config.properties
    
    local TMP_KFK_SETUP_EAGLE_DBADDRESS="127.0.0.1"
    local TMP_KFK_SETUP_EAGLE_DBPORT="3306"
    local TMP_KFK_SETUP_EAGLE_DBUNAME="root"
    local TMP_KFK_SETUP_EAGLE_DBPWD="mysql\@DB!m${LOCAL_ID}_"

	input_if_empty "TMP_KFK_SETUP_EAGLE_DBADDRESS" "KafkaEagle.Mysql: Please ender ${red}mysql host address${reset}"
	input_if_empty "TMP_KFK_SETUP_EAGLE_DBPORT" "KafkaEagle.Mysql: Please ender ${red}mysql database port${reset} of ${TMP_KFK_SETUP_EAGLE_DBADDRESS}"
	input_if_empty "TMP_KFK_SETUP_EAGLE_DBUNAME" "KafkaEagle.Mysql: Please ender ${red}mysql user name${reset} of '${TMP_KFK_SETUP_EAGLE_DBADDRESS}'"
	input_if_empty "TMP_KFK_SETUP_EAGLE_DBPWD" "KafkaEagle.Mysql: Please ender ${red}mysql password${reset} of ${TMP_KFK_SETUP_EAGLE_DBUNAME}@${TMP_KFK_SETUP_EAGLE_DBADDRESS}"

    sed -i "s@^#kafka.eagle.driver=.*@kafka.eagle.driver=com.mysql.jdbc.Driver@g" conf/system-config.properties
    sed -i "s@^#kafka.eagle.url=.*@kafka.eagle.url=jdbc:mysql://${TMP_KFK_SETUP_EAGLE_DBADDRESS}:${TMP_KFK_SETUP_EAGLE_DBPORT}/ke?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull@g" conf/system-config.properties
    sed -i "s@^#kafka.eagle.username=.*@kafka.eagle.username=${TMP_KFK_SETUP_EAGLE_DBUNAME}@g" conf/system-config.properties
    sed -i "s@^#kafka.eagle.password=.*@kafka.eagle.password=${TMP_KFK_SETUP_EAGLE_DBPWD}@g" conf/system-config.properties

	local TMP_KFK_SETUP_EAGLE_TOKEN=""
    rand_str "TMP_KFK_SETUP_EAGLE_TOKEN" 32
    sed -i "s@^kafka.eagle.topic.token=.*@kafka.eagle.topic.token=${TMP_KFK_SETUP_EAGLE_TOKEN}@g" conf/system-config.properties

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_kafka()
{
	local TMP_KFK_SETUP_DIR=${1}

	cd ${TMP_KFK_SETUP_DIR}
	
	# 验证安装
    find ./libs/ -name \*kafka_\* | head -1 | grep -o '\kafka[^\n]*'
	jps

	# 当前启动命令
	JMX_PORT=${TMP_KFK_SETUP_JMX_PORT} && nohup bash bin/kafka-server-start.sh config/server.properties > logs/boot.log 2>&1 &
	
    # 等待启动
    echo "Starting kafka，Waiting for a moment"
    sleep 10

	# 启动状态检测
	lsof -i:${TMP_KFK_SETUP_LISTENERS_PORT}

	# 添加系统启动命令
    echo_startup_config "kafka" "${TMP_KFK_SETUP_DIR}" "bash bin/kafka-server-start.sh config/server.properties" "JMX_PORT=${TMP_KFK_SETUP_JMX_PORT}" "999"
	
	# 授权iptables端口访问
    echo_soft_port ${TMP_KFK_SETUP_LISTENERS_PORT}
	echo_soft_port ${TMP_KFK_SETUP_ZK_ADMIN_SERVER_PORT}
    echo_soft_port ${TMP_KFK_SETUP_JMX_PORT}

	return $?
}

function boot_kafka_eagle()
{
	local TMP_KFK_EGL_SETUP_DIR=${1}

	cd ${TMP_KFK_EGL_SETUP_DIR}
	
	# 验证安装
    # bin/ke.sh status

	# 当前启动命令
	nohup bin/ke.sh start > logs/boot.log 2>&1 &
	
    # 等待启动
    echo "Starting kafka_eagle，Waiting for a moment"
    sleep 10

	# 启动状态检测
	bin/ke.sh status  # lsof -i:${TMP_KFK_EGL_SETUP_WEBUI_PORT}

	# 添加系统启动命令
    echo_startup_config "kafka_eagle" "${TMP_KFK_EGL_SETUP_DIR}" "bin/ke.sh start" "" "100"
	
	# 授权iptables端口访问
	echo_soft_port ${TMP_KFK_EGL_SETUP_WEBUI_PORT}

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_kafka()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_kafka()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_kafka()
{
	local TMP_KFK_SETUP_DIR=${1}
	local TMP_KFK_CURRENT_DIR=`pwd`
    
	set_env_kafka "${TMP_KFK_SETUP_DIR}"

	setup_kafka "${TMP_KFK_SETUP_DIR}" "${TMP_KFK_CURRENT_DIR}"

	conf_kafka "${TMP_KFK_SETUP_DIR}"

    # down_plugin_kafka "${TMP_KFK_SETUP_DIR}"

	boot_kafka "${TMP_KFK_SETUP_DIR}"

	return $?
}

function exec_step_kafka_eagle()
{
	local TMP_KFK_EGL_SETUP_DIR=${1}
	local TMP_KFK_EGL_CURRENT_DIR=`pwd`
    
	set_env_kafka_eagle "${TMP_KFK_EGL_SETUP_DIR}"

	setup_kafka_eagle "${TMP_KFK_EGL_SETUP_DIR}" "${TMP_KFK_EGL_CURRENT_DIR}"

	conf_kafka_eagle "${TMP_KFK_EGL_SETUP_DIR}"

    # down_plugin_kafka_eagle "${TMP_KFK_EGL_SETUP_DIR}"

	boot_kafka_eagle "${TMP_KFK_EGL_SETUP_DIR}"

	return $?
}

##########################################################################################################

# x1-下载软件
function down_kafka()
{
	local TMP_KFK_SETUP_NEWER="2.8.0"
	local TMP_KFK_DOWN_URL_BASE="https://mirrors.cnnic.cn/apache/kafka/"
	set_url_list_newer_href_link_filename "TMP_KFK_SETUP_NEWER" "${TMP_KFK_DOWN_URL_BASE}" "()/"
	exec_text_format "TMP_KFK_SETUP_NEWER" "${TMP_KFK_DOWN_URL_BASE}%s/kafka_2.12-%s.tgz"
    setup_soft_wget "kafka" "${TMP_KFK_SETUP_NEWER}" "exec_step_kafka"

	return $?
}

function down_kafka_eagle()
{
	local TMP_KFK_EGL_SETUP_NEWER="2.0.6"
	set_github_soft_releases_newer_version "TMP_KFK_EGL_SETUP_NEWER" "smartloli/kafka-eagle-bin"
	# https://codeload.github.com/smartloli/kafka-eagle-bin/tar.gz/v%s
	exec_text_format "TMP_KFK_EGL_SETUP_NEWER" "https://github.com/smartloli/kafka-eagle-bin/raw/master/kafka-eagle-web-%s-bin.tar.gz"
    setup_soft_wget "kafka_eagle" "${TMP_KFK_EGL_SETUP_NEWER}" "exec_step_kafka_eagle"
	
	return $?
}

##########################################################################################################

#安装主体
function print_kafka()
{
	setup_soft_basic "Kafka" "down_kafka"

	return $?
}

function print_kafka_eagle()
{
    setup_soft_basic "KafkaEagle" "down_kafka_eagle"

	return $?
}

#安装主体
exec_if_choice "TMP_KFK_SETUP_CHOICE" "Please choice which kafka compoment you want to setup" "...,Kafka,Kafka_Eagle,Exit" "${TMP_SPLITER}" "print_"