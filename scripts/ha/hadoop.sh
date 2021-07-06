#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_environment()
{
    # 需要提前安装Java
    cd ${__DIR}
    source scripts/lang/java.sh

	echo "Some Infomation Please See：http://www.jianshu.com/p/b49712bbe044"

	return $?
}

function setup_hadoop()
{
    cd ..
    
    HADOOP_DIR=$SETUP_DIR/hadoop
    HADOOP_DATA_DIR=$DATA_DIR/hadoop

	  mv hadoop-2.8.5 $HADOOP_DIR

    mkdir -pv $HADOOP_DATA_DIR/tmp
    mkdir -pv $HADOOP_DATA_DIR/var
    mkdir -pv $HADOOP_DATA_DIR/dfs
    mkdir -pv $HADOOP_DATA_DIR/dfs/name  
    mkdir -pv $HADOOP_DATA_DIR/dfs/data

    cd $HADOOP_DIR

    HADOOP_MASTER_HOST="$LOCAL_HOST"
    input_if_empty "HADOOP_MASTER_HOST" "Hadoop: Please ender your ${red}cluster master host address${reset} like '$LOCAL_HOST'"
    HADOOP_MASTER_ID=`echo \${HADOOP_MASTER_HOST##*.}`
    
    echo "$LOCAL_HOST lnxsvr.ha$LOCAL_ID" >> /etc/hosts 
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
	<value>$HADOOP_DATA_DIR/tmp</value>
	<description>Abase for other temporary directories.</description>
</property>
<property>
	<name>fs.default.name</name>
	<value>hdfs://lnxsvr.ha$HADOOP_MASTER_ID:3000</value>
</property>
</configuration>
EOF

    sed -i "s@^export JAVA_HOME=\${JAVA_HOME}@export JAVA_HOME=$JAVA_HOME@g" etc/hadoop/hadoop-env.sh

    echo "HADOOP_HOME=$HADOOP_DIR" >> /etc/profile
    echo "HADOOP_BIN=\$HADOOP_HOME/bin" >> /etc/profile
    echo "PATH=\$HADOOP_BIN:\$PATH" >> /etc/profile
    source /etc/profile

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
   <name>dfs.name.dir</name>
   <value>$HADOOP_DATA_DIR/dfs/name</value>
   <description>Path on the local filesystem where theNameNode stores the namespace and transactions logs persistently.</description>
</property>
<property>
  <name>dfs.data.dir</name>
   <value>$HADOOP_DATA_DIR/dfs/data</value>
   <description>Comma separated list of paths on the localfilesystem of a DataNode where it should store its blocks.</description>
</property>
<property>
   <name>dfs.replication</name>
   <value>2</value>
</property>
<property>
      <name>dfs.permissions</name>
      <value>false</value>
      <description>need not permissions</description>
</property>
</configuration>
EOF

	cp etc/hadoop/mapred-site.xml.template etc/hadoop/mapred-site.xml
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
    <value>lnxsvr.ha$HADOOP_MASTER_ID:49001</value>
</property>
<property>
      <name>mapred.local.dir</name>
       <value>$HADOOP_DATA_DIR/var</value>
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
        <value>lnxsvr.ha$HADOOP_MASTER_ID</value>
   </property>
   <property>
        <description>The address of the applications manager interface in the RM.</description>
        <name>yarn.resourcemanager.address</name>
        <value>\${yarn.resourcemanager.hostname}:8032</value>
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
        <value>2048</value>
   </property>
   <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
   </property>
</configuration>
EOF

    rm -rf share/doc

    bin/hadoop namenode -format
    ls $HADOOP_DATA_DIR/dfs/name/current/

    exec_yn_action "set_hadoop_cluster" "Hadoop: Please sure if this install is cluster mode"

    exec_yn_action "start_hadoop" "Hadoop: Please Sure You If This Is A Boot Server"

	return $?
}

function start_hadoop() {
	if [ $? -eq 1 ]; then
        bash sbin/start-all.sh
    else
        bash sbin/start-dfs.sh
	fi

    echo "Hadoop: Start To Test The Hadoop Server Is Ok，please wait a moment when slaves start..."

    sleep 3

    bin/hdfs dfs -ls /
    echo "test ok" > $MOUNT_DIR/test.log && bin/hdfs dfs -put $MOUNT_DIR/test.log hdfs://lnxsvr.ha$HADOOP_MASTER_ID:3000/ && rm $MOUNT_DIR/test.log
    bin/hdfs dfs -ls /

    bin/hdfs dfs -get hdfs://lnxsvr.ha$HADOOP_MASTER_ID:3000/test.log

    bin/hdfs dfs -df -h /

    bin/hdfs dfsadmin -report

    echo "Hadoop: Install complete，Then u should start your hadoop server on hadoop boot server"
    
    echo_startup_config "hadoop" "$HADOOP_DIR/sbin" "bash start-all.sh" "" "10"

	return $?
}

