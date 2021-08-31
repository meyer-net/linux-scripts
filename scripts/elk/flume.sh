#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

# 1-配置环境
function set_environment()
{    
    # 需要提前安装Java,Hadoop
    source ${__DIR}/scripts/lang/java.sh

	return $?
}

# 2-安装软件
function setup_flume()
{
	local TMP_FLM_SETUP_DIR=${1}
	local TMP_FLM_CURRENT_DIR=`pwd`
	
	cd ..
	mv ${TMP_FLM_CURRENT_DIR:-} ${TMP_FLM_SETUP_DIR}

	local TMP_FLM_LNK_LOGS_DIR=${LOGS_DIR}/flume
	local TMP_FLM_LNK_DATA_DIR=${DATA_DIR}/flume
	local TMP_FLM_LOGS_DIR=${TMP_FLM_SETUP_DIR}/logs
	local TMP_FLM_DATA_DIR=${TMP_FLM_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_FLM_LOGS_DIR}
	rm -rf ${TMP_FLM_DATA_DIR}
	mkdir -pv ${TMP_FLM_LNK_LOGS_DIR}
	mkdir -pv ${TMP_FLM_LNK_DATA_DIR}

	ln -sf ${TMP_FLM_LNK_LOGS_DIR} ${TMP_FLM_LOGS_DIR}
	ln -sf ${TMP_FLM_LNK_DATA_DIR} ${TMP_FLM_DATA_DIR}

	# 环境变量
    echo "FLUME_HOME=${TMP_FLM_SETUP_DIR}" >> /etc/profile
    echo 'FLUME_BIN=${FLUME_HOME}/bin' >> /etc/profile
    echo 'PATH=${FLUME_BIN}:${PATH}' >> /etc/profile
	echo "export PATH FLUME_HOME FLUME_BIN" >> /etc/profile

    source /etc/profile

	return $?
}

# 3-设置软件
function conf_flume()
{
	cd ${1}

    # cp conf/flume-conf.properties.template conf/flume-conf.properties
    cat > conf/local-port8124-listener-conf.properties <<EOF
# The configuration file needs to define the sources,
# the channels and the sinks.
# Sources, channels and sinks are defined per agent,
# in this case called 'agent'

a1.sources = r1
a1.channels = c1
a1.sinks = s1

# For each one of the sources, the type is defined
a1.sources.r1.type = netcat
a1.sources.r1.bind = localhost
a1.sources.r1.port = 8124

# The channel can be defined as follows.
a1.sources.r1.channels = c1

# Each sink's type must be defined
a1.sinks.s1.type = logger
a1.sinks.s1.sink.directory = ${TMP_FLM_LOGS_DIR}

#Specify the channel the sink should use
a1.sinks.s1.channel = c1

# Each channel's type is defined.
a1.channels.c1.type = memory

# Other config values specific to each type of channel(sink or source)
# can be defined as well
# In this case, it specifies the capacity of the memory channel
a1.channels.c1.capacity = 1000
a1.channels.c1.transactionCapacity = 100  
EOF

    sed -i "s@flume\.log\.dir=.*@flume\.log\.dir=${TMP_FLM_LOGS_DIR}@g" conf/log4j.properties

	return $?
}

# 4-启动软件
function boot_flume()
{
	local TMP_FLM_SETUP_DIR=${1}

	cd ${TMP_FLM_SETUP_DIR}

    bin/flume-ng agent -n a1 --c conf -f conf/local-port8124-listener-conf.properties -Dflume.root.logger=INFO,console

    echo_startup_config "flume" "${TMP_FLM_SETUP_DIR}" "bin/flume-ng agent -n a1 --c conf -f conf/local-port8124-listener-conf.properties -Dflume.root.logger=INFO,console" "" "100"

	return $?
}

##########################################################################################################

# 下载插件
function down_driver_ng_sql_source()
{
    setup_soft_git "flume-ng-sql-source" "https://github.com/keedio/flume-ng-sql-source" "setup_driver_ng_sql_source" "-b feature/check-compatibility-latest-stable"

	return $?
}

# 安装插件
function setup_driver_ng_sql_source()
{
	local TMP_FLM_DRIVERS_NGSQLSOURCE_SETUP_DIR=${1}
	local TMP_FLM_DRIVERS_NGSQLSOURCE_CURRENT_DIR=`pwd`

    mvn package && cp target/flume-ng-sql-source-1.5.0.jar ${TMP_FLM_SETUP_DIR}/lib/

    # 创建一个假地址，混淆安装
    ln -sf ${TMP_FLM_SETUP_DIR}/lib/flume-ng-sql-source-1.5.0.jar ${TMP_FLM_DRIVERS_NGSQLSOURCE_SETUP_DIR}
    
    # 安装驱动
    # https://dev.mysql.com/downloads/connector/

    #https://github.com/baniuyao/flume-ng-kafka-source
    #https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.35.tar.gz
    #https://download.microsoft.com/download/A/F/B/AFB381FF-7037-46CE-AF9B-6B1875EA81D7/sqljdbc_6.0.8112.200_chs.tar.gz

    rm -rf ${TMP_FLM_DRIVERS_NGSQLSOURCE_CURRENT_DIR}

	return $?
}

##########################################################################################################

# x-执行步骤
function exec_step_flume()
{
	local TMP_FLM_SETUP_DIR=${1}
    
	set_environment "${TMP_FLM_SETUP_DIR}"

	setup_flume "${TMP_FLM_SETUP_DIR}"

	conf_flume "${TMP_FLM_SETUP_DIR}"

    down_driver_ng_sql_source "${TMP_FLM_SETUP_DIR}"

	boot_flume "${TMP_FLM_SETUP_DIR}"

	return $?
}

# x-下载软件
function down_flume()
{
    #官方2年未更新版本，固版本写死
    #http://www.apache.org/dyn/closer.lua/flume/1.9.0/apache-flume-1.9.0-bin.tar.gz
    setup_soft_wget "flume" "http://mirrors.hust.edu.cn/apache/flume/stable/apache-flume-1.9.0-bin.tar.gz" "exec_step_flume"

	return $?
}

setup_soft_basic "Flume" "down_flume"