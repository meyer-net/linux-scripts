#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 相关参考：
#		  https://www.ibm.com/developerworks/cn/linux/l-buildbot/index.html
#		  http://www.cnblogs.com/aguncn/p/3427707.html
#		  https://segmentfault.com/a/1190000007031057
#------------------------------------------------

##########################################################################################################

# 1-配置环境
function set_env_python()
{
    cd ${__DIR}

    soft_yum_check_setup "python-setuptools"
	
	# active gcc to 
	soft_yum_check_setup "devtoolset-8-gcc*"

	# scl enable devtoolset-8 bash
	source /opt/rh/devtoolset-8/enable
	gcc -v

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_python()
{
	cd ${TMP_PY_CURRENT_DIR}

	# 编译模式
	./configure --prefix=${TMP_PY_SETUP_DIR} --enable-optimizations
	make -j4 && make -j4 install

	cd ${TMP_PY_SETUP_DIR}

	local TMP_PY_SETUP_NEWER_PATH=`pip3 show pip | grep "Location" | awk -F' ' '{print $2}'`
	mv ${TMP_PY_SETUP_NEWER_PATH} ${PY3_PKGS_SETUP_DIR}
	ln -sf ${PY3_PKGS_SETUP_DIR} ${TMP_PY_SETUP_NEWER_PATH}
	
	rm -rf /usr/local/ssl
	ln -sf `which openssl` /usr/local/ssl

	pip3 install --upgrade pip

	# 卸载旧的pip
	python -m pip uninstall pip

	# pip3 install setuptools # virtualenv virtualenvwrapper
	# pip3 install zc.buildout  #buildout init, wget -O bootstrap.py https://bootstrap.pypa.io/bootstrap-buildout.py, wget -O ez_setup.py https://bootstrap.pypa.io/ez_setup.py, python bootstrap.py, buildout install
	
	# 移除源文件
	rm -rf ${TMP_PY_CURRENT_DIR}
	
    # 安装初始

    # 创建源码目录
    path_not_exists_create "${PY_DIR}"
    path_not_exists_create "${PYA_DIR}"

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_python()
{
	cd ${TMP_PY_SETUP_DIR}

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_python()
{
	cd ${TMP_PY_SETUP_DIR}
	
	# 验证安装
    python3 -V
	pip3 --version

	# 当前启动命令
	python3 -m venv pyenv3
	
	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_python()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_python()
{
	pip3 install hiredis
	pip3 install thrift
	pip3 install scrapy
	#pip3 install django
	#pip3 install djangorestframework
	#pip3 install markdown       # Markdown support for the browsable API.
	#pip3 install django-filter  # Filtering support
	pip3 install numpy
	pip3 install requests
	pip3 install nltk

	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_python()
{
	# 变量覆盖特性，其它方法均可读取
	local TMP_PY_SETUP_DIR=${1}
	local TMP_PY_CURRENT_DIR=`pwd`
    
	set_env_python 

	setup_python 

	conf_python 

    # down_plugin_python 
    setup_plugin_python 

	boot_python 

	# reconf_python 

	return $?
}

##########################################################################################################

# x1-下载软件
function down_python()
{
    setup_soft_wget "python" "https://www.python.org/ftp/python/3.8.5/Python-3.8.5.tgz" "exec_step_python"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "Python3" "down_python"
