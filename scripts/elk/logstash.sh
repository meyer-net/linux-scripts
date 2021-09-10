#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 相关参考：
#		  
#------------------------------------------------
local TMP_ELK_LS_SETUP_PORT=15044
local TMP_ELK_LS_SETUP_ES_HTTP_PORT=19200

##########################################################################################################

# 1-配置环境
function set_env_logstash()
{
    cd ${__DIR}

	# 自带jdk，暂省略
    # source scripts/lang/java.sh

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_logstash()
{
	## 直装模式
	cd `dirname ${TMP_ELK_LS_CURRENT_DIR}`

	mv ${TMP_ELK_LS_CURRENT_DIR} ${TMP_ELK_LS_SETUP_DIR}

	cd ${TMP_ELK_LS_SETUP_DIR}

	# 创建日志软链
	local TMP_ELK_LS_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/logstash
	local TMP_ELK_LS_SETUP_LNK_DATA_DIR=${DATA_DIR}/logstash
	local TMP_ELK_LS_SETUP_LOGS_DIR=${TMP_ELK_LS_SETUP_DIR}/logs
	local TMP_ELK_LS_SETUP_DATA_DIR=${TMP_ELK_LS_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_ELK_LS_SETUP_LOGS_DIR}
	rm -rf ${TMP_ELK_LS_SETUP_DATA_DIR}
	mkdir -pv ${TMP_ELK_LS_SETUP_LNK_LOGS_DIR}
	mkdir -pv ${TMP_ELK_LS_SETUP_LNK_DATA_DIR}

	mkdir -pv ${TMP_ELK_LS_SETUP_LNK_DATA_DIR}/dead_letter_queue
	mkdir -pv ${TMP_ELK_LS_SETUP_LNK_DATA_DIR}/queue
	
	ln -sf ${TMP_ELK_LS_SETUP_LNK_LOGS_DIR} ${TMP_ELK_LS_SETUP_LOGS_DIR}
	ln -sf ${TMP_ELK_LS_SETUP_LNK_DATA_DIR} ${TMP_ELK_LS_SETUP_DATA_DIR}

	# 环境变量或软连接
	echo "LOGSTASH_HOME=${TMP_ELK_LS_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$LOGSTASH_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH LOGSTASH_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

	# 授权权限，否则无法写入
	create_user_if_not_exists elk elk
	chown -R elk:elk ${TMP_ELK_LS_SETUP_DIR}
	chown -R elk:elk ${TMP_ELK_LS_SETUP_LNK_LOGS_DIR}
	chown -R elk:elk ${TMP_ELK_LS_SETUP_LNK_DATA_DIR}
	
    # 安装初始

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_logstash()
{
	cd ${TMP_ELK_LS_SETUP_DIR}
	
	local TMP_ELK_LS_SETUP_LNK_ETC_DIR=${ATT_DIR}/logstash
	local TMP_ELK_LS_SETUP_ETC_DIR=${TMP_ELK_LS_SETUP_DIR}/config

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mv ${TMP_ELK_LS_SETUP_ETC_DIR} ${TMP_ELK_LS_SETUP_LNK_ETC_DIR}

	# 替换原路径链接（存在etc下时，不能作为软连接存在）
	ln -sf ${TMP_ELK_LS_SETUP_LNK_ETC_DIR} ${TMP_ELK_LS_SETUP_ETC_DIR}

	# 开始配置
	cp config/logstash-sample.conf config/logstash.conf

	local TMP_ELK_LS_SETUP_ES_HOST="${LOCAL_HOST}"
    input_if_empty "TMP_ELK_LS_SETUP_ES_HOST" "LogStash: Please ender your ${red}elasticsearch host address${reset} like '${LOCAL_HOST}'"
	set_if_equals "TMP_ELK_LS_SETUP_ES_HOST" "LOCAL_HOST" "127.0.0.1"

    sed -i "s@port => 5044@port => ${TMP_ELK_LS_SETUP_PORT}@g" config/logstash.conf
    sed -i "s@localhost:9200@${TMP_ELK_LS_SETUP_ES_HOST}:${TMP_ELK_LS_SETUP_ES_HTTP_PORT}@g" config/logstash.conf
	
	chown -R elk:elk ${TMP_ELK_LS_SETUP_LNK_ETC_DIR}

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_logstash()
{
	cd ${TMP_ELK_LS_SETUP_DIR}
	
	# 验证安装	
	bin/logstash -V
	# （1）测试启动，看配置文件是否正确：
	bin/logstash -f first-pipeline.conf --config.test_and_exit
	# （2）以config.reload.automatic方式启动，这样在修改配置文件后无需重新启动，它会自动加载：bin/logstash -f first-pipeline.conf --config.reload.automatic
	# （3）列出所有已安装的插件：
	bin/logstash-plugin list
	# （4）安装外部的插件：bin/logstash-plugin install [插件名称]
	# （5）更新所有插件：
	bin/logstash-plugin update
	# （6）更新指定插件：bin/logstash-plugin update logstash-output-kafka
	# （7）删除指定插件：bin/logstash-plugin remove logstash-output-kafka
	# 测试conf文件是否正确配置
	bin/logstash -f config/logstash.conf --config.test_and_exit

	# 启动logstash，如果有修改conf会自动加载
	su - elk -c "cd ${TMP_ELK_LS_SETUP_DIR} && nohup bin/logstash -f config/logstash.conf --config.reload.automatic > logs/boot.log 2>&1 &" 
	
    # 等待启动
    echo "Starting logstash，Waiting for a moment"
    echo "--------------------------------------------"
    sleep 30

    cat logs/boot.log
    # cat /var/log/logstash/logstash.log
    echo "--------------------------------------------"

	# 启动状态检测
	bin/logstash status  # lsof -i:${TMP_ELK_LS_SETUP_PORT}

	# 添加系统启动命令
	echo_startup_config "logstash" "${TMP_ELK_LS_SETUP_DIR}" "bash bin/logstash -f config/logstash.conf --config.reload.automatic" "" "2" "" "elk"
	
	# 授权iptables端口访问
	echo_soft_port ${TMP_ELK_LS_SETUP_PORT}

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_logstash()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_logstash()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_logstash()
{
	# 变量覆盖特性，其它方法均可读取
	local TMP_ELK_LS_SETUP_DIR=${1}
	local TMP_ELK_LS_CURRENT_DIR=`pwd`
    
	set_env_logstash 

	setup_logstash 

	conf_logstash 

    # down_plugin_logstash 
    # setup_plugin_logstash 

	boot_logstash 

	# reconf_logstash 

	return $?
}

##########################################################################################################

# x1-下载软件
function down_logstash()
{
	local TMP_ELK_LS_SETUP_NEWER="7.8.0"
	set_github_soft_releases_newer_version "TMP_ELK_LS_SETUP_NEWER" "elastic/logstash"
	exec_text_format "TMP_ELK_LS_SETUP_NEWER" "https://artifacts.elastic.co/downloads/logstash/logstash-%s-linux-x86_64.tar.gz"
    setup_soft_wget "logstash" "${TMP_ELK_LS_SETUP_NEWER}" "exec_step_logstash"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "LogStash" "down_logstash"
