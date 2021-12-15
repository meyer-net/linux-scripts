#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 参考：https://docs.jumpserver.org/zh/master/install/setup_by_fast/
#------------------------------------------------
local TMP_JMS_SETUP_HTTP_PORT=10080
local TMP_JMS_SETUP_HTTPS_PORT=10443
local TMP_JMS_SETUP_SSH_PORT=22222
local TMP_JMS_SETUP_RDP_PORT=33389
local TMP_JMS_SETUP_RDS_HOST=
local TMP_JMS_SETUP_RDS_PORT=16379
local TMP_JMS_SETUP_RDS_PWD=
local TMP_JMS_SETUP_DB_HOST="${LOCAL_HOST}"
local TMP_JMS_SETUP_DB_PORT=13306

    
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
    input_if_empty "TMP_JMS_SETUP_DB_HOST" "JumpServer.Mysql.Pre: Please ender ${green}mysql host address${reset}，or type enter to setup docker-image"
    set_if_equals "TMP_JMS_SETUP_DB_HOST" "LOCAL_HOST" "127.0.0.1"

    if [ "${TMP_JMS_SETUP_DB_HOST}" == "" ] ; then
        echo "JumpServer.Mysql.Pre: Jumpserver typed local docker-image mode"
    else
        local TMP_JMS_SETUP_DBNAME="jumpserver"
        local TMP_JMS_SETUP_DBUNAME="jumpserver"
        # 不能用&，否则会被识别成读取前一个值
        local TMP_JMS_SETUP_DBPWD="jms%SVR^m${LOCAL_ID}~"

        #???如果设定的DB用户无法访问mysql，则需要修改为root用户（疑似哪里缺失权限）
        input_if_empty "TMP_JMS_SETUP_DBNAME" "JumpServer.Mysql.Pre: Please ender ${green}mysql database name${reset} of '${TMP_JMS_SETUP_DB_HOST}' for jumpserver"
        input_if_empty "TMP_JMS_SETUP_DBUNAME" "JumpServer.Mysql.Pre: Please ender ${green}mysql user name${reset} of '${TMP_JMS_SETUP_DB_HOST}:${TMP_JMS_SETUP_DBNAME}' for jumpserver"
        input_if_empty "TMP_JMS_SETUP_DBPWD" "JumpServer.Mysql.Pre: Please ender ${green}mysql password${reset} of '${TMP_JMS_SETUP_DBUNAME}@${TMP_JMS_SETUP_DB_HOST}:${TMP_JMS_SETUP_DBNAME}' for jumpserver"
            
        local TMP_JMS_SETUP_SCRIPTS="CREATE DATABASE ${TMP_JMS_SETUP_DBNAME} DEFAULT CHARACTER SET UTF8 COLLATE UTF8_GENERAL_CI;  \
        GRANT ALL PRIVILEGES ON ${TMP_JMS_SETUP_DBNAME}.* to '${TMP_JMS_SETUP_DBUNAME}'@'%' identified by '${TMP_JMS_SETUP_DBPWD}' WITH GRANT OPTION;  \
        GRANT ALL PRIVILEGES ON ${TMP_JMS_SETUP_DBNAME}.* to '${TMP_JMS_SETUP_DBUNAME}'@'localhost' identified by '${TMP_JMS_SETUP_DBPWD}' WITH GRANT OPTION;  \
        FLUSH PRIVILEGES;"

        if [ "${TMP_JMS_SETUP_DB_HOST}" == "127.0.0.1" ] || [ "${TMP_JMS_SETUP_DB_HOST}" == "localhost" ]; then
            echo "JumpServer.Mysql.Pre: Start to init jumpserver database by ${green}root user${reset} of mysql"
            mysql -h${TMP_JMS_SETUP_DB_HOST} -P${TMP_JMS_SETUP_DB_PORT} -uroot -p -e"
            ${TMP_JMS_SETUP_SCRIPTS}
            exit" #--connect-expired-password
        else
            echo "JumpServer.Mysql.Pre: Please execute ${green}mysql scripts${reset} By Follow"
            echo "${TMP_JMS_SETUP_SCRIPTS}"
        fi
        
        sed -i "s@USE_EXTERNAL_MYSQL=0@USE_EXTERNAL_MYSQL=1@g" config-example.txt
        sed -i "s@DB_HOST=.*@DB_HOST=${TMP_JMS_SETUP_DB_HOST}@g" config-example.txt
        sed -i "s@DB_PORT=.*@DB_PORT=${TMP_JMS_SETUP_DB_PORT}@g" config-example.txt
        sed -i "s@DB_USER=.*@DB_USER=${TMP_JMS_SETUP_DBUNAME}@g" config-example.txt
        sed -i "s@DB_PASSWORD=.*@DB_PASSWORD='${TMP_JMS_SETUP_DBPWD}'@g" config-example.txt
        sed -i "s@DB_NAME=.*@DB_NAME=${TMP_JMS_SETUP_DBNAME}@g" config-example.txt
    fi

    # 缓存Redis，???使用外置redis时依旧存在问题
    input_if_empty "TMP_JMS_SETUP_RDS_HOST" "JumpServer.Redis.Pre: Please ender ${green}redis host address${reset}，or type enter to setup docker-image"
    set_if_equals "TMP_JMS_SETUP_RDS_HOST" "LOCAL_HOST" "127.0.0.1"
    
    rand_str "TMP_JMS_SETUP_RDS_PWD" 32
    if [ "${TMP_JMS_SETUP_RDS_HOST}" == "" ] ; then
        echo "JumpServer.Redis.Pre: Jumpserver typed local docker-image mode"
    else
        if [ "${TMP_JMS_SETUP_RDS_HOST}" == "127.0.0.1" ] || [ "${TMP_JMS_SETUP_RDS_HOST}" == "localhost" ]; then
            redis-cli config set stop-writes-on-bgsave-error no
        fi

        input_if_empty "TMP_JMS_SETUP_RDS_PWD" "JumpServer.Redis.Pre: Please ender ${green}redis auth login password${reset} of host address '${green}${TMP_JMS_SETUP_RDS_HOST}${reset}'"

        sed -i "s@USE_EXTERNAL_REDIS=0@USE_EXTERNAL_REDIS=1@g" config-example.txt
        sed -i "s@REDIS_HOST=.*@REDIS_HOST=${TMP_JMS_SETUP_RDS_HOST}@g" config-example.txt
        
    fi
    
    sed -i "s@REDIS_PORT=.*@REDIS_PORT=${TMP_JMS_SETUP_RDS_PORT}@g" config-example.txt
    sed -i "s@REDIS_PASSWORD=.*@REDIS_PASSWORD=${TMP_JMS_SETUP_RDS_PWD}@g" config-example.txt
    
    # Nginx配置
    sed -i "s@HTTP_PORT=.*@HTTP_PORT=${TMP_JMS_SETUP_HTTP_PORT}@g" config-example.txt
    sed -i "s@HTTPS_PORT=.*@HTTPS_PORT=${TMP_JMS_SETUP_HTTPS_PORT}@g" config-example.txt
    sed -i "s@SSH_PORT=.*@SSH_PORT=${TMP_JMS_SETUP_SSH_PORT}@g" config-example.txt
    sed -i "s@RDP_PORT=.*@RDP_PORT=${TMP_JMS_SETUP_RDP_PORT}@g" config-example.txt
    
	return $?
}

