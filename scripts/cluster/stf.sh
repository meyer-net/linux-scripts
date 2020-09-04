#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 项目依赖：
# Node.js 8.x required (some dependencies don't support newer versions)
# ADB properly set up
# RethinkDB >= 2.2
# GraphicsMagick (for resizing screenshots)
# ZeroMQ libraries installed
# Protocol Buffers libraries installed
# yasm installed (for compiling embedded libjpeg-turbo)
# pkg-config so that Node.js can find the libraries
# 参考文档：
#	https://sutune.me/2018/11/26/stf-manual/
#------------------------------------------------

# 1-配置环境
function set_environment()
{
    cd $WORK_PATH

    #安装依赖库
    source scripts/lang/java.sh

    source scripts/database/rethinkdb.sh

    source scripts/bi/zeromq.sh

    source scripts/tools/graphics_magick.sh

    source scripts/tools/protocol_buffers.sh

    source scripts/tools/yasm.sh

    source scripts/tools/pkg_config.sh

	return $?
}

# 2-安装软件
function setup_stf()
{
	local TMP_STF_SETUP_DIR=${1}
	local TMP_STF_CURRENT_DIR=`pwd`

	# local TMP_CL_STF_LNK_LOGS_DIR=${LOGS_DIR}/stf
	# local TMP_CL_STF_LNK_DATA_DIR=${DATA_DIR}/stf
	# local TMP_CL_STF_LOGS_DIR=${TMP_CL_STF_SETUP_DIR}/logs
	# local TMP_CL_STF_DATA_DIR=${TMP_CL_STF_SETUP_DIR}/data

	# # 先清理文件，再创建文件
	# rm -rf ${TMP_CL_STF_LOGS_DIR}
	# rm -rf ${TMP_CL_STF_DATA_DIR}
	# mkdir -pv ${TMP_CL_STF_LNK_LOGS_DIR}
	# mkdir -pv ${TMP_CL_STF_LNK_DATA_DIR}

	# ln -sf ${TMP_CL_STF_LNK_LOGS_DIR} ${TMP_CL_STF_LOGS_DIR}
	# ln -sf ${TMP_CL_STF_LNK_DATA_DIR} ${TMP_CL_STF_DATA_DIR}

	# 建立bin链接
	ln -sf ${TMP_STF_SETUP_DIR}/bin/stf /usr/bin/stf

	# 移除源文件
	rm -rf ${STF_CURRENT_DIR}

	return $?
}

# 3-设置软件.1
function conf_stf()
{
	cd ${1}

	conf_stf_rethinkdb ${1}

	return $?
}

# 3-设置软件.1
function conf_stf_rethinkdb()
{
	## 日志调整 （设置实际路径需放置在需要运用的项目中，固不在原项目中调整）
	local TMP_CL_STF_DB_RTK_LNK_LOG_PATH=${LOGS_DIR}/rethinkdb/stf
	local TMP_CL_STF_DB_RTK_LNK_DATA_DIR=${DATA_DIR}/rethinkdb/stf
	local TMP_CL_STF_DB_RTK_DATA_DIR=${1}/rethinkdb_data
	local TMP_CL_STF_DB_RTK_LOG_PATH=${TMP_CL_STF_DB_RTK_DATA_DIR}/log_file

	# 先清理文件，再创建文件
	rm -rf ${TMP_CL_STF_DB_RTK_LOG_PATH}
	rm -rf ${TMP_CL_STF_DB_RTK_DATA_DIR}
	mkdir -pv ${TMP_CL_STF_DB_RTK_LNK_DATA_DIR}

	ln -sf ${TMP_CL_STF_DB_RTK_LNK_LOG_PATH} ${TMP_CL_STF_DB_RTK_LOG_PATH}
	ln -sf ${TMP_CL_STF_DB_RTK_LNK_DATA_DIR} ${TMP_CL_STF_DB_RTK_DATA_DIR}

	return $?
}

# 4-启动软件.1
function boot_stf()
{
	boot_stf_rethinkdb ${1}

	local TMP_CL_STF_SETUP_DIR=${1}
	local TMP_CL_STF_NODE_VERSION=${2}

	cd ${TMP_CL_STF_SETUP_DIR}

	stf doctor

	nvm use ${TMP_CL_STF_NODE_VERSION} && bin/stf local --public-ip 0.0.0.0 --allow-remote &

    echo_startup_config "stf" "${TMP_CL_STF_SETUP_DIR}" "nvm use ${TMP_CL_STF_NODE_VERSION} && bin/stf local --public-ip 0.0.0.0 --allow-remote &" "" "100"

	return $?
}

# 4-启动软件.2
function boot_stf_rethinkdb()
{
	local TMP_CL_STF_SETUP_DIR=${1}

	cd ${TMP_CL_STF_SETUP_DIR}

    nohup rethinkdb --bind all &

    echo_startup_config "rethinkdb_stf" "${TMP_CL_STF_SETUP_DIR}" "rethinkdb --bind all" "" "1"

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_android_tools()
{
	# 没有好的方法获取新版本，暂时写死
	local CL_AT_SETUP_NEWER="4333796"
	exec_text_format "CL_AT_SETUP_NEWER" "https://dl.google.com/android/repository/sdk-tools-linux-%s.zip"
    setup_soft_wget "android-sdk-linux" "${CL_AT_SETUP_NEWER}" "setup_android_tools"

	return $?
}

# 安装驱动/插件
function setup_android_tools()
{
	local TMP_ANDROID_TOOLS_SETUP_DIR=${1}
	local TMP_ANDROID_TOOLS_CURRENT_DIR=`pwd`
	
    mkdir -pv ${TMP_ANDROID_TOOLS_SETUP_DIR}
    mv ${TMP_ANDROID_TOOLS_CURRENT_DIR} ${TMP_ANDROID_TOOLS_SETUP_DIR}

	echo "ANDROID_HOME=${TMP_ANDROID_TOOLS_SETUP_DIR}" >> /etc/profile
	echo 'PATH=${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:$PATH' >> /etc/profile
	echo "export PATH ANDROID_HOME" >> /etc/profile
	source /etc/profile

    yes | sdkmanager --licenses

    sdkmanager "tools" "platform-tools"

    adb version

	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_stf()
{
	local TMP_CL_STF_SETUP_DIR=${1}
	local TMP_CL_STF_NODE_VERSION=${2}
    
	set_environment "${TMP_CL_STF_SETUP_DIR}"

	down_android_tools

	setup_stf "${TMP_CL_STF_SETUP_DIR}"

	set_stf "${TMP_CL_STF_SETUP_DIR}"

	boot_stf "${TMP_CL_STF_SETUP_DIR}" "${TMP_CL_STF_NODE_VERSION}"

	return $?
}

# x1-下载软件
function down_stf()
{
    setup_soft_npm "stf" "exec_step_stf" "v8.1.4"

	return $?
}

#安装主体
setup_soft_basic "STF" "down_stf"
