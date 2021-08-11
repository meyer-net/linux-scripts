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
	mkdir -pv ${TMP_RBT_MQ_LNK_LOGS_DIR}
	mkdir -pv ${TMP_RBT_MQ_LNK_DATA_DIR}

    mkdir -pv `dirname ${TMP_RBT_MQ_LOGS_DIR}`
    mkdir -pv `dirname ${TMP_RBT_MQ_DATA_DIR}`

	ln -sf ${TMP_RBT_MQ_LNK_LOGS_DIR} ${TMP_RBT_MQ_LOGS_DIR}
	ln -sf ${TMP_RBT_MQ_LNK_DATA_DIR} ${TMP_RBT_MQ_DATA_DIR}

	return $?
}

# 3-设置软件
function conf_rabbitmq()
{
	cd ${1}

    #(epmd), 25672 (Erlang distribution)
    echo_soft_port 4369

    #(AMQP 0-9-1 without and with TLS)
    echo_soft_port 5671
    echo_soft_port 5672

    #(if management plugin is enabled)
    echo_soft_port 15672

    #(if STOMP is enabled)
    echo_soft_port 61613
    echo_soft_port 61614

    #(if MQTT is enabled)
    echo_soft_port 1883
    echo_soft_port 8883

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
