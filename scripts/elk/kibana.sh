#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 相关参考：
#		  
#------------------------------------------------
local TMP_ELK_KBN_SETUP_HTTP_PORT=15601
local TMP_ELK_KBN_SETUP_ES_PORT=19200

##########################################################################################################

# 1-配置环境
function set_env_kibana()
{
    cd ${__DIR}

    # 安装插件需要提前安装nodejs
    # source scripts/lang/nodejs.sh

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_kibana()
{
	## 直装模式
	cd `dirname ${TMP_ELK_KBN_CURRENT_DIR}`

	mv ${TMP_ELK_KBN_CURRENT_DIR} ${TMP_ELK_KBN_SETUP_DIR}

	cd ${TMP_ELK_KBN_SETUP_DIR}

	# 创建日志软链
	local TMP_ELK_KBN_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/kibana
	local TMP_ELK_KBN_SETUP_LNK_DATA_DIR=${DATA_DIR}/kibana
	local TMP_ELK_KBN_SETUP_LOGS_DIR=${TMP_ELK_KBN_SETUP_DIR}/logs
	local TMP_ELK_KBN_SETUP_DATA_DIR=${TMP_ELK_KBN_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_ELK_KBN_SETUP_LOGS_DIR}
	rm -rf ${TMP_ELK_KBN_SETUP_DATA_DIR}
	mkdir -pv ${TMP_ELK_KBN_SETUP_LNK_LOGS_DIR}
	mkdir -pv ${TMP_ELK_KBN_SETUP_LNK_DATA_DIR}
	
	ln -sf ${TMP_ELK_KBN_SETUP_LNK_LOGS_DIR} ${TMP_ELK_KBN_SETUP_LOGS_DIR}
	ln -sf ${TMP_ELK_KBN_SETUP_LNK_DATA_DIR} ${TMP_ELK_KBN_SETUP_DATA_DIR}

	# 环境变量或软连接
	echo "KIBANA_HOME=${TMP_ELK_KBN_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$KIBANA_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH KIBANA_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

	# 授权权限，否则无法写入
	create_user_if_not_exists elk elk
	chown -R elk:elk ${TMP_ELK_KBN_SETUP_DIR}
	chown -R elk:elk ${TMP_ELK_KBN_SETUP_LNK_LOGS_DIR}
	chown -R elk:elk ${TMP_ELK_KBN_SETUP_LNK_DATA_DIR}
	
    # 安装初始

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_kibana()
{
	cd ${TMP_ELK_KBN_SETUP_DIR}
	
	local TMP_ELK_KBN_SETUP_LNK_ETC_DIR=${ATT_DIR}/kibana
	local TMP_ELK_KBN_SETUP_ETC_DIR=${TMP_ELK_KBN_SETUP_DIR}/config

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mv ${TMP_ELK_KBN_SETUP_ETC_DIR} ${TMP_ELK_KBN_SETUP_LNK_ETC_DIR}

	ln -sf ${TMP_ELK_KBN_SETUP_LNK_ETC_DIR} ${TMP_ELK_KBN_SETUP_ETC_DIR}

	# 开始配置
	local TMP_ELK_KBN_SETUP_ES_HOST="${LOCAL_HOST}"
    input_if_empty "TMP_ELK_KBN_SETUP_ES_HOST" "Kibana: Please ender your ${red}elasticsearch host address${reset} like '${LOCAL_HOST}'"
	set_if_equals "TMP_ELK_KBN_SETUP_ES_HOST" "LOCAL_HOST" "127.0.0.1"

	local TMP_ELK_KBN_SETUP_ES_USER="root"
    input_if_empty "TMP_ELK_KBN_SETUP_ES_USER" "Kibana: Please ender your ${red}elasticsearch user${reset} of '${TMP_ELK_KBN_SETUP_ES_HOST}'"

	local TMP_ELK_KBN_SETUP_ES_PASSWD="es%DB!m${LOCAL_ID}_"
    input_if_empty "TMP_ELK_KBN_SETUP_ES_PASSWD" "Kibana: Please ender your ${red}elasticsearch password${reset} of '${TMP_ELK_KBN_SETUP_ES_HOST}'"

    sed -i "s@[#]*server\.port@.*server.port: ${TMP_ELK_KBN_SETUP_HTTP_PORT}@g" config/kibana.yml
    sed -i "s@[#]*server\.host.*@server.host: \"0.0.0.0\"@g" config/kibana.yml
    sed -i "s@[#]*elasticsearch\.hosts:.*@elasticsearch.hosts: \"[http://${TMP_ELK_KBN_SETUP_ES_HOST}:${TMP_ELK_KBN_SETUP_ES_PORT}]\"@g" config/kibana.yml
    sed -i "s@[#]*elasticsearch\.username:.*@elasticsearch.username: \"${TMP_ELK_KBN_SETUP_ES_USER}\"@g" config/kibana.yml
    sed -i "s@[#]*elasticsearch\.password:.*@elasticsearch.password: \"${TMP_ELK_KBN_SETUP_ES_PASSWD}\"@g" config/kibana.yml
	
	chown -R elk:elk ${TMP_ELK_KBN_SETUP_LNK_ETC_DIR}

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_kibana()
{
	cd ${TMP_ELK_KBN_SETUP_DIR}
	
	# 验证安装
    bin/kibana -V --allow-root

	# 当前启动命令
	su - elk -c "cd ${TMP_ELK_KBN_SETUP_DIR} && nohup bin/kibana > logs/boot.log 2>&1 &"
	
    # 等待启动
    echo "Starting kibana，Waiting for a moment"
    echo "--------------------------------------------"
    sleep 15

    cat logs/boot.log
    echo "--------------------------------------------"

	# 启动状态检测
	lsof -i:${TMP_ELK_KBN_SETUP_HTTP_PORT}

	# 添加系统启动命令
    echo_startup_config "kibana" "${TMP_ELK_KBN_SETUP_DIR}" "bin/kibana" "" "3" "" "elk"
	
	# 授权iptables端口访问
	echo_soft_port ${TMP_ELK_KBN_SETUP_HTTP_PORT}
	
    # 生成web授权访问脚本
    echo_web_service_init_scripts "kibana${LOCAL_ID}" "kibana${LOCAL_ID}-webui.${SYS_DOMAIN}" ${TMP_ELK_KBN_SETUP_HTTP_PORT} "${LOCAL_HOST}"

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_kibana()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_kibana()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_kibana()
{
	# 变量覆盖特性，其它方法均可读取
	local TMP_ELK_KBN_SETUP_DIR=${1}
	local TMP_ELK_KBN_CURRENT_DIR=`pwd`
    
	set_env_kibana 

	setup_kibana 

	conf_kibana 

    # down_plugin_kibana 
    # setup_plugin_kibana 

	boot_kibana 

	# reconf_kibana 

	return $?
}

##########################################################################################################

# x1-下载软件
function down_kibana()
{
	local TMP_ELK_KBN_SETUP_NEWER="7.8.0"
	set_github_soft_releases_newer_version "TMP_ELK_KBN_SETUP_NEWER" "elastic/kibana"
	exec_text_format "TMP_ELK_KBN_SETUP_NEWER" "https://artifacts.elastic.co/downloads/kibana/kibana-%s-linux-x86_64.tar.gz"
    setup_soft_wget "kibana" "${TMP_ELK_KBN_SETUP_NEWER}" "exec_step_kibana"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "Kibana" "down_kibana"
