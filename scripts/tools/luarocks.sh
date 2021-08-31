#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 相关参考：
#		  
#------------------------------------------------
# 作为OpenResty的插件，因为共用，所以代码隔离
#------------------------------------------------
# 稍微适配非openresty的情况
# local TMP_LR_SETUP_LUAJIT_DIR=`find / -name luajit 2> /dev/null | grep "luajit/bin" | sed "s@/bin/luajit@@g"`

##########################################################################################################

# 1-配置环境
function set_env_luarocks()
{
    cd ${__DIR}

    soft_yum_check_setup "libtermcap-devel,ncurses-devel,libevent-devel,readline-devel"

	return $?
}

##########################################################################################################

# 2-安装软件（需已安装luajit）
function setup_luarocks()
{
	local TMP_LR_SETUP_DIR=${1}
	local TMP_LR_CURRENT_DIR=${2}

	cd ${TMP_LR_CURRENT_DIR}

	# 编译模式
	./configure --prefix=${TMP_LR_SETUP_DIR} --with-lua=${LUAJIT_HOME} --lua-suffix=jit --with-lua-include=${LUAJIT_INC}
	make -j4 build && sudo make -j4 install

	cd ${TMP_LR_SETUP_DIR}
	
	# 环境变量或软连接
	echo "LUAROCKS_HOME=${TMP_LR_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$LUAROCKS_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH LUAROCKS_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

	# 移除源文件
	rm -rf ${TMP_LR_CURRENT_DIR}

    # 安装初始
    # -- 利用luarocks安装插件
    luarocks install lua-resty-session
    luarocks install lua-resty-jwt
    luarocks install lua-resty-cookie
    luarocks install lua-resty-template
    luarocks install lua-resty-http
    luarocks install lua-resty-redis
    luarocks install luasocket
    luarocks install busted 
    luarocks install luasql-sqlite3
    luarocks install lzlib
    luarocks install luafilesystem
    luarocks install luasec
    luarocks install md5
    luarocks install multipart  
    luarocks install lua-resty-rsa 

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_luarocks()
{
	local TMP_LR_SETUP_DIR=${1}

	cd ${TMP_LR_SETUP_DIR}

	# 开始配置

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_luarocks()
{
	local TMP_LR_SETUP_DIR=${1}

	cd ${TMP_LR_SETUP_DIR}
	
	# 验证安装
    luarocks version

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_luarocks()
{	
	local TMP_LR_SETUP_DIR=${1}

	cd ${TMP_LR_SETUP_DIR}

	return $?
}

# 安装驱动/插件
function setup_plugin_luarocks()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_luarocks()
{
	local TMP_LR_SETUP_DIR=${1}
	local TMP_LR_CURRENT_DIR=`pwd`
    
	set_env_luarocks "${TMP_LR_SETUP_DIR}"

	setup_luarocks "${TMP_LR_SETUP_DIR}" "${TMP_LR_CURRENT_DIR}"

	conf_luarocks "${TMP_LR_SETUP_DIR}"

    down_plugin_luarocks "${TMP_LR_SETUP_DIR}"

	boot_luarocks "${TMP_LR_SETUP_DIR}"

	return $?
}

##########################################################################################################

# x1-下载软件
function down_luarocks()
{
	local TMP_LR_SETUP_NEWER="3.7.0"
	set_github_soft_releases_newer_version "TMP_LR_SETUP_NEWER" "luarocks/luarocks"
	# http://luarocks.github.io/luarocks/releases/luarocks-3.7.0.tar.gz
	exec_text_format "TMP_LR_SETUP_NEWER" "https://github.com/luarocks/luarocks/archive/refs/tags/v%s.tar.gz"
    setup_soft_wget "luarocks" "${TMP_LR_SETUP_NEWER}" "exec_step_luarocks"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "LuaRocks" "down_luarocks"
