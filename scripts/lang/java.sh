#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------

##########################################################################################################

# 1-配置环境
function set_env_java()
{	
	return $?
}

##########################################################################################################

# 2-安装软件
function setup_java()
{
	local TMP_LANG_JAVA_SETUP_DIR=${1}
	local TMP_LANG_JAVA_CURRENT_DIR=`pwd`

	## 直装模式

	cd ..

	mv ${TMP_LANG_JAVA_CURRENT_DIR} ${TMP_LANG_JAVA_SETUP_DIR}

    path_not_exists_action "/usr/lib/jvm/java-1.8.0" "mkdir -pv /usr/lib/jvm && ln -sf ${JAVA_HOME:-${TMP_LANG_JAVA_SETUP_DIR}} /usr/lib/jvm/java-1.8.0"

	# 环境变量
	echo "JAVA_HOME=${JAVA_HOME:-${TMP_LANG_JAVA_SETUP_DIR}}" >> /etc/profile
	echo 'JRE_HOME=$JAVA_HOME/jre' >> /etc/profile
	echo 'CLASSPATH=$JAVA_HOME/lib:$JRE_HOME/lib' >> /etc/profile
	echo 'JAVA_BIN=$JAVA_HOME/bin' >> /etc/profile
	echo 'PATH=$JAVA_BIN:$PATH' >> /etc/profile
	echo "export PATH JAVA_HOME JAVA_BIN JRE_HOME CLASSPATH" >> /etc/profile
	
	source /etc/profile
	
    path_not_exists_create "${JV_DIR}"

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_java()
{
	cd ${1}

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_java()
{
	local TMP_LANG_JAVA_SETUP_DIR=${1}

	cd ${TMP_LANG_JAVA_SETUP_DIR}

    # 验证安装
	java -version

    # echo_startup_config "graphics_magick" "${TMP_TL_GM_SETUP_DIR}" "bin/graphics_magick" "" "100"

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_tool_gradle()
{
	local TMP_LANG_JAVA_TOOL_GRADLE_SETUP_NEWER="7.2"
	
	local TMP_LANG_JAVA_TOOL_GRADLE_SETUP_DOWN_URL_BASE="https://services.gradle.org/distributions/"
	set_newer_by_url_list_link_text "TMP_LANG_JAVA_TOOL_GRADLE_SETUP_NEWER" "${TMP_LANG_JAVA_TOOL_GRADLE_SETUP_DOWN_URL_BASE}" "gradle-()-bin.zip"
	exec_text_format "TMP_LANG_JAVA_TOOL_GRADLE_SETUP_NEWER" "${TMP_LANG_JAVA_TOOL_GRADLE_SETUP_DOWN_URL_BASE}gradle-%s-bin.zip"
	setup_soft_wget "gradle" "${TMP_LANG_JAVA_TOOL_GRADLE_SETUP_NEWER}" "setup_tool_gradle"

	return $?
}

# 安装驱动/插件
function setup_tool_gradle()
{
	local TMP_LANG_JAVA_TOOL_GRADLE_SETUP_DIR=${1}
	local TMP_LANG_JAVA_TOOL_GRADLE_CURRENT_DIR=`pwd`

	## 直装模式

	cd ..

	mv ${TMP_LANG_JAVA_TOOL_GRADLE_CURRENT_DIR} ${TMP_LANG_JAVA_TOOL_GRADLE_SETUP_DIR}

	echo "GRADLE_HOME=${TMP_LANG_JAVA_TOOL_GRADLE_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$GRADLE_HOME/bin:$PATH' >> /etc/profile
	echo "export PATH GRADLE_HOME" >> /etc/profile

	source /etc/profile

	gradle -version

	return $?
}

# 安装工具
function setup_tool_maven()
{
	soft_yum_check_setup "maven"

	mvn -version
	
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_java()
{
	local TMP_LANG_JAVA_SETUP_DIR=${1}
    
	set_env_java "${TMP_LANG_JAVA_SETUP_DIR}"

	setup_java "${TMP_LANG_JAVA_SETUP_DIR}"

	conf_java "${TMP_LANG_JAVA_SETUP_DIR}"

	boot_java "${TMP_LANG_JAVA_SETUP_DIR}"

    down_tool_gradle
	
	setup_tool_maven

	return $?
}

##########################################################################################################

# x1-下载软件
function down_java()
{
	# http://dl.mycat.io/jdk-8u20-linux-x64.tar.gz
	# wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" +链接地址
	# https://www.oracle.com/java/technologies/javase/javase-jdk8-downloads.html
	# wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" https://download.oracle.com/otn-pub/java/jdk/8u201-b09/42970487e3af4f5aa5bca3f542482c60/jdk-8u151-linux-x64.rpm 
	# rpm -ivh jdk-8u151-linux-x64.rpm 

	# setup_soft_wget "java" '--no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u291-b10/d7fc238d0cbf4b0dac67be84580cfb4b/jdk-8u291-linux-x64.tar.gz' "exec_step_java"
	# setup_soft_wget "java" 'https://d6.injdk.cn/openjdk/liberica/8/full/bellsoft-jdk8u275+1-linux-amd64-full.tar.gz' "exec_step_java"
	# setup_soft_wget "java" 'https://d6.injdk.cn/openjdk/liberica/8/standard/bellsoft-jdk8u275+1-linux-amd64.tar.gz' "exec_step_java"
	setup_soft_wget "java" 'https://mirrors.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz' "exec_step_java"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "java" "down_java"
