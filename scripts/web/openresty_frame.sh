#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 相关参考：
#		  
#------------------------------------------------

##########################################################################################################

# 1-配置环境
function set_env_openresty_frame_lor()
{
    cd ${__DIR}

	return $?
}

function set_env_openresty_frame_lor_baseapp()
{
    cd ${__DIR}

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_openresty_frame_lor()
{
	local TMP_ORST_FWS_LOR_SETUP_DIR=${1}
	local TMP_ORST_FWS_LOR_SETUP_ORST_DIR=`which openresty | sed 's@/bin/openresty@@g'`
	local TMP_ORST_FWS_LOR_CURRENT_DIR=${2}

	## 编译模式    
	cd ${TMP_ORST_FWS_LOR_CURRENT_DIR}

    local TMP_ORST_FWS_LOR_SETUP_COMPILE_HOME="${TMP_ORST_FWS_LOR_SETUP_ORST_DIR}/luafws/lor"

    sed -i "s@LOR_HOME ?=.*@LOR_HOME = ${TMP_ORST_FWS_LOR_SETUP_DIR}@g" Makefile
    sed -i "s@LORD_BIN ?=.*@LORD_BIN = ${TMP_ORST_FWS_LOR_SETUP_COMPILE_HOME}/bin@g" Makefile
    make -j4 install

	cd ${TMP_ORST_FWS_LOR_SETUP_DIR}

	# 环境变量或软连接
	echo "LORD_BIN=${TMP_ORST_FWS_LOR_SETUP_COMPILE_HOME}/bin" >> /etc/profile
	echo 'PATH=$LORD_BIN:$PATH' >> /etc/profile
	echo 'export PATH' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

	return $?
}

function setup_openresty_frame_lor_baseapp()
{
	local TMP_ORST_FWS_LOR_BASEAPP_SETUP_DIR=${1}
	local TMP_ORST_FWS_LOR_BASEAPP_CURRENT_DIR=${2}

	## 直装模式
	path_not_exits_create `dirname ${TMP_ORST_FWS_LOR_BASEAPP_SETUP_DIR}`
	cd `dirname ${TMP_ORST_FWS_LOR_BASEAPP_CURRENT_DIR}`

	mv ${TMP_ORST_FWS_LOR_BASEAPP_CURRENT_DIR} ${TMP_ORST_FWS_LOR_BASEAPP_SETUP_DIR}

	cd ${TMP_ORST_FWS_LOR_BASEAPP_SETUP_DIR}

	return $?
}

##########################################################################################################

# 3-设置软件

##########################################################################################################

# 4-启动软件
function boot_openresty_frame_lor()
{
	local TMP_ORST_FWS_LOR_SETUP_DIR=${1}

	cd ${TMP_ORST_FWS_LOR_SETUP_DIR}
	
	# 验证安装
    lord -v

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_openresty_frame_lor_baseapp()
{
	local TMP_LR_SETUP_LUALIB_DIR=`dirname ${LUAJIT_HOME}`/lualib
	
    # cd ${TMP_LR_SETUP_DIR}/lib/luarocks/rocks
    # git clone https://github.com/juce/lua-resty-shell
	wget_unpack_dist "https://github.com/doujiang24/lua-resty-kafka/archive/master.zip" "lib/resty" "${TMP_LR_SETUP_LUALIB_DIR}"
	
	local TMP_LR_SETUP_LPEG_OFFICIAL_STABLE_LINK=`curl -s http://www.inf.puc-rio.br/~roberto/lpeg/\#download | egrep "source code." | sed 's/\(.*\)href="\([^"\n]*\)"\(.*\)/\2/g'`
	echo "LPEG: The newer stable link is ${TMP_LR_SETUP_LPEG_OFFICIAL_STABLE_LINK}"
    
    wget_unpack_dist "${TMP_LR_SETUP_LPEG_OFFICIAL_STABLE_LINK}" "lpeg.so" "${TMP_LR_SETUP_LUALIB_DIR}" "
        sed -i 's@LUADIR =.*@LUADIR = ${LUAJIT_INC}@g' makefile
        sudo make -j4
    "

	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_openresty_frame_lor()
{
	local TMP_ORST_FWS_LOR_SETUP_DIR=${OR_DIR}/lor
	local TMP_ORST_FWS_LOR_CURRENT_DIR=`pwd`

    set_env_openresty_frame_lor "${TMP_ORST_FWS_LOR_SETUP_DIR}"

	setup_openresty_frame_lor "${TMP_ORST_FWS_LOR_SETUP_DIR}" "${TMP_ORST_FWS_LOR_CURRENT_DIR}"
	
	boot_openresty_frame_lor "${TMP_ORST_FWS_LOR_SETUP_DIR}"

	return $?
}

function exec_step_openresty_frame_lor_baseapp()
{
	local TMP_ORST_FWS_LOR_BASEAPP_SETUP_DIR=${OR_DIR}/lor-baseapp
	local TMP_ORST_FWS_LOR_BASEAPP_CURRENT_DIR=`pwd`

    set_env_openresty_frame_lor_baseapp "${TMP_ORST_FWS_LOR_BASEAPP_SETUP_DIR}"

	setup_openresty_frame_lor_baseapp "${TMP_ORST_FWS_LOR_BASEAPP_SETUP_DIR}" "${TMP_ORST_FWS_LOR_BASEAPP_CURRENT_DIR}"
	
	down_plugin_openresty_frame_lor_baseapp "${TMP_ORST_FWS_LOR_BASEAPP_SETUP_DIR}"

	# boot_openresty_frame_lor_baseapp "${TMP_ORST_FWS_LOR_BASEAPP_SETUP_DIR}"

	return $?
}

##########################################################################################################

    #lua_package_path '../?.lua;$MOUNT_DIR/bin/openresty/luafws/lor/?.lua;;';
    # sed -i "s@[[:space:]]*lua_package_path '$TMP_SETUP_OPENRESTY_DIR/luafws/lor/dependprj/gateway/orange//?.lua;/usr/local/lor/?.lua;;';@    lua_package_path '../?.lua;$ATT_DIR/openresty/integration_libs/?.lua;$TMP_SETUP_LUAROCKS_DIR/share/lua/5.1/?.lua;$TMP_SETUP_OPENRESTY_DIR/luafws/lor/?.lua;$TMP_SETUP_OPENRESTY_DIR/luafws/lor/dependprj/gateway/orange/?.lua;;';@g" $ORANGE_DIR/orange/conf/nginx.conf

function check_setup_openresty_frame_lor()
{
    setup_soft_git "lor" "https://github.com/sumory/lor" "exec_step_openresty_frame_lor"

	return $?
}

function check_setup_openresty_frame_lor_baseapp()
{
    setup_soft_git "lor-baseapp" "https://github.com/meyer-net/lor-baseapp" "exec_step_openresty_frame_lor_baseapp"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "OpenResty-Framework-Lor" "check_setup_openresty_frame_lor"

setup_soft_basic "OpenResty-Framework-Lor-BaseApp" "check_setup_openresty_frame_lor_baseapp"