#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 安装标题：erlang
# 软件名称：erlang
# 软件大写名称：ERLANG
# 软件大写分组与简称：ERL
# 软件安装名称：erlang
# 软件授权用户名称&组：erlang/erlang
#------------------------------------------------

# 1-配置环境
function set_environment()
{
    soft_yum_check_setup "make gcc gcc-c++ kernel-devel m4 ncurses-devel openssl-devel unixODBC unixODBC-devel httpd python-simplejson"

	return $?
}

# 2-安装软件
function setup_erlang()
{
	local TMP_ERL_SETUP_DIR=${1}
	local TMP_ERL_CURRENT_DIR=`pwd`

	# 编译模式
	./configure --prefix=${TMP_ERL_SETUP_DIR} --enable-smp-support --enable-threads --enable-sctp --enable-kernel-poll --enable-hipe --with-ssl --without-javac
	make -j4 && make -j4 install

	# 环境变量或软连接
	echo "ERLANG_HOME=${TMP_ERL_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$ERLANG_HOME/bin:$PATH' >> /etc/profile
	echo "export PATH ERLANG_HOME" >> /etc/profile

    # 重新加载profile文件
	source /etc/profile
	# ln -sf ${TMP_ERL_SETUP_DIR}/bin/erlang /usr/bin/erlang

	return $?
}

# 3-设置软件
function conf_erlang()
{
	cd ${1}

	return $?
}

# 4-启动软件
function boot_erlang()
{
	local TMP_ERL_SETUP_DIR=${1}

	cd ${TMP_ERL_SETUP_DIR}
	
	# 验证安装
    erl -version

	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_erlang()
{
	local TMP_ERL_SETUP_DIR=${1}
    
	set_environment "${TMP_ERL_SETUP_DIR}"

	setup_erlang "${TMP_ERL_SETUP_DIR}"

	conf_erlang "${TMP_ERL_SETUP_DIR}"

	boot_erlang "${TMP_ERL_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_erlang()
{
    #http://erlang.org/download/otp_src_24.0.tar.gz
	TMP_ERL_SETUP_NEWER="otp_src_24.0.tar.gz"
    local TMP_ERL_DOWN_URL_BASE="http://erlang.org/download/"
	set_url_list_newer_href_link_filename "TMP_ERL_SETUP_NEWER" "${TMP_ERL_DOWN_URL_BASE}" "otp_src_().tar.gz"
	exec_text_format "TMP_ERL_SETUP_NEWER" "${TMP_ERL_DOWN_URL_BASE}%s"
    setup_soft_wget "erlang" "${TMP_ERL_SETUP_NEWER}" "exec_step_erlang"

	return $?
}

#安装主体
setup_soft_basic "erlang" "down_erlang"
