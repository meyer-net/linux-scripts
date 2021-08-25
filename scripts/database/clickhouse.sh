#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 相关参考：
#         https://clickhouse.tech/docs/zh/
#         https://www.zouyesheng.com/clickhouse.html
#         http://www.clickhouse.com.cn/topic/5a366e97828d76d75ab5d5a0
#------------------------------------------------
local TMP_CH_SETUP_HTTP_PORT=18123
local TMP_CH_SETUP_TCP_PORT=19000
local TMP_CH_SETUP_MYSQL_PORT=19004
local TMP_CH_SETUP_PSQL_PORT=19005
local TMP_CH_SETUP_ITS_HTTP_PORT=19009

##########################################################################################################

# 1-配置环境
function set_env_clickhouse()
{
    cd ${__DIR}

    soft_yum_check_setup "libicu-devel"

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_clickhouse()
{
	local TMP_CH_SETUP_DIR=${1}

	## 源模式    
    echo "------------------------------------------------------"
    echo "ClickHouse: System start find the newer stable version"
    echo "------------------------------------------------------"
    local TMP_CH_SETUP_CH_SERVER_NEWER="clickhouse-server-21.6.6.51-2.noarch.rpm"
    set_url_list_newer_href_link_filename "TMP_CH_SETUP_CH_SERVER_NEWER" "http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/" "clickhouse-server-().noarch.rpm"
    local TMP_CH_SETUP_CLIENT_NEWER=`echo "${TMP_CH_SETUP_CH_SERVER_NEWER}" | sed 's@server@client@g'`

    local TMP_CH_SETUP_CH_SERVER_COMMON_NEWER="clickhouse-server-common-19.4.0-2.noarch.rpm"
    set_url_list_newer_href_link_filename "TMP_CH_SETUP_CH_SERVER_COMMON_NEWER" "http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/" "clickhouse-server-common-().noarch.rpm"

    local TMP_CH_SETUP_COMMON_STATIC_NEWER="clickhouse-common-static-21.6.6.51-2.x86_64.rpm"
    set_url_list_newer_href_link_filename "TMP_CH_SETUP_COMMON_STATIC_NEWER" "http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/" "clickhouse-common-static-().x86_64.rpm"

    #19.13.3.26-1
    #curl -s https://packagecloud.io/install/repositories/Altinity/clickhouse/script.rpm.sh | sudo bash
    
    echo "ClickHouse[server-common]: The newer stable version is ${TMP_CH_SETUP_CH_SERVER_COMMON_NEWER}"
    while_wget "--content-disposition http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/${TMP_CH_SETUP_CH_SERVER_COMMON_NEWER}" "rpm -ivh ${TMP_CH_SETUP_CH_SERVER_COMMON_NEWER}"

    echo "ClickHouse[server-static]: The newer stable version is ${TMP_CH_SETUP_COMMON_STATIC_NEWER}"
    while_wget "--content-disposition http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/${TMP_CH_SETUP_COMMON_STATIC_NEWER}" "rpm -ivh ${TMP_CH_SETUP_COMMON_STATIC_NEWER}"

    echo "ClickHouse[server]: The newer stable version is ${TMP_CH_SETUP_CH_SERVER_NEWER}"
    while_wget "--content-disposition http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/${TMP_CH_SETUP_CH_SERVER_NEWER}" "rpm -ivh ${TMP_CH_SETUP_CH_SERVER_NEWER}"

    echo "ClickHouse[client]: The newer stable version is ${TMP_CH_SETUP_CLIENT_NEWER}"
    while_wget "--content-disposition http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/${TMP_CH_SETUP_CLIENT_NEWER}" "rpm -ivh ${TMP_CH_SETUP_CLIENT_NEWER}"

	# 需要运行一次，生成基础文件
    echo "ClickHouse: Setup Successded，Starting init data file..."
    systemctl start clickhouse-server.service 
    systemctl stop clickhouse-server.service
    sleep 15

	# 创建日志软链
    local TMP_CH_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/clickhouse
	local TMP_CH_SETUP_LNK_SERVER_LOGS_DIR=${TMP_CH_SETUP_LNK_LOGS_DIR}/server
	local TMP_CH_SETUP_LNK_DATA_DIR=${DATA_DIR}/clickhouse
	local TMP_CH_SETUP_LNK_SERVER_DATA_DIR=${TMP_CH_SETUP_LNK_DATA_DIR}/server
	local TMP_CH_SETUP_LNK_SERVER_DATA_LIB_DIR=${TMP_CH_SETUP_LNK_SERVER_DATA_DIR}/lib
	local TMP_CH_SETUP_LNK_SERVER_DATA_XML_DIR=${TMP_CH_SETUP_LNK_SERVER_DATA_DIR}/xml
	local TMP_CH_SETUP_SERVER_LOGS_DIR=${TMP_CH_SETUP_DIR}/logs
	local TMP_CH_SETUP_SERVER_DATA_DIR=${TMP_CH_SETUP_DIR}/data

	# 先清理文件，再创建文件
	path_not_exits_create ${TMP_CH_SETUP_DIR}
    path_not_exits_create ${TMP_CH_SETUP_LNK_LOGS_DIR}
	rm -rf ${TMP_CH_SETUP_SERVER_LOGS_DIR}
	rm -rf ${TMP_CH_SETUP_SERVER_DATA_DIR}
    path_not_exits_create ${TMP_CH_SETUP_LNK_SERVER_DATA_DIR}
	mv /var/log/clickhouse-server ${TMP_CH_SETUP_LNK_SERVER_LOGS_DIR}
	cp /var/lib/clickhouse ${TMP_CH_SETUP_LNK_SERVER_DATA_LIB_DIR} -Rp
    mv /var/lib/clickhouse ${TMP_CH_SETUP_LNK_SERVER_DATA_LIB_DIR}_empty
    path_not_exits_create ${TMP_CH_SETUP_LNK_SERVER_DATA_XML_DIR}
	
    ln -sf ${TMP_CH_SETUP_LNK_SERVER_LOGS_DIR} /var/log/clickhouse-server
	ln -sf ${TMP_CH_SETUP_LNK_SERVER_LOGS_DIR} ${TMP_CH_SETUP_SERVER_LOGS_DIR}
	ln -sf ${TMP_CH_SETUP_LNK_SERVER_DATA_LIB_DIR} /var/lib/clickhouse
	ln -sf ${TMP_CH_SETUP_LNK_SERVER_DATA_DIR} ${TMP_CH_SETUP_SERVER_DATA_DIR}

	# 授权权限，否则无法写入
	create_user_if_not_exists clickhouse clickhouse
	chgrp -R clickhouse ${TMP_CH_SETUP_LNK_LOGS_DIR}
	chown -R clickhouse:clickhouse ${TMP_CH_SETUP_LNK_LOGS_DIR}
	chgrp -R clickhouse ${TMP_CH_SETUP_LNK_DATA_DIR}
	chown -R clickhouse:clickhouse ${TMP_CH_SETUP_LNK_DATA_DIR}
	
	return $?
}

##########################################################################################################

# 3-设置软件
function conf_clickhouse()
{
	local TMP_CH_SETUP_DIR=${1}

	cd ${TMP_CH_SETUP_DIR}
	
	local TMP_CH_SETUP_LNK_SERVER_ETC_DIR=${ATT_DIR}/clickhouse/server/conf
	local TMP_CH_SETUP_LNK_CLIENT_ETC_DIR=${ATT_DIR}/clickhouse/client/conf
	local TMP_CH_SETUP_SERVER_ETC_DIR=${TMP_CH_SETUP_DIR}/etc/server
	local TMP_CH_SETUP_CLIENT_ETC_DIR=${TMP_CH_SETUP_DIR}/etc/client

	# 特殊多层结构下使用
    mkdir -pv `dirname ${TMP_CH_SETUP_LNK_SERVER_ETC_DIR}`
    mkdir -pv `dirname ${TMP_CH_SETUP_LNK_CLIENT_ETC_DIR}`
    mkdir -pv `dirname ${TMP_CH_SETUP_SERVER_ETC_DIR}`
    mkdir -pv `dirname ${TMP_CH_SETUP_CLIENT_ETC_DIR}`

	# 替换原路径链接
	ln -sf /etc/clickhouse-server ${TMP_CH_SETUP_LNK_SERVER_ETC_DIR}
    ln -sf /etc/clickhouse-server ${TMP_CH_SETUP_SERVER_ETC_DIR}
	ln -sf /etc/clickhouse-client ${TMP_CH_SETUP_LNK_CLIENT_ETC_DIR}
    ln -sf /etc/clickhouse-client ${TMP_CH_SETUP_CLIENT_ETC_DIR}
	
    # 开始配置
    # 默认启动脚本，注意，这个名字虽然叫server，其实是个shell脚本
    # sed -i "s@^CLICKHOUSE_LOGDIR_USER=.*@CLICKHOUSE_LOGDIR_USER=clickhouse@g" /etc/rc.d/init.d/clickhouse-server

    # 启动完成以后再修改配置文件
    sed -i "/<yandex>/a     \\\    <listen_host>0.0.0.0</listen_host>" /etc/clickhouse-server/config.xml

	input_if_empty "TMP_CH_SETUP_HTTP_PORT" "Clickhouse-Server: Please ender ${red}http port${reset}"
    sed -i "0,/<http_port>[0-9]*<\/http_port>/{s@<http_port>[0-9]*</http_port>@<http_port>${TMP_CH_SETUP_HTTP_PORT}</http_port>@}" /etc/clickhouse-server/config.xml

	input_if_empty "TMP_CH_SETUP_TCP_PORT" "Clickhouse-Server: Please ender ${red}tcp port${reset}"
    sed -i "0,/<tcp_port>[0-9]*<\/tcp_port>/{s@<tcp_port>[0-9]*</tcp_port>@<tcp_port>${TMP_CH_SETUP_TCP_PORT}</tcp_port>@}" /etc/clickhouse-server/config.xml

	input_if_empty "TMP_CH_SETUP_MYSQL_PORT" "Clickhouse-Server: Please ender ${red}mysql port${reset}"
    sed -i "0,/<mysql_port>[0-9]*<\/mysql_port>/{s@<mysql_port>[0-9]*</mysql_port>@<mysql_port>${TMP_CH_SETUP_MYSQL_PORT}</mysql_port>@}" /etc/clickhouse-server/config.xml
    
	input_if_empty "TMP_CH_SETUP_PSQL_PORT" "Clickhouse-Server: Please ender ${red}postgresql port${reset}"
    sed -i "0,/<postgresql_port>[0-9]*<\/postgresql_port>/{s@<postgresql_port>[0-9]*</postgresql_port>@<postgresql_port>${TMP_CH_SETUP_PSQL_PORT}</postgresql_port>@}" /etc/clickhouse-server/config.xml
    
	input_if_empty "TMP_CH_SETUP_ITS_HTTP_PORT" "Clickhouse-Server: Please ender ${red}interserver http port${reset}"
    sed -i "0,/<interserver_http_port>[0-9]*<\/interserver_http_port>/{s@<interserver_http_port>[0-9]*</interserver_http_port>@<interserver_http_port>${TMP_CH_SETUP_ITS_HTTP_PORT}</interserver_http_port>@}" /etc/clickhouse-server/config.xml

	local TMP_CH_SETUP_SERVER_DATA_DIR=${TMP_CH_SETUP_DIR}/data
	local TMP_CH_SETUP_SERVER_DATA_XML_DIR=${TMP_CH_SETUP_SERVER_DATA_DIR}/xml
    sed -i "0,/<path>.*<\/path>/{s@<path>.*</path>@<path>${TMP_CH_SETUP_SERVER_DATA_XML_DIR}/</path>@}" /etc/clickhouse-server/config.xml
    sed -i "0,/<tmp_path>.*<\/tmp_path>/{s@<tmp_path>.*</tmp_path>@<tmp_path>${TMP_CH_SETUP_SERVER_DATA_XML_DIR}/tmp/</tmp_path>@}" /etc/clickhouse-server/config.xml
    
	return $?
}

##########################################################################################################

# 4-启动软件
function boot_clickhouse()
{
	local TMP_CH_SETUP_DIR=${1}

	cd ${TMP_CH_SETUP_DIR}
	
	# 验证安装
    clickhouse-server -V  # lsof -i:${TMP_CH_SETUP_PORT}

	# 当前启动命令
    # nohup sudo -u clickhouse clickhouse-server --config-file /etc/clickhouse-server/config.xml > logs/boot.log 2>&1 &
    sudo systemctl daemon-reload
    sudo systemctl enable clickhouse-server.service
    sudo systemctl start clickhouse-server.service
    
    # 等待启动
    echo "Starting clickhouse-server，Waiting for a moment..."
    echo "--------------------------------------------"
    sleep 5

    cat /var/log/clickhouse-server/clickhouse-server.log
    sudo systemctl status clickhouse-server.service
    sudo chkconfig clickhouse-server on
    echo "--------------------------------------------"
    
	# 授权iptables端口访问
	echo_soft_port ${TMP_CH_SETUP_HTTP_PORT}
	echo_soft_port ${TMP_CH_SETUP_TCP_PORT}
	echo_soft_port ${TMP_CH_SETUP_MYSQL_PORT}
	echo_soft_port ${TMP_CH_SETUP_PSQL_PORT}
	echo_soft_port ${TMP_CH_SETUP_ITS_HTTP_PORT}
    
	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_clickhouse()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_clickhouse()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_clickhouse()
{
	local TMP_CH_SETUP_DIR=${SETUP_DIR}/clickhouse
    
	set_env_clickhouse "${TMP_CH_SETUP_DIR}"

	setup_clickhouse "${TMP_CH_SETUP_DIR}"

	conf_clickhouse "${TMP_CH_SETUP_DIR}"

    # down_plugin_clickhouse "${TMP_CH_SETUP_DIR}"

	boot_clickhouse "${TMP_CH_SETUP_DIR}"

	return $?
}

##########################################################################################################

# x1-下载软件
function check_setup_clickhouse()
{
    soft_rpm_check_action "clickhouse" "exec_step_clickhouse" "ClickHouse was installed"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "ClickHouse" "check_setup_clickhouse"

##########################################################################################################
# 1、/etc/clickhouse-server/config.xml添加修改如下：
#     <listen_host>0.0.0.0</listen_host>
	
#     <include_from>/etc/clickhouse-server/metrika.xml</include_from>
	
# 2、metrika.xml内容如下：
# <yandex>
# <!-- 集群配置 -->
# <clickhouse_remote_servers>
#     <!-- 集群名称  -->
#     <bh_3s1r_cluster>
#         <!-- 数据分片1  -->
#         <shard>
#             <weight>1</weight>
#             <internal_replication>true</internal_replication>
#             <replica>
#                 <host>ip-172-30-10-152</host>
#                 <port>9876</port>
#                 <user>default</user>
#                 <password>123456</password>
#             </replica>
#         </shard>
#         <!-- 数据分片2  -->
#         <shard>
#             <weight>1</weight>
#             <internal_replication>true</internal_replication>
#             <replica>
#                 <host>ip-172-30-10-155</host>
#                 <port>9876</port>
#                 <user>default</user>
#                 <password>123456</password>
#             </replica>
#         </shard>
#         <!-- 数据分片3  -->
#         <shard>
#             <weight>1</weight>
#             <internal_replication>true</internal_replication>
#             <replica>
#                 <host>ip-172-30-10-158</host>
#                 <port>9876</port>
#                 <user>default</user>
#                 <password>123456</password>
#             </replica>
#         </shard>
#     </bh_3s1r_cluster>
# </clickhouse_remote_servers>

# <!-- 本节点副本名称，不同节点配置不同命名 -->
# <macros>
#     <shard>s1</shard>
#     <replica>r1</replica>
# </macros>

# <!-- 监听网络 -->
# <networks>
#     <ip>::/0</ip>
# </networks>

# <!-- ZK  -->
# <zookeeper-servers>
#     <node index="1">
#         <host>ip-172-30-10-152</host>
#         <port>12181</port>
#     </node>
#     <node index="2">
#         <host>ip-172-30-10-155</host>
#         <port>12181</port>
#     </node>
#     <node index="3">
#         <host>ip-172-30-10-158</host>
#         <port>12181</port>
#     </node>
# </zookeeper-servers>

# <!-- 数据压缩算法  -->
# <clickhouse_compression>
#     <case>
#         <min_part_size>10000000000</min_part_size>
#         <min_part_size_ratio>0.01</min_part_size_ratio>
#         <method>lz4</method>
#     </case>
# </clickhouse_compression>

# </yandex>

# 3、user.xml配置如下

# <?xml version="1.0"?>
# <yandex>
#     <!-- Profiles of settings. -->
#     <profiles>
#         <!-- Default settings. -->
#         <default>
#             <!-- Maximum memory usage for processing single query, in bytes. -->
#             <max_memory_usage>10000000000</max_memory_usage>

#             <!-- Use cache of uncompressed blocks of data. Meaningful only for processing many of very short queries. -->
#             <use_uncompressed_cache>0</use_uncompressed_cache>

#             <!-- How to choose between replicas during distributed query processing.
#                  random - choose random replica from set of replicas with minimum number of errors
#                  nearest_hostname - from set of replicas with minimum number of errors, choose replica
#                   with minimum number of different symbols between replica's hostname and local hostname
#                   (Hamming distance).
#                  in_order - first live replica is chosen in specified order.
#             -->
#             <load_balancing>random</load_balancing>
#         </default>

#         <!-- Profile that allows only read queries. -->
#         <readonly>
#             <max_memory_usage>10000000000</max_memory_usage>
#             <use_uncompressed_cache>0</use_uncompressed_cache>
#             <load_balancing>random</load_balancing>
#             <readonly>1</readonly>
#         </readonly>
#     </profiles>

#     <!-- Users and ACL. -->
#     <users>
#         <!-- If user name was not specified, 'default' user is used. -->
#         <default>
#             <!-- Password could be specified in plaintext or in SHA256 (in hex format).

#                  If you want to specify password in plaintext (not recommended), place it in 'password' element.
#                  Example: <password>qwerty</password>.
#                  Password could be empty.

#                  If you want to specify SHA256, place it in 'password_sha256_hex' element.
#                  Example: <password_sha256_hex>65e84be33532fb784c48129675f9eff3a682b27168c0ea744b2cf58ee02337c5</password_sha256_hex>

#                  How to generate decent password:
#                  Execute: PASSWORD=$(base64 < /dev/urandom | head -c8); echo "$PASSWORD"; echo -n "$PASSWORD" | sha256sum | tr -d '-'
#                  In first line will be password and in second - corresponding SHA256.
#             -->
#            <!--  <password>123456</password> -->
#             <password_sha256_hex>8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92</password_sha256_hex>

#             <!-- List of networks with open access.

#                  To open access from everywhere, specify:
#                     <ip>::/0</ip>

#                  To open access only from localhost, specify:
#                     <ip>::1</ip>
#                     <ip>127.0.0.1</ip>

#                  Each element of list has one of the following forms:
#                  <ip> IP-address or network mask. Examples: 213.180.204.3 or 10.0.0.1/8 or 10.0.0.1/255.255.255.0
#                      2a02:6b8::3 or 2a02:6b8::3/64 or 2a02:6b8::3/ffff:ffff:ffff:ffff::.
#                  <host> Hostname. Example: server01.yandex.ru.
#                      To check access, DNS query is performed, and all received addresses compared to peer address.
#                  <host_regexp> Regular expression for host names. Example, ^server\d\d-\d\d-\d\.yandex\.ru$
#                      To check access, DNS PTR query is performed for peer address and then regexp is applied.
#                      Then, for result of PTR query, another DNS query is performed and all received addresses compared to peer address.
#                      Strongly recommended that regexp is ends with $
#                  All results of DNS requests are cached till server restart.
#             -->
#             <networks incl="networks" replace="replace">
#                 <ip>::/0</ip>
#             </networks>

#             <!-- Settings profile for user. -->
#             <profile>default</profile>

#             <!-- Quota for user. -->
#             <quota>default</quota>
#         </default>

#         <!-- Example of user with readonly access. -->
#         <readonly>
#            <!--  <password>123456</password> -->
#             <password_sha256_hex>8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92</password_sha256_hex>
#             <networks incl="networks" replace="replace">
#                 <ip>::1</ip>
#                 <ip>127.0.0.1</ip>
#             </networks>
#             <profile>readonly</profile>
#             <quota>default</quota>
#         </readonly>
#         <ckh_readonly>
#             <password_sha256_hex>8545f4dc3fe83224980663ebc2540d6a68288c8afcbaf4da3b22e72212e256e1</password_sha256_hex>
#             <networks incl="networks" replace="replace">
#                 <ip>::/0</ip>
#             </networks>
#             <profile>readonly</profile>
#             <quota>default</quota>
#             <allow_databases>
#                 <database>default</database>
#             </allow_databases>
#         </ckh_readonly>
#     </users>

#     <!-- Quotas. -->
#     <quotas>
#         <!-- Name of quota. -->
#         <default>
#             <!-- Limits for time interval. You could specify many intervals with different limits. -->
#             <interval>
#                 <!-- Length of interval. -->
#                 <duration>3600</duration>

#                 <!-- No limits. Just calculate resource usage for time interval. -->
#                 <queries>0</queries>
#                 <errors>0</errors>
#                 <result_rows>0</result_rows>
#                 <read_rows>0</read_rows>
#                 <execution_time>0</execution_time>
#             </interval>
#         </default>
#     </quotas>
# </yandex>

# 4、修改 /etc/hosts
# #三台集群服务器同时修改，对应本机的IP修改为127.0.0.1
# 172.30.10.152 ip-172-30-10-152
# 172.30.10.155 ip-172-30-10-155
# 172.30.10.158 ip-172-30-10-158

# 5、启动服务，创建表如下：
# #三台集群服务器同时执行以下创表DDL
# CREATE TABLE ontime_local (FlightDate Date,Year UInt16) ENGINE = ReplicatedMergeTree('/clickhouse/tables/ontime_replica/{shard}', '{replica}', FlightDate, (Year, FlightDate), 8192);
# CREATE TABLE ontime_all AS ontime_local ENGINE = Distributed(bh_3s1r_cluster, default, ontime_local, rand());

# 6、往其中一台客户端插入数据，从另外集群的客户端查询没有相应数据。
# insert into ontime_all (FlightDate,Year)values('2001-01-01',2001);
# insert into ontime_all (FlightDate,Year)values('2002-01-01',2002);
# insert into ontime_all (FlightDate,Year)values('2003-01-01',2003);