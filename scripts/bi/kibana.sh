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

    # 安装插件需要提前安装nodejs
    source ${__DIR}/scripts/lang/nodejs.sh

	return $?
}

# 2-安装软件
function setup_kibana()
{
	local TMP_ELK_KBN_SETUP_DIR=${1}
	local TMP_ELK_KBN_CURRENT_DIR=`pwd`

	cd ..
	mv ${TMP_ELK_KBN_CURRENT_DIR:-} ${TMP_ELK_KBN_SETUP_DIR}
	
	local TMP_ELK_KBN_LNK_LOGS_DIR=${LOGS_DIR}/kibana
	local TMP_ELK_KBN_LNK_DATA_DIR=${DATA_DIR}/kibana
	local TMP_ELK_KBN_LOGS_DIR=${TMP_ELK_KBN_SETUP_DIR}/logs
	local TMP_ELK_KBN_DATA_DIR=${TMP_ELK_KBN_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_ELK_KBN_LOGS_DIR}
	rm -rf ${TMP_ELK_KBN_DATA_DIR}
	mkdir -pv ${TMP_ELK_KBN_LNK_LOGS_DIR}
	mkdir -pv ${TMP_ELK_KBN_LNK_DATA_DIR}

	ln -sf ${TMP_ELK_KBN_LNK_LOGS_DIR} ${TMP_ELK_KBN_LOGS_DIR}
	ln -sf ${TMP_ELK_KBN_LNK_DATA_DIR} ${TMP_ELK_KBN_DATA_DIR}

	# 授权权限，否则无法写入
	chown -R elk:elk ${TMP_ELK_KBN_SETUP_DIR}
	chown -R elk:elk ${TMP_ELK_KBN_LNK_LOGS_DIR}
	chown -R elk:elk ${TMP_ELK_KBN_LNK_DATA_DIR}

    echo_soft_port 5601

	return $?
}

# 3-设置软件
function set_kibana()
{
	cd ${1}

	local TMP_ELK_KBN_ES_HOST=${LOCAL_HOST}
    input_if_empty "TMP_ELK_KBN_ES_HOST" "Kibana: Please ender your ${red}elasticsearch host address${reset} like '${LOCAL_HOST}'"
	set_if_equals "TMP_ELK_KBN_ES_HOST" "LOCAL_HOST" "127.0.0.1"

	local TMP_ELK_KBN_ES_USER="root"
    input_if_empty "TMP_ELK_KBN_ES_USER" "Kibana: Please ender your ${red}elasticsearch user${reset} of '${TMP_ELK_KBN_ES_HOST}'"

	local TMP_ELK_KBN_ES_PASSWD="es12345"
    input_if_empty "TMP_ELK_KBN_ES_PASSWD" "Kibana: Please ender your ${red}elasticsearch password${reset} of '${TMP_ELK_KBN_ES_HOST}'"

    sed -i "s@[#]*server\.port@server.port@g" config/kibana.yml
    sed -i "s@[#]*server\.host.*@server.host: \"0.0.0.0\"@g" config/kibana.yml
    sed -i "s@[#]*elasticsearch\.hosts:.*@elasticsearch.hosts: \"[http://${TMP_ELK_KBN_ES_HOST}:9200]\"@g" config/kibana.yml
    sed -i "s@[#]*elasticsearch\.username:.*@elasticsearch.username: \"${TMP_ELK_KBN_ES_USER}\"@g" config/kibana.yml
    sed -i "s@[#]*elasticsearch\.password:.*@elasticsearch.password: \"${TMP_ELK_KBN_ES_PASSWD}\"@g" config/kibana.yml

	return $?
}

# 4-启动软件
function boot_kibana()
{
	local TMP_ELK_KBN_SETUP_DIR=${1}

	su - elk -c "cd ${TMP_ELK_KBN_SETUP_DIR} && nohup bash bin/kibana &"
	
    echo_startup_config "kibana" "${TMP_ELK_KBN_SETUP_DIR}" "bash bin/kibana" "" "3" "" "elk"

	return $?
}

# x-执行步骤
function exec_step_kibana()
{
	local TMP_ELK_KBN_SETUP_DIR=${1}

	set_environment "${TMP_ELK_KBN_SETUP_DIR}"

	setup_kibana "${TMP_ELK_KBN_SETUP_DIR}"

	set_kibana "${TMP_ELK_KBN_SETUP_DIR}"

	boot_kibana "${TMP_ELK_KBN_SETUP_DIR}"

	return $?
}

# x-下载软件
function down_kibana()
{	
	ELK_KBN_SETUP_NEWER="7.8.0"
	set_github_soft_releases_newer_version "ELK_KBN_SETUP_NEWER" "elastic/kibana"
	exec_text_format "ELK_KBN_SETUP_NEWER" "https://artifacts.elastic.co/downloads/kibana/kibana-%s-linux-x86_64.tar.gz"
    setup_soft_wget "kibana" "$ELK_KBN_SETUP_NEWER" "exec_step_kibana"

	return $?
}

setup_soft_basic "Kibana" "down_kibana"