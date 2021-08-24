#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 安装标题：RabbitMQ
# 软件名称：rabbitmq
# 软件大写名称：RABBITMQ
# 软件大写分组与简称：RBT_MQ
# 软件安装名称：rabbitmq
# 软件授权用户名称&组：rabbitmq/rabbitmq_group
#------------------------------------------------
local TMP_RBT_SETUP_LISTENERS_SSL_PORT=56711
local TMP_RBT_SETUP_LISTENERS_TCP_PORT=56721
local TMP_RBT_SETUP_MQTT_LISTENERS_SSL_PORT=18883
local TMP_RBT_SETUP_MQTT_LISTENERS_TCP_PORT=28883

# 1-配置环境
function set_environment()
{
    cd ${__DIR}
    
    # 需要提前安装erlang
    source scripts/lang/erlang.sh

	return $?
}

# 2-安装软件
function setup_rabbitmq()
{
	local TMP_RBT_MQ_SETUP_DIR=${1}
	local TMP_RBT_MQ_CURRENT_DIR=${2}

	## 直装模式
	cd `dirname ${TMP_RBT_MQ_CURRENT_DIR}`

	mv ${TMP_RBT_MQ_CURRENT_DIR} ${TMP_RBT_MQ_SETUP_DIR}
    
	# 创建日志软链(启动后才能出现日志及数据目录)
	local TMP_RBT_MQ_LNK_LOGS_DIR=${LOGS_DIR}/rabbitmq
	local TMP_RBT_MQ_LNK_DATA_DIR=${DATA_DIR}/rabbitmq
	local TMP_RBT_MQ_LOGS_DIR=${TMP_RBT_MQ_SETUP_DIR}/var/log/rabbitmq
	local TMP_RBT_MQ_DATA_DIR=${TMP_RBT_MQ_SETUP_DIR}/var/lib/rabbitmq

	# 先清理文件，再创建文件
	rm -rf ${TMP_RBT_MQ_LOGS_DIR}
	rm -rf ${TMP_RBT_MQ_DATA_DIR}

	if [ ! -d "/var/log/rabbitmq" ]; then
		mkdir -pv ${TMP_RBT_MQ_LNK_LOGS_DIR}
	else
		mv /var/log/rabbitmq ${TMP_RBT_MQ_LNK_LOGS_DIR}
	fi
	
	if [ ! -d "/var/lib/rabbitmq" ]; then
		mkdir -pv ${TMP_RBT_MQ_LNK_DATA_DIR}
	else
		mv /var/lib/rabbitmq ${TMP_RBT_MQ_LNK_DATA_DIR}
	fi

    mkdir -pv `dirname ${TMP_RBT_MQ_LOGS_DIR}`
    mkdir -pv `dirname ${TMP_RBT_MQ_DATA_DIR}`

	ln -sf ${TMP_RBT_MQ_LNK_LOGS_DIR} ${TMP_RBT_MQ_LOGS_DIR}
	ln -sf ${TMP_RBT_MQ_LNK_LOGS_DIR} /var/log/rabbitmq
	ln -sf ${TMP_RBT_MQ_LNK_DATA_DIR} ${TMP_RBT_MQ_DATA_DIR}
	ln -sf ${TMP_RBT_MQ_LNK_DATA_DIR} /var/lib/rabbitmq

	return $?
}

