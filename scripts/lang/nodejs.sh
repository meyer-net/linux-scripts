#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function check_setup_nodejs()
{
    path_not_exits_action "$NVM_PATH" "print_nodejs" "Nodejs was installed"
	source $NVM_PATH

	local NPM_PATH=`which npm`
	local NODE_PATH=`which node`

	# 部分程序是识别 /usr/bin or /usr/local/bin 目录的，所以在此创建适配其需要的软连接
    path_not_exits_action "/usr/bin/npm" "ln -sf $NPM_PATH /usr/bin/npm" "Npm at '/usr/bin/npm' was linked"
    path_not_exits_action "/usr/local/bin/npm" "ln -sf $NPM_PATH /usr/local/bin/npm" "Npm at '/usr/local/bin/npm' was linked"

    path_not_exits_action "/usr/bin/node" "ln -sf $NODE_PATH /usr/bin/node" "Node at '/usr/bin/node' was linked"
    path_not_exits_action "/usr/local/bin/node" "ln -sf $NODE_PATH /usr/bin/node" "Node at '/usr/local/bin/node' was linked"
	
	return $?
}

function print_nodejs()
{
	setup_soft_basic "NodeJs" "setup_nodejs"

	return $?
}

function setup_nodejs()
{
	curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash

	source $NVM_PATH
	nvm ls

	#保留默认稳定版
	nvm install stable
	nvm current
	
    #安装官方指定稳定版,https://nodejs.org/en/查看
    echo "--------------------------------------------------"
    echo "NodeJs: System start find the newer popular version"
    echo "--------------------------------------------------"
	local TMP_OFFICIAL_STABLE_VERSION=`curl -s https://nodejs.org/en/ | grep "https://nodejs.org/dist" | awk -F'\"' '{print $2}' | awk -F'/' '{print $(NF-1)}' | awk NR==1 | sed 's@v@@'`
	echo "NodeJs: The newer popular version is $TMP_OFFICIAL_STABLE_VERSION"
    echo "--------------------------------------------------"
	
	#如果没加载到最新版，则默认使用稳定版（防止官方展示规则变动的情况）
	set_if_empty "TMP_OFFICIAL_STABLE_VERSION" "stable"

	#安装并指定新版本
	nvm install $TMP_OFFICIAL_STABLE_VERSION
	nvm use $TMP_OFFICIAL_STABLE_VERSION
	nvm alias default $TMP_OFFICIAL_STABLE_VERSION

	nvm current
	nvm ls
	nvm use node
	node --v8-options | grep harmony
	npm config set registry https://registry.npm.taobao.org
	npm config set disturl https://npm.taobao.org/dist
	npm install -g npm
	npm install -g es-checker
	es-checker
	npm install -g yarn
	yarn config set registry https://registry.npm.taobao.org --global
	yarn config set disturl https://npm.taobao.org/dist --global

	#https://www.npmjs.com/package/nrm 
	#npm config delete registry
	#npm config delete disturl

	return $?
}

check_setup_nodejs