##########################################################################################################

# 3-安装软件
function setup_jumpserver()
{
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

	path_not_exists_create `dirname ${TMP_JMS_LOGS_NGINX_DIR}`
	path_not_exists_create `dirname ${TMP_JMS_LOGS_CORE_DIR}`

    if [ "${COUNTRY_CODE}" == "CN" ]; then
        export DOCKER_IMAGE_PREFIX="swr.cn-south-1.myhuaweicloud.com"
    else
        export DOCKER_IMAGE_PREFIX="swr.ap-southeast-1.myhuaweicloud.com"
    fi

    # 开始安装
    bash jmsctl.sh install

    # 等待创建OK
    sleep 5

    local TMP_JMS_LNK_LOGS_DIR=${LOGS_DIR}/jumpserver
	local TMP_JMS_LNK_LOGS_NGINX_DIR=${TMP_JMS_LNK_LOGS_DIR}/nginx
	local TMP_JMS_LNK_LOGS_CORE_DIR=${TMP_JMS_LNK_LOGS_DIR}/core
	local TMP_JMS_LNK_DATA_DIR=${DATA_DIR}/jumpserver

    if [ -d ${TMP_JMS_LOGS_NGINX_DIR} ]; then
        mv ${TMP_JMS_LOGS_NGINX_DIR} ${TMP_JMS_LNK_LOGS_NGINX_DIR}
    else
        mkdir -pv `dirname ${TMP_JMS_LNK_LOGS_NGINX_DIR}`
    fi
    
    if [ -d ${TMP_JMS_LOGS_CORE_DIR} ]; then
        mv ${TMP_JMS_LOGS_CORE_DIR} ${TMP_JMS_LNK_LOGS_CORE_DIR}
    else
        mkdir -pv `dirname ${TMP_JMS_LNK_LOGS_CORE_DIR}`
    fi

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
	local TMP_JMS_LNK_ETC_DIR=${ATT_DIR}/jumpserver
	local TMP_JMS_DATA_DIR=${TMP_JMS_SETUP_DIR}/volume
	local TMP_JMS_ETC_DIR=${TMP_JMS_SETUP_DIR}/config

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mv ${TMP_JMS_ETC_DIR} ${TMP_JMS_LNK_ETC_DIR}

	# 替换原路径链接
	ln -sf ${TMP_JMS_LNK_ETC_DIR} ${TMP_JMS_ETC_DIR}

	# 开始配置
    # docker exec -it jms_redis redis-cli

	return $?
}

