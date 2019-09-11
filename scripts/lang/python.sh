#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_python()
{
    #export PIP_INDEX_URL=https://mirror.in.zhihu.com/simple
	mkdir -pv $PY_DIR
	return $?
}

function setup_python()
{
	PYTHON_DIR=$SETUP_DIR/python3
	./configure --prefix=$PYTHON_DIR
	make -j4 && make -j4 install
	
	ln -sf $PYTHON_DIR/bin/python3 /usr/bin/python3

	cd $SETUP_DIR
	python3 -m venv pyenv3

	#把系统默认python命令改成python3
	#mv /usr/bin/python /usr/bin/python2.7.x
	#sed -i '1s@^.*$@#!/usr/bin/python2.7@' /usr/bin/yum
	#sed -i '1s@^.*$@#!/usr/bin/python2.7@' /usr/libexec/urlgrabber-ext-down

	# 修改 RPM源
# 	mkdir -pv ~/.pip
# 	cat >> ~/.pip/pip.conf <<EOF
# [global]
# index-url = https://pypi.tuna.tsinghua.edu.cn/simple
# EOF

	#easy_install pip
	pip install --upgrade pip
	pip3 install --upgrade pip
	#pip install --upgrade setuptools
	#pip install uwsgi
	#pip list

	python3 -V
	pip3 --version

	pip3 install --upgrade setuptools
	
	#virtualenv --distribute $pyDir

	#https://www.ibm.com/developerworks/cn/linux/l-buildbot/index.html
	#http://www.cnblogs.com/aguncn/p/3427707.html
	#https://segmentfault.com/a/1190000007031057
	# pip3 install setuptools # virtualenv virtualenvwrapper
	# pip3 install zc.buildout  #buildout init, wget -O bootstrap.py https://bootstrap.pypa.io/bootstrap-buildout.py, wget -O ez_setup.py https://bootstrap.pypa.io/ez_setup.py, python bootstrap.py, buildout install
	
	#pip3 install hiredis
	#pip3 install thrift
	#pip3 install scrapy
	#pip3 install django
	#pip3 install djangorestframework
	#pip3 install markdown       # Markdown support for the browsable API.
	#pip3 install django-filter  # Filtering support
	#pip3 install numpy
	#pip3 install requests
	#pip3 install nltk

	#https://www.zhihu.com/question/21639330
	#pip freeze > requirements.txt
	#pip install -r requirements.txt

	return $?
}

function down_python()
{
	set_python
    setup_soft_wget "python3" "https://www.python.org/ftp/python/3.6.6/Python-3.6.6.tar.xz" "setup_python"

	return $?
}

setup_soft_basic "Python" "down_python"
