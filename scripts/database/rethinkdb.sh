#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 相关参考：
#		  https://rethinkdb.com/docs/install/centos/
#------------------------------------------------
# Listening for administrative HTTP connections on port 8080
local TMP_RTDB_SETUP_HTTP_PORT=18080
# Listening for client driver connections on port 28015
local TMP_RTDB_SETUP_CDRV_PORT=28015
# Listening for intracluster connections on port 29015
local TMP_RTDB_SETUP_ICLS_PORT=29015

##########################################################################################################

# 1-配置环境
function set_env_rethinkdb()
{
    cd ${__DIR}

    soft_yum_check_setup "openssl-devel,libcurl-devel,wget,tar,m4,git-core,boost-static,m4,gcc-c++,npm,ncurses-devel,which,make,ncurses-static,zlib-devel,zlib-static,bzip2,patch"

    soft_yum_check_setup "epel-release,protobuf-devel,protobuf-static,jemalloc-devel"
	
	# yum不一定能安装成功，jemalloc-devel，改用rpm
	soft_yum_check_action "soft_yum_check_setup" "soft_rpm_check_action 'jemalloc' 'setup_jemalloc' 'Jemalloc was installed'"
    
	return $?
}

##########################################################################################################

# 1-配置环境
function setup_jemalloc()
{
	local TMP_JML_SETUP_NEWER="jemalloc-3.6.0-1.el${OS_VERS}.x86_64.rpm"
	set_url_list_newer_href_link_filename "TMP_JML_SETUP_NEWER" "https://download-ib01.fedoraproject.org/pub/epel/${OS_VERS}/x86_64/Packages/j/" "jemalloc-().el${OS_VERS}.x86_64.rpm"
	while_wget "--content-disposition https://download-ib01.fedoraproject.org/pub/epel/${OS_VERS}/x86_64/Packages/j/${TMP_JML_SETUP_NEWER}" "rpm -ivh ${TMP_JML_SETUP_NEWER}"
	
	# 等待jemalloc生效，有待测试。同脚本，手动尝试反而OK（也有可能网络问题，编译会安装npm相关依赖包）
	echo "RethinkDB：Watting for jemalloc active"
	sleep 15
	
	return $?
}

