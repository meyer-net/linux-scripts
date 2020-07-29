#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_environment()
{	
	return $?
}

function setup_$soft_name()
{
	local $setup_upper_name_CURRENT_DIR=`pwd`
	local $setup_upper_name_SETUP_DIR=$SETUP_DIR/$setup_name

	## 直装模式

	# cd ..

	# mv $$setup_upper_name_CURRENT_DIR $$setup_upper_name_SETUP_DIR
	# chown -R $soft_name:$soft_name $$setup_upper_name_SETUP_DIR

	## 编译模式
	# ./configure --prefix=$$setup_upper_name_SETUP_DIR
	# make -j4 && make -j4 install

	## 通用
	conf_environment

	ln -sf $$setup_upper_name_SETUP_DIR/bin/$setup_name /usr/bin/$setup_name

	return $?
}

function conf_environment()
{
	rm -rf $setup_upper_name_CURRENT_DIR

	return $?
}

function check_newer()
{	
	echo "----------------------------------------------------"
    echo "$setup_upper_name: System start find the newer stable version"
    echo "----------------------------------------------------"
	local TMP_$setup_upper_name_NEWER_VERSION=``
    local TMP_$setup_upper_name_DOWNLOAD_URL=""

    echo "$setup_upper_name: The newer stable version is $TMP_$setup_upper_name_NEWER_VERSION"
    echo "----------------------------------------------------"

	return $?
}

function boot_$soft_name()
{
	return $?
}

function down_$soft_name()
{
	set_environment
	check_newer
    setup_soft_wget "$setup_name" "$down_url" "setup_$soft_name"

	return $?
}

#安装主体
setup_soft_basic "$title_name" "down_$soft_name"
