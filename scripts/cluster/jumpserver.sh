#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 参考：https://docs.jumpserver.org/zh/master/install/setup_by_fast/
#------------------------------------------------
local TMP_JMS_SETUP_SSH_PORT=22222
local TMP_JMS_SETUP_RDP_PORT=33389

##########################################################################################################

# 1-配置环境
function set_env_jumpserver()
{
    cd ${__DIR}

	return $?
}

##########################################################################################################

# 2-1预配置
function conf_jumpserver_pre()
{
	local TMP_JMS_SETUP_DIR=${1}
	local TMP_JMS_CURRENT_DIR=${2}
	local TMP_JMS_DATA_DIR=${TMP_JMS_SETUP_DIR}/volume
    
    cd ${TMP_JMS_CURRENT_DIR}

    # 修改 Jumpserver 配置文件
    cp config-example.txt config-example.txt.bak

    ## 手动配置
    # 安装配置
    sed -i "s@VOLUME_DIR=.*@VOLUME_DIR=${TMP_JMS_DATA_DIR}@g" config-example.txt
    sed -i "s@DOCKER_DIR=.*@DOCKER_DIR=${SETUP_DIR}/docker_jms@g" config-example.txt
    
    # 密钥配置
    local TMP_JMS_SETUP_SECRET_KEY=""
    local TMP_JMS_SETUP_TOKEN=`cat /proc/sys/kernel/random/uuid`

    rand_str "TMP_JMS_SETUP_SECRET_KEY" 32
    sed -i "s@SECRET_KEY=.*@SECRET_KEY=${TMP_JMS_SETUP_SECRET_KEY}@g" config-example.txt
    sed -i "s@BOOTSTRAP_TOKEN=.*@BOOTSTRAP_TOKEN=${TMP_JMS_SETUP_TOKEN}@g" config-example.txt

    # 生成数据库表结构和初始化数据
    local TMP_JMS_SETUP_DB_HOST=""
    input_if_empty "TMP_JMS_SETUP_DB_HOST" "JumpServer.Mysql.Pre: Please ender ${red}mysql host address${reset}，or type enter to setup docker-image"
    set_if_equals "TMP_JMS_SETUP_DB_HOST" "LOCAL_HOST" "127.0.0.1"

    if [ "${TMP_JMS_SETUP_DB_HOST}" == "" ] ; then
        echo "JumpServer.Mysql.Pre: Jumpserver typed local docker-image mode"
    else
        local TMP_JMS_SETUP_DBNAME="jumpserver"
        local TMP_JMS_SETUP_DBUNAME="jumpserver"
        # 不能用&，否则会被识别成读取前一个值
        local TMP_JMS_SETUP_DBPWD="jms%SVR!m${LOCAL_ID}_"

        input_if_empty "TMP_JMS_SETUP_DBNAME" "JumpServer.Mysql.Pre: Please ender ${red}mysql database name${reset} of '${TMP_JMS_SETUP_DB_HOST}' for jumpserver"
        input_if_empty "TMP_JMS_SETUP_DBUNAME" "JumpServer.Mysql.Pre: Please ender ${red}mysql user name${reset} of '${TMP_JMS_SETUP_DB_HOST}:${TMP_JMS_SETUP_DBNAME}' for jumpserver"
        input_if_empty "TMP_JMS_SETUP_DBPWD" "JumpServer.Mysql.Pre: Please ender ${red}mysql password${reset} of '${TMP_JMS_SETUP_DBUNAME}@${TMP_JMS_SETUP_DB_HOST}:${TMP_JMS_SETUP_DBNAME}' for jumpserver"
            
        local TMP_JMS_SETUP_SCRIPTS="CREATE DATABASE ${TMP_JMS_SETUP_DBNAME} DEFAULT CHARACTER SET UTF8 COLLATE UTF8_GENERAL_CI;  \
        GRANT ALL PRIVILEGES ON ${TMP_JMS_SETUP_DBNAME}.* to '${TMP_JMS_SETUP_DBUNAME}'@'%' identified by '${TMP_JMS_SETUP_DBPWD}';  \
        GRANT ALL PRIVILEGES ON ${TMP_JMS_SETUP_DBNAME}.* to '${TMP_JMS_SETUP_DBUNAME}'@'localhost' identified by '${TMP_JMS_SETUP_DBPWD}';  \
        FLUSH PRIVILEGES;"

        if [ "${TMP_JMS_SETUP_DB_HOST}" == "127.0.0.1" ] || [ "${TMP_JMS_SETUP_DB_HOST}" == "localhost" ] || [ "${TMP_JMS_SETUP_DB_HOST}" == "${LOCAL_HOST}" ] ; then
            echo "JumpServer.Mysql.Pre: Start to init jumpserver database by root user of mysql"
            mysql -h ${TMP_JMS_SETUP_DB_HOST} -uroot -e"
            ${TMP_JMS_SETUP_SCRIPTS}
            exit" --connect-expired-password
        else
            echo "JumpServer.Mysql.Pre: Please execute ${red}mysql scripts${reset} By Follow"
            echo "${TMP_JMS_SETUP_SCRIPTS}"
        fi
        
        sed -i "s@USE_EXTERNAL_MYSQL=0@USE_EXTERNAL_MYSQL=1@g" config-example.txt
        sed -i "s@DB_HOST=.*@DB_HOST=${TMP_JMS_SETUP_DB_HOST}@g" config-example.txt
        sed -i "s@DB_USER=.*@DB_USER=${TMP_JMS_SETUP_DBUNAME}@g" config-example.txt
        sed -i "s@DB_PASSWORD=.*@DB_PASSWORD='${TMP_JMS_SETUP_DBPWD}'@g" config-example.txt
        sed -i "s@DB_NAME=.*@DB_NAME=${TMP_JMS_SETUP_DBNAME}@g" config-example.txt
    fi

    # 缓存Redis，???使用外置redis时依旧存在问题
    local TMP_JMS_SETUP_REDIS_HOST=""
    input_if_empty "TMP_JMS_SETUP_REDIS_HOST" "JumpServer.Redis.Pre: Please ender ${red}redis host address${reset}，or type enter to setup docker-image"
    set_if_equals "TMP_JMS_SETUP_REDIS_HOST" "LOCAL_HOST" "127.0.0.1"
    
    if [ "${TMP_JMS_SETUP_REDIS_HOST}" == "" ] ; then
        echo "JumpServer.Redis.Pre: Jumpserver typed local docker-image mode"
    else
        if [ "${TMP_JMS_SETUP_REDIS_HOST}" == "127.0.0.1" ] || [ "${TMP_JMS_SETUP_REDIS_HOST}" == "localhost" ] || [ "${TMP_JMS_SETUP_REDIS_HOST}" == "${LOCAL_HOST}" ] ; then
            redis-cli config set stop-writes-on-bgsave-error no
        fi

        sed -i "s@USE_EXTERNAL_REDIS=0@USE_EXTERNAL_REDIS=1@g" config-example.txt
        sed -i "s@REDIS_HOST=.*@REDIS_HOST=${TMP_JMS_SETUP_REDIS_HOST}@g" config-example.txt
            
        local TMP_JMS_SETUP_REDIS_PWD=""
        rand_str "TMP_JMS_SETUP_REDIS_PWD" 32
        input_if_empty "TMP_JMS_SETUP_REDIS_PWD" "JumpServer.Redis.Pre: Please ender ${red}redis auth login password${reset} of host address '${green}${TMP_JMS_SETUP_REDIS_HOST}${reset}'"
        sed -i "s@REDIS_PASSWORD=.*@REDIS_PASSWORD=${TMP_JMS_SETUP_REDIS_PWD}@g" config-example.txt
    fi
    
    # Nginx配置
    sed -i "s@SSH_PORT=.*@SSH_PORT=${TMP_JMS_SETUP_SSH_PORT}@g" config-example.txt
    sed -i "s@RDP_PORT=.*@RDP_PORT=${TMP_JMS_SETUP_RDP_PORT}@g" config-example.txt
    
	return $?
}

