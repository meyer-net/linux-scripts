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

	return $?
}

# 2-安装软件
function setup_filebeat()
{
	local TMP_ELK_FBT_SETUP_DIR=${1}
	local TMP_ELK_FBT_CURRENT_DIR=`pwd`

	cd ..
	mv ${TMP_ELK_FBT_CURRENT_DIR:-} ${TMP_ELK_FBT_SETUP_DIR}
	chown -R elk:elk ${TMP_ELK_FBT_SETUP_DIR}

	return $?
}

# 3-设置软件
#??? 搜索配置文件改成从第X行匹配最近的字符
function set_filebeat()
{
	cd ${1}

	# 找到需要配置的侦听日志部分的节点起始行数
	local TMP_ELK_FBT_YML_INPUTS_LINE=`cat filebeat.yml | awk '/filebeat.inputs:/ {print NR}'`
	local TMP_ELK_FBT_YML_PATHS_LINE_IN_PART=`cat filebeat.yml | grep -A 13 "filebeat.inputs:" | awk '/\s*paths:/ {print NR}'`
	local TMP_ELK_FBT_YML_PATHS_FILE_LINE=$((TMP_ELK_FBT_YML_INPUTS_LINE+TMP_ELK_FBT_YML_PATHS_LINE_IN_PART))

	# 找到需要侦听的日志部分，并泛化到配置文件
	find ${LOGS_DIR} -name *.log | sed 's@\w*.log$@*.log@g' | uniq | xargs -I {} sed -i "${TMP_ELK_FBT_YML_PATHS_FILE_LINE}a\    - {}" filebeat.yml

	# 修改启用状态
	local TMP_ELK_FBT_YML_ENABLED_LINE_IN_PART=`cat filebeat.yml | grep -A 10 "filebeat.inputs:" | awk '/\s*enabled:/ {print NR}'`
	local TMP_ELK_FBT_YML_ENABLED_FILE_LINE=$((TMP_ELK_FBT_YML_INPUTS_LINE+TMP_ELK_FBT_YML_ENABLED_LINE_IN_PART-1))
	sed -i "${TMP_ELK_FBT_YML_ENABLED_FILE_LINE}s@enabled: false@enabled: true@g" filebeat.yml

	return $?
}

# 4-启动软件
function boot_filebeat()
{
	local TMP_ELK_FBT_SETUP_DIR=${1}

	su - elk -c "cd ${TMP_ELK_FBT_SETUP_DIR} && nohup ./filebeat -e -c filebeat.yml -d \"publish\" &" 
	
    echo_startup_config "filebeat" "${TMP_ELK_FBT_SETUP_DIR}" './filebeat -e -c filebeat.yml -d "publish"' "" "3" "" "elk"

	return $?
}

# x-执行步骤
function exec_step_filebeat()
{
	local TMP_ELK_FBT_SETUP_DIR=${1}

	set_environment "${TMP_ELK_FBT_SETUP_DIR}"

	setup_filebeat "${TMP_ELK_FBT_SETUP_DIR}"

	set_filebeat "${TMP_ELK_FBT_SETUP_DIR}"

	boot_filebeat "${TMP_ELK_FBT_SETUP_DIR}"

	return $?
}

# x-下载软件
function down_filebeat()
{
	ELK_FBT_SETUP_NEWER="7.8.0"
	set_github_soft_releases_newer_version "ELK_FBT_SETUP_NEWER" "elastic/beats"
	exec_text_format "ELK_FBT_SETUP_NEWER" "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-%-linux-x86_64.tar.gz"
    setup_soft_wget "filebeat" "$ELK_FBT_SETUP_NEWER" "exec_step_filebeat"

	return $?
}

setup_soft_basic "FileBeat" "down_filebeat"
