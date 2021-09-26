#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 参考文献：
#         https://ci.apache.org/projects/flink/flink-docs-release-1.13/zh/docs
#------------------------------------------------
local TMP_FLK_SETUP_PRC_PORT=16123
local TMP_FLK_SETUP_REST_PORT=18081
local TMP_FLK_SETUP_HIS_WEB_PORT=19010

local TMP_FLK_SETUP_HDOP_PORT=13000

##########################################################################################################

# 1-配置环境
function set_env_flink()
{
    cd ${__DIR} && source scripts/lang/java.sh
    cd ${__DIR} && source scripts/lang/python.sh
    
    local TMP_IS_FLK_HDOP_LOCAL=`lsof -i:${TMP_FLK_SETUP_HDOP_PORT}`
    if [ -z "${TMP_IS_FLK_HDOP_LOCAL}" ]; then 
        exec_yn_action "setup_hadoop" "Flink.Hadoop: Please sure if u want to get hadoop local?"
    fi

	return $?
}

##########################################################################################################

function setup_hadoop()
{
    cd ${__DIR} && source scripts/ha/hadoop.sh

	return $?
}

##########################################################################################################

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
	echo 'export PATH FLINK_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile
	# ln -sf ${TMP_FLK_SETUP_DIR}/bin/flink /usr/bin/flink

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_flink()
{
	cd ${1}

    # 相关配置参考：https://ci.apache.org/projects/flink/flink-docs-release-1.13/docs/deployment/config/
    sed -i "s@jobmanager\.rpc\.address:.*@jobmanager\.rpc\.address: ${LOCAL_HOST}@g" conf/flink-conf.yaml
    sed -i "s@jobmanager\.rpc\.port:.*@jobmanager\.rpc\.port: ${TMP_FLK_SETUP_PRC_PORT}@g" conf/flink-conf.yaml
    sed -i "s@jobmanager\.memory\.process\.size:.*@jobmanager\.memory\.process\.size: $((MEMORY_GB_FREE*1024))m@g" conf/flink-conf.yaml
    sed -i "s@taskmanager\.memory\.process\.size:.*@taskmanager\.memory\.process\.size: $((MEMORY_GB_FREE*1024))m@g" conf/flink-conf.yaml

    # 每一台机器上能使用的 CPU 个数
    sed -i "s@taskmanager\.numberOfTaskSlots:.*@taskmanager\.numberOfTaskSlots: ${PROCESSOR_COUNT}@g" conf/flink-conf.yaml
    
    # Flink web UI默认端口与Spark的端口8081冲突,更改为${TMP_FLK_SETUP_REST_PORT}
    sed -i "s@^#rest\.port:.*@rest\.port: ${TMP_FLK_SETUP_REST_PORT}@g" conf/flink-conf.yaml

    sed -i "s@^#historyserver\.web\.address@historyserver\.web\.address@g" conf/flink-conf.yaml
    sed -i "s@^#historyserver\.web\.port:.*@historyserver\.web\.port: ${TMP_FLK_SETUP_HIS_WEB_PORT}@g" conf/flink-conf.yaml

    # ??? 集群部署尚不完善，参考hadoop配置发方法操作完成：https://www.cnblogs.com/frankdeng/p/9400627.html
    # exec_yn_action "conf_flink_cluster" "Flink.Cluster: Please sure if this install is ${green}cluster mode${reset}"

    # cd $FLINK_DIR/resources/python
    # python setup.py install

	return $?
}

##########################################################################################################