##########################################################################################################

# 3-安装软件
function setup_jumpserver()
{
	local TMP_JMS_SETUP_DIR=${1}
	local TMP_JMS_CURRENT_DIR=${2}

	## 直装模式
	cd `dirname ${TMP_JMS_CURRENT_DIR}`

	mv ${TMP_JMS_CURRENT_DIR} ${TMP_JMS_SETUP_DIR}

    cd ${TMP_JMS_SETUP_DIR}
    
	# 创建日志软链
	local TMP_JMS_LOGS_DIR=${TMP_JMS_SETUP_DIR}/logs
	local TMP_JMS_LOGS_NGINX_DIR=${TMP_JMS_SETUP_DIR}/volume/nginx/log
	local TMP_JMS_LOGS_CORE_DIR=${TMP_JMS_SETUP_DIR}/volume/core/logs
	local TMP_JMS_DATA_DIR=${TMP_JMS_SETUP_DIR}/volume

	# 先清理文件，再创建文件
	rm -rf ${TMP_JMS_LOGS_NGINX_DIR}
	rm -rf ${TMP_JMS_LOGS_CORE_DIR}
	rm -rf ${TMP_JMS_DATA_DIR}

    if [ "${COUNTRY_CODE}" == "CN" ]; then
        export DOCKER_IMAGE_PREFIX="hub-mirror.c.163.com"
    fi

    # 开始安装
    bash jmsctl.sh install

    local TMP_JMS_LNK_LOGS_DIR=${LOGS_DIR}/jumpserver
	local TMP_JMS_LNK_LOGS_NGINX_DIR=${LOGS_DIR}/jumpserver/nginx
	local TMP_JMS_LNK_LOGS_CORE_DIR=${LOGS_DIR}/jumpserver/core
	local TMP_JMS_LNK_DATA_DIR=${DATA_DIR}/jumpserver

    mkdir -pv ${TMP_JMS_LNK_LOGS_DIR}
	mkdir -pv ${TMP_JMS_LNK_LOGS_NGINX_DIR}
	mkdir -pv ${TMP_JMS_LNK_LOGS_CORE_DIR}
    mkdir -pv `dirname ${TMP_JMS_LOGS_NGINX_DIR}`
    mkdir -pv `dirname ${TMP_JMS_LOGS_CORE_DIR}`
	mv ${TMP_JMS_DATA_DIR} ${TMP_JMS_LNK_DATA_DIR}

    ln -sf ${TMP_JMS_LNK_LOGS_DIR} ${TMP_JMS_LOGS_DIR}
	ln -sf ${TMP_JMS_LNK_LOGS_NGINX_DIR} ${TMP_JMS_LOGS_NGINX_DIR}
	ln -sf ${TMP_JMS_LNK_LOGS_CORE_DIR} ${TMP_JMS_LOGS_CORE_DIR}
	ln -sf ${TMP_JMS_LNK_DATA_DIR} ${TMP_JMS_DATA_DIR}

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_jumpserver()
{
	local TMP_JMS_SETUP_DIR=${1}
	local TMP_JMS_LNK_ETC_DIR=${ATT_DIR}/jumpserver
	local TMP_JMS_DATA_DIR=${TMP_JMS_SETUP_DIR}/volume
	local TMP_JMS_ETC_DIR=${TMP_JMS_SETUP_DIR}/config

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mv ${TMP_JMS_ETC_DIR} ${TMP_JMS_LNK_ETC_DIR}

	# 替换原路径链接
	ln -sf ${TMP_JMS_LNK_ETC_DIR} ${TMP_JMS_ETC_DIR}

	# 开始配置

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_jumpserver()
{
	local TMP_JMS_SETUP_DIR=${1}

	cd ${TMP_JMS_SETUP_DIR}

    # 重启docker
    systemctl restart docker.service
	
	# 验证安装
    echo "Checking jumpserver，Waiting for a moment"
    bash jmsctl.sh check_update

	# 当前启动命令
	nohup bash jmsctl.sh start > logs/boot.log 2>&1 &
	
    # 等待启动
    echo "Starting jumpserver，Waiting for a moment"
    sleep 60

	# 启动状态检测
	bash jmsctl.sh status

	# 添加系统启动命令
    echo_startup_config "jumpserver" "${TMP_JMS_SETUP_DIR}" "bash jmsctl.sh start" "" "100"
	
	# 授权iptables端口访问
	echo_soft_port 80
	echo_soft_port ${TMP_JMS_SETUP_SSH_PORT}
	echo_soft_port ${TMP_JMS_SETUP_RDP_PORT}

    # 生成web授权访问脚本
    echo_web_service_init_scripts "jumpserver${LOCAL_ID}" "jms${LOCAL_ID}-webui.${SYS_DOMAIN}" 80 "${LOCAL_HOST}"

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_jumpserver()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_jumpserver()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_jumpserver()
{
	local TMP_JMS_SETUP_DIR=${1}
	local TMP_JMS_CURRENT_DIR=`pwd`
    
	set_env_jumpserver "${TMP_JMS_SETUP_DIR}"

    # jumpserver 属于先配置再安装，故此处反转
	conf_jumpserver_pre "${TMP_JMS_SETUP_DIR}" "${TMP_JMS_CURRENT_DIR}"

	setup_jumpserver "${TMP_JMS_SETUP_DIR}" "${TMP_JMS_CURRENT_DIR}"
    
	conf_jumpserver "${TMP_JMS_SETUP_DIR}"

    # down_plugin_jumpserver "${TMP_JMS_SETUP_DIR}"

	boot_jumpserver "${TMP_JMS_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_jumpserver()
{
	local TMP_JMS_SETUP_NEWER="2.13.0"
	set_github_soft_releases_newer_version "TMP_JMS_SETUP_NEWER" "jumpserver/installer"
	exec_text_format "TMP_JMS_SETUP_NEWER" "https://github.com/jumpserver/installer/releases/download/v%s/jumpserver-installer-v%s.tar.gz"    
    setup_soft_wget "jumpserver" "${TMP_JMS_SETUP_NEWER}" "exec_step_jumpserver"

	return $?
}

#安装主体
setup_soft_basic "Jumpserver" "down_jumpserver"