# 2-安装软件
function setup_rethinkdb()
{
	cd ${TMP_RTDB_CURRENT_DIR}

	# 编译模式
	./configure --prefix=${TMP_RTDB_SETUP_DIR} --allow-fetch --dynamic jemalloc
	make -j4 && make -j4 install

	cd ${TMP_RTDB_SETUP_DIR}

	# 创建日志软链
	local TMP_RTDB_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/rethinkdb
	local TMP_RTDB_SETUP_LNK_DATA_DIR=${DATA_DIR}/rethinkdb
	local TMP_RTDB_SETUP_LOGS_DIR=${TMP_RTDB_SETUP_DIR}/logs
	local TMP_RTDB_SETUP_DATA_DIR=${TMP_RTDB_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_RTDB_SETUP_LOGS_DIR}
	rm -rf ${TMP_RTDB_SETUP_DATA_DIR}
	mkdir -pv ${TMP_RTDB_SETUP_LNK_LOGS_DIR}
	mkdir -pv ${TMP_RTDB_SETUP_LNK_DATA_DIR}
	
	ln -sf ${TMP_RTDB_SETUP_LNK_LOGS_DIR} ${TMP_RTDB_SETUP_LOGS_DIR}
	ln -sf ${TMP_RTDB_SETUP_LNK_DATA_DIR} ${TMP_RTDB_SETUP_DATA_DIR}
	
	# 环境变量或软连接
	echo "RETHINKDB_HOME=${TMP_RTDB_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$RETHINKDB_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH RETHINKDB_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

	# 授权权限，否则无法写入
	# create_user_if_not_exists rethinkdb rethinkdb
	# chown -R rethinkdb:rethinkdb ${TMP_RTDB_SETUP_LNK_LOGS_DIR}
	# chown -R rethinkdb:rethinkdb ${TMP_RTDB_SETUP_LNK_DATA_DIR}

	# 移除源文件
	rm -rf ${TMP_RTDB_CURRENT_DIR}
	
    # 安装初始

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_rethinkdb()
{
	cd ${TMP_RTDB_SETUP_DIR}
	
	local TMP_RTDB_SETUP_LNK_ETC_DIR=${ATT_DIR}/rethinkdb
	local TMP_RTDB_SETUP_ETC_DIR=${TMP_RTDB_SETUP_DIR}/etc

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mv ${TMP_RTDB_SETUP_ETC_DIR} ${TMP_RTDB_SETUP_LNK_ETC_DIR}

	ln -sf ${TMP_RTDB_SETUP_LNK_ETC_DIR} ${TMP_RTDB_SETUP_ETC_DIR}

	# 开始配置
	sed -i "s@^default_driver_port=28015@default_driver_port=${TMP_RTDB_SETUP_CDRV_PORT}@g" etc/init.d/rethinkdb
	sed -i "s@^default_cluster_port=29015@default_cluster_port=${TMP_RTDB_SETUP_ICLS_PORT}@g" etc/init.d/rethinkdb
	sed -i "s@^default_http_port=8080@default_http_port=${TMP_RTDB_SETUP_HTTP_PORT}@g" etc/init.d/rethinkdb

	cp etc/rethinkdb/default.conf.sample etc/rethinkdb/default.conf
	sed -i "s@^# bind=127.0.0.1@bind=0.0.0.0@g" etc/rethinkdb/default.conf
	sed -i "s@^# driver-port=28015@driver-port=${TMP_RTDB_SETUP_CDRV_PORT}@g" etc/rethinkdb/default.conf
	sed -i "s@^# cluster-port=29015@cluster-port=${TMP_RTDB_SETUP_ICLS_PORT}@g" etc/rethinkdb/default.conf
	sed -i "s@^# http-port=8080@http-port=${TMP_RTDB_SETUP_HTTP_PORT}@g" etc/rethinkdb/default.conf

	# 授权权限，否则无法写入
	# chown -R rethinkdb:rethinkdb ${TMP_RTDB_SETUP_LNK_ETC_DIR}

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_rethinkdb()
{
	cd ${TMP_RTDB_SETUP_DIR}
	
	# 验证安装
    bin/rethinkdb -v

	# 当前启动命令(其db与日志需指定方可)
	nohup bin/rethinkdb --bind all -d data/default --log-file logs/default.log > logs/boot.log 2>&1 &
	
    # 等待启动
    echo "Starting rethinkdb，Waiting for a moment"
    echo "--------------------------------------------"
    sleep 5

    cat logs/boot.log
    echo "--------------------------------------------"

	# 启动状态检测
	lsof -i:${TMP_RTDB_SETUP_HTTP_PORT}
	lsof -i:${TMP_RTDB_SETUP_CDRV_PORT}
	lsof -i:${TMP_RTDB_SETUP_ICLS_PORT}

	# 添加系统启动命令
    echo_startup_config "rethinkdb_default" "${TMP_RTDB_SETUP_DIR}" "bin/rethinkdb --bind all -d data/default --log-file logs/default.log" "" "1"

	# 授权iptables端口访问
	echo_soft_port ${TMP_RTDB_SETUP_HTTP_PORT}
	echo_soft_port ${TMP_RTDB_SETUP_CDRV_PORT}
	echo_soft_port ${TMP_RTDB_SETUP_ICLS_PORT}

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_rethinkdb()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_rethinkdb()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_rethinkdb()
{
	# 变量覆盖特性，其它方法均可读取
	local TMP_RTDB_SETUP_DIR=${1}
	local TMP_RTDB_CURRENT_DIR=`pwd`
    
	set_env_rethinkdb 

	setup_rethinkdb 

	conf_rethinkdb 

    # down_plugin_rethinkdb 
    # setup_plugin_rethinkdb 

	boot_rethinkdb 

	# reconf_rethinkdb 

	return $?
}

##########################################################################################################

# x1-下载软件
function down_rethinkdb()
{
	local TMP_RTDB_SETUP_NEWER="2.4.1"
	set_github_soft_releases_newer_version "TMP_RTDB_SETUP_NEWER" "rethinkdb/rethinkdb"
	exec_text_format "TMP_RTDB_SETUP_NEWER" "https://download.rethinkdb.com/repository/raw/dist/rethinkdb-%s.tgz"
    setup_soft_wget "rethinkdb" "${TMP_RTDB_SETUP_NEWER}" "exec_step_rethinkdb"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "RethinkDB" "down_rethinkdb"
