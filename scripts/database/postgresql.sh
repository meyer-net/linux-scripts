#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

#路径配置
POSTGRESQL_LOGS_DIR=$LOGS_DIR/postgresql
POSTGRESQL_DATA_DIR=$DATA_DIR/postgresql
POSTGRESQL_CONF_PATH=$POSTGRESQL_DATA_DIR/postgresql.conf
function set_environment()
{
	return $?
}

function check_setup_postgresql()
{
    path_not_exits_action "$DATA_DIR/postgresql" "setup_postgresql" "PostgreSql was installed"

	return $?
}

function setup_postgresql()
{
    #安装postgresql rpm包
    sudo yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
    sudo yum -y install postgresql13
    sudo yum -y install postgresql13-server

    set_postgresql

	return $?
}

function set_postgresql()
{    
    #初始化db
    mkdir -pv $POSTGRESQL_LOGS_DIR
    chown -R postgres:postgres $POSTGRESQL_LOGS_DIR

    mkdir -pv $POSTGRESQL_DATA_DIR
    chown -R postgres:postgres $POSTGRESQL_DATA_DIR
    su - postgres -c "/usr/pgsql-13/bin/initdb -D $POSTGRESQL_DATA_DIR"

    #停止服务
    systemctl stop postgresql-13.service

    #开启外网访问
    sed -i "s@^#listen_addresses =.*@listen_addresses = '*'@g" $POSTGRESQL_CONF_PATH

    #修改日志目录
    sed -i "s@^log_directory =.*@log_directory = '$POSTGRESQL_LOGS_DIR'@g" $POSTGRESQL_CONF_PATH

    #修改数据库目录
    sed -i "s@^#data_directory =.*@data_directory = '$POSTGRESQL_DATA_DIR'@g" $POSTGRESQL_CONF_PATH

    #修改启动环境
    sed -i "s@^Environment=PGDATA=.*@Environment=PGDATA=$POSTGRESQL_DATA_DIR@g" /usr/lib/systemd/system/postgresql-13.service
    systemctl daemon-reload

    #修改认证
    echo "host    all             all              0.0.0.0/0              trust" >> $POSTGRESQL_DATA_DIR/pg_hba.conf

    #唤醒服务
    systemctl start postgresql-13.service
    systemctl disable postgresql-13.service
    systemctl enable postgresql-13.service
    systemctl status postgresql-13.service
    chkconfig postgresql-13 on

    #初始化密码
    echo "PostgreSql: Please Ender Your System Inited Password Of User 'postgres'"
    echo "--------------------------------------------"
psql -U postgres -h localhost -d postgres << EOF
    \password postgres;
EOF
    
    echo_soft_port 5432
}

function check_setup_set()
{
    exec_if_choice "CHOICE_POSTGRES_SET" "Please choice which postgresql mode you want to set" "...,Master,Slave,Exit" "$TMP_SPLITER" "set_db_"
	return $?
}