function reconf_jumpserver()
{
	local TMP_JMS_ETC_DIR=${TMP_JMS_SETUP_DIR}/config

    # 如果是内置RDS模式    
    if [ "${TMP_JMS_SETUP_RDS_HOST}" == "" ] ; then
        echo "config set stop-writes-on-bgsave-error no" | docker exec -i jms_redis redis-cli -a "${TMP_JMS_SETUP_RDS_PWD}"
    fi
	
	# 验证安装
    echo "Checking jumpserver，Waiting for a moment"
    bash jmsctl.sh check_update

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_jumpserver()
{
	cd ${TMP_JMS_SETUP_DIR}

    # 重启docker
    systemctl restart docker.service

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
	echo_soft_port ${TMP_JMS_SETUP_HTTP_PORT}
	echo_soft_port ${TMP_JMS_SETUP_SSH_PORT}
	echo_soft_port ${TMP_JMS_SETUP_RDP_PORT}

    # 生成web授权访问脚本
    echo_web_service_init_scripts "jumpserver${LOCAL_ID}" "jms${LOCAL_ID}-webui.${SYS_DOMAIN}" ${TMP_JMS_SETUP_HTTP_PORT} "${LOCAL_HOST}"

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
    
	set_env_jumpserver

    # jumpserver 属于先配置再安装，故此处反转
	conf_jumpserver_pre

	setup_jumpserver
    
	conf_jumpserver

    # down_plugin_jumpserver

	boot_jumpserver

    reconf_jumpserver

	return $?
}

# x1-下载软件
function down_jumpserver()
{
	local TMP_JMS_SETUP_NEWER="2.16.0"
	set_github_soft_releases_newer_version "TMP_JMS_SETUP_NEWER" "jumpserver/installer"
	exec_text_format "TMP_JMS_SETUP_NEWER" "https://github.com/jumpserver/installer/releases/download/v%s/jumpserver-installer-v%s.tar.gz"    
    setup_soft_wget "jumpserver" "${TMP_JMS_SETUP_NEWER}" "exec_step_jumpserver"

	return $?
}

#安装主体
setup_soft_basic "Jumpserver" "down_jumpserver"