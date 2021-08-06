#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function check_setup_nodejs()
{
    path_not_exits_action "${NVM_PATH}" "print_nodejs" "Nodejs was installed"

	source ${NVM_PATH}

	local NPM_PATH=`which npm`
	local NODE_PATH=`which node`

	# 部分程序是识别 /usr/bin or /usr/local/bin 目录的，所以在此创建适配其需要的软连接
    path_not_exits_action "/usr/bin/npm" "ln -sf ${NPM_PATH} /usr/bin/npm" "Npm at '/usr/bin/npm' was linked"
    path_not_exits_action "/usr/local/bin/npm" "ln -sf ${NPM_PATH} /usr/local/bin/npm" "Npm at '/usr/local/bin/npm' was linked"

    path_not_exits_action "/usr/bin/node" "ln -sf ${NODE_PATH} /usr/bin/node" "Node at '/usr/bin/node' was linked"
    path_not_exits_action "/usr/local/bin/node" "ln -sf ${NODE_PATH} /usr/bin/node" "Node at '/usr/local/bin/node' was linked"
	
	return $?
}

function print_nodejs()
{
	setup_soft_basic "NodeJs" "setup_nodejs"

	return $?
}

function setup_nodejs()
{
	curl -s -o- https://raw.githubusercontent.com/creationix/nvm/v0.38.0/install.sh | bash

	source ${NVM_PATH}
	echo "NodeJs: Remote list"
	nvm ls-remote --lts
	
    #安装官方指定稳定版,https://nodejs.org/en/查看
    echo "--------------------------------------------------"
    echo "NodeJs: System start find the newer popular version"
    echo "--------------------------------------------------"
	local TMP_OFFICIAL_STABLE_VERSION=`curl -s https://nodejs.org/en/ | grep "https://nodejs.org/dist" | awk -F'\"' '{print $2}' | awk -F'/' '{print $(NF-1)}' | awk NR==1 | sed 's@v@@'`
	echo "NodeJs: The newer popular version is ${TMP_OFFICIAL_STABLE_VERSION}"
    echo "--------------------------------------------------"
	
	#如果没加载到最新版，则默认使用稳定版（防止官方展示规则变动的情况）
	set_if_empty "TMP_OFFICIAL_STABLE_VERSION" "stable"

	#安装并指定新版本
	if [ -n "${TMP_OFFICIAL_STABLE_VERSION}" ]; then
		nvm install ${TMP_OFFICIAL_STABLE_VERSION}
		nvm use ${TMP_OFFICIAL_STABLE_VERSION}
		nvm alias default ${TMP_OFFICIAL_STABLE_VERSION}
	else
		nvm use node
	fi

	echo "NodeJs: Local list"
	nvm ls

	nvm current

	node --version
	node --v8-options | grep harmony
	npm install -g nrm
	echo "-------------------------------------------------"
	nrm ls
	echo "-------------------------------------------------"
	echo "Start to check the quickly registry by nrm："
	# 查找响应时间最短的源
	local TMP_SOFT_NPM_NRM_TEST=`nrm test`
	local TMP_SOFT_NPM_NRM_RESP_MIN=`echo "${TMP_SOFT_NPM_NRM_TEST}" | grep -oP "(?<=\s)\d+(?=ms)" | sort -g | awk 'NR==1'`
	local TMP_SOFT_NPM_NRM_REPO=`echo "${TMP_SOFT_NPM_NRM_TEST}" | grep "${TMP_SOFT_NPM_NRM_RESP_MIN}" | sed "s@-@@g" | grep -oP "(?<=\s).*(?=\s\d)" | awk '{sub("^ *","");sub(" *$","");print}' | awk 'NR==1'`

	echo "${TMP_SOFT_NPM_NRM_TEST}"
	echo "----------------------------------------------------------------"
	echo "The quickly registry is '${red}${TMP_SOFT_NPM_NRM_REPO}${reset}'"
	echo "----------------------------------------------------------------"
	nrm use ${TMP_SOFT_NPM_NRM_REPO}
	#* npm -------- https://registry.npmjs.org/
	#  yarn ------- https://registry.yarnpkg.com/
	#  cnpm ------- http://r.cnpmjs.org/
	#  taobao ----- https://registry.npm.taobao.org/
	#  nj --------- https://registry.nodejitsu.com/
	#  npmMirror -- https://skimdb.npmjs.com/registry/
	#  edunpm ----- http://registry.enpmjs.org/

	# npm config set registry https://registry.npm.taobao.org
	# npm config set disturl https://npm.taobao.org/dist
	npm install -g npm@next cnpm
	npm install -g es-checker
	npm --version
	es-checker
	npm install -g yarn
	# yarn config set registry https://registry.npm.taobao.org --global
	# yarn config set disturl https://npm.taobao.org/dist --global

    echo_startup_config "nvm" `dirname ${NVM_PATH}` "tail -f $(dirname ~/1)/npm-debug.log" "" "1" "${NVM_PATH}"

	#https://www.npmjs.com/package/nrm 
	#npm config delete registry
	#npm config delete disturl

	return $?
}

check_setup_nodejs