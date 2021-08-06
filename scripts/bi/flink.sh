#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 参考文献：
#         https://ci.apache.org/projects/flink/flink-docs-release-1.13/zh/docs
#------------------------------------------------

# 1-配置环境
function set_environment()
{
    cd ${__DIR}

    source scripts/lang/java.sh
    source scripts/ha/hadoop.sh

	return $?
}

# 2-安装软件
function setup_flink()
{
	local TMP_FLK_SETUP_DIR=${1}
	local TMP_FLK_CURRENT_DIR=${2}

	## 直装模式
	cd `dirname ${TMP_FLK_CURRENT_DIR}`

	mv ${TMP_FLK_CURRENT_DIR} ${TMP_FLK_SETUP_DIR}

	# 创建日志软链
	local TMP_FLK_LNK_LOGS_DIR=${LOGS_DIR}/flink
	local TMP_FLK_LNK_DATA_DIR=${DATA_DIR}/flink
	local TMP_FLK_LOGS_DIR=${TMP_FLK_SETUP_DIR}/log
	local TMP_FLK_DATA_DIR=${TMP_FLK_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_FLK_LOGS_DIR}
	rm -rf ${TMP_FLK_DATA_DIR}
	mkdir -pv ${TMP_FLK_LNK_LOGS_DIR}
	mkdir -pv ${TMP_FLK_LNK_DATA_DIR}
	
	ln -sf ${TMP_FLK_LNK_LOGS_DIR} ${TMP_FLK_LOGS_DIR}
	ln -sf ${TMP_FLK_LNK_DATA_DIR} ${TMP_FLK_DATA_DIR}

	# 环境变量或软连接
	echo "FLINK_HOME=${TMP_FLK_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$FLINK_HOME/bin:$PATH' >> /etc/profile
	echo "export PATH FLINK_HOME" >> /etc/profile

    # 重新加载profile文件
	source /etc/profile
	# ln -sf ${TMP_FLK_SETUP_DIR}/bin/flink /usr/bin/flink

	# 授权权限，否则无法写入
	# chown -R flink:flink_group ${TMP_FLK_SETUP_DIR}

	return $?
}

# 3-设置软件
function conf_flink()
{
	cd ${1}

    sed -i "s@web\.port:.*@web\.port: 9010@g" conf/flink-conf.yaml

    local TMP_FLK_HDOP_CLUSTER_MASTER_HOSTS="${LOCAL_HOST}"
    exec_while_read "TMP_FLK_HDOP_CLUSTER_MASTER_HOSTS" "Hadoop: Please ender cluster-master-host part \$I of address like '${LOCAL_HOST}'"
    echo "${TMP_FLK_HDOP_CLUSTER_MASTER_HOSTS}" | sed "s@,@\n@g" | awk -F'.' '{print "lnxsvr.ha"$4}' > conf/masters
    cat conf/masters
    echo 

    sed -i "s@jobmanager\.rpc\.address:.*@jobmanager\.rpc\.address: ${TMP_FLK_HDOP_CLUSTER_MASTER_HOSTS}@g" conf/flink-conf.yaml
    sed -i "s@taskmanager\.numberOfTaskSlots:.*@taskmanager\.numberOfTaskSlots: $PROCESSOR_COUNT@g" conf/flink-conf.yaml

    local TMP_FLNK_HDOP_CLUSTER_SLAVE_HOSTS="${LOCAL_HOST}"
    exec_while_read "TMP_FLNK_HDOP_CLUSTER_SLAVE_HOSTS" "Hadoop: Please ender cluster-slave-host part \$I of address like '${LOCAL_HOST}'"
    echo "$TMP_FLNK_HDOP_CLUSTER_SLAVE_HOSTS" | sed "s@,@\n@g" | awk -F'.' '{print "lnxsvr.ha"$4}' > conf/slaves
    cat conf/slaves
    echo 

    # cd $FLINK_DIR/resources/python
    # python setup.py install
    
    echo_soft_port 9010

    echo_startup_config "flink" "$FLINK_DIR" "bash bin/start-cluster.sh" "" "100"

	return $?
}

# 4-启动软件
function boot_flink()
{
	local TMP_FLK_SETUP_DIR=${1}

	cd ${TMP_FLK_SETUP_DIR}
	
	# 当前启动命令
    exec_yn_action "start_flink" "Flink-Cluster: Please sure you if this is a boot server of master"
	
	return $?
}

function boot_flink_realy()
{
    # 集群模式下，只需要主服务启动
    bash bin/start-cluster.sh

	# 验证安装
    jps

	# 添加系统启动命令
    echo_startup_config "flink" "${TMP_FLK_SETUP_DIR}" "bash bin/start-cluster.sh" "" "100"
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_flink()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_flink()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_flink()
{
	local TMP_FLK_SETUP_DIR=${1}
	local TMP_FLK_CURRENT_DIR=`pwd`
    
	set_environment "${TMP_FLK_SETUP_DIR}"

	setup_flink "${TMP_FLK_SETUP_DIR}" "${TMP_FLK_CURRENT_DIR}"

	conf_flink "${TMP_FLK_SETUP_DIR}"

    # down_plugin_flink "${TMP_FLK_SETUP_DIR}"

	boot_flink "${TMP_FLK_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_flink()
{
	local TMP_OFFICIAL_STABLE_VERSION=`curl -s https://flink.apache.org/downloads.html | egrep "Apache Flink® .+ is our latest stable release" | awk -F' ' '{print $3}'`
	echo "Flink: The newer stable version is ${TMP_OFFICIAL_STABLE_VERSION}"
    
	exec_text_format "TMP_FLK_SETUP_NEWER" "https://archive.apache.org/dist/flink/flink-%s/flink-%s-bin-scala_2.12.tgz"
    setup_soft_wget "flink" "${TMP_FLK_SETUP_NEWER}" "exec_step_flink"

	return $?
}

#安装主体
setup_soft_basic "Flink" "down_flink"