function set_db_master()
{
	echo "Start Config PostgreSql-Master"
    
    #获取从库信息
    local TMP_SET_DB_MASTER_SLAVER=$LOCAL_HOST
    input_if_empty "TMP_SET_DB_MASTER_SLAVER" "PostgreSql: Please ender ${red}postgresql slaver address in internal${reset}"

    #修改最大同步用户
    sed -i "s@^#max_wal_senders =.*@max_wal_senders = 5@g" $POSTGRESQL_CONF_PATH
    
    #
    sed -i "s@^#wal_level@wal_level@g" $POSTGRESQL_CONF_PATH
    
    #
    sed -i "s@^#archive_mode =.*@archive_mode = on@g" $POSTGRESQL_CONF_PATH
    
    #
    sed -i "s@^#archive_command =.*@archive_command = 'cd ./'@g" $POSTGRESQL_CONF_PATH
    
    #
    sed -i "s@^#hot_standby@hot_standby@g" $POSTGRESQL_CONF_PATH
    
    #
    sed -i "s@^#wal_keep_segments =.*@wal_keep_segments = 64@g" $POSTGRESQL_CONF_PATH
    
    #
    sed -i "s@^#full_page_writes@full_page_writes@g" $POSTGRESQL_CONF_PATH
    
    #
    sed -i "s@^#wal_log_hints =.*@wal_log_hints = on@g" $POSTGRESQL_CONF_PATH

    #修改认证
    echo "host    replication     rep_user        $TMP_SET_DB_MASTER_SLAVER/32        md5" >> $POSTGRESQL_DATA_DIR/pg_hba.conf
    
    #创建同步用户
psql -U postgres -h localhost -d postgres << EOF
    CREATE USER rep_user replication LOGIN CONNECTION LIMIT 3 ENCRYPTED PASSWORD 'reppsql%1475963&m';
EOF
    
    #复制样例
    cp /usr/pgsql-13/share/recovery.conf.sample $POSTGRESQL_DATA_DIR/recovery.done
    
    #
    sed -i "s@^#recovery_target_timeline =.*@recovery_target_timeline = 'latest'@g" $POSTGRESQL_DATA_DIR/recovery.done
    
    #
    sed -i "s@^#standby_mode =.*@standby_mode = on@g" $POSTGRESQL_DATA_DIR/recovery.done
    
    #
    sed -i "s@^#primary_conninfo =.*@primary_conninfo = 'host=$TMP_SET_DB_MASTER_SLAVER port=5432 user=rep_user password=reppsql%1475963\&m'@g" $POSTGRESQL_DATA_DIR/recovery.done
    
    #
    sed -i "s@^#trigger_file =.*@trigger_file = '$POSTGRESQL_DATA_DIR/trigger_file'@g" $POSTGRESQL_DATA_DIR/recovery.done

    #输出pgpass
    echo "$TMP_SET_DB_MASTER_SLAVER:5432:replication:rep_user:reppsql%1475963&m" > ~/.pgpass
    chmod 0600 ~/.pgpass

    systemctl restart postgresql-13.service
	echo "Config PostgreSql-Master Over。"
	echo "------------------------------------------"
	echo "Set All Done"

	return $?
}

function set_db_slave()
{
	echo "Start Config PostgreSql-Slave"
    
    #获取从库信息
    local TMP_SET_DB_SLAVER_MASTER=$LOCAL_HOST
    input_if_empty "TMP_SET_DB_SLAVER_MASTER" "PostgreSql: Please ender ${red}postgresql master address in internal${reset}"

    #复制样例
    cp /usr/pgsql-13/share/recovery.conf.sample $POSTGRESQL_DATA_DIR/recovery.conf
    
    #
    sed -i "s@^#recovery_target_timeline =.*@recovery_target_timeline = 'latest'@g" $POSTGRESQL_DATA_DIR/recovery.conf
    
    #
    sed -i "s@^#standby_mode =.*@standby_mode = on@g" $POSTGRESQL_DATA_DIR/recovery.conf
    
    #
    sed -i "s@^#primary_conninfo =.*@primary_conninfo = 'host=$TMP_SET_DB_SLAVER_MASTER port=5432 user=rep_user password=reppsql%1475963\&m'@g" $POSTGRESQL_DATA_DIR/recovery.conf
    
    #
    sed -i "s@^#trigger_file =.*@trigger_file = '$POSTGRESQL_DATA_DIR/trigger_file'@g" $POSTGRESQL_DATA_DIR/recovery.conf
    
    #输出pgpass
    echo "$TMP_SET_DB_SLAVER_MASTER:5432:replication:rep_user:reppsql%1475963&m" > ~/.pgpass
    chmod 0600 ~/.pgpass

    #修改认证
    echo "host    replication     rep_user        $TMP_SET_DB_SLAVER_MASTER/32       md5" >> $POSTGRESQL_DATA_DIR/pg_hba.conf

    #创建备库
    pg_basebackup -D ${POSTGRESQL_DATA_DIR}_replicate -Fp -Xs -v -P -h $TMP_SET_DB_SLAVER_MASTER -p 5432 -U rep_user
    rsync -av ${POSTGRESQL_DATA_DIR}_replicate/* ${POSTGRESQL_DATA_DIR} --exclude '*.conf *.done *.pots'

    #重新授权
    chown -R postgres:postgres $POSTGRESQL_DATA_DIR

    rm -rf ${POSTGRESQL_DATA_DIR}_replicate

    systemctl restart postgresql-13.service
	echo "Config PostgreSql-Slaver Over。"
	echo "------------------------------------------"
	echo "Set All Done"

	return $?
}

set_environment
exec_if_choice "CHOICE_POSTGRES" "Please choice which postgresql action you want to done" "...,PostgreSql,Set,Exit" "$TMP_SPLITER" "check_setup_"