#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 参考文献：http://www.jianshu.com/p/b49712bbe044
#------------------------------------------------

# 1-配置环境
function set_environment()
{
    cd ${__DIR}

	source scripts/lang/java.sh

	return $?
}

# 2-安装软件
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
	echo 'PATH=$HADOOP_HOME/bin:$PATH' >> /etc/profile
	echo "export PATH HADOOP_HOME" >> /etc/profile

    # 重新加载profile文件
	source /etc/profile
	# ln -sf ${TMP_HDOP_SETUP_DIR}/bin/hadoop /usr/bin/hadoop

	# 授权权限，否则无法写入
	chown -R hadoop:hadoop_group ${TMP_HDOP_SETUP_DIR}

	return $?
}

# 3-设置软件
function conf_hadoop()
{
	local TMP_HDOP_SETUP_DIR=${1}
	cd ${TMP_HDOP_SETUP_DIR}
	
	local TMP_HDOP_DATA_DIR=${TMP_HDOP_SETUP_DIR}/data

    local TMP_HDOP_MASTER_HOST="${LOCAL_HOST}"
    input_if_empty "TMP_HDOP_MASTER_HOST" "Hadoop: Please ender your ${red}cluster master host address${reset} like '${LOCAL_HOST}'"

	# 本机转换
	if [ "${TMP_HDOP_MASTER_HOST}" == "127.0.0.1" ] || [ "${TMP_HDOP_MASTER_HOST}" == "localhost" ]; then
		TMP_HDOP_MASTER_HOST="${LOCAL_HOST}"
	fi
    
	echo "export HDFS_NAMENODE_USER=hadoop" >> etc/hadoop/hadoop-env.sh
	echo "export HDFS_DATANODE_USER=hadoop" >> etc/hadoop/hadoop-env.sh
	echo "export HDFS_SECONDARYNAMENODE_USER=hadoop" >> etc/hadoop/hadoop-env.sh
	echo "export YARN_RESOURCEMANAGER_USER=hadoop" >> etc/hadoop/hadoop-env.sh
	echo "export YARN_NODEMANAGER_USER=hadoop" >> etc/hadoop/hadoop-env.sh
	echo "export JAVA_HOME=${JAVA_HOME}" >> etc/hadoop/hadoop-env.sh

	# 全局，给后面的函数读取
	TMP_HDOP_HADOOP_MASTER_ID=`echo ${TMP_HDOP_MASTER_HOST##*.}`
    
    echo "127.0.0.1 lnxsvr.ha${LOCAL_ID}" >> /etc/hosts 
    # echo "${LOCAL_HOST} lnxsvr.ha${LOCAL_ID}" >> /etc/hosts 
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
	<value>hdfs://lnxsvr.ha${TMP_HDOP_HADOOP_MASTER_ID}:3000</value>
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
    <value>lnxsvr.ha${TMP_HDOP_HADOOP_MASTER_ID}:49001</value>
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
        <value>lnxsvr.ha${TMP_HDOP_HADOOP_MASTER_ID}</value>
		<description>表示ResourceManager安装的主机</description>
   </property>
   <property>
        <description>The address of the applications manager interface in the RM.</description>
        <name>yarn.resourcemanager.address</name>
        <value>\${yarn.resourcemanager.hostname}:8032</value>
		<description>表示ResourceManager监听的端口</description>
   </property>
   <property>
        <description>The address of the scheduler interface.</description>
        <name>yarn.resourcemanager.scheduler.address</name>
        <value>\${yarn.resourcemanager.hostname}:8030</value>
   </property>
   <property>
        <description>The http address of the RM web application.</description>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>\${yarn.resourcemanager.hostname}:8088</value>
   </property>
   <property>
        <description>The https adddress of the RM web application.</description>
        <name>yarn.resourcemanager.webapp.https.address</name>
        <value>\${yarn.resourcemanager.hostname}:8090</value>
   </property>
   <property>
        <name>yarn.resourcemanager.resource-tracker.address</name>
        <value>\${yarn.resourcemanager.hostname}:8031</value>
   </property>
   <property>
        <description>The address of the RM admin interface.</description>
        <name>yarn.resourcemanager.admin.address</name>
        <value>\${yarn.resourcemanager.hostname}:8033</value>
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

    bin/hadoop namenode -format
    ls ${TMP_HDOP_DATA_DIR}/dfs/name/current/

	ssh-keygen -t rsa -P ''
            
    cat ~/.ssh/id_rsa.pub | sed "s@lnxsvr.*@lnxsvr.ha$LOCAL_ID@g" > ~/.ssh/authorized_keys
    cat ~/.ssh/authorized_keys > ~/.ssh/id_rsa.pub

    echo_soft_port 3000 "${TMP_HDOP_MASTER_HOST}"
    echo_soft_port 49001 "${TMP_HDOP_MASTER_HOST}"
    echo_soft_port 8032 "${TMP_HDOP_MASTER_HOST}"
    echo_soft_port 8030 "${TMP_HDOP_MASTER_HOST}"
    echo_soft_port 8088 "${TMP_HDOP_MASTER_HOST}"
    echo_soft_port 8090 "${TMP_HDOP_MASTER_HOST}"
    echo_soft_port 8031 "${TMP_HDOP_MASTER_HOST}"
    echo_soft_port 8033 "${TMP_HDOP_MASTER_HOST}"
    echo_soft_port 50070 "${TMP_HDOP_MASTER_HOST}"
    echo_soft_port 50075 "${TMP_HDOP_MASTER_HOST}"
	
    cat /etc/sysconfig/iptables | sed -n '12,21p' > ssh_sed_hadoop${TMP_HDOP_HADOOP_MASTER_ID}_port.tmp

    exec_yn_action "conf_hadoop_cluster" "Hadoop: Please sure if this install is cluster mode"

	return $?
}

