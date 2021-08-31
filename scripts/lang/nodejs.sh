#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 安装标题：NodeJS
# 软件名称：nodejs
# 软件大写分组与简称：NVM
# 软件安装名称：nvm
# 软件授权用户名称&组：$setup_owner/$setup_owner_group
#------------------------------------------------


##########################################################################################################

# 1-配置环境
function set_env_nodejs()
{
    cd ${__DIR}

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_nodejs()
{
	local TMP_NVM_SETUP_DIR=${1}

	## 源模式
    #通过BASH安装
	local TMP_NVM_SETUP_SH_NEWER="0.38.0"
	set_github_soft_releases_newer_version "TMP_NVM_SETUP_SH_NEWER" "nvm-sh/nvm"
	exec_text_format "TMP_NVM_SETUP_SH_NEWER" "https://raw.githubusercontent.com/creationix/nvm/v%s/install.sh"
	
	local TMP_NVM_SETUP_SH_FILE_NEWER="install_nvm.sh"

	path_not_exists_create "${TMP_NVM_SETUP_DIR}"

	export NVM_DIR="${TMP_NVM_SETUP_DIR}" && (
    	while_curl "${TMP_NVM_SETUP_SH_NEWER} -o ${TMP_NVM_SETUP_SH_FILE_NEWER}" "bash ${TMP_NVM_SETUP_SH_FILE_NEWER}"
		echo "NodeJS：Start to wait environment alivable，about 30 secs..."
		sleep 5
	)
	
	sed -i "1 iNVM_DIR='${TMP_NVM_SETUP_DIR}'" ${TMP_NVM_SETUP_DIR}/nvm.sh
	source ${TMP_NVM_SETUP_DIR}/nvm.sh

    echo "---------------------------------------"
	echo "NodeJs: Remote list"
    echo "---------------------------------------"
	nvm ls-remote --lts

    #安装官方指定稳定版,https://nodejs.org/en/查看
    echo "---------------------------------------------------"
    echo "NodeJs: System start find the newer popular version"
    echo "---------------------------------------------------"
	local TMP_NVM_SETUP_OFFICIAL_STABLE_VERSION=`curl -s https://nodejs.org/en/ | grep "https://nodejs.org/dist" | awk -F'\"' '{print $2}' | awk -F'/' '{print $(NF-1)}' | awk NR==1 | sed 's@v@@'`
	echo "NodeJs: The newer popular version is ${TMP_NVM_SETUP_OFFICIAL_STABLE_VERSION}"
    echo "--------------------------------------------------"
	
	#如果没加载到最新版，则默认使用稳定版（防止官方展示规则变动的情况）
	set_if_empty "TMP_NVM_SETUP_OFFICIAL_STABLE_VERSION" "stable"

	#安装并指定新版本
	if [ -n "${TMP_NVM_SETUP_OFFICIAL_STABLE_VERSION}" ]; then
		nvm install ${TMP_NVM_SETUP_OFFICIAL_STABLE_VERSION}
		nvm use ${TMP_NVM_SETUP_OFFICIAL_STABLE_VERSION}
		nvm alias default ${TMP_NVM_SETUP_OFFICIAL_STABLE_VERSION}
	else
		nvm use node
	fi

    echo "---------------------------------"
	echo "NodeJs: Local list"
    echo "---------------------------------"
	nvm ls

    # 安装初始
	local TMP_NVM_SETUP_NPM_PATH=`which npm`
	local TMP_NVM_SETUP_NODE_PATH=`which node`

	# 部分程序是识别 /usr/bin or /usr/local/bin 目录的，所以在此创建适配其需要的软连接
    path_not_exists_action "/usr/bin/npm" "ln -sf ${TMP_NVM_SETUP_NPM_PATH} /usr/bin/npm" "Npm at '/usr/bin/npm' was linked"
    path_not_exists_action "/usr/local/bin/npm" "ln -sf ${TMP_NVM_SETUP_NPM_PATH} /usr/local/bin/npm" "Npm at '/usr/local/bin/npm' was linked"

    path_not_exists_action "/usr/bin/node" "ln -sf ${TMP_NVM_SETUP_NODE_PATH} /usr/bin/node" "Node at '/usr/bin/node' was linked"
    path_not_exists_action "/usr/local/bin/node" "ln -sf ${TMP_NVM_SETUP_NODE_PATH} /usr/bin/node" "Node at '/usr/local/bin/node' was linked"

	node --version
	node --v8-options | grep harmony
	npm install -g nrm
	echo "-------------------------------------------------"
	nrm ls
	echo "-------------------------------------------------"
	npm install -g npm@next cnpm
	npm install -g es-checker
	npm --version
	es-checker
	npm install -g yarn

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_nodejs()
{
	local TMP_NVM_SETUP_DIR=${1}

	cd ${TMP_NVM_SETUP_DIR}
	
    # 开始配置
	echo "--------------------------------------------"
	echo "Start to check the quickly registry by nrm："
	echo "--------------------------------------------"
	# 查找响应时间最短的源
	local TMP_NVM_SETUP_SOFT_NPM_NRM_TEST=`nrm test`
	local TMP_NVM_SETUP_SOFT_NPM_NRM_RESP_MIN=`echo "${TMP_NVM_SETUP_SOFT_NPM_NRM_TEST}" | grep -oP "(?<=\s)\d+(?=ms)" | sort -g | awk 'NR==1'`
	local TMP_NVM_SETUP_SOFT_NPM_NRM_REPO=`echo "${TMP_NVM_SETUP_SOFT_NPM_NRM_TEST}" | grep "${TMP_NVM_SETUP_SOFT_NPM_NRM_RESP_MIN}" | sed "s@-@@g" | grep -oP "(?<=\s).*(?=\s\d)" | awk '{sub("^ *","");sub(" *$","");print}' | awk 'NR==1'`

	echo "${TMP_NVM_SETUP_SOFT_NPM_NRM_TEST}"
	echo "----------------------------------------------------------------"
	echo "The quickly registry is '${red}${TMP_NVM_SETUP_SOFT_NPM_NRM_REPO}${reset}'"
	echo "----------------------------------------------------------------"
	nrm use ${TMP_NVM_SETUP_SOFT_NPM_NRM_REPO}
	#* npm -------- https://registry.npmjs.org/
	#  yarn ------- https://registry.yarnpkg.com/
	#  cnpm ------- http://r.cnpmjs.org/
	#  taobao ----- https://registry.npm.taobao.org/
	#  nj --------- https://registry.nodejitsu.com/
	#  npmMirror -- https://skimdb.npmjs.com/registry/
	#  edunpm ----- http://registry.enpmjs.org/

	# npm config set registry https://registry.npm.taobao.org
	# npm config set disturl https://npm.taobao.org/dist
	
	# yarn config set registry https://registry.npm.taobao.org --global
	# yarn config set disturl https://npm.taobao.org/dist --global

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_nodejs()
{
	local TMP_NVM_SETUP_DIR=${1}

	cd ${TMP_NVM_SETUP_DIR}
	
	# 验证安装
	nvm current

	# 添加系统启动命令（RPM还是需要）
    echo_startup_config "nvm" "${TMP_NVM_SETUP_DIR}" "tail -f $(dirname ~/1)/npm-debug.log" "" "1" "${NVM_PATH}"

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_nodejs()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_nodejs()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_nodejs()
{
	local TMP_NVM_SETUP_DIR=${SETUP_DIR}/nvm
    
	set_env_nodejs "${TMP_NVM_SETUP_DIR}"

	setup_nodejs "${TMP_NVM_SETUP_DIR}"

	conf_nodejs "${TMP_NVM_SETUP_DIR}"

    # down_plugin_nodejs "${TMP_NVM_SETUP_DIR}"

	boot_nodejs "${TMP_NVM_SETUP_DIR}"

	return $?
}

##########################################################################################################

# x1-下载软件
function check_setup_nodejs()
{
    path_not_exists_action "${NVM_PATH}" "exec_step_nodejs" "NodeJS was installed"
	
	source ${NVM_PATH}

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "NodeJS" "check_setup_nodejs"