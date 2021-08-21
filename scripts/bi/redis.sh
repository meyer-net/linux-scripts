#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 安装标题：Redis
#------------------------------------------------

# 1-配置环境
function set_environment()
{
    cd ${__DIR}

    soft_yum_check_setup "tcl"
    
    # fix the version upper then 6.0
	soft_yum_check_setup "devtoolset-9-gcc*"
	
    soft_yum_check_setup "devtoolset-9-binutils"
    
    source /opt/rh/devtoolset-9/enable
    
    gcc -v
    
    #??? 解决执行命令后UI退出的问题
    # scl enable devtoolset-9 bash
    echo "source /opt/rh/devtoolset-9/enable" >> /etc/profile

	return $?
}

# 2-安装软件
function setup_redis()
{
	local TMP_RDS_SETUP_DIR=${1}
	local TMP_RDS_CURRENT_DIR=${2}

	## 编译模式
	cd ${TMP_RDS_CURRENT_DIR}
    
    sed -i "s@PREFIX?=/usr/local@PREFIX?=${TMP_RDS_SETUP_DIR}@g" src/Makefile
    
    make -j4 && make -j4 install

	# 创建日志软链
	local TMP_RDS_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/redis
	local TMP_RDS_SETUP_LNK_DATA_DIR=${DATA_DIR}/redis
	local TMP_RDS_SETUP_LOGS_DIR=${TMP_RDS_SETUP_DIR}/logs
	local TMP_RDS_SETUP_DATA_DIR=${TMP_RDS_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_RDS_SETUP_LOGS_DIR}
	rm -rf ${TMP_RDS_SETUP_DATA_DIR}
	mkdir -pv ${TMP_RDS_SETUP_LNK_LOGS_DIR}
	mkdir -pv ${TMP_RDS_SETUP_LNK_DATA_DIR}
	
	ln -sf ${TMP_RDS_SETUP_LNK_LOGS_DIR} ${TMP_RDS_SETUP_LOGS_DIR}
	ln -sf ${TMP_RDS_SETUP_LNK_DATA_DIR} ${TMP_RDS_SETUP_DATA_DIR}

	# 环境变量或软连接
	echo "REDIS_HOME=${TMP_RDS_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$REDIS_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH REDIS_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile
	# ln -sf ${TMP_RDS_SETUP_DIR}/bin/redis /usr/bin/redis

	# 移动编译目录所需文件
	mv redis.conf ${TMP_RDS_SETUP_DIR}/

	# 移除源文件
	cd `dirname ${TMP_RDS_CURRENT_DIR}`
    rm -rf ${TMP_RDS_CURRENT_DIR}

	return $?
}

# 3-设置软件
function conf_redis()
{
	local TMP_RDS_SETUP_DIR=${1}

	cd ${TMP_RDS_SETUP_DIR}
	
	local TMP_RDS_SETUP_LNK_ETC_DIR=${ATT_DIR}/redis
	local TMP_RDS_SETUP_LNK_ETC_PATH=${TMP_RDS_SETUP_LNK_ETC_DIR}/redis.conf
	local TMP_RDS_SETUP_ETC_DIR=${TMP_RDS_SETUP_DIR}/etc

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mkdir -pv ${TMP_RDS_SETUP_LNK_ETC_DIR}
    mv redis.conf ${TMP_RDS_SETUP_LNK_ETC_PATH}

	# 替换原路径链接
	ln -sf ${TMP_RDS_SETUP_LNK_ETC_DIR} ${TMP_RDS_SETUP_ETC_DIR}
    ln -sf ${TMP_RDS_SETUP_LNK_ETC_PATH} /etc/redis.conf

	# 开始配置
    # Set Init Script.
    echo "vm.overcommit_memory=1" >> /etc/sysctl.conf

	local TMP_RDS_SETUP_LOGS_DIR=${TMP_RDS_SETUP_DIR}/logs
    sed -i "s@^logfile.*@logfile \"${TMP_RDS_SETUP_LOGS_DIR}/redis.log\"@g" etc/redis.conf
    
	local TMP_RDS_SETUP_DATA_DIR=${TMP_RDS_SETUP_DIR}/data
    sed -i "s@^dir.*@dir ${TMP_RDS_SETUP_DATA_DIR}@g" etc/redis.conf

    # -- 是否打开 AOF 持久化功能
    sed -i "s@^appendonly.*@appendonly yes@g" etc/redis.conf
    sed -i "s@^daemonize no@daemonize yes@g" etc/redis.conf
    sed -i "s@^bind 127.0.0.1.*@bind * -::*@g" etc/redis.conf
    sed -i "s@^port.*@port 16379@g" etc/redis.conf

	local TMP_RDS_SETUP_AUTH_PWD=""
    rand_str "TMP_RDS_SETUP_AUTH_PWD" 32
    input_if_empty "TMP_RDS_SETUP_AUTH_PWD" "Redis: Please sure ${red}login auth password${reset}"
    # echo "config set requirepass " | redis-cli
    sed -i "s@^# requirepass.*@requirepass ${TMP_RDS_SETUP_AUTH_PWD}@g" etc/redis.conf
    
    sysctl vm.overcommit_memory=1

	return $?
}

# 4-启动软件
function boot_redis()
{
	local TMP_RDS_SETUP_DIR=${1}

	cd ${TMP_RDS_SETUP_DIR}
    	
	# 验证安装
    redis-cli -v

	# 当前启动命令
	nohup redis-cli /etc/redis.conf > logs/boot.log 2>&1 &
	
    # 等待启动
    echo "Starting redis，Waiting for a moment"
    sleep 1

	# 启动状态检测
	lsof -i:16379

	# 添加系统启动命令
    echo_startup_config "redis" "${TMP_RDS_SETUP_DIR}" "redis-cli /etc/redis.conf " "" "1"
		
	# 授权iptables端口访问
	echo_soft_port 16379

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_redis()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_redis()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_redis()
{
	local TMP_RDS_SETUP_DIR=${1}
	local TMP_RDS_CURRENT_DIR=`pwd`
    
	set_environment "${TMP_RDS_SETUP_DIR}"

	setup_redis "${TMP_RDS_SETUP_DIR}" "${TMP_RDS_CURRENT_DIR}"

	conf_redis "${TMP_RDS_SETUP_DIR}"

    # down_plugin_redis "${TMP_RDS_SETUP_DIR}"

	boot_redis "${TMP_RDS_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_redis()
{
    setup_soft_wget "redis" "http://download.redis.io/redis-stable.tar.gz" "exec_step_redis"

	return $?
}

#安装主体
setup_soft_basic "Redis" "down_redis"