# 集群模式yarn管理下需安装hadoop，此处暂时略
function conf_flink_cluster()
{
    local TMP_FLK_HDOP_CLUSTER_MASTER_HOST="${LOCAL_HOST}"
    local TMP_FLK_HDOP_CLUSTER_SLAVE_HOSTS="${LOCAL_HOST}"

    input_if_empty "TMP_FLK_HDOP_CLUSTER_MASTER_HOST" "Flink.Hadoop: Please ender cluster-master-host like '${LOCAL_HOST}'"
    echo "${LOCAL_HOST}" > conf/masters
    echo "${TMP_FLK_HDOP_CLUSTER_MASTER_HOST}" > conf/masters
    # echo "${TMP_FLK_HDOP_CLUSTER_MASTER_HOST}" | sed "s@\.@-@g" | awk '{print "ip-"$1}' > conf/masters
    # echo "${TMP_FLK_HDOP_CLUSTER_MASTER_HOST}" | sed 's@,@\n@g' | awk '{print $1" ip-"$1}' | sed 's@\.@-@4g' > /etc/hosts
    cat conf/masters
    echo 

    # 这里定于rpc地址，可以认为是master地址，jobmanager所在节点
    # sed -i "s@jobmanager\.rpc\.address:.*@jobmanager\.rpc\.address: ${TMP_FLK_HDOP_CLUSTER_MASTER_HOST}@g" conf/flink-conf.yaml

    exec_while_read "TMP_FLK_HDOP_CLUSTER_SLAVE_HOSTS" "Flink.Hadoop: Please ender cluster-slave-host part \${I} of address like '${LOCAL_HOST}'"
    echo "${TMP_FLK_HDOP_CLUSTER_SLAVE_HOSTS}" | sed 's@,@\n@g' > conf/slaves
    # echo "${TMP_FLK_HDOP_CLUSTER_SLAVE_HOSTS}" | sed "s@\.@-@g" | sed 's@,@\n@g' | awk '{print "ip-"$1}' > conf/slaves
    # echo "${TMP_FLK_HDOP_CLUSTER_SLAVE_HOSTS}" | sed 's@,@\n@g' | awk '{print $1" ip-"$1}' | sed 's@\.@-@4g' > /etc/hosts
    cat conf/slaves
    echo 
    
    # 启动应用的默认并行度（该应用所使用总的CPU数，即集群中的总 CPU个数）
    local TMP_FLK_CLUSTER_COUNT=`echo ${TMP_FLK_HDOP_CLUSTER_SLAVE_HOSTS} | grep -o "," | echo $((\`wc -l\`+1))`
    sed -i "s@parallelism\.default:.*@parallelism\.default: $((TMP_FLK_CLUSTER_COUNT*PROCESSOR_COUNT))@g" conf/flink-conf.yaml

    # ???添加集群高可用支持zookeeper

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_flink()
{
	local TMP_FLK_SETUP_DIR=${1}

	cd ${TMP_FLK_SETUP_DIR}
    
	# 授权iptables端口访问
    echo_soft_port ${TMP_FLK_SETUP_PRC_PORT}
    echo_soft_port ${TMP_FLK_SETUP_REST_PORT}
    echo_soft_port ${TMP_FLK_SETUP_HIS_WEB_PORT}
	
    # 生成web授权访问脚本
    echo_web_service_init_scripts "flink${LOCAL_ID}" "flink${LOCAL_ID}-webui.${SYS_DOMAIN}" ${TMP_FLK_SETUP_REST_PORT} "${LOCAL_HOST}"

	# 当前启动命令
    exec_yn_action "boot_flink_master" "Flink.Cluster.Master: Please sure if this is a boot server of master"
	
	return $?
}

function boot_flink_master()
{
    # 集群模式下，只需要主服务启动
    bash bin/start-cluster.sh
    bash bin/historyserver.sh start

	# 验证安装
    jps
    lsof -i:${TMP_FLK_SETUP_PRC_PORT}
    lsof -i:${TMP_FLK_SETUP_REST_PORT}
    lsof -i:${TMP_FLK_SETUP_HIS_WEB_PORT}

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
    
	set_env_flink "${TMP_FLK_SETUP_DIR}"

	setup_flink "${TMP_FLK_SETUP_DIR}" "${TMP_FLK_CURRENT_DIR}"

	conf_flink "${TMP_FLK_SETUP_DIR}"

    # down_plugin_flink "${TMP_FLK_SETUP_DIR}"

	boot_flink "${TMP_FLK_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_flink()
{
	local TMP_FLK_SETUP_OFFICIAL_STABLE_VERS=`curl -s https://flink.apache.org/downloads.html | egrep "Apache Flink® .+ is our latest stable release" | awk -F' ' '{print $3}'`
	echo "Flink: The newer stable version is ${TMP_FLK_SETUP_OFFICIAL_STABLE_VERS}"
    
    # 目前robot仅最高支持1.12.5
    input_if_empty "TMP_FLK_SETUP_OFFICIAL_STABLE_VERS" "Please sure the checked soft version by official newer ${green}${TMP_NEWER_DATE_LINK_FILENAME}${reset}，if u want to change"

    local TMP_FLK_SETUP_NEWER="${TMP_FLK_SETUP_OFFICIAL_STABLE_VERS}"
	exec_text_format "TMP_FLK_SETUP_NEWER" "https://archive.apache.org/dist/flink/flink-%s/flink-%s-bin-scala_2.12.tgz"
    setup_soft_wget "flink" "${TMP_FLK_SETUP_NEWER}" "exec_step_flink"

	return $?
}

#安装主体
setup_soft_basic "Flink" "down_flink"
