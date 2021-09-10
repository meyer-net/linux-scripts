#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 相关参考：
#		  https://blog.csdn.net/qq_41453285/article/details/105984928
#------------------------------------------------
local TMP_ZMQ_SETUP_PORT=11234

##########################################################################################################

# 1-配置环境
function set_env_zeromq()
{
    cd ${__DIR}

    # soft_yum_check_setup ""

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_zeromq()
{
	cd ${TMP_ZMQ_CURRENT_DIR}

	# 编译模式
	./configure --prefix=${TMP_ZMQ_SETUP_DIR} --without-libsodium
	make -j4 && make -j4 install

	cd ${TMP_ZMQ_SETUP_DIR}
	
	# 环境变量或软连接
	echo "ZEROMQ_HOME=${TMP_ZMQ_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$ZEROMQ_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH ZEROMQ_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

	# 移除源文件
	rm -rf ${TMP_ZMQ_CURRENT_DIR}
	
    # 安装初始

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_zeromq()
{
	cd ${TMP_ZMQ_SETUP_DIR}
	
	return $?
}

##########################################################################################################

# 4-启动软件
function boot_zeromq()
{
	cd ${TMP_ZMQ_SETUP_DIR}
	
	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_zeromq()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_zeromq()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_zeromq()
{
	# 变量覆盖特性，其它方法均可读取
	local TMP_ZMQ_SETUP_DIR=${1}
	local TMP_ZMQ_CURRENT_DIR=`pwd`
    
	set_env_zeromq 

	setup_zeromq 

	conf_zeromq 

    # down_plugin_zeromq 
    # setup_plugin_zeromq 

	boot_zeromq 

	# reconf_zeromq 

	return $?
}

##########################################################################################################

# x1-下载软件
function down_zeromq()
{
	local TMP_ZMQ_SETUP_NEWER="4.3.0"
	set_github_soft_releases_newer_version "TMP_ZMQ_SETUP_NEWER" "zeromq/libzmq"
	exec_text_format "TMP_ZMQ_SETUP_NEWER" "https://github.com/zeromq/libzmq/releases/download/v%s/zeromq-%s.tar.gz"
    setup_soft_wget "zeromq" "${TMP_ZMQ_SETUP_NEWER}" "exec_step_zeromq"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "ZeroMQ" "down_zeromq"
