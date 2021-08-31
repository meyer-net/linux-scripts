#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

# 1-配置环境
function set_env_zeromq()
{	
	return $?
}

# 2-安装软件
function setup_zeromq()
{
	local TMP_ZEROMQ_SETUP_DIR=${1}
	local TMP_ZEROMQ_CURRENT_DIR=`pwd`

	# 编译模式
	./configure --prefix=${TMP_ZEROMQ_SETUP_DIR} --without-libsodium
	sudo make -j4 && make -j4 install

	cd ${TMP_ZEROMQ_SETUP_DIR}

	# # 创建日志软链
	# local TMP_BI_ZM_LNK_LOGS_DIR=${LOGS_DIR}/zeromq
	# local TMP_BI_ZM_LNK_DATA_DIR=${DATA_DIR}/zeromq
	# local TMP_BI_ZM_LOGS_DIR=${TMP_BI_ZM_SETUP_DIR}/logs
	# local TMP_BI_ZM_DATA_DIR=${TMP_BI_ZM_SETUP_DIR}/data

	# # 先清理文件，再创建文件
	# rm -rf ${TMP_BI_ZM_LOGS_DIR}
	# rm -rf ${TMP_BI_ZM_DATA_DIR}
	# mkdir -pv ${TMP_BI_ZM_LNK_LOGS_DIR}
	# mkdir -pv ${TMP_BI_ZM_LNK_DATA_DIR}

	# ln -sf ${TMP_BI_ZM_LNK_LOGS_DIR} ${TMP_BI_ZM_LOGS_DIR}
	# ln -sf ${TMP_BI_ZM_LNK_DATA_DIR} ${TMP_BI_ZM_DATA_DIR}
	
	# # 环境变量或软连接
	# echo "ZEROMQ_HOME=${TMP_ZEROMQ_SETUP_DIR}" >> /etc/profile
	# echo 'PATH=$ZEROMQ/bin:$PATH' >> /etc/profile
	# echo "export PATH ZEROMQ_HOME" >> /etc/profile
	# source /etc/profile
	# ln -sf ${TMP_BI_ZM_SETUP_DIR}/bin/zeromq /usr/bin/zeromq

	# 移除源文件
	rm -rf ${TMP_ZEROMQ_CURRENT_DIR}

	return $?
}

# 3-设置软件
function conf_zeromq()
{
	cd ${1}

	return $?
}

# 4-启动软件
function boot_zeromq()
{
	local TMP_BI_ZM_SETUP_DIR=${1}

	cd ${TMP_BI_ZM_SETUP_DIR}

    # echo_startup_config "zeromq" "${TMP_BI_ZM_SETUP_DIR}" "bin/zeromq" "" "100"

	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_zeromq()
{
	local TMP_BI_ZM_SETUP_DIR=${1}
    
	set_env_zeromq "${TMP_BI_ZM_SETUP_DIR}"

	setup_zeromq "${TMP_BI_ZM_SETUP_DIR}"

	conf_zeromq "${TMP_BI_ZM_SETUP_DIR}"

	boot_zeromq "${TMP_BI_ZM_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_zeromq()
{
	TMP_BI_ZM_SETUP_NEWER="4.3.0"
	set_github_soft_releases_newer_version "TMP_BI_ZM_SETUP_NEWER" "zeromq/libzmq"
    
	exec_text_format "TMP_BI_ZM_SETUP_NEWER" "https://github.com/zeromq/libzmq/releases/download/v%s/zeromq-%s.tar.gz"
    setup_soft_wget "zeromq" "${TMP_BI_ZM_SETUP_NEWER}" "exec_step_zeromq"

	return $?
}

#安装主体
setup_soft_basic "ZeroMQ" "down_zeromq"
