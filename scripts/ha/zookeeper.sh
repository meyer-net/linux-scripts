#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 安装标题：Zookeeper
# 软件名称：zookeeper
# 软件大写名称：ZOOKEEPER
# 软件大写分组与简称：ZK
# 软件安装名称：zookeeper
# 软件授权用户名称&组：zookeeper/zookeeper_group
#------------------------------------------------

# 1-配置环境
function set_environment()
{
    cd ${__DIR}

    source scripts/lang/java.sh

	return $?
}

# 2-安装软件
function setup_zookeeper()
{
	local TMP_ZK_SETUP_DIR=${1}
	local TMP_ZK_CURRENT_DIR=${2}

	## 直装模式
	cd `dirname ${TMP_ZK_CURRENT_DIR}`

	mv ${TMP_ZK_CURRENT_DIR} ${TMP_ZK_SETUP_DIR}

	# 创建日志软链
	local TMP_ZK_LNK_LOGS_DIR=${LOGS_DIR}/zookeeper
	local TMP_ZK_LNK_DATA_DIR=${DATA_DIR}/zookeeper
	local TMP_ZK_LOGS_DIR=${TMP_ZK_SETUP_DIR}/logs
	local TMP_ZK_DATA_DIR=${TMP_ZK_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_ZK_LOGS_DIR}
	rm -rf ${TMP_ZK_DATA_DIR}
	mkdir -pv ${TMP_ZK_LNK_LOGS_DIR}
	mkdir -pv ${TMP_ZK_LNK_DATA_DIR}
	
	# 特殊多层结构下使用
    # mkdir -pv `dirname ${TMP_ZK_LOGS_DIR}`
    # mkdir -pv `dirname ${TMP_ZK_DATA_DIR}`

	ln -sf ${TMP_ZK_LNK_LOGS_DIR} ${TMP_ZK_LOGS_DIR}
	ln -sf ${TMP_ZK_LNK_DATA_DIR} ${TMP_ZK_DATA_DIR}

	# 环境变量或软连接
	echo "ZOOKEEPER_HOME=${TMP_ZK_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$ZOOKEEPER_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH ZOOKEEPER_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

	return $?
}

# 3-设置软件，集群分开装，只管配置本机与其它集群许可
function conf_zookeeper()
{
	local TMP_ZK_SETUP_DIR=${1}

	cd ${TMP_ZK_SETUP_DIR}
	
	local TMP_ZK_LNK_ETC_DIR=${ATT_DIR}/zookeeper
	local TMP_ZK_ETC_DIR=${TMP_ZK_SETUP_DIR}/conf
    mv ${TMP_ZK_ETC_DIR} ${TMP_ZK_LNK_ETC_DIR}
	# rm -rf ${TMP_ZK_ETC_DIR}
	# mkdir -pv ${TMP_ZK_LNK_ETC_DIR}
	ln -sf ${TMP_ZK_LNK_ETC_DIR} ${TMP_ZK_ETC_DIR}

	local TMP_ZK_DATA_DIR=${TMP_ZK_SETUP_DIR}/data
    local TMP_ZK_MASTER_HOST="${LOCAL_HOST}"
    mv conf/zoo_sample.cfg conf/zoo.cfg

	# 开始配置
    sed -i "s@dataDir=.*@dataDir=${TMP_ZK_DATA_DIR}@g" conf/zoo.cfg
    sed -i "s@clientPort=2181@clientPort=2233@g" conf/zoo.cfg

    # 添加许可密钥给定集群
	path_not_exists_action "~/.ssh/id_rsa.pub" "ssh-keygen -t rsa -P \'\'"
    
    local TMP_ZK_CLUSTER_LOCAL_ID="${LOCAL_ID}"
    # input_if_empty "TMP_ZK_CLUSTER_LOCAL_ID" "ZooKeeper: Please Ender This Server Of Index In Cluster"
    echo ${TMP_ZK_CLUSTER_LOCAL_ID} > ${TMP_ZK_DATA_DIR}/myid

    local TMP_ZK_CLUSTER_INDEX_DFT="${LOCAL_HOST}"
    exec_while_read "TMP_ZK_CLUSTER_INDEX_DFT" "ZooKeeper: Please Ender Cluster Index.\${I} Address Like '${LOCAL_HOST}'" "" "
        local TMP_ZK_CLUSTER_INDEX_ID=\`echo \\\${CURRENT##*.}\`
        echo \"Port of 4001 allowed for \'\${CURRENT}\'\"
        echo_soft_port 4001 \${CURRENT}
        echo \"Port of 4002 allowed for \'\${CURRENT}\'\"
        echo_soft_port 4002 \${CURRENT}
        
        # 本机则开放全部授权
        if [ \${TMP_ZK_CLUSTER_INDEX_ID} == \${TMP_ZK_CLUSTER_LOCAL_ID} ]; then
            CURRENT='0.0.0.0'
        fi

        echo \"server.\${TMP_ZK_CLUSTER_INDEX_ID}=\${CURRENT}:4001:4002\" >> conf/zoo.cfg
        echo \"Cluster INDEX-\$I Of 'server.\${TMP_ZK_CLUSTER_INDEX_ID} -> \${CURRENT}' Was Added To conf/zoo.cfg\"
    "

	return $?
}

# 4-启动软件
function boot_zookeeper()
{
	local TMP_ZK_SETUP_DIR=${1}

	cd ${TMP_ZK_SETUP_DIR}
	
	# 验证安装
    bash bin/zkServer.sh version

	# 当前启动命令
	nohup bash bin/zkServer.sh start > logs/boot.log 2>&1 &

    # 等待启动
    echo "Starting zookeeper，Waiting for a moment"
    sleep 10
    bash bin/zkServer.sh status

	# 添加系统启动命令
    echo_startup_config "zookeeper" "${TMP_ZK_SETUP_DIR}" "bash bin/zkServer.sh start" "" "1"

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_zookeeper()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_zookeeper()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_zookeeper()
{
	local TMP_ZK_SETUP_DIR=${1}
	local TMP_ZK_CURRENT_DIR=`pwd`
    
	set_environment "${TMP_ZK_SETUP_DIR}"

	setup_zookeeper "${TMP_ZK_SETUP_DIR}" "${TMP_ZK_CURRENT_DIR}"

	conf_zookeeper "${TMP_ZK_SETUP_DIR}"

    # down_plugin_zookeeper "${TMP_ZK_SETUP_DIR}"

	boot_zookeeper "${TMP_ZK_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_zookeeper()
{
	local TMP_ZK_SETUP_NEWER="zookeeper-3.7.0"
	local TMP_ZK_DOWN_URL_BASE="https://archive.apache.org/dist/zookeeper/"
	set_url_list_newer_href_link_filename "TMP_ZK_SETUP_NEWER" "${TMP_ZK_DOWN_URL_BASE}" "zookeeper-()"
	exec_text_format "TMP_ZK_SETUP_NEWER" "${TMP_ZK_DOWN_URL_BASE}/%s/apache-%s-bin.tar.gz"
    setup_soft_wget "zookeeper" "${TMP_ZK_SETUP_NEWER}" "exec_step_zookeeper"

	return $?
}

#安装主体
setup_soft_basic "Zookeeper" "down_zookeeper"
