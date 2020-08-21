#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

# 1-配置环境
function set_environment()
{
    soft_yum_check_setup "openssl-devel,libcurl-devel,wget,tar,m4,git-core,boost-static,m4,gcc-c++,npm,ncurses-devel,which,make,ncurses-static,zlib-devel,zlib-static,bzip2,patch"

    soft_yum_check_setup "protobuf-devel protobuf-static jemalloc-devel"

	return $?
}

# 2-安装软件
function setup_rethinkdb()
{
	local TMP_DB_RTK_SETUP_DIR=${1}
	local TMP_DB_RTK_CURRENT_DIR=`pwd`

	# 编译模式
	./configure --prefix=${TMP_DB_RTK_SETUP_DIR} --allow-fetch --dynamic jemalloc
	sudo make -j4 && make -j4 install

	# ## 日志调整 （设置实际路径需放置在需要运用的项目中，固不在原项目中调整）
	# local TMP_${$soft_upper_short_name}_DB_RTK_LNK_LOG_PATH=${LOGS_DIR}/rethinkdb/$soft_name
	# local TMP_${$soft_upper_short_name}_DB_RTK_LNK_DATA_DIR=${DATA_DIR}/rethinkdb/$soft_name
	# local TMP_${$soft_upper_short_name}_DB_RTK_DATA_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/rethinkdb_data
	# local TMP_${$soft_upper_short_name}_DB_RTK_LOG_PATH=${TMP_${$soft_upper_short_name}_DB_RTK_DATA_DIR}/log_file

	# # 先清理文件，再创建文件
	# rm -rf ${TMP_${$soft_upper_short_name}_DB_RTK_LOG_PATH}
	# rm -rf ${TMP_${$soft_upper_short_name}_DB_RTK_DATA_DIR}
	# mkdir -pv ${TMP_${$soft_upper_short_name}_DB_RTK_LNK_DATA_DIR}

	# ln -sf ${TMP_${$soft_upper_short_name}_DB_RTK_LNK_LOG_PATH} ${TMP_${$soft_upper_short_name}_DB_RTK_LOG_PATH}
	# ln -sf ${TMP_${$soft_upper_short_name}_DB_RTK_LNK_DATA_DIR} ${TMP_${$soft_upper_short_name}_DB_RTK_DATA_DIR}

	# 环境变量或软连接
    ln -sf ${TMP_DB_RTK_SETUP_DIR}/bin/rethinkdb /usr/bin/rethinkdb

	# 移除源文件
	rm -rf ${TMP_DB_RTK_CURRENT_DIR}

	return $?
}

# 3-设置软件
function conf_rethinkdb()
{
	cd ${1}

    # cp -r etc/rethinkdb/default.conf.sample etc/rethinkdb/default.conf

	return $?
}

# 4-启动软件
function boot_rethinkdb()
{
    # 启动命令需放置在需要运用的项目中
    
	# local TMP_$soft_upper_short_name_SETUP_DIR=${1}

	# cd ${TMP_$soft_upper_short_name_SETUP_DIR}

    # nohup rethinkdb --bind all &

    # echo_startup_config "rethinkdb_$soft_name" "${TMP_$soft_upper_short_name_SETUP_DIR}" "rethinkdb --bind all" "" "1"
    
	# 验证安装
    rethinkdb -v

	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_rethinkdb()
{
	local TMP_DB_RTK_SETUP_DIR=${1}
    
	set_environment "${TMP_DB_RTK_SETUP_DIR}"

	setup_rethinkdb "${TMP_DB_RTK_SETUP_DIR}"

	conf_rethinkdb "${TMP_DB_RTK_SETUP_DIR}"

	boot_rethinkdb "${TMP_DB_RTK_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_rethinkdb()
{
	TMP_DB_RTK_SETUP_NEWER="2.4.1"
	set_github_soft_releases_newer_version "TMP_DB_RTK_SETUP_NEWER" "rethinkdb/rethinkdb"
	exec_text_format "TMP_DB_RTK_SETUP_NEWER" "https://download.rethinkdb.com/repository/raw/dist/rethinkdb-%s.tgz"
    setup_soft_wget "rethinkdb" "${TMP_DB_RTK_SETUP_NEWER}" "exec_step_rethinkdb"

	return $?
}

#安装主体
setup_soft_basic "RethinkDB" "down_rethinkdb"
