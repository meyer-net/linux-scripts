#!/bin/bash
#------------------------------------------------
#      centos7 project env installscript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_environment()
{
    export pip_index_url=https://mirror.in.zhihu.com/simple
	return $?
}

function setup_python()
{
    echo "setup"
	return $?
}


function down_python()
{
    setup_soft_wget "Python" "https://www.python.org/ftp/python/3.6.4/python-3.6.4.tar.xz" "setup_python" "set_environment"

	return $?
}

setup_soft_basic "Python" "down_python"