function set_hadoop_cluster() 
{
    ssh-keygen -t rsa -P ''
            
    cat ~/.ssh/id_rsa.pub | sed "s@lnxsvr.*@lnxsvr.ha$LOCAL_ID@g" > ~/.ssh/authorized_keys
    cat ~/.ssh/authorized_keys > ~/.ssh/id_rsa.pub

    echo_soft_port 3000 "$HADOOP_MASTER_HOST"
    echo_soft_port 49001 "$HADOOP_MASTER_HOST"
    echo_soft_port 8032 "$HADOOP_MASTER_HOST"
    echo_soft_port 8030 "$HADOOP_MASTER_HOST"
    echo_soft_port 8088 "$HADOOP_MASTER_HOST"
    echo_soft_port 8090 "$HADOOP_MASTER_HOST"
    echo_soft_port 8031 "$HADOOP_MASTER_HOST"
    echo_soft_port 8033 "$HADOOP_MASTER_HOST"
    echo_soft_port 50070 "$HADOOP_MASTER_HOST"
    echo_soft_port 50075 "$HADOOP_MASTER_HOST"

    cat /etc/sysconfig/iptables | sed -n '12,21p' > ssh_sed_hadoop${HADOOP_MASTER_ID}_port.tmp

    CLUSTER_SLAVE_HOSTS="$LOCAL_HOST"
    exec_while_read "CLUSTER_SLAVE_HOSTS" "Hadoop: Please ender cluster-slaves-host part \$I of address like '$LOCAL_HOST', but except '$LOCAL_HOST'" "" "
        local CLUSTER_SLAVE_ID=`echo \\\${CURRENT##*.}`
        if [ "\$I" -eq 1 ]; then
            echo \"lnxsvr.ha\$CLUSTER_SLAVE_ID\" > etc/hadoop/slaves
        else
            echo \"lnxsvr.ha\$CLUSTER_SLAVE_ID\" >> etc/hadoop/slaves
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

        echo \"\$CURRENT lnxsvr.ha\$CLUSTER_SLAVE_ID\" >> /etc/hosts

        ssh-copy-id -i ~/.ssh/id_rsa.pub lnxsvr.ha\$CLUSTER_SLAVE_ID

        sleep 1

        scp -r $HADOOP_DIR root@lnxsvr.ha\$CLUSTER_SLAVE_ID:$HADOOP_DIR
        scp -r $HADOOP_DATA_DIR root@lnxsvr.ha\$CLUSTER_SLAVE_ID:$HADOOP_DATA_DIR

        cat /etc/sysconfig/iptables | sed -n '12,21p' | sed 's@\$CURRENT@\$HADOOP_MASTER_HOST@g' > ssh_sed_hadoop\${CLUSTER_SLAVE_ID}_port.tmp

        echo
        echo \"Hadoop: File of ssh_sed_hadoop\${CLUSTER_SLAVE_ID}_port.tmp will upload to '\$CURRENT' then append to iptables.service\"
        echo
    
        scp -r ssh_sed_hadoop\${CLUSTER_SLAVE_ID}_port.tmp root@lnxsvr.ha\$CLUSTER_SLAVE_ID:/tmp
        scp -r ssh_sed_hadoop${HADOOP_MASTER_ID}_port.tmp root@lnxsvr.ha\$CLUSTER_SLAVE_ID:/tmp
        
        ssh -o \"StrictHostKeyChecking no\" lnxsvr.ha\$CLUSTER_SLAVE_ID \"sed -i '11 r /tmp/ssh_sed_hadoop${HADOOP_MASTER_ID}_port.tmp' /etc/sysconfig/iptables\"
        ssh -o \"StrictHostKeyChecking no\" lnxsvr.ha\$CLUSTER_SLAVE_ID \"sed -i '11 r /tmp/ssh_sed_hadoop\${CLUSTER_SLAVE_ID}_port.tmp' /etc/sysconfig/iptables\"
    "

	return $?
}

function down_hadoop()
{
    set_environment
    setup_soft_wget "hadoop" "http://mirrors.hust.edu.cn/apache/hadoop/common/hadoop-2.8.5/hadoop-2.8.5.tar.gz" "setup_hadoop"

	return $?
}

setup_soft_basic "Hadoop" "down_hadoop"
