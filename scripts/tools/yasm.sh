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
function setup_yasm()
{
	local TMP_YASM_SETUP_DIR=${1}
	local TMP_YASM_CURRENT_DIR=`pwd`

	# 编译模式
	./configure --prefix=${TMP_YASM_SETUP_DIR}
	make -j4 && make -j4 install
	
	# 环境变量或软连接
	echo "YASM_HOME=${TMP_YASM_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$YASM_HOME/bin:$PATH' >> /etc/profile
	echo "export PATH YASM_HOME" >> /etc/profile
	source /etc/profile

	# 移除源文件
	rm -rf ${TMP_YASM_CURRENT_DIR}

	return $?
}

# 3-设置软件
function conf_yasm()
{
	cd ${1}

	return $?
}

# 4-启动软件
function boot_yasm()
{
	local TMP_TL_YASM_SETUP_DIR=${1}

	cd ${TMP_TL_YASM_SETUP_DIR}
	
	# 验证安装
    yasm --version

	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_yasm()
{
	local TMP_TL_YASM_SETUP_DIR=${1}
    
	set_environment "${TMP_TL_YASM_SETUP_DIR}"

	setup_yasm "${TMP_TL_YASM_SETUP_DIR}"

	conf_yasm "${TMP_TL_YASM_SETUP_DIR}"

	boot_yasm "${TMP_TL_YASM_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_yasm()
{
	TMP_TL_YASM_SETUP_NEWER="1.3.0"
	set_newer_by_url_list_link_date "TMP_TL_YASM_SETUP_NEWER" "http://www.tortall.net/projects/yasm/releases/" "yasm-.*.tar.gz"
	exec_text_format "TMP_TL_YASM_SETUP_NEWER" "http://www.tortall.net/projects/yasm/releases/%s"
    setup_soft_wget "yasm" "${TMP_TL_YASM_SETUP_NEWER}" "exec_step_yasm"

	return $?
}

#安装主体
setup_soft_basic "Yasm" "down_yasm"
