#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function check_env()
{
    # local SSE42_SUPPORTED=`grep -q sse4_2 /proc/cpuinfo`
    # check_yn_action "SSE42_SUPPORTED"
    
    soft_rpm_check_action "clickhouse" "setup_ck" "Clickhouse was installed"

    return $?
}
# https://www.zouyesheng.com/clickhouse.html
function setup_ck()
{
    cd $DOWN_DIR
    mkdir -pv rpms/clickhouse
    cd rpms/clickhouse

    # http://www.clickhouse.com.cn/topic/5a366e97828d76d75ab5d5a0
    yum -y install libicu-devel

    echo "------------------------------------------------------"
    echo "ClickHouse: System start find the newer stable version"
    echo "------------------------------------------------------"
    local TMP_NEWER_STABLE_VERSION_CH_SERVER="clickhouse-server-19.4.0-2.rpm"
    set_url_list_newer_href_link_filename "TMP_NEWER_STABLE_VERSION_CH_SERVER" "http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/" "clickhouse-server-().rpm"
    local TMP_NEWER_STABLE_VERSION_CH_CLIENT=`echo "${TMP_NEWER_STABLE_VERSION_CH_SERVER}" | sed 's@server@client@g'`

    local TMP_NEWER_STABLE_VERSION_CH_SERVER_COMMON="clickhouse-server-common-19.4.0-2.rpm"
    set_url_list_newer_href_link_filename "TMP_NEWER_STABLE_VERSION_CH_SERVER_COMMON" "http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/" "clickhouse-server-common-().rpm"

    local TMP_NEWER_STABLE_VERSION_CH_COMMON_STATIC="clickhouse-common-static-19.4.0-2.rpm"
    set_url_list_newer_href_link_filename "TMP_NEWER_STABLE_VERSION_CH_COMMON_STATIC" "http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/" "clickhouse-common-static-().rpm"

    #19.13.3.26-1
    #curl -s https://packagecloud.io/install/repositories/Altinity/clickhouse/script.rpm.sh | sudo bash
    
    echo "ClickHouse[server-common]: The newer stable version is ${TMP_NEWER_STABLE_VERSION_CH_SERVER_COMMON}"
    while_wget "--content-disposition http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/${TMP_NEWER_STABLE_VERSION_CH_SERVER_COMMON}" "rpm -ivh ${TMP_NEWER_STABLE_VERSION_CH_SERVER_COMMON}"

    echo "ClickHouse[server-static]: The newer stable version is ${TMP_NEWER_STABLE_VERSION_CH_COMMON_STATIC}"
    while_wget "--content-disposition http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/${TMP_NEWER_STABLE_VERSION_CH_COMMON_STATIC}" "rpm -ivh ${TMP_NEWER_STABLE_VERSION_CH_COMMON_STATIC}"

    echo "ClickHouse[server]: The newer stable version is ${TMP_NEWER_STABLE_VERSION_CH_SERVER}"
    while_wget "--content-disposition http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/${TMP_NEWER_STABLE_VERSION_CH_SERVER}" "rpm -ivh ${TMP_NEWER_STABLE_VERSION_CH_SERVER}"

    echo "ClickHouse[client]: The newer stable version is ${TMP_NEWER_STABLE_VERSION_CH_CLIENT}"
    while_wget "--content-disposition http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/${TMP_NEWER_STABLE_VERSION_CH_CLIENT}" "rpm -ivh ${TMP_NEWER_STABLE_VERSION_CH_CLIENT}"

    # 默认配置文件位置
    # /etc/clickhouse-server/config.xml  
    # /etc/clickhouse-server/users.xml

    CLICKHOUSE_SERVER_CONF_DIR=${ATT_DIR}/clickhouse/server/conf
    CLICKHOUSE_CLIENT_CONF_DIR=${ATT_DIR}/clickhouse/client/conf
    CLICKHOUSE_SERVER_LOGS_DIR=${LOGS_DIR}/clickhouse/server
    CLICKHOUSE_SERVER_DATA_DIR=${DATA_DIR}/clickhouse
    CLICKHOUSE_SERVER_DATA_ETC_DIR=${CLICKHOUSE_SERVER_DATA_DIR}/etc
    CLICKHOUSE_SERVER_DATA_XML_DIR=${CLICKHOUSE_SERVER_DATA_DIR}/xml
    mkdir -pv ${CLICKHOUSE_SERVER_LOGS_DIR}
    mkdir -pv ${CLICKHOUSE_SERVER_DATA_ETC_DIR} && rm -rf ${CLICKHOUSE_SERVER_DATA_ETC_DIR}
    mkdir -pv ${CLICKHOUSE_SERVER_DATA_XML_DIR} && rm -rf ${CLICKHOUSE_SERVER_DATA_XML_DIR}
    # mv mycat $SETUP_DIR

    mkdir -pv ${CLICKHOUSE_SERVER_CONF_DIR} && rm -rf ${CLICKHOUSE_SERVER_CONF_DIR}
    mv /etc/clickhouse-server ${CLICKHOUSE_SERVER_CONF_DIR}
    ln -sf ${CLICKHOUSE_SERVER_CONF_DIR} /etc/clickhouse-server

    mkdir -pv ${CLICKHOUSE_CLIENT_CONF_DIR} && rm -rf ${CLICKHOUSE_CLIENT_CONF_DIR}
    mv /etc/clickhouse-client ${CLICKHOUSE_CLIENT_CONF_DIR}
    ln -sf ${CLICKHOUSE_CLIENT_CONF_DIR} /etc/clickhouse-client

read -e T
    # 默认启动脚本，注意，这个名字虽然叫server，其实是个shell脚本
    sed -i "s@^CLICKHOUSE_LOGDIR_USER=.*@CLICKHOUSE_LOGDIR_USER=clickhouse@g" /etc/rc.d/init.d/clickhouse-server

    local CLICKHOUSE_TCP_PORT=9876
	input_if_empty "CLICKHOUSE_TCP_PORT" "Clickhouse: Please ender ${red}tcp port${reset}"
    sed -i "s@<tcp_port>[0-9]*</tcp_port>@<tcp_port>$CLICKHOUSE_TCP_PORT</tcp_port>@g" /etc/clickhouse-server/config.xml

    sed -i "s@<path>.*</path>@<path>${CLICKHOUSE_SERVER_DATA_XML_DIR}/</path>@g" /etc/clickhouse-server/config.xml
    sed -i "s@<tmp_path>.*</tmp_path>@<tmp_path>${CLICKHOUSE_SERVER_DATA_XML_DIR}/tmp/</tmp_path>@g" /etc/clickhouse-server/config.xml
    sed -i "/<yandex>/a     <listen_host>0.0.0.0</listen_host>" /etc/clickhouse-server/config.xml
    
read -e T
    echo_soft_port 8123

    bash /etc/rc.d/init.d/clickhouse-server start
    sleep 3
    bash /etc/rc.d/init.d/clickhouse-server status

read -e T
    mv /var/lib/clickhouse-server ${CLICKHOUSE_SERVER_DATA_ETC_DIR}
    chown -R clickhouse:clickhouse ${CLICKHOUSE_SERVER_DATA_ETC_DIR}
    ln -sf ${CLICKHOUSE_SERVER_DATA_ETC_DIR} /var/lib/clickhouse-server

read -e T
    mv /var/log/clickhouse-server ${CLICKHOUSE_SERVER_LOGS_DIR}
    chown -R clickhouse:clickhouse ${CLICKHOUSE_SERVER_LOGS_DIR}
    ln -sf ${CLICKHOUSE_SERVER_LOGS_DIR} /var/log/clickhouse-server
    
    echo_startup_config "clickhouse" "/etc/rc.d/init.d" "bash clickhouse-server start"

	return $?
}

setup_soft_basic "Clickhouse" "check_env"

# 1、/etc/clickhouse-server/config.xml添加修改如下：
#     <listen_host>::1</listen_host>
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
#         <port>2233</port>
#     </node>
#     <node index="2">
#         <host>ip-172-30-10-155</host>
#         <port>2233</port>
#     </node>
#     <node index="3">
#         <host>ip-172-30-10-158</host>
#         <port>2233</port>
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
