#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

##########################################################################################################

function set_env_python()
{
    #export PIP_INDEX_URL=https://mirror.in.zhihu.com/simple
	mkdir -pv ${PY_DIR}

    sudo yum -y install python-setuptools

	# active gcc to 
	soft_yum_check_setup "devtoolset-8-gcc*"
	# scl enable devtoolset-8 bash
	source /opt/rh/devtoolset-8/enable
	gcc -v

	return $?
}

##########################################################################################################

function setup_python()
{
	local PYTHON_CURRENT_DIR=`pwd`
	local PYTHON_SETUP_DIR=${1}

	./configure --prefix=${PYTHON_SETUP_DIR} --enable-optimizations
	make -j4 && make -j4 install
	
	ln -sf ${PYTHON_SETUP_DIR}/bin/python3 /usr/bin/python3
	python3 -m venv pyenv3

	ln -sf ${PYTHON_SETUP_DIR}/bin/pip3 /usr/bin/pip3

	local TMP_PY_NEWER_SETUP_PATH=`pip3 show pip | grep "Location" | awk -F' ' '{print $2}'`
	mv ${TMP_PY_NEWER_SETUP_PATH} ${PY3_PKGS_SETUP_DIR}
	ln -sf ${PY3_PKGS_SETUP_DIR} ${TMP_PY_NEWER_SETUP_PATH}

	python3 -V
	pip3 --version

	#把系统默认python命令改成python3
	#mv /usr/bin/python /usr/bin/python2.7.x
	#sed -i '1s@^.*$@#!/usr/bin/python2.7@' /usr/bin/yum
	#sed -i '1s@^.*$@#!/usr/bin/python2.7@' /usr/libexec/urlgrabber-ext-down

	local PYTHON_DEPE_OPENSSL=`which openssl`
	rm -rf /usr/local/ssl
	ln -sf ${PYTHON_DEPE_OPENSSL} /usr/local/ssl

	pip3 install --upgrade pip
	
	# 重新链接，因为upgrade后不认
	ln -sf ${PYTHON_SETUP_DIR}/bin/pip3 /usr/bin/pip3
	pip3 install --upgrade setuptools
	
	#virtualenv --distribute $pyDir

	#https://www.ibm.com/developerworks/cn/linux/l-buildbot/index.html
	#http://www.cnblogs.com/aguncn/p/3427707.html
	#https://segmentfault.com/a/1190000007031057
	# pip3 install setuptools # virtualenv virtualenvwrapper
	# pip3 install zc.buildout  #buildout init, wget -O bootstrap.py https://bootstrap.pypa.io/bootstrap-buildout.py, wget -O ez_setup.py https://bootstrap.pypa.io/ez_setup.py, python bootstrap.py, buildout install
	
	pip3 install hiredis
	#pip3 install thrift
	#pip3 install scrapy
	#pip3 install django
	#pip3 install djangorestframework
	#pip3 install markdown       # Markdown support for the browsable API.
	#pip3 install django-filter  # Filtering support
	pip3 install numpy
	pip3 install requests
	# pip3 install nltk

	#https://www.zhihu.com/question/21639330
	#pip freeze > requirements.txt
	#pip install -r requirements.txt
	rm -rf ${PYTHON_CURRENT_DIR}

	return $?
}

##########################################################################################################

function down_python()
{
	set_env_python
    setup_soft_wget "python3" "https://www.python.org/ftp/python/3.9.6/Python-3.9.6.tgz" "setup_python"

	return $?
}

##########################################################################################################

setup_soft_basic "Python" "down_python"
