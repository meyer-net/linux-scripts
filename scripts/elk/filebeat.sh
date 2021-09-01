#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 相关参考：
#		  
#------------------------------------------------
# local TMP_ELK_FBT_SETUP_PORT=11234
local TMP_ELK_FBT_SETUP_ES_HTTP_PORT=19200

##########################################################################################################

# 1-配置环境
function set_env_filebeat()
{
    cd ${__DIR}

    # soft_yum_check_setup ""

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_filebeat()
{
	## 直装模式
	cd `dirname ${TMP_ELK_FBT_CURRENT_DIR}`

	mv ${TMP_ELK_FBT_CURRENT_DIR} ${TMP_ELK_FBT_SETUP_DIR}

	cd ${TMP_ELK_FBT_SETUP_DIR}

	# 创建日志软链
	local TMP_ELK_FBT_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/filebeat
	local TMP_ELK_FBT_SETUP_LNK_DATA_DIR=${DATA_DIR}/filebeat
	local TMP_ELK_FBT_SETUP_LOGS_DIR=${TMP_ELK_FBT_SETUP_DIR}/logs
	local TMP_ELK_FBT_SETUP_DATA_DIR=${TMP_ELK_FBT_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_ELK_FBT_SETUP_LOGS_DIR}
	rm -rf ${TMP_ELK_FBT_SETUP_DATA_DIR}
	mkdir -pv ${TMP_ELK_FBT_SETUP_LNK_LOGS_DIR}
	mkdir -pv ${TMP_ELK_FBT_SETUP_LNK_DATA_DIR}
	
	ln -sf ${TMP_ELK_FBT_SETUP_LNK_LOGS_DIR} ${TMP_ELK_FBT_SETUP_LOGS_DIR}
	ln -sf ${TMP_ELK_FBT_SETUP_LNK_DATA_DIR} ${TMP_ELK_FBT_SETUP_DATA_DIR}
	
	# 环境变量或软连接
	echo "FILEBEAT_HOME=${TMP_ELK_FBT_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$FILEBEAT_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH FILEBEAT_HOME' >> /etc/profile

	# 移动bin
	mkdir bin
	mv filebeat bin/

    # 重新加载profile文件
	source /etc/profile

	# 授权权限，否则无法写入
	create_user_if_not_exists elk elk
	chown -R elk:elk ${TMP_ELK_FBT_SETUP_DIR}
	chown -R elk:elk ${TMP_ELK_FBT_SETUP_LNK_LOGS_DIR}
	chown -R elk:elk ${TMP_ELK_FBT_SETUP_LNK_DATA_DIR}
	
    # 安装初始

	return $?
}

##########################################################################################################

# 3-设置软件
#??? 搜索配置文件改成从第X行匹配最近的字符
function conf_filebeat()
{
	cd ${TMP_ELK_FBT_SETUP_DIR}
	
	local TMP_ELK_FBT_SETUP_LNK_ETC_DIR=${ATT_DIR}/filebeat
	local TMP_ELK_FBT_SETUP_ETC_DIR=${TMP_ELK_FBT_SETUP_DIR}/config

	# ①-Y：存在配置文件：原路径文件放给真实路径
	path_not_exists_create "${TMP_ELK_FBT_SETUP_LNK_ETC_DIR}"

	# 替换原路径链接（存在etc下时，不能作为软连接存在）
	ln -sf ${TMP_ELK_FBT_SETUP_LNK_ETC_DIR} ${TMP_ELK_FBT_SETUP_ETC_DIR}

	# 开始配置
	# 找到需要配置的侦听日志部分的节点起始行数
	local TMP_ELK_FBT_SETUP_YML_INPUTS_LINE=`cat filebeat.yml | awk '/filebeat.inputs:/ {print NR}'`
	local TMP_ELK_FBT_SETUP_YML_PATHS_LINE_IN_PART=`cat filebeat.yml | grep -A 13 "filebeat.inputs:" | awk '/\s*paths:/ {print NR}'`
	local TMP_ELK_FBT_SETUP_YML_PATHS_FILE_LINE=$((TMP_ELK_FBT_SETUP_YML_INPUTS_LINE+TMP_ELK_FBT_SETUP_YML_PATHS_LINE_IN_PART))

	# 找到需要侦听的日志部分，并泛化到配置文件
	find ${LOGS_DIR} -name *.log 2> /dev/null | sed 's@\w*.log$@*.log@g' | grep -v "${LOGS_DIR}/anaconda" | grep -v "${LOGS_DIR}/filebeat" | grep -v "${LOGS_DIR}/elasticsearch" | grep -v "${LOGS_DIR}/logstash" | grep -v "${LOGS_DIR}/kibana" | uniq | xargs -I {} sed -i "${TMP_ELK_FBT_SETUP_YML_PATHS_FILE_LINE}a\    - {}" filebeat.yml

	# 修改启用状态
	local TMP_ELK_FBT_SETUP_YML_ENABLED_LINE_IN_PART=`cat filebeat.yml | grep -A 10 "filebeat.inputs:" | awk '/\s*enabled:/ {print NR}'`
	local TMP_ELK_FBT_SETUP_YML_ENABLED_FILE_LINE=$((TMP_ELK_FBT_SETUP_YML_INPUTS_LINE+TMP_ELK_FBT_SETUP_YML_ENABLED_LINE_IN_PART-1))
	sed -i "${TMP_ELK_FBT_SETUP_YML_ENABLED_FILE_LINE}s@enabled: false@enabled: true@g" filebeat.yml

	local TMP_ELK_FBT_SETUP_ES_HOST="${LOCAL_HOST}"
    input_if_empty "TMP_ELK_FBT_SETUP_ES_HOST" "FileBeat: Please ender your ${red}elasticsearch host address${reset}"
	set_if_equals "TMP_ELK_FBT_SETUP_ES_HOST" "LOCAL_HOST" "127.0.0.1"

    sed -i "s@localhost:9200@${TMP_ELK_FBT_SETUP_ES_HOST}:${TMP_ELK_FBT_SETUP_ES_HTTP_PORT}@g" filebeat.yml

	# 移动etc
	mv *.yml ${TMP_ELK_FBT_SETUP_ETC_DIR}

	# 授权权限，否则无法写入
	chown -R elk:elk ${TMP_ELK_FBT_SETUP_LNK_ETC_DIR}
	
	return $?
}

##########################################################################################################

# 4-启动软件
function boot_filebeat()
{
	cd ${TMP_ELK_FBT_SETUP_DIR}
	
	# 验证安装
    bin/filebeat version

	# 当前启动命令
	su - elk -c "cd ${TMP_ELK_FBT_SETUP_DIR} && nohup bin/filebeat -e -c config/filebeat.yml -d \"publish\" > logs/boot.log 2>&1 &" 
		
    # 等待启动
    echo "Starting filebeat，Waiting for a moment"
    echo "--------------------------------------------"
    sleep 15

    cat logs/boot.log
    echo "--------------------------------------------"

	# 启动状态检测
	lsof -i:${TMP_ELK_FBT_SETUP_PORT}

	# 添加系统启动命令
    echo_startup_config "filebeat" "${TMP_ELK_FBT_SETUP_DIR}" 'bin/filebeat -e -c config/filebeat.yml -d "publish"' "" "3" "" "elk"
		
	# 授权iptables端口访问
	# echo_soft_port ${TMP_ELK_FBT_SETUP_PORT}

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_filebeat()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_filebeat()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_filebeat()
{
	# 变量覆盖特性，其它方法均可读取
	local TMP_ELK_FBT_SETUP_DIR=${1}
	local TMP_ELK_FBT_CURRENT_DIR=`pwd`
    
	set_env_filebeat 

	setup_filebeat 

	conf_filebeat 

    # down_plugin_filebeat 
    # setup_plugin_filebeat 

	boot_filebeat 

	# reconf_filebeat 

	return $?
}

##########################################################################################################

# x1-下载软件
function down_filebeat()
{
	local TMP_ELK_FBT_SETUP_NEWER="7.8.0"
	set_github_soft_releases_newer_version "TMP_ELK_FBT_SETUP_NEWER" "elastic/beats"
	exec_text_format "TMP_ELK_FBT_SETUP_NEWER" "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-%s-linux-x86_64.tar.gz"
    setup_soft_wget "filebeat" "${TMP_ELK_FBT_SETUP_NEWER}" "exec_step_filebeat"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "FileBeat" "down_filebeat"
