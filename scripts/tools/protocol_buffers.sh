#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
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
	make -j4 && make -j4 install
	
	# 环境变量或软连接
	echo "PROTOCOL_BUFFERS_HOME=${TMP_PROTOCOL_BUFFERS_SETUP_DIR}" >> /etc/profile
	echo 'PKG_CONFIG_PATH=$PROTOCOL_BUFFERS_HOME/lib/pkgconfig/' >> /etc/profile
	echo 'PATH=$PROTOCOL_BUFFERS_HOME/bin:$PATH' >> /etc/profile
	echo "export PATH PROTOCOL_BUFFERS_HOME" >> /etc/profile
	source /etc/profile

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
