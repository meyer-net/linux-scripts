#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 相关参考：
#          https://linux.cn/article-5730-1.html
#------------------------------------------------
local TMP_MYSQL_SETUP_PORT=13306
local TMP_MYSQL_SETUP_PWD="mysql%DB^m${LOCAL_ID}~"
local TMP_MYSQL_SETUP_BK_PWD="msql%DB^bk${LOCAL_ID}~"

##########################################################################################################

# 1-配置环境
function set_environment()
{
    cd ${__DIR}

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_mysql()
{
	local TMP_MSQL_SETUP_DIR=${1}

	## 源模式
    local TMP_MSQL_SETUP_RPM_NAME="mysql57-community-release-el${OS_VERS}-11.noarch.rpm"
    while_wget "--content-disposition http://dev.mysql.com/get/${TMP_MSQL_SETUP_RPM_NAME}" "rpm -ivh ${TMP_MSQL_SETUP_RPM_NAME}"

    soft_yum_check_setup "mysql-community-server"

	# 需要运行一次，生成基础文件
    echo "MySql: Setup Successded，Starting init data file..."
    systemctl start mysqld.service 
    systemctl stop mysqld.service

	# 创建日志软链
	local TMP_MSQL_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/mysql
	local TMP_MSQL_SETUP_LNK_LOGS_PATH=${TMP_MSQL_SETUP_LNK_LOGS_DIR}/mysqld.log
	local TMP_MSQL_SETUP_LNK_DATA_DIR=${DATA_DIR}/mysql
	local TMP_MSQL_SETUP_LOGS_DIR=${TMP_MSQL_SETUP_DIR}/logs
	local TMP_MSQL_SETUP_DATA_DIR=${TMP_MSQL_SETUP_DIR}/data

	# 先清理文件，再创建文件
    path_not_exists_create ${TMP_MSQL_SETUP_DIR}
	rm -rf ${TMP_MSQL_SETUP_LOGS_DIR}
	rm -rf ${TMP_MSQL_SETUP_DATA_DIR}
	mkdir -pv ${TMP_MSQL_SETUP_LNK_LOGS_DIR}
    mv /var/log/mysqld.log ${TMP_MSQL_SETUP_LNK_LOGS_PATH}
	cp /var/lib/mysql ${TMP_MSQL_SETUP_LNK_DATA_DIR} -Rp
    mv /var/lib/mysql ${TMP_MSQL_SETUP_LNK_DATA_DIR}_empty
	
    ln -sf ${TMP_MSQL_SETUP_LNK_LOGS_PATH} /var/log/mysqld.log
	ln -sf ${TMP_MSQL_SETUP_LNK_LOGS_DIR} ${TMP_MSQL_SETUP_LOGS_DIR}
	ln -sf ${TMP_MSQL_SETUP_LNK_DATA_DIR} /var/lib/mysql
	ln -sf ${TMP_MSQL_SETUP_LNK_DATA_DIR} ${TMP_MSQL_SETUP_DATA_DIR}

    if [ ! -d ${TMP_MSQL_SETUP_LNK_DATA_DIR} ]; then
        echo "MySql: Path '/var/lib/mysql --> ${TMP_MSQL_SETUP_LNK_DATA_DIR}' can't move，sure it no problems and press anykey to go on"
        read -e _tmp
    fi

	# 授权权限，否则无法写入
    create_user_if_not_exists mysql mysql
    chgrp -R mysql ${TMP_MSQL_SETUP_LNK_DATA_DIR}
    chown -R mysql:mysql ${TMP_MSQL_SETUP_LNK_DATA_DIR}

	return $?
}

##########################################################################################################

function setup_mariadb()
{
	local TMP_MDB_SETUP_DIR=${1}

	## 直装模式
    tee /etc/yum.repos.d/MariaDB.repo <<-'EOF'
# MariaDB 10.x CentOS repository list
# http://mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = https://mirrors.ustc.edu.cn/mariadb/yum/10.2/centos7-amd64/
gpgkey = http://mirrors.ustc.edu.cn/mariadb/yum/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

	soft_yum_check_setup "MariaDB-devel"
    
	soft_yum_check_setup "MariaDB-client"
    
	soft_yum_check_setup "MariaDB-server"

	# 需要运行一次，生成基础文件
    echo "MariaDB: Setup Successded，Starting init data file..."
    systemctl start mariadb.service 
    systemctl stop mariadb.service

	# 创建日志软链
	local TMP_MDB_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/mariadb
	local TMP_MDB_SETUP_LNK_DATA_DIR=${DATA_DIR}/mariadb
	local TMP_MDB_SETUP_LOGS_DIR=${TMP_MDB_SETUP_DIR}/logs
	local TMP_MDB_SETUP_DATA_DIR=${TMP_MDB_SETUP_DIR}/data

	# 先清理文件，再创建文件
    path_not_exists_create ${TMP_MDB_SETUP_DIR}
	rm -rf ${TMP_MDB_SETUP_LOGS_DIR}
	rm -rf ${TMP_MDB_SETUP_DATA_DIR}

	cp /var/lib/mysql ${TMP_MDB_SETUP_LNK_DATA_DIR} -Rp
    mv /var/lib/mysql ${TMP_MDB_SETUP_LNK_DATA_DIR}_empty
    
	ln -sf ${TMP_MDB_SETUP_LNK_LOGS_DIR} ${TMP_MDB_SETUP_LOGS_DIR}
	ln -sf ${TMP_MDB_SETUP_LNK_DATA_DIR} /var/lib/mysql
	ln -sf ${TMP_MDB_SETUP_LNK_DATA_DIR} ${TMP_MDB_SETUP_DATA_DIR}

    if [ ! -d ${TMP_MDB_SETUP_LNK_DATA_DIR} ]; then
        echo "MariaDB: Path '/var/lib/mysql --> ${TMP_MDB_SETUP_LNK_DATA_DIR}' can't move，sure it no problems and press anykey to go on"
        read -e _tmp
    fi

	# 授权权限，否则无法写入
    create_user_if_not_exists mysql mysql
    chgrp -R mysql ${TMP_MDB_SETUP_LNK_DATA_DIR}
    chown -R mysql:mysql ${TMP_MDB_SETUP_LNK_DATA_DIR}
    chmod 700 ${TMP_MDB_SETUP_LNK_DATA_DIR}/test/
    
    rm -rf /etc/yum.repos.d/MariaDB.repo

    yum clean all && yum makecache fast

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_mysql()
{
	local TMP_MSQL_SETUP_DIR=${1}

	cd ${TMP_MSQL_SETUP_DIR}
	
	local TMP_MSQL_SETUP_LNK_ETC_DIR=${ATT_DIR}/mysql
	local TMP_MSQL_SETUP_LNK_ETC_REALY_DIR=${TMP_MSQL_SETUP_LNK_ETC_DIR}/my.cnf.d
	local TMP_MSQL_SETUP_LNK_ETC_PATH=${TMP_MSQL_SETUP_LNK_ETC_DIR}/my.cnf
	local TMP_MSQL_SETUP_ETC_DIR=${TMP_MSQL_SETUP_DIR}/etc

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mkdir -pv ${TMP_MSQL_SETUP_LNK_ETC_DIR}

	# 替换原路径链接
    ln -sf /etc/my.cnf.d ${TMP_MSQL_SETUP_LNK_ETC_REALY_DIR} 
	ln -sf ${TMP_MSQL_SETUP_LNK_ETC_DIR} ${TMP_MSQL_SETUP_ETC_DIR}
    ln -sf /etc/my.cnf ${TMP_MSQL_SETUP_LNK_ETC_PATH}

    local TMP_MSQL_SETUP_TEMPORARY_PWD=`grep "A temporary password is generated for root" /var/log/mysqld.log`
    TMP_MSQL_SETUP_TEMPORARY_PWD="${TMP_MSQL_SETUP_TEMPORARY_PWD##*: }"
    echo "MySql: System temporary password is '${green}${TMP_MSQL_SETUP_TEMPORARY_PWD}${reset}'，Please ${red}remember it${reset} for local login"

	input_if_empty "TMP_MYSQL_SETUP_PWD" "MySql: Please ender ${green}mysql password${reset} of ${red}user(Root)${reset} for '%'"
    
    systemctl start mysqld.service 
    mysql -uroot -p${TMP_MSQL_SETUP_TEMPORARY_PWD} -P${TMP_MYSQL_SETUP_PORT} -e"
    SET password FOR 'root'@'localhost'=PASSWORD('${TMP_MSQL_SETUP_TEMPORARY_PWD}');
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${TMP_MYSQL_SETUP_PWD}' WITH GRANT OPTION;
    USE mysql;
    DELETE FROM user WHERE user='' OR user='${SYS_NAME}' OR authentication_string='';
    SET GLOBAL MAX_CONNECT_ERRORS=1024;
    FLUSH HOSTS;
    FLUSH PRIVILEGES;
	select host,user,authentication_string from user;
    exit" --connect-expired-password
    echo "MySql: Password（'${TMP_MYSQL_SETUP_PWD}'） Set Success！"
    systemctl stop mysqld.service

    # 开始配置
    conf_all "${TMP_MDB_SETUP_DIR}" "/etc/my.cnf"

	return $?
}

##########################################################################################################

function conf_mariadb()
{
	local TMP_MDB_SETUP_DIR=${1}

	cd ${TMP_MDB_SETUP_DIR}
	
	local TMP_MDB_SETUP_LNK_ETC_DIR=${ATT_DIR}/mysql
	local TMP_MDB_SETUP_LNK_ETC_REALY_DIR=${TMP_MDB_SETUP_LNK_ETC_DIR}/my.cnf.d
	local TMP_MDB_SETUP_LNK_ETC_PATH=${TMP_MDB_SETUP_LNK_ETC_DIR}/my.cnf
	local TMP_MDB_SETUP_ETC_DIR=${TMP_MDB_SETUP_DIR}/etc

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mkdir -pv ${TMP_MDB_SETUP_LNK_ETC_DIR}

	# 替换原路径链接
    ln -sf /etc/my.cnf.d ${TMP_MDB_SETUP_LNK_ETC_REALY_DIR} 
	ln -sf ${TMP_MDB_SETUP_LNK_ETC_DIR} ${TMP_MDB_SETUP_ETC_DIR}
    ln -sf /etc/my.cnf ${TMP_MDB_SETUP_LNK_ETC_PATH}

	input_if_empty "TMP_MYSQL_SETUP_PWD" "MariaDB: Please ender ${green}mysql password${reset} of User(Root)"
    
    systemctl start mariadb.service 
    mysql -e"
    use mysql;
    UPDATE user SET password=PASSWORD('${TMP_MYSQL_SETUP_PWD}') WHERE user='root';
    GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY '${TMP_MYSQL_SETUP_PWD}' WITH GRANT OPTION;
    DELETE FROM user WHERE user='' OR user='${SYS_NAME}' OR password='';
    FLUSH PRIVILEGES;
	select host,user,password from user;
    exit"
    echo "MariaDB: Password（'${TMP_MYSQL_SETUP_PWD}'） Set Success！"

    systemctl stop mariadb.service

    # 开始配置    
    conf_all "${TMP_MDB_SETUP_DIR}" "/etc/my.cnf.d/server.cnf"

	return $?
}

function conf_all()
{  
	local TMP_DB_SETUP_DIR=${1}
	local TMP_DB_ETC_PATH=${2}

	local TMP_DB_SETUP_LOGS_DIR=${TMP_DB_SETUP_DIR}/logs

    sed -i "/\[mysqld\]/a \ " ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a long_query_time=3" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a slow-query-log-file=${TMP_DB_SETUP_LOGS_DIR}/mysql-slow.log" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a slow-query-log=0" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a \ " ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a max_heap_table_size=64M" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a tmp_table_size=64M" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a \ " ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a query_cache_size=256M" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a query_cache_min_res_unit=4K" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a query_cache_limit=512K" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a query_cache_type=1" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a \ " ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a thread_cache_size=512" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a max_connect_errors=256" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a max_connections=1024" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a \ " ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a skip-character-set-client-handshake" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a skip-name-resolve" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a \ " ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a collation-server=utf8_unicode_ci" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a init_connect='SET collation_connection=utf8_unicode_ci'" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a init_connect='SET NAMES utf8'" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a character-set-server=utf8" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a \ " ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a server-id=${LOCAL_ID}" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a user=mysql" ${TMP_DB_ETC_PATH}
    sed -i "/\[mysqld\]/a port=${TMP_MYSQL_SETUP_PORT}" ${TMP_DB_ETC_PATH}
    
	return $?
}

function check_setup_conf()
{
    TMP_MYSQL_SETUP_CNF_PATH="/etc/my.cnf"
    if [ -f "/etc/my.cnf.d/server.cnf" ]; then
        TMP_MYSQL_SETUP_CNF_PATH="/etc/my.cnf.d/server.cnf"
    fi

    exec_if_choice "TMP_MYSQL_SETUP_CHOICE_CONF" "Please choice which mysql(mariadb) conf you want to do" "...,Master,Slave,Exit" "${TMP_SPLITER}" "conf_mysql_"

	return $?
}

function conf_mysql_master()
{
	echo "Start Config MySQL-Master"

	#不加binlog-do-db和binlog_ignore_db，那就表示备份全部数据库。
	#echo "MySQL: Please Ender MySQL-Master All DB To Bak And Use Character ',' To Split Like 'db_a,db_b' In Network"
	#read -e DBS

	sed -i "s@^server-id.*@server-id = ${LOCAL_ID}@g" ${TMP_MYSQL_SETUP_CNF_PATH}

	sed -i "/\[mysqld\]/a relay-log-index = relay-bin-index" ${TMP_MYSQL_SETUP_CNF_PATH}
	sed -i "/\[mysqld\]/a relay-log = relay-bin" ${TMP_MYSQL_SETUP_CNF_PATH}
	sed -i "/\[mysqld\]/a binlog-ignore-db = mysql" ${TMP_MYSQL_SETUP_CNF_PATH}
	#表示只备份
	#sed -i "/\[mysqld\]/a binlog-do-db=$DBS" ${TMP_MYSQL_SETUP_CNF_PATH}
	sed -i "/\[mysqld\]/a #Defind By Meyer 2016.12.16" ${TMP_MYSQL_SETUP_CNF_PATH}

	service mysql restart
	echo "Config MySQL-Master Over。"
	echo "------------------------------------------"
	echo "Start Grant Permission MySQL To Slave"
	local TMP_MYSQL_SETUP_CONF_DB_MASTER_PWD="${TMP_MYSQL_SETUP_PWD}"
    input_if_empty "TMP_MYSQL_SETUP_CONF_DB_MASTER_PWD" "MySQL: Please ender ${red}mysql localhost password of root${reset}"
    input_if_empty "TMP_MYSQL_SETUP_CONF_DB_MASTER_SLAVE" "MySQL: Please ender ${red}mysql slave address in internal${reset}"
	
	#在主服务器新建一个用户赋予“REPLICATION SLAVE”的权限。
	mysql -uroot -p${TMP_MYSQL_SETUP_CONF_DB_MASTER_PWD} -P${TMP_MYSQL_SETUP_PORT} -e"
	GRANT FILE ON *.* TO 'backup'@'${TMP_MYSQL_SETUP_CONF_DB_MASTER_SLAVE}' IDENTIFIED BY '${TMP_MYSQL_SETUP_BK_PWD}';
	GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* to 'backup'@'${TMP_MYSQL_SETUP_CONF_DB_MASTER_SLAVE}' identified by '${TMP_MYSQL_SETUP_BK_PWD}';
	FLUSH PRIVILEGES;
	select user,host,password from mysql.user;
	show master status;
	exit"
	echo "Grant Permission MySQL To Slave Over。"
	echo "------------------------------------------"
	echo "Set All Done"

	return $?
}

# option:
#         MASTER_BIND = 'interface_name'
#       | MASTER_HOST = 'host_name'
#       | MASTER_USER = 'user_name'
#       | MASTER_PASSWORD = 'password'
#       | MASTER_PORT = port_num
#       | MASTER_CONNECT_RETRY = interval
#       | MASTER_RETRY_COUNT = count
#       | MASTER_DELAY = interval
#       | MASTER_HEARTBEAT_PERIOD = interval
#       | MASTER_LOG_FILE = 'master_log_name'
#       | MASTER_LOG_POS = master_log_pos
#       | MASTER_AUTO_POSITION = {0|1}
#       | RELAY_LOG_FILE = 'relay_log_name'
#       | RELAY_LOG_POS = relay_log_pos
#       | MASTER_SSL = {0|1}
#       | MASTER_SSL_CA = 'ca_file_name'
#       | MASTER_SSL_CAPATH = 'ca_directory_name'
#       | MASTER_SSL_CERT = 'cert_file_name'
#       | MASTER_SSL_CRL = 'crl_file_name'
#       | MASTER_SSL_CRLPATH = 'crl_directory_name'
#       | MASTER_SSL_KEY = 'key_file_name'
#       | MASTER_SSL_CIPHER = 'cipher_list'
#       | MASTER_SSL_VERIFY_SERVER_CERT = {0|1}
#       | IGNORE_SERVER_IDS = (server_id_list)
function conf_mysql_slave()
{
	echo "Start Config MySQL-Slave"
	local TMP_MYSQL_SETUP_CONF_DB_SLAVE_MASTER=""
    input_if_empty "TMP_MYSQL_SETUP_CONF_DB_SLAVE_MASTER" "MySQL: Please ender ${green}mysql master host${reset} in internal"

	local TMP_MYSQL_SETUP_CONF_DB_SLAVE_MASTER_PORT="${TMP_MYSQL_SETUP_PORT}"
    input_if_empty "TMP_MYSQL_SETUP_CONF_DB_SLAVE_MASTER_PORT" "MySQL: Please sure ${green}mysql master port${reset} of host(${red}${TMP_MYSQL_SETUP_CONF_DB_SLAVE_MASTER}${reset})"

	#不加binlog-do-db和binlog_ignore_db，那就表示备份全部数据库。
	#echo "MySQL: Please Ender MySQL-Slave All DB To Bak And Use Character ',' To Split Like 'db_a,db_b' In Network"
	#read -e DBS

	sed -i "s@^server-id = 1@server-id = ${LOCAL_ID}@g" ${TMP_MYSQL_SETUP_CNF_PATH}
	sed -i "s@^innodb_thread_concurrency =.*@innodb_thread_concurrency = 0@g" ${TMP_MYSQL_SETUP_CNF_PATH}

	sed -i "/\[mysqld\]/a skip-slave-start" ${TMP_MYSQL_SETUP_CNF_PATH}
	sed -i "/\[mysqld\]/a replicate-ignore-db = mysql" ${TMP_MYSQL_SETUP_CNF_PATH}
	#表示只备份
	#sed -i "/\[mysqld\]/a replicate-do-db=$DBS" ${TMP_MYSQL_SETUP_CNF_PATH}
	sed -i "/\[mysqld\]/a #Defind By Meyer 2016.12.16" ${TMP_MYSQL_SETUP_CNF_PATH}

	service mysql restart
	echo "Config MySQL-Slave Over。"
	echo "------------------------------------------"
	echo "Start Set And Test To Login MySQL-Master"    
	local TMP_MYSQL_SETUP_CONF_DB_SLAVE_PWD="${TMP_MYSQL_SETUP_PWD}"
    input_if_empty "TMP_MYSQL_SETUP_CONF_DB_SLAVE_PWD" "MySQL: Please ender ${green}mysql localhost password of root${reset}"
	
	#在主服务器新建一个用户赋予“REPLICATION SLAVE”的权限。
	mysql -uroot -p${TMP_MYSQL_SETUP_CONF_DB_SLAVE_PWD} -P${TMP_MYSQL_SETUP_PORT} -e"
	stop slave;
	reset slave;
	change master to master_host='${TMP_MYSQL_SETUP_CONF_DB_SLAVE_MASTER}', master_port=${TMP_MYSQL_SETUP_CONF_DB_SLAVE_MASTER_PORT}, master_user='backup', master_password='${TMP_MYSQL_SETUP_BK_PWD}';
	start slave;
	show slave status\G;
	FLUSH PRIVILEGES;
	select user,host,password from mysql.user;
	exit"
	echo "Set And Test To Login MySQL-Master Over。"
	echo "------------------------------------------"
	echo "If U See Some Problems Please Visit 'https://yq.aliyun.com/articles/27792' To Look Some Questions"
	echo "------------------------------------------"
	echo "Set All Done"

	# 添加系统启动命令
    echo_startup_config "mysql_slave" "${TMP_MSQL_SETUP_DIR}" "echo 'start slave' | mysql -uroot -p${TMP_MYSQL_SETUP_CONF_DB_SLAVE_PWD} -P${TMP_MYSQL_SETUP_PORT}" "" "999"

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_mysql()
{
	local TMP_MSQL_SETUP_DIR=${1}

	cd ${TMP_MSQL_SETUP_DIR}
	
	# 验证安装
    mysql -V

	# 当前启动命令
    systemctl daemon-reload
    systemctl enable mysqld.service
    systemctl start mysqld.service
    systemctl status mysqld.service
    chkconfig mysqld on
    # journalctl -u mysql --no-pager | less
    # systemctl reload mysql.service

	# 授权iptables端口访问
	echo_soft_port ${TMP_MYSQL_SETUP_PORT}

	return $?
}

function boot_mariadb()
{
	local TMP_MDB_SETUP_DIR=${1}

	cd ${TMP_MDB_SETUP_DIR}
	
	# 验证安装
    mysql -V

	# 当前启动命令
    systemctl daemon-reload
    systemctl enable mariadb.service
    systemctl start mariadb.service
    systemctl status mariadb.service
    chkconfig mariadb on
    # journalctl -u mariadb --no-pager | less
    # systemctl reload mariadb

	# 授权iptables端口访问
	echo_soft_port ${TMP_MDB_SETUP_PORT}

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_mysql()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_mysql()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_mysql()
{
	local TMP_MSQL_SETUP_DIR=${SETUP_DIR}/mysql
    
	set_environment "${TMP_MSQL_SETUP_DIR}"

	setup_mysql "${TMP_MSQL_SETUP_DIR}"

	conf_mysql "${TMP_MSQL_SETUP_DIR}"

    # down_plugin_mysql "${TMP_MSQL_SETUP_DIR}"

	boot_mysql "${TMP_MSQL_SETUP_DIR}"

	return $?
}

function exec_step_mariadb()
{
	local TMP_MDB_SETUP_DIR=${SETUP_DIR}/mariadb
    
	set_environment "${TMP_MDB_SETUP_DIR}"

	setup_mariadb "${TMP_MDB_SETUP_DIR}"

	conf_mariadb "${TMP_MDB_SETUP_DIR}"

    # down_plugin_mariadb "${TMP_MDB_SETUP_DIR}"

	boot_mariadb "${TMP_MDB_SETUP_DIR}"

	return $?
}

# x1-下载软件
function check_setup_mysql()
{
	local TMP_MSQL_SETUP_LNK_DATA_DIR=${DATA_DIR}/mysql

    path_not_exists_action "${TMP_MSQL_SETUP_LNK_DATA_DIR}" "print_mysql" "MySql was installed"

	return $?
}

function check_setup_mariadb()
{
	local TMP_MDB_SETUP_LNK_DATA_DIR=${DATA_DIR}/mariadb

    path_not_exists_action "${TMP_MDB_SETUP_LNK_DATA_DIR}" "print_mariadb" "MariaDB was installed"

	return $?
}

function print_mysql()
{
    setup_soft_basic "MySql" "exec_step_mysql"

	return $?
}

function print_mariadb()
{
    setup_soft_basic "MariaDB" "exec_step_mariadb"

	return $?
}

##########################################################################################################

#安装主体
exec_if_choice "TMP_MSQL_SETUP_CHOICE" "Please choice which mysql type you want to setup" "...,MySQL,MariaDB,Conf,Exit" "${TMP_SPLITER}" "check_setup_"
#mysqlcheck -u root -p --auto-repair --check --optimize --all-databases