# 3-设置软件
function conf_rabbitmq()
{
	local TMP_RBT_SETUP_DIR=${1}

	cd ${TMP_RBT_SETUP_DIR}
	
	local TMP_RBT_SETUP_LNK_ETC_DIR=${ATT_DIR}/rabbitmq
	local TMP_RBT_SETUP_ETC_DIR=${TMP_RBT_SETUP_DIR}/etc

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mv ${TMP_RBT_SETUP_ETC_DIR} ${TMP_RBT_SETUP_LNK_ETC_DIR}

	# 替换原路径链接
	ln -sf ${TMP_RBT_SETUP_LNK_ETC_DIR} ${TMP_RBT_SETUP_ETC_DIR}

	while_wget "https://raw.githubusercontent.com/rabbitmq/rabbitmq-server/master/deps/rabbit/docs/rabbitmq.conf.example" "mv rabbitmq.conf.example etc/rabbitmq/rabbitmq.conf"

	# 4369，epmd（Erlang Port Mapper Daemon），是Erlang的端口/结点名称映射程序，用来跟踪节点名称监听地址，在集群中起到一个类似DNS的作用。
	# 5672, 5671， AMQP 0-9-1 和 1.0 客户端端口，used by AMQP 0-9-1 and 1.0 clients without and with TLS(Transport Layer Security)
	# 25672，Erlang distribution，和4369配合
	# 15672，HTTP_API端口，管理员用户才能访问，用于管理RbbitMQ，需要启用management插件，rabbitmq-plugins enable rabbitmq_management，访问http://server-name:15672/
	# 61613, 61614，当STOMP插件启用的时候打开，作为STOMP客户端端口（根据是否使用TLS选择）
	# 1883, 8883，当MQTT插件启用的时候打开，作为MQTT客户端端口（根据是否使用TLS选择）
	# 15674，基于WebSocket的STOMP客户端端口（当插件Web STOMP启用的时候打开）
	# 15675，基于WebSocket的MQTT客户端端口（当插件Web MQTT启用的时候打开）

	sed -i "s@^# listeners.ssl.default=.*@listeners.ssl.default = ${TMP_RBT_SETUP_LISTENERS_SSL_PORT}@g" etc/rabbitmq/rabbitmq.conf
	sed -i "s@^# listeners.tcp.default=.*@listeners.tcp.default = ${TMP_RBT_SETUP_LISTENERS_TCP_PORT}@g" etc/rabbitmq/rabbitmq.conf

	sed -i "s@^# listeners.tcp.default=.*@listeners.tcp.default = ${TMP_RBT_SETUP_LISTENERS_TCP_PORT}@g" etc/rabbitmq/rabbitmq.conf
	sed -i "s@^# mqtt.listeners.ssl.default=.*@mqtt.listeners.ssl.default = ${TMP_RBT_SETUP_MQTT_LISTENERS_SSL_PORT}@g" etc/rabbitmq/rabbitmq.conf
    sed -i "/# mqtt.listeners.tcp.2 = ::1:61613/a mqtt.listeners.tcp.default=${TMP_RBT_SETUP_MQTT_LISTENERS_TCP_PORT}" ${TMP_DB_ETC_PATH}

    #(epmd), 25672 (Erlang distribution)
    echo_soft_port 4369

    #(AMQP 0-9-1 without and with TLS)
    echo_soft_port ${TMP_RBT_SETUP_LISTENERS_SSL_PORT}
    echo_soft_port ${TMP_RBT_SETUP_LISTENERS_TCP_PORT}

    #(if management plugin is enabled)
    echo_soft_port 15672

    #(if STOMP is enabled)
    echo_soft_port 61613
    echo_soft_port 61614

    #(if MQTT is enabled)
    echo_soft_port ${TMP_RBT_SETUP_MQTT_LISTENERS_SSL_PORT}
    echo_soft_port ${TMP_RBT_SETUP_MQTT_LISTENERS_TCP_PORT}

	return $?
}

# 4-启动软件
function boot_rabbitmq()
{
	local TMP_RBT_MQ_SETUP_DIR=${1}

	cd ${TMP_RBT_MQ_SETUP_DIR}

	# 当前启动命令
	sbin/rabbitmq-server -detached
	
	# 验证安装
    sbin/rabbitmqctl status | grep "RabbitMQ version"

    # 启动管理界面
    sbin/rabbitmq-plugins enable rabbitmq_management

	# 添加系统启动命令
    echo_startup_config "rabbitmq" "${TMP_RBT_MQ_SETUP_DIR}" "sbin/rabbitmq-server -detached" "" "1"
	
	# # 其他命令
	# rabbitmqctl add_user <username> <password>
	# rabbitmqctl delete_user <username>
	# rabbitmqctl change_password <username> <newpassword>
	# rabbitmqctl clear_password <username>
	# rabbitmqctl authenticate_user <username> <password>
	# rabbitmqctl set_user_tags <username> <tag> ...
	# rabbitmqctl list_users

	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_rabbitmq()
{
	local TMP_RBT_MQ_SETUP_DIR=${1}
	local TMP_RBT_MQ_CURRENT_DIR=`pwd`
    
	set_environment "${TMP_RBT_MQ_SETUP_DIR}"

	setup_rabbitmq "${TMP_RBT_MQ_SETUP_DIR}" "${TMP_RBT_MQ_CURRENT_DIR}"

	conf_rabbitmq "${TMP_RBT_MQ_SETUP_DIR}"

    # down_plugin_rabbitmq "${TMP_RBT_MQ_SETUP_DIR}"

	boot_rabbitmq "${TMP_RBT_MQ_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_rabbitmq()
{
	TMP_RBT_MQ_SETUP_NEWER="3.8.19"
	set_github_soft_releases_newer_version "TMP_RBT_MQ_SETUP_NEWER" "rabbitmq/rabbitmq-server"
	exec_text_format "TMP_RBT_MQ_SETUP_NEWER" "https://github.com/rabbitmq/rabbitmq-server/releases/download/v%s/rabbitmq-server-generic-unix-%s.tar.xz"
    setup_soft_wget "rabbitmq" "${TMP_RBT_MQ_SETUP_NEWER}" "exec_step_rabbitmq"

	return $?
}

#安装主体
setup_soft_basic "RabbitMQ" "down_rabbitmq"
