#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_environment()
{
	sudo mkdir -pv $DATA_DIR
	return $?
}

function check_setup_mysql()
{
    path_not_exits_action "$DATA_DIR/mysql" "print_mysql" "MySql was installed"
	return $?
}

function check_setup_mariadb()
{
    path_not_exits_action "$DATA_DIR/mariadb" "print_mariadb" "MariaDB was installed"
	return $?
}

function print_mysql()
{
    setup_soft_basic "Mysql" "setup_mysql"
	return $?
}

function print_mariadb()
{
    setup_soft_basic "MariaDB" "setup_mariadb"
	return $?
}

function print_conf()
{
    return $?
}

function setup_mysql()
{
    yum -y remove mysql-community-server
    rm -rf /var/log/mysqld.log

    #安装mysql rpm包
    rpm -ivh http://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm

    #安装mysql
    yum -y install mysql-community-server

    service mysqld restart

    set_mysql

	return $?
}

function set_mysql()
{
    password=`grep "A temporary password is generated for root" /var/log/mysqld.log`
    password=${password##*: }
    echo "Mysql: System Inited Password Is '$password'"
    echo "--------------------------------------------"
	input_if_empty "TMP_SETUP_MYSQL_PWD" "Mysql: Please ender ${red}mysql password${reset} of User(Root)"

    mysql -uroot -p$password -e"
    SET password=PASSWORD('$TMP_SETUP_MYSQL_PWD');
    GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY '$TMP_SETUP_MYSQL_PWD';
    USE mysql;
    DELETE FROM user WHERE user='' OR password='';
    SET GLOBAL MAX_CONNECT_ERRORS=1000;
    FLUSH HOSTS;
    FLUSH PRIVILEGES;
    exit"

    echo "Mysql: Password（'$TMP_SETUP_MYSQL_PWD'） Set Success！"

    mysqlDbDir=$DATA_DIR/mysql
    systemctl stop mysqld.service
    mv /var/lib/mysql $mysqlDbDir
    #mysqladmin -uroot password "$TMP_SETUP_MYSQL_PWD"

    if [ ! -d $mysqlDbDir ]; then
        echo "Mysql: Path '/var/lib/mysql' Cannot Move，Sure It No Problems And Press Anykey To Go On"
        read -e TMP
    fi
    
    chgrp -R mysql $mysqlDbDir
    chown -R mysql:mysql $mysqlDbDir
    service mysqld start
    systemctl disable mysqld.service
    systemctl enable mysqld.service
    
    echo_soft_port 3306
}

function setup_mariadb()
{
    echo '# MariaDB 10.1 CentOS repository list - created 2014-10-18 16:58 UTC
# http://mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
#baseurl = http://mirrors.ustc.edu.cn/mariadb/yum/10.0/centos7-amd64/
baseurl = https://mirrors.ustc.edu.cn/mariadb/yum/10.1/centos7-amd64/
gpgkey = http://mirrors.ustc.edu.cn/mariadb/yum/RPM-GPG-KEY-MariaDB
gpgcheck=1' > /etc/yum.repos.d/MariaDB.repo

    yum -y remove MariaDB-devel MariaDB-server MariaDB-client

    rm -rf /etc/my.cnf
    rm -rf /etc/init.d/mysql

    yum -y install mariadb-devel mysql-devel
    yum -y install MariaDB-client
    yum -y install MariaDB-server

    echo "---------------"
    mysql -V
    echo "---------------"
    
    set_mariadb
}

function set_mariadb()
{
    TMP_DATA_DIR=$DATA_DIR/mariadb
    
    yes | cp /usr/share/mysql/my-innodb-heavy-4G.cnf /etc/my.cnf
    sed -i "/\[mysqld\]/a datadir = $TMP_DATA_DIR" /etc/my.cnf
    sed -i "/\[mysqld\]/a skip-character-set-client-handshake" /etc/my.cnf
    sed -i "/\[mysqld\]/a collation-server=utf8_unicode_ci" /etc/my.cnf
    sed -i "/\[mysqld\]/a init_connect='SET collation_connection = utf8_unicode_ci'" /etc/my.cnf
    sed -i "/\[mysqld\]/a init_connect='SET NAMES utf8'" /etc/my.cnf
    sed -i "/\[mysqld\]/a character-set-server=utf8" /etc/my.cnf
    sed -i "/\[mysqld\]/a user = mysql" /etc/my.cnf
    sed -i "s@^socket[[:space:]]*=[[:space:]]*.*@socket          = $TMP_DATA_DIR/mysql.sock@g" /etc/my.cnf
    sed -i "s@^datadir=.*@datadir=$TMP_DATA_DIR@g" /etc/init.d/mysql
    echo "------------------------------------------"
    echo "MariaDB: Config Was Changed"
    echo "------------------------------------------"
	input_if_empty "TMP_SETUP_MYSQL_PWD" "MariaDB: Please ender ${red}mysql password${reset} of User(Root)"
    #/etc/init.d/mysql start
    #GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.1.210' WITH GRANT OPTION;
    #UPDATE user SET PASSWORD=PASSWORD('dbrootxxx@svr.1-211') WHERE USER='root';
    #FLUSH PRIVILEGES;
    #CREATE DATABASE db_name DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    #mysql_install_db
    
    if [ ! -d "$TMP_DATA_DIR" ]; then
        echo "MariaDB: Path '/var/lib/mysql' Will Be Move To '$TMP_DATA_DIR'"
        mv /var/lib/mysql $TMP_DATA_DIR
        sleep 10
        #mysqladmin -uroot password "$TMP_SETUP_MYSQL_PWD"
    fi
    
    chgrp -R mysql $TMP_DATA_DIR
    chown -R mysql:mysql $TMP_DATA_DIR
    chmod 700 $TMP_DATA_DIR/test/

    systemctl start mariadb.service

    mysql -e"
    use mysql;
    UPDATE user SET password=PASSWORD('$TMP_SETUP_MYSQL_PWD') WHERE user='root';
    GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY '$TMP_SETUP_MYSQL_PWD';
    DELETE FROM user WHERE user='' OR password='';
    FLUSH PRIVILEGES;
    exit"
    echo "MariaDB: Password（'$TMP_SETUP_MYSQL_PWD'） Set Success！"

    systemctl enable mariadb.service

    rm -rf /etc/yum.repos.d/MariaDB.repo
    
    echo_soft_port 3306

	return $?
}

function check_setup_set()
{
    exec_if_choice "CHOICE_MYSQL_SET" "Please choice which mysql set you want to do" "...,Master,Slave,Exit" "$TMP_SPLITER" "set_db_"
	return $?
}

function set_db_master()
{
	echo "Start Config Mysql-Master"

	#不加binlog-do-db和binlog_ignore_db，那就表示备份全部数据库。
	#echo "Mysql: Please Ender Mysql-Master All DB To Bak And Use Character ',' To Split Like 'db_a,db_b' In Network"
	#read -e DBS

	sed -i "s@^server-id = 1@server-id = $LOCAL_ID@g" /etc/my.cnf

	sed -i "/\[mysqld\]/a relay-log-index = relay-bin-index" /etc/my.cnf
	sed -i "/\[mysqld\]/a relay-log = relay-bin" /etc/my.cnf
	sed -i "/\[mysqld\]/a binlog-ignore-db = mysql" /etc/my.cnf
	#表示只备份
	#sed -i "/\[mysqld\]/a binlog-do-db=$DBS" /etc/my.cnf
	sed -i "/\[mysqld\]/a #Defind By Meyer 2016.12.16" /etc/my.cnf

	service mysql restart
	echo "Config Mysql-Master Over。"
	echo "------------------------------------------"
	echo "Start Grant Permission Mysql To Slave"
    input_if_empty "TMP_SET_DB_MASTER_PASSWORD" "Mysql: Please ender ${red}mysql localhost password of root${reset}"
    input_if_empty "TMP_SET_DB_MASTER_SLAVER" "Mysql: Please ender ${red}mysql slaver address in internal${reset}"
	
	#在主服务器新建一个用户赋予“REPLICATION SLAVE”的权限。
	mysql -uroot -p$TMP_SET_DB_MASTER_PASSWORD -e"
	GRANT FILE ON *.* TO 'backup'@'$TMP_SET_DB_MASTER_SLAVER' IDENTIFIED BY 'backup#1475963&m';
	GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* to 'backup'@'$TMP_SET_DB_MASTER_SLAVER' identified by 'backup#1475963&m';
	FLUSH PRIVILEGES;
	select user,host,password from mysql.user;
	show master status;
	exit"
	echo "Grant Permission Mysql To Slave Over。"
	echo "------------------------------------------"
	echo "Set All Done"

	return $?
}

function set_db_slave()
{
	echo "Start Config Mysql-Slave"
    input_if_empty "TMP_SET_DB_SLAVER_MASTER" "Mysql: Please ender ${red}mysql master address in internal${reset}"

	#不加binlog-do-db和binlog_ignore_db，那就表示备份全部数据库。
	#echo "Mysql: Please Ender Mysql-Slave All DB To Bak And Use Character ',' To Split Like 'db_a,db_b' In Network"
	#read -e DBS

	sed -i "s@^server-id = 1@server-id = $LOCAL_ID@g" /etc/my.cnf
	sed -i "s@^innodb_thread_concurrency =.*@innodb_thread_concurrency = 0@g" /etc/my.cnf

	sed -i "/\[mysqld\]/a skip-slave-start" /etc/my.cnf
	sed -i "/\[mysqld\]/a replicate-ignore-db = mysql" /etc/my.cnf
	#表示只备份
	#sed -i "/\[mysqld\]/a replicate-do-db=$DBS" /etc/my.cnf
	sed -i "/\[mysqld\]/a #Defind By Meyer 2016.12.16" /etc/my.cnf

	service mysql restart
	echo "Config Mysql-Slave Over。"
	echo "------------------------------------------"
	echo "Start Set And Test To Login Mysql-Master"    
    input_if_empty "TMP_SET_DB_SLAVER_PASSWORD" "Mysql: Please ender ${red}mysql localhost password of root${reset}"
	
	#在主服务器新建一个用户赋予“REPLICATION SLAVE”的权限。
	mysql -uroot -p$TMP_SET_DB_SLAVER_PASSWORD -e"
	stop slave;
	change master to master_host='$TMP_SET_DB_SLAVER_MASTER', master_user='backup', master_password='backup#1475963&m';
	start slave;
	show slave status\G;
	FLUSH PRIVILEGES;
	select user,host,password from mysql.user;
	exit"
	echo "Set And Test To Login Mysql-Master Over。"
	echo "------------------------------------------"
	echo "If U See Some Problems Please Visit 'https://yq.aliyun.com/articles/27792' To Look Some Questions"
	echo "------------------------------------------"
	echo "Set All Done"

	return $?
}
    
TMP_SETUP_MYSQL_PWD="123456"
set_environment
exec_if_choice "CHOICE_MYSQL" "Please choice which mysql version you want to setup" "...,Mysql,MariaDB,Set,Exit" "$TMP_SPLITER" "check_setup_"
