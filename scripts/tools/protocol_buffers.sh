#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

# 1-配置环境
function set_environment()
{	
	return $?
}

# 2-安装软件
function setup_protocol_buffers()
{
	local TMP_PROTOCOL_BUFFERS_SETUP_DIR=${1}
	local TMP_PROTOCOL_BUFFERS_CURRENT_DIR=`pwd`

	# 编译模式
	./configure --prefix=${TMP_PROTOCOL_BUFFERS_SETUP_DIR}
	sudo make -j4 && make -j4 install

	# # 创建日志软链
	# local TMP_TL_PB_LNK_LOGS_DIR=${LOGS_DIR}/protocolbuffers
	# local TMP_TL_PB_LNK_DATA_DIR=${DATA_DIR}/protocolbuffers
	# local TMP_TL_PB_LOGS_DIR=${TMP_TL_PB_SETUP_DIR}/logs
	# local TMP_TL_PB_DATA_DIR=${TMP_TL_PB_SETUP_DIR}/data

	# # 先清理文件，再创建文件
	# rm -rf ${TMP_TL_PB_LOGS_DIR}
	# rm -rf ${TMP_TL_PB_DATA_DIR}
	# mkdir -pv ${TMP_TL_PB_LNK_LOGS_DIR}
	# mkdir -pv ${TMP_TL_PB_LNK_DATA_DIR}

	# ln -sf ${TMP_TL_PB_LNK_LOGS_DIR} ${TMP_TL_PB_LOGS_DIR}
	# ln -sf ${TMP_TL_PB_LNK_DATA_DIR} ${TMP_TL_PB_DATA_DIR}
	
	# 环境变量或软连接
	echo "PROTOCOL_BUFFERS_HOME=${TMP_PROTOCOL_BUFFERS_SETUP_DIR}" >> /etc/profile
	echo 'PKG_CONFIG_PATH=$PROTOCOL_BUFFERS_HOME/lib/pkgconfig/' >> /etc/profile
	echo 'PATH=$PROTOCOL_BUFFERS_HOME/bin:$PATH' >> /etc/profile
	echo "export PATH PROTOCOL_BUFFERS_HOME" >> /etc/profile
	source /etc/profile
	# ln -sf ${TMP_TL_PB_SETUP_DIR}/bin/protocolbuffers /usr/bin/protocolbuffers

	# 移除源文件
	rm -rf ${TMP_PROTOCOL_BUFFERS_CURRENT_DIR}

	return $?
}

# 3-设置软件
function conf_protocol_buffers()
{
	cd ${1}

	return $?
}

# 4-启动软件
function boot_protocol_buffers()
{
	local TMP_TL_PB_SETUP_DIR=${1}

	cd ${TMP_TL_PB_SETUP_DIR}
	
	# 验证安装
    protoc --version

    # echo_startup_config "protocol_buffers" "${TMP_TL_PB_SETUP_DIR}" "bin/protocol_buffers" "" "100"

	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_protocol_buffers()
{
	local TMP_TL_PB_SETUP_DIR=${1}
    
	set_environment "${TMP_TL_PB_SETUP_DIR}"

	setup_protocol_buffers "${TMP_TL_PB_SETUP_DIR}"

	conf_protocol_buffers "${TMP_TL_PB_SETUP_DIR}"

    # down_plugin_protocol_buffers "${TMP_TL_PB_SETUP_DIR}"

	boot_protocol_buffers "${TMP_TL_PB_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_protocol_buffers()
{
	TMP_TL_PB_SETUP_NEWER="3.13.0"
	set_github_soft_releases_newer_version "TMP_TL_PB_SETUP_NEWER" "protocolbuffers/protobuf"
	exec_text_format "TMP_TL_PB_SETUP_NEWER" "https://github.com/protocolbuffers/protobuf/releases/download/v%s/protobuf-cpp-%s.tar.gz"
    setup_soft_wget "protocolbuffers" "${TMP_TL_PB_SETUP_NEWER}" "exec_step_protocol_buffers"

	return $?
}

#安装主体
setup_soft_basic "ProtocolBuffers" "down_protocol_buffers"