function conf_hadoop_cluster()
{
	local TMP_HDOP_SETUP_DIR=`pwd`
	local TMP_HDOP_DATA_DIR=${TMP_HDOP_SETUP_DIR}/data

    local TMP_HDOP_CLUSTER_SLAVE_HOSTS="${LOCAL_HOST}"
    exec_while_read "TMP_HDOP_CLUSTER_SLAVE_HOSTS" "Hadoop: Please ender cluster-slaves-host part \$I of address like '${LOCAL_HOST}', but except '${LOCAL_HOST}'" "" "
        local TMP_HDOP_CLUSTER_SLAVE_ID=\`echo \\\${CURRENT##*.}\`
        if [ "\$I" -eq 1 ]; then
            echo \"lnxsvr.ha\${TMP_HDOP_CLUSTER_SLAVE_ID}\" > etc/hadoop/slaves
        else
            echo \"lnxsvr.ha\${TMP_HDOP_CLUSTER_SLAVE_ID}\" >> etc/hadoop/slaves
        fi

        echo_soft_port 3000 \"\$CURRENT\"
        echo_soft_port 49001 \"\$CURRENT\"
        echo_soft_port 8032 \"\$CURRENT\"
        echo_soft_port 8030 \"\$CURRENT\"
        echo_soft_port 8088 \"\$CURRENT\"
        echo_soft_port 8090 \"\$CURRENT\"
        echo_soft_port 8031 \"\$CURRENT\"
        echo_soft_port 8033 \"\$CURRENT\"
        echo_soft_port 50070 \"\$CURRENT\"
        echo_soft_port 50075 \"\$CURRENT\"

        echo \"\$CURRENT lnxsvr.ha\${TMP_HDOP_CLUSTER_SLAVE_ID}\" >> /etc/hosts

        ssh-copy-id -i ~/.ssh/id_rsa.pub lnxsvr.ha\${TMP_HDOP_CLUSTER_SLAVE_ID}

        sleep 1

        scp -r ${TMP_HDOP_SETUP_DIR} root@lnxsvr.ha\${TMP_HDOP_CLUSTER_SLAVE_ID}:${TMP_HDOP_SETUP_DIR}
        scp -r ${TMP_HDOP_DATA_DIR} root@lnxsvr.ha\${TMP_HDOP_CLUSTER_SLAVE_ID}:${TMP_HDOP_DATA_DIR}

        cat /etc/sysconfig/iptables | sed -n '12,21p' | sed 's@\$CURRENT@\${TMP_HDOP_MASTER_HOST}@g' > ssh_sed_hadoop\${TMP_HDOP_CLUSTER_SLAVE_ID}_port.tmp

        echo
        echo \"Hadoop: File of ssh_sed_hadoop\${TMP_HDOP_CLUSTER_SLAVE_ID}_port.tmp will upload to '\$CURRENT' then append to iptables.service\"
        echo
    
        scp -r ssh_sed_hadoop\${TMP_HDOP_CLUSTER_SLAVE_ID}_port.tmp root@lnxsvr.ha\${TMP_HDOP_CLUSTER_SLAVE_ID}:/tmp
        scp -r ssh_sed_hadoop${TMP_HDOP_HADOOP_MASTER_ID}_port.tmp root@lnxsvr.ha\${TMP_HDOP_CLUSTER_SLAVE_ID}:/tmp
        
        ssh -o \"StrictHostKeyChecking no\" lnxsvr.ha\${TMP_HDOP_CLUSTER_SLAVE_ID} \"sed -i '11 r /tmp/ssh_sed_hadoop${TMP_HDOP_HADOOP_MASTER_ID}_port.tmp' /etc/sysconfig/iptables\"
        ssh -o \"StrictHostKeyChecking no\" lnxsvr.ha\${TMP_HDOP_CLUSTER_SLAVE_ID} \"sed -i '11 r /tmp/ssh_sed_hadoop\${TMP_HDOP_CLUSTER_SLAVE_ID}_port.tmp' /etc/sysconfig/iptables\"
    "

	return $?
}

# 4-启动软件
function boot_hadoop()
{
	local TMP_HDOP_SETUP_DIR=${1}

	cd ${TMP_HDOP_SETUP_DIR}

	# 验证安装
	bin/hadoop version

	# 添加系统启动命令，如果当前机器ID与主机器ID相等
    # exec_if_choice "CHOICE_HADOOP_BOOT_TYPE" "Please choice which boot type you want to do" "...,Master,Slave,Exit" "${TMP_SPLITER}" "boot_hadoop_"
	if [ ${TMP_HDOP_HADOOP_MASTER_ID} -eq ${LOCAL_ID} ]; then		
		# 添加系统启动命令
		echo_startup_config "hadoop" `pwd` "bash sbin/start-all.sh" "" "10"
	else
		# 添加系统启动命令
		echo_startup_config "hadoop" `pwd` "bash sbin/start-dfs.sh" "" "10"
	fi

	bash sbin/start-dfs.sh

    sleep 10

	# 测试安装
    bin/hdfs dfs -ls /
    echo "test ok" > test.log && bin/hdfs dfs -put test.log hdfs://lnxsvr.ha${TMP_HDOP_HADOOP_MASTER_ID}:3000/ && rm -f test.log
    bin/hdfs dfs -ls /

    bin/hdfs dfs -get hdfs://lnxsvr.ha${TMP_HDOP_HADOOP_MASTER_ID}:3000/test.log

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
    
	set_environment "${TMP_HDOP_SETUP_DIR}"

	setup_hadoop "${TMP_HDOP_SETUP_DIR}" "${TMP_HDOP_CURRENT_DIR}"

	conf_hadoop "${TMP_HDOP_SETUP_DIR}"

    # down_plugin_hadoop "${TMP_HDOP_SETUP_DIR}"

	boot_hadoop "${TMP_HDOP_SETUP_DIR}"

	return $?
}

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

#安装主体
setup_soft_basic "Hadoop" "down_hadoop"