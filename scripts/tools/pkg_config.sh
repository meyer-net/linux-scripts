#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------

# 1-配置环境
function set_environment()
{	
	configure: error: Either a previously installed pkg-config or "glib-2.0 >= 2.16" could not be found. Please set GLIB_CFLAGS and GLIB_LIBS to the correct values or pass --with-internal-glib to configure to use the bundled copy.
	return $?
}

# 2-安装软件
function setup_pkg_config()
{
	local TMP_PKG_CONFIG_SETUP_DIR=${1}
	local TMP_PKG_CONFIG_CURRENT_DIR=`pwd`

	# 编译模式
	./configure --prefix=${TMP_PKG_CONFIG_SETUP_DIR} --with-internal-glib
	make -j4 && make -j4 install
	
	# 环境变量或软连接
	echo "PKG_CONFIG_HOME=${TMP_PKG_CONFIG_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$PKG_CONFIG_HOME/bin:$PATH' >> /etc/profile
	echo "export PATH PKG_CONFIG_HOME" >> /etc/profile
	source /etc/profile

	# 移除源文件
	rm -rf ${TMP_PKG_CONFIG_CURRENT_DIR}

	return $?
}

# 3-设置软件
function conf_pkg_config()
{
	cd ${1}

	return $?
}

# 4-启动软件
function boot_pkg_config()
{
	local TMP_TL_PKG_CFG_SETUP_DIR=${1}

	cd ${TMP_TL_PKG_CFG_SETUP_DIR}
	
	# 验证安装
    pkg-config --version

	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_pkg_config()
{
	local TMP_TL_PKG_CFG_SETUP_DIR=${1}
    
	set_environment "${TMP_TL_PKG_CFG_SETUP_DIR}"

	setup_pkg_config "${TMP_TL_PKG_CFG_SETUP_DIR}"

	conf_pkg_config "${TMP_TL_PKG_CFG_SETUP_DIR}"

	boot_pkg_config "${TMP_TL_PKG_CFG_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_pkg_config()
{
	local TMP_TL_PKG_CFG_SETUP_NEWER="0.29"
	
	local TMP_TL_PKG_CFG_SETUP_DOWN_URL_BASE="https://pkgconfig.freedesktop.org/releases/"
	set_newer_by_url_list_link_text "TMP_TL_PKG_CFG_SETUP_NEWER" "${TMP_TL_PKG_CFG_SETUP_DOWN_URL_BASE}" "pkg-config-().tar.gz"
	exec_text_format "TMP_TL_PKG_CFG_SETUP_NEWER" "${TMP_TL_PKG_CFG_SETUP_DOWN_URL_BASE}pkg-config-%s.tar.gz"
    setup_soft_wget "pkg-config" "${TMP_TL_PKG_CFG_SETUP_NEWER}" "exec_step_pkg_config"

	return $?
}

#安装主体
setup_soft_basic "PkgConfig" "down_pkg_config"
