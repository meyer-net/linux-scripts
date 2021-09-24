#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 参考文献：
#		   http://www.jianshu.com/p/b49712bbe044
#          http://dblab.xmu.edu.cn/blog/install-hadoop/
#------------------------------------------------
local TMP_HDOP_SETUP_HDFS_PORT=13000
local TMP_HDOP_SETUP_SCHEDULER_PORT=18030
local TMP_HDOP_SETUP_RES_TRACK_PORT=18031
local TMP_HDOP_SETUP_RES_MGR_PORT=18032
local TMP_HDOP_SETUP_RES_ADMIN_PORT=18033
local TMP_HDOP_SETUP_WEBAPP_PORT=18088
local TMP_HDOP_SETUP_WEBAPP_HTTPS_PORT=18090

local TMP_HDOP_WAS_SETUPED=0

##########################################################################################################

# 1-配置环境
function set_env_hadoop()
{
    cd ${__DIR} && source scripts/lang/java.sh

	return $?
}

##########################################################################################################

# 2-安装软件
# 因采用主拷贝从的方式安装，所以默认本机为安装的情况均为主节点
function setup_hadoop()
{
	local TMP_HDOP_SETUP_DIR=${1}
	local TMP_HDOP_CURRENT_DIR=${2}

	## 直装模式
	cd `dirname ${TMP_HDOP_CURRENT_DIR}`

	mv ${TMP_HDOP_CURRENT_DIR} ${TMP_HDOP_SETUP_DIR}

	# 创建日志软链
	local TMP_HDOP_LNK_LOGS_DIR=${LOGS_DIR}/hadoop
	local TMP_HDOP_LNK_DATA_DIR=${DATA_DIR}/hadoop
	local TMP_HDOP_LOGS_DIR=${TMP_HDOP_SETUP_DIR}/logs
	local TMP_HDOP_DATA_DIR=${TMP_HDOP_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_HDOP_LOGS_DIR}
	rm -rf ${TMP_HDOP_DATA_DIR}
	mkdir -pv ${TMP_HDOP_LNK_LOGS_DIR}
	mkdir -pv ${TMP_HDOP_LNK_DATA_DIR}
	
	ln -sf ${TMP_HDOP_LNK_LOGS_DIR} ${TMP_HDOP_LOGS_DIR}
	ln -sf ${TMP_HDOP_LNK_DATA_DIR} ${TMP_HDOP_DATA_DIR}
	
    mkdir -pv ${TMP_HDOP_DATA_DIR}/tmp
    mkdir -pv ${TMP_HDOP_DATA_DIR}/var
    mkdir -pv ${TMP_HDOP_DATA_DIR}/dfs
    mkdir -pv ${TMP_HDOP_DATA_DIR}/dfs/name
    mkdir -pv ${TMP_HDOP_DATA_DIR}/dfs/data

	# 环境变量或软连接
	echo "HADOOP_HOME=${TMP_HDOP_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH' >> /etc/profile
	echo "export PATH HADOOP_HOME" >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_hadoop()
{
	local TMP_HDOP_SETUP_DIR=${1}
	cd ${TMP_HDOP_SETUP_DIR}
	
	local TMP_HDOP_DATA_DIR=${TMP_HDOP_SETUP_DIR}/data
	local TMP_HDOP_LOGS_DIR=${TMP_HDOP_SETUP_DIR}/logs	
	local TMP_HDOP_LNK_ETC_DIR=${ATT_DIR}/hadoop
	local TMP_HDOP_ETC_DIR=${TMP_HDOP_SETUP_DIR}/etc

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mv ${TMP_HDOP_ETC_DIR} ${TMP_HDOP_LNK_ETC_DIR}

	# 替换原路径链接
	ln -sf ${TMP_HDOP_LNK_ETC_DIR} ${TMP_HDOP_ETC_DIR}

    local TMP_HDOP_MASTER_HOST="${LOCAL_HOST}"
    
	echo "export HDFS_NAMENODE_USER=root" >> etc/hadoop/hadoop-env.sh
	echo "export HDFS_DATANODE_USER=root" >> etc/hadoop/hadoop-env.sh
	echo "export HDFS_SECONDARYNAMENODE_USER=root" >> etc/hadoop/hadoop-env.sh
	echo "export YARN_RESOURCEMANAGER_USER=root" >> etc/hadoop/hadoop-env.sh
	echo "export YARN_NODEMANAGER_USER=root" >> etc/hadoop/hadoop-env.sh
	echo "export JAVA_HOME=${JAVA_HOME}" >> etc/hadoop/hadoop-env.sh
		
	local TMP_HDOP_CLUSTER_SSH_PORT=10022
	input_if_empty "TMP_HDOP_CLUSTER_SSH_PORT" "Hadoop: Please ender the ${green}ssh port${reset} of cluster"
	echo "export HADOOP_SSH_OPTS='-p ${TMP_HDOP_CLUSTER_SSH_PORT}'" >> etc/hadoop/hadoop-env.sh

	# 全局，给后面的函数读取
	# TMP_HDOP_HADOOP_MASTER_NAME=`echo ${TMP_HDOP_MASTER_HOST##*.}`
	TMP_HDOP_HADOOP_MASTER_NAME=`echo ${TMP_HDOP_MASTER_HOST} | sed 's@\.@-@g' | xargs -I {} echo "ip-{}"`
	
	echo "${TMP_HDOP_MASTER_HOST} ${TMP_HDOP_CLUSTER_MASTER_NAME}" >> /etc/hosts
    
    cat >etc/hadoop/core-site.xml<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
<property>
	<name>hadoop.tmp.dir</name>
	<value>file:${TMP_HDOP_DATA_DIR}/tmp</value>
	<description>Abase for other temporary directories.</description>
</property>
<property>
	<name>fs.defaultFS</name>
	<value>hdfs://${TMP_HDOP_HADOOP_MASTER_NAME}:${TMP_HDOP_SETUP_HDFS_PORT}</value>
</property>
</configuration>
EOF

    # sed -i "s@^export JAVA_HOME=\${JAVA_HOME}@export JAVA_HOME=$JAVA_HOME@g" etc/hadoop/hadoop-env.sh

    cat >etc/hadoop/hdfs-site.xml<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
<property>
	<name>dfs.replication</name>
	<value>1</value>
	<description>表示数据块的备份数量，不能大于DataNode的数量</description>
</property>
<property>
	<name>dfs.namenode.name.dir</name>
	<value>${TMP_HDOP_DATA_DIR}/dfs/name</value>
	<description>表示 NameNode 需要存储数据的文件目录</description>
</property>
<property>
  <name>dfs.datanode.data.dir</name>
	<value>${TMP_HDOP_DATA_DIR}/dfs/data</value>
	<description>表示 DataNode 需要存放数据的文件目录</description>
</property>
</configuration>
EOF

	# cp etc/hadoop/mapred-site.xml.template etc/hadoop/mapred-site.xml
	cat >etc/hadoop/mapred-site.xml<<EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
<property>
    <name>mapred.job.tracker</name>
    <value>${TMP_HDOP_HADOOP_MASTER_NAME}:49001</value>
</property>
<property>
      <name>mapred.local.dir</name>
       <value>${TMP_HDOP_DATA_DIR}/var</value>
</property>
<property>
       <name>mapreduce.framework.name</name>
       <value>yarn</value>
</property>
</configuration>
EOF
		
	cat >etc/hadoop/yarn-site.xml<<EOF
<?xml version="1.0"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<configuration>

<!-- Site specific YARN configuration properties -->
<property>
        <name>yarn.resourcemanager.hostname</name>
        <value>${TMP_HDOP_HADOOP_MASTER_NAME}</value>
		<description>表示ResourceManager安装的主机</description>
   </property>
   <property>
        <description>The address of the applications manager interface in the RM.</description>
        <name>yarn.resourcemanager.address</name>
        <value>\${yarn.resourcemanager.hostname}:${TMP_HDOP_SETUP_RES_MGR_PORT}</value>
		<description>表示ResourceManager监听的端口</description>
   </property>
   <property>
        <description>The address of the scheduler interface.</description>
        <name>yarn.resourcemanager.scheduler.address</name>
        <value>\${yarn.resourcemanager.hostname}:${TMP_HDOP_SETUP_SCHEDULER_PORT}</value>
   </property>
   <property>
        <description>The http address of the RM web application.</description>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>\${yarn.resourcemanager.hostname}:${TMP_HDOP_SETUP_WEBAPP_PORT}</value>
   </property>
   <property>
        <description>The https adddress of the RM web application.</description>
        <name>yarn.resourcemanager.webapp.https.address</name>
        <value>\${yarn.resourcemanager.hostname}:${TMP_HDOP_SETUP_WEBAPP_HTTPS_PORT}</value>
   </property>
   <property>
        <name>yarn.resourcemanager.resource-tracker.address</name>
        <value>\${yarn.resourcemanager.hostname}:${TMP_HDOP_SETUP_RES_TRACK_PORT}</value>
   </property>
   <property>
        <description>The address of the RM admin interface.</description>
        <name>yarn.resourcemanager.admin.address</name>
        <value>\${yarn.resourcemanager.hostname}:${TMP_HDOP_SETUP_RES_ADMIN_PORT}</value>
   </property>
   <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
   </property>
   <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>2048</value>
        <discription>每个节点可用内存,单位MB,默认8182MB</discription>
   </property>
   <property>
        <name>yarn.nodemanager.vmem-pmem-ratio</name>
        <value>2.1</value>
   </property>
   <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>4096</value>
		<description>表示这个NodeManager管理的内存大小</description>
   </property>
   <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
   </property>
</configuration>
EOF

    rm -rf share/doc

    # 添加许可密钥给定集群
	path_not_exists_action '~/.ssh/id_rsa.pub' 'ssh-keygen -t rsa -P ""'

	# 添加授权
    cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys

    # echo_soft_port ${TMP_HDOP_SETUP_HDFS_PORT} "${TMP_HDOP_MASTER_HOST}"
    # echo_soft_port ${TMP_HDOP_SETUP_SCHEDULER_PORT} "${TMP_HDOP_MASTER_HOST}"
    # echo_soft_port ${TMP_HDOP_SETUP_RES_TRACK_PORT} "${TMP_HDOP_MASTER_HOST}"
    # echo_soft_port ${TMP_HDOP_SETUP_RES_MGR_PORT} "${TMP_HDOP_MASTER_HOST}"
    # echo_soft_port ${TMP_HDOP_SETUP_RES_ADMIN_PORT} "${TMP_HDOP_MASTER_HOST}"
    # echo_soft_port ${TMP_HDOP_SETUP_WEBAPP_PORT} "${TMP_HDOP_MASTER_HOST}"
    # echo_soft_port ${TMP_HDOP_SETUP_WEBAPP_HTTPS_PORT} "${TMP_HDOP_MASTER_HOST}"
    # echo_soft_port 49001 "${TMP_HDOP_MASTER_HOST}"
    # echo_soft_port 50070 "${TMP_HDOP_MASTER_HOST}"
    # echo_soft_port 50075 "${TMP_HDOP_MASTER_HOST}"

    # cat /etc/sysconfig/iptables | sed -n '12,21p' > ssh_sed_hadoop_${TMP_HDOP_HADOOP_MASTER_NAME}_port.tmp

	# 添加系统启动命令
	echo_startup_config "hadoop-dfs" `pwd` "bash sbin/start-dfs.sh" "" "10"
	
    exec_yn_action "conf_hadoop_cluster" "Hadoop: Please sure if this install is cluster mode"

	return $?
}

# Hadoop安装：选定一台主机作为master
# 远程机器目录必须预先初始化系统目录基础结构
function conf_hadoop_cluster()
{
	local TMP_HDOP_SETUP_DIR=`pwd`
	local TMP_HDOP_LNK_LOGS_DIR=${LOGS_DIR}/hadoop
	local TMP_HDOP_LNK_DATA_DIR=${DATA_DIR}/hadoop
	local TMP_HDOP_LNK_ETC_DIR=${ATT_DIR}/hadoop
	
	local TMP_HDOP_LOGS_DIR=${TMP_HDOP_SETUP_DIR}/logs
	local TMP_HDOP_DATA_DIR=${TMP_HDOP_SETUP_DIR}/data
	local TMP_HDOP_ETC_DIR=${TMP_HDOP_SETUP_DIR}/etc

	# 启动配置文件
	local TMP_HDOP_SUP_CONF_PATH=`find / -name hadoop-dfs.conf 2> /dev/null`

	local TMP_HDOP_CLUSTER_WORKER_USER=`whoami`
	input_if_empty "TMP_HDOP_CLUSTER_WORKER_USER" "Hadoop: Please ender the ${green}ssh user${reset} of cluster-workers"

	local TMP_EXEC_IF_CHOICE_SCRIPT_PATH_ARR=(${TMP_EXEC_IF_CHOICE_SCRIPT_PATH})
    local TMP_HDOP_CLUSTER_WORKER_HOSTS="${LOCAL_HOST}"

	function _conf_hadoop_cluster_while_read()
	{
		local I=${1}
		local CURRENT=${2}
		if [ "${CURRENT}" == "${LOCAL_HOST}" ]; then
			return $?
		fi

		# 添加从属节点配置
        local TMP_HDOP_CLUSTER_WORKER_NAME=\`echo ${CURRENT} | sed 's@\\.@-@g' | xargs -I {} echo "ip-{}"\`
        if [ "$I" -eq 1 ]; then
            echo "${TMP_HDOP_CLUSTER_WORKER_NAME}" > etc/hadoop/workers
        else
            echo "${TMP_HDOP_CLUSTER_WORKER_NAME}" >> etc/hadoop/workers
        fi

		# 授权本地端口开放给Slaves
        echo_soft_port ${TMP_HDOP_SETUP_HDFS_PORT} "${CURRENT}"
        echo_soft_port ${TMP_HDOP_SETUP_SCHEDULER_PORT} "${CURRENT}"
        echo_soft_port ${TMP_HDOP_SETUP_RES_TRACK_PORT} "${CURRENT}"
        echo_soft_port ${TMP_HDOP_SETUP_RES_MGR_PORT} "${CURRENT}"
        echo_soft_port ${TMP_HDOP_SETUP_RES_ADMIN_PORT} "${CURRENT}"
        echo_soft_port ${TMP_HDOP_SETUP_WEBAPP_PORT} "${CURRENT}"
        echo_soft_port ${TMP_HDOP_SETUP_WEBAPP_HTTPS_PORT} "${CURRENT}"
        echo_soft_port 49001 "${CURRENT}"
        echo_soft_port 50070 "${CURRENT}"
        echo_soft_port 50075 "${CURRENT}"
		
		# 生成web授权访问脚本
		echo_web_service_init_scripts "hadoop${I}" "hadoop${I}-webui.${SYS_DOMAIN}" ${TMP_HDOP_SETUP_WEBAPP_PORT} "${CURRENT}"

		# NameNode映射
        echo "${CURRENT} ${TMP_HDOP_CLUSTER_WORKER_NAME}" >> /etc/hosts
		
		# 远程机器免登录授权
		ssh-copy-id ${TMP_HDOP_CLUSTER_WORKER_USER}@${CURRENT} -p ${TMP_HDOP_CLUSTER_SSH_PORT}

        sleep 1

		# 远程机器识别本地HOST映射
		ssh -tt ${TMP_HDOP_CLUSTER_WORKER_USER}@${TMP_HDOP_CLUSTER_WORKER_NAME} -p ${TMP_HDOP_CLUSTER_SSH_PORT} "echo '${LOCAL_HOST} ${TMP_HDOP_HADOOP_MASTER_NAME}' >> /etc/hosts"

		# 拷贝本地安装目录给定远程
        scp -P ${TMP_HDOP_CLUSTER_SSH_PORT} -r ${TMP_HDOP_SETUP_DIR} ${TMP_HDOP_CLUSTER_WORKER_USER}@${TMP_HDOP_CLUSTER_WORKER_NAME}:${TMP_HDOP_SETUP_DIR}
        scp -P ${TMP_HDOP_CLUSTER_SSH_PORT} -r ${TMP_HDOP_SUP_CONF_PATH} ${TMP_HDOP_CLUSTER_WORKER_USER}@${TMP_HDOP_CLUSTER_WORKER_NAME}:${TMP_HDOP_SUP_CONF_PATH}
		
		ssh -tt ${TMP_HDOP_CLUSTER_WORKER_USER}@${TMP_HDOP_CLUSTER_WORKER_NAME} -p ${TMP_HDOP_CLUSTER_SSH_PORT} "mv ${TMP_HDOP_LOGS_DIR} ${TMP_HDOP_LNK_LOGS_DIR} && ln -sf ${TMP_HDOP_LNK_LOGS_DIR} ${TMP_HDOP_LOGS_DIR}"
		ssh -tt ${TMP_HDOP_CLUSTER_WORKER_USER}@${TMP_HDOP_CLUSTER_WORKER_NAME} -p ${TMP_HDOP_CLUSTER_SSH_PORT} "mv ${TMP_HDOP_DATA_DIR} ${TMP_HDOP_LNK_DATA_DIR} && ln -sf ${TMP_HDOP_LNK_DATA_DIR} ${TMP_HDOP_DATA_DIR}"
		ssh -tt ${TMP_HDOP_CLUSTER_WORKER_USER}@${TMP_HDOP_CLUSTER_WORKER_NAME} -p ${TMP_HDOP_CLUSTER_SSH_PORT} "mv ${TMP_HDOP_ETC_DIR} ${TMP_HDOP_LNK_ETC_DIR} && ln -sf ${TMP_HDOP_LNK_ETC_DIR} ${TMP_HDOP_ETC_DIR}"

		# 添加远程环境变量
		ssh -tt ${TMP_HDOP_CLUSTER_WORKER_USER}@${TMP_HDOP_CLUSTER_WORKER_NAME} -p ${TMP_HDOP_CLUSTER_SSH_PORT} "echo 'HADOOP_HOME=${TMP_HDOP_SETUP_DIR}' >> /etc/profile"
		ssh -tt ${TMP_HDOP_CLUSTER_WORKER_USER}@${TMP_HDOP_CLUSTER_WORKER_NAME} -p ${TMP_HDOP_CLUSTER_SSH_PORT} 'echo "PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH" >> /etc/profile'
		ssh -tt ${TMP_HDOP_CLUSTER_WORKER_USER}@${TMP_HDOP_CLUSTER_WORKER_NAME} -p ${TMP_HDOP_CLUSTER_SSH_PORT} "echo 'export PATH HADOOP_HOME' >> /etc/profile"
		ssh -tt ${TMP_HDOP_CLUSTER_WORKER_USER}@${TMP_HDOP_CLUSTER_WORKER_NAME} -p ${TMP_HDOP_CLUSTER_SSH_PORT} "source /etc/profile"

		# ssh -tt ${TMP_HDOP_CLUSTER_WORKER_USER}@${TMP_HDOP_CLUSTER_WORKER_NAME} -p ${TMP_HDOP_CLUSTER_SSH_PORT} ''

		# 备份iptables授权IP:端口配置
        cat /etc/sysconfig/iptables | sed -n '12,21p' | sed "s@${CURRENT}@${TMP_HDOP_MASTER_HOST}@g" > ssh_sed_hadoop_${TMP_HDOP_CLUSTER_WORKER_NAME}_port.tmp

        echo
        echo "Hadoop: File of ssh_sed_hadoop_${TMP_HDOP_CLUSTER_WORKER_NAME}_port.tmp will upload to '${CURRENT}' then append to iptables.service"
        echo
    
        scp -P ${TMP_HDOP_CLUSTER_SSH_PORT} -r ssh_sed_hadoop_${TMP_HDOP_CLUSTER_WORKER_NAME}_port.tmp ${TMP_HDOP_CLUSTER_WORKER_USER}@${TMP_HDOP_CLUSTER_WORKER_NAME}:/tmp
        
        ssh -o "StrictHostKeyChecking no" ${TMP_HDOP_CLUSTER_WORKER_NAME} -p ${TMP_HDOP_CLUSTER_SSH_PORT} "sed -i '11 r /tmp/ssh_sed_hadoop_${TMP_HDOP_CLUSTER_WORKER_NAME}_port.tmp' /etc/sysconfig/iptables && rm -rf /tmp/ssh_sed_hadoop_${TMP_HDOP_CLUSTER_WORKER_NAME}_port.tmp"
		
		# 远程启动
		ssh -tt ${TMP_HDOP_CLUSTER_WORKER_USER}@${TMP_HDOP_CLUSTER_WORKER_NAME} -p ${TMP_HDOP_CLUSTER_SSH_PORT} "cd ${HADOOP_HOME} && bin/hadoop version"

		return $?
	}

    exec_while_read "TMP_HDOP_CLUSTER_WORKER_HOSTS" "Hadoop: Please ender cluster-workers-host part \$I of address like '${LOCAL_HOST}', but except '${LOCAL_HOST}'" "" "_conf_hadoop_cluster_while_read \"\$I\" \"\$CURRENT\""

	# 因动态设置，所以需要重新修改对应集群数量
	local TMP_HDOP_CLUSTER_WORKER_HOSTS_LEN=`echo ${TMP_HDOP_CLUSTER_WORKER_HOSTS} | grep -o "," | wc -l`
	
	echo "127.0.0.1,${TMP_HDOP_CLUSTER_WORKER_HOSTS}" | sed 's@,@\n@g' | xargs -I {} sh -c "ssh -tt ${TMP_HDOP_CLUSTER_WORKER_USER}@{} -p \${TMP_HDOP_CLUSTER_SSH_PORT} \"sed -i \'s@<value>1</value>@<value>${TMP_HDOP_CLUSTER_WORKER_HOSTS_LEN}</value>@g\' ${TMP_HDOP_SETUP_DIR}/etc/hadoop/hdfs-site.xml\""
	
	return $?
}

##########################################################################################################

# 4-启动软件
function boot_hadoop()
{
	local TMP_HDOP_SETUP_DIR=${1}

	cd ${TMP_HDOP_SETUP_DIR}

	# 验证安装
	bin/hadoop version

	# NameNode初始化
    bin/hadoop namenode -format
	
	# 添加系统启动命令
	echo_startup_config "hadoop-yarn" `pwd` "bash sbin/start-yarn.sh" "" "20"

	bash sbin/start-dfs.sh
	bash sbin/start-yarn.sh

    sleep 10

    ls data/dfs/name/current/

	# 测试安装
    bin/hdfs dfs -ls /
    echo "test ok" > test.log && bin/hdfs dfs -put test.log hdfs://${TMP_HDOP_HADOOP_MASTER_NAME}:${TMP_HDOP_SETUP_HDFS_PORT}/ && rm -f test.log
    bin/hdfs dfs -ls /

    bin/hdfs dfs -get hdfs://${TMP_HDOP_HADOOP_MASTER_NAME}:${TMP_HDOP_SETUP_HDFS_PORT}/test.log

    bin/hdfs dfs -df -h /

    bin/hdfs dfsadmin -report

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_hadoop()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_hadoop()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_hadoop()
{
	local TMP_HDOP_SETUP_DIR=${1}
	local TMP_HDOP_CURRENT_DIR=`pwd`
    
	set_env_hadoop "${TMP_HDOP_SETUP_DIR}"

	setup_hadoop "${TMP_HDOP_SETUP_DIR}" "${TMP_HDOP_CURRENT_DIR}"

	conf_hadoop "${TMP_HDOP_SETUP_DIR}"

    # down_plugin_hadoop "${TMP_HDOP_SETUP_DIR}"

	boot_hadoop "${TMP_HDOP_SETUP_DIR}"

	TMP_HDOP_WAS_SETUPED=1

	return $?
}

##########################################################################################################

# x1-下载软件
function down_hadoop()
{
	TMP_HDOP_SETUP_NEWER="hadoop-3.3.1.tar.gz"
	local TMP_HDOP_DOWN_URL_BASE="https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/stable/"
	set_url_list_newer_href_link_filename "TMP_HDOP_SETUP_NEWER" "${TMP_HDOP_DOWN_URL_BASE}" "hadoop-().tar.gz"
	exec_text_format "TMP_HDOP_SETUP_NEWER" "${TMP_HDOP_DOWN_URL_BASE}%s"
    setup_soft_wget "hadoop" "${TMP_HDOP_SETUP_NEWER}" "exec_step_hadoop"

	return $?
}

##########################################################################################################

# 安装主体
setup_soft_basic "Hadoop" "down_hadoop"

# 判断从属节点的安装
function check_and_run_slave()
{
	if [ ${TMP_HDOP_WAS_SETUPED} -eq 0 ]; then
		boot_hadoop "${HADOOP_HOME}"
	fi

	return $?
}

check_and_run_slave