#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

# 1-配置环境
function set_environment()
{
	create_user_if_not_exists elk elk
	
    source ${WORK_PATH}/scripts/lang/java.sh

	return $?
}

# 2-安装软件
function setup_logstash()
{
	local TMP_ELK_LS_SETUP_DIR=${1}
	local TMP_ELK_LS_CURRENT_DIR=`pwd`
	
	cd ..
	mv ${TMP_ELK_LS_CURRENT_DIR:-} ${TMP_ELK_LS_SETUP_DIR}

	local TMP_ELK_LS_LNK_LOGS_DIR=${LOGS_DIR}/logstash
	local TMP_ELK_LS_LNK_DATA_DIR=${DATA_DIR}/logstash
	local TMP_ELK_LS_LOGS_DIR=${TMP_ELK_LS_SETUP_DIR}/logs
	local TMP_ELK_LS_DATA_DIR=${TMP_ELK_LS_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_ELK_LS_LOGS_DIR}
	rm -rf ${TMP_ELK_LS_DATA_DIR}
	mkdir -pv ${TMP_ELK_LS_LNK_LOGS_DIR}
	mkdir -pv ${TMP_ELK_LS_LNK_DATA_DIR}
	mkdir -pv ${TMP_ELK_LS_DATA_DIR}/dead_letter_queue
	mkdir -pv ${TMP_ELK_LS_DATA_DIR}/queue

	ln -sf ${TMP_ELK_LS_LNK_LOGS_DIR} ${TMP_ELK_LS_LOGS_DIR}
	ln -sf ${TMP_ELK_LS_LNK_DATA_DIR} ${TMP_ELK_LS_DATA_DIR}

	# 授权权限，否则无法写入
	chown -R elk:elk ${TMP_ELK_LS_SETUP_DIR}
	chown -R elk:elk ${TMP_ELK_LS_LNK_LOGS_DIR}
	chown -R elk:elk ${TMP_ELK_LS_LNK_DATA_DIR}

	return $?
}

# 3-设置软件
function set_logstash()
{
	cd ${1}

	cp config/logstash-sample.conf config/logstash.conf

	local TMP_ELK_LS_ES_HOST=${LOCAL_HOST}
    input_if_empty "TMP_ELK_LS_ES_HOST" "Logstash: Please ender your ${red}elasticsearch host address${reset} like '${LOCAL_HOST}'"
	set_if_equals "TMP_ELK_LS_ES_HOST" "LOCAL_HOST" "127.0.0.1"

    sed -i "s@localhost@${TMP_ELK_LS_ES_HOST}@g" config/logstash.conf

	return $?
}

# 4-启动软件
function boot_logstash()
{
	local TMP_LS_SETUP_DIR=${1}

	cd ${TMP_LS_SETUP_DIR}
	
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
	su - elk -c "cd ${TMP_LS_SETUP_DIR} && nohup bin/logstash -f config/logstash.conf --config.reload.automatic &" 
	
    echo_startup_config "logstash" "${TMP_LS_SETUP_DIR}" "bash bin/logstash -f config/logstash.conf --config.reload.automatic" "" "2" "" "elk"

	return $?
}

# x-执行步骤
function exec_step_logstash()
{
	local TMP_LS_SETUP_DIR=${1}

	set_environment "${TMP_LS_SETUP_DIR}"

	setup_logstash "${TMP_LS_SETUP_DIR}"

	set_logstash "${TMP_LS_SETUP_DIR}"

	boot_logstash "${TMP_LS_SETUP_DIR}"

	return $?
}

# x-下载软件
function down_logstash()
{
	ELK_LOGSTASH_SETUP_NEWER="7.8.0"
	set_github_soft_releases_newer_version "ELK_LOGSTASH_SETUP_NEWER" "elastic/logstash"
	exec_text_format "ELK_LOGSTASH_SETUP_NEWER" "https://artifacts.elastic.co/downloads/logstash/logstash-%.tar.gz"
    setup_soft_wget "logstash" "$ELK_LOGSTASH_SETUP_NEWER" "exec_step_logstash"

	return $?
}

setup_soft_basic "LogStash" "down_logstash"
