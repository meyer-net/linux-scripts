#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_$soft_name()
{	
	return $?
}

function setup_$soft_name()
{
	$setup_upper_name_DIR=$SETUP_DIR/$setup_name
	./configure --prefix=$$setup_upper_name_DIR
	make -j4 && make -j4 install

	ln -sf $$setup_upper_name_DIR/bin/$setup_name /usr/bin/$setup_name

	return $?
}

function down_$soft_name()
{
	set_$soft_name
    setup_soft_wget "$setup_name" "$down_url" "setup_$soft_name"

	return $?
}

setup_soft_basic "$title_name" "down_$soft_name"
