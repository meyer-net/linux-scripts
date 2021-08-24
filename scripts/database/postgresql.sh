#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
local TMP_PSQL_SETUP_PORT=15432

#路径配置
local POSTGRESQL_LOGS_DIR=${LOGS_DIR}/postgresql
local POSTGRESQL_DATA_DIR=${DATA_DIR}/postgresql
local POSTGRESQL_CONF_PATH=${POSTGRESQL_DATA_DIR}/postgresql.conf
local POSTGRESQL_STP_VER=11

function set_env_postgresql()
{
	return $?
}

function switch_setup_postgresql_version()
{
	input_if_empty "POSTGRESQL_STP_VER" "PostgreSql: Please ender the ${red}version 10/11/12/13${reset} for needs"

	return $?
}

function check_setup_postgresql()
{
    path_not_exists_action "${DATA_DIR}/postgresql" "setup_postgresql" "PostgreSql was installed"

	return $?
}

function setup_postgresql()
{
    switch_setup_postgresql_version
    
    #安装postgresql rpm包
    sudo yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
    sudo yum -y install postgresql${POSTGRESQL_STP_VER}
    sudo yum -y install postgresql${POSTGRESQL_STP_VER}-server

    psql --version

    set_postgresql

	return $?
}

function set_postgresql()
{    
    #初始化db
    mkdir -pv ${POSTGRESQL_LOGS_DIR}
    create_user_if_not_exists postgres postgres
    chown -R postgres:postgres ${POSTGRESQL_LOGS_DIR}

    mkdir -pv ${POSTGRESQL_DATA_DIR}
    chown -R postgres:postgres ${POSTGRESQL_DATA_DIR}
    su - postgres -c "/usr/pgsql-${POSTGRESQL_STP_VER}/bin/initdb -D ${POSTGRESQL_DATA_DIR}"

    # 停止服务
    systemctl stop postgresql-${POSTGRESQL_STP_VER}.service

    # 开启外网访问
    sed -i "s@^#listen_addresses =.*@listen_addresses = '*'@g" ${POSTGRESQL_CONF_PATH}

    # 修改端口
    sed -i "s@^#port = 5432 @port = ${TMP_PSQL_SETUP_PORT}@g" ${POSTGRESQL_CONF_PATH}

    # 修改日志目录
    sed -i "s@^log_directory =.*@log_directory = '${POSTGRESQL_LOGS_DIR}'@g" ${POSTGRESQL_CONF_PATH}

    # 修改数据库目录
    sed -i "s@^#data_directory =.*@data_directory = '${POSTGRESQL_DATA_DIR}'@g" ${POSTGRESQL_CONF_PATH}

    # 修改启动环境
    sed -i "s@^Environment=PGDATA=.*@Environment=PGDATA=${POSTGRESQL_DATA_DIR}@g" /usr/lib/systemd/system/postgresql-${POSTGRESQL_STP_VER}.service
    systemctl daemon-reload

    # 修改认证
    echo "host    all             all              0.0.0.0/0              trust" >> ${POSTGRESQL_DATA_DIR}/pg_hba.conf

    #唤醒服务
    systemctl start postgresql-${POSTGRESQL_STP_VER}.service
    systemctl disable postgresql-${POSTGRESQL_STP_VER}.service
    systemctl enable postgresql-${POSTGRESQL_STP_VER}.service
    systemctl status postgresql-${POSTGRESQL_STP_VER}.service
    chkconfig postgresql-${POSTGRESQL_STP_VER} on

    #初始化密码
    echo "PostgreSql: Please Ender Your System Inited Password Of User 'postgres'"
    echo "--------------------------------------------"
psql -U postgres -h localhost -d postgres << EOF
    \password postgres;
EOF
    
    echo_soft_port ${TMP_PSQL_SETUP_PORT}
}

function check_setup_set()
{
    switch_setup_postgresql_version
    exec_if_choice "CHOICE_POSTGRES_SET" "Please choice which postgresql mode you want to set" "...,Master,Slave,Exit" "$TMP_SPLITER" "set_db_"
	return $?
}

function set_db_master()
{
	echo "Start Config PostgreSql-Master"
    
    #获取从库信息
    local TMP_SET_DB_MASTER_SLAVE=$LOCAL_HOST
    input_if_empty "TMP_SET_DB_MASTER_SLAVE" "PostgreSql: Please ender ${red}postgresql slave address in internal${reset}"

    #修改最大同步用户
    sed -i "s@^#max_wal_senders =.*@max_wal_senders = 5@g" ${POSTGRESQL_CONF_PATH}
    
    #
    sed -i "s@^#wal_level@wal_level@g" ${POSTGRESQL_CONF_PATH}
    
    #
    sed -i "s@^#archive_mode =.*@archive_mode = on@g" ${POSTGRESQL_CONF_PATH}
    
    #
    sed -i "s@^#archive_command =.*@archive_command = 'cd ./'@g" ${POSTGRESQL_CONF_PATH}
    
    #
    sed -i "s@^#hot_standby@hot_standby@g" ${POSTGRESQL_CONF_PATH}
    
    #
    sed -i "s@^#wal_keep_segments =.*@wal_keep_segments = 64@g" ${POSTGRESQL_CONF_PATH}
    
    #
    sed -i "s@^#full_page_writes@full_page_writes@g" ${POSTGRESQL_CONF_PATH}
    
    #
    sed -i "s@^#wal_log_hints =.*@wal_log_hints = on@g" ${POSTGRESQL_CONF_PATH}

    #修改认证
    echo "host    replication     rep_user        $TMP_SET_DB_MASTER_SLAVE/32        md5" >> ${POSTGRESQL_DATA_DIR}/pg_hba.conf
    
    #创建同步用户
psql -U postgres -h localhost -d postgres << EOF
    CREATE USER rep_user replication LOGIN CONNECTION LIMIT 3 ENCRYPTED PASSWORD 'reppsql%1475963&m';
EOF
    
    #复制样例
    cp /usr/pgsql-${POSTGRESQL_STP_VER}/share/recovery.conf.sample ${POSTGRESQL_DATA_DIR}/recovery.done
    
    #
    sed -i "s@^#recovery_target_timeline =.*@recovery_target_timeline = 'latest'@g" ${POSTGRESQL_DATA_DIR}/recovery.done
    
    #
    sed -i "s@^#standby_mode =.*@standby_mode = on@g" ${POSTGRESQL_DATA_DIR}/recovery.done
    
    #
    sed -i "s@^#primary_conninfo =.*@primary_conninfo = 'host=$TMP_SET_DB_MASTER_SLAVE port=${TMP_PSQL_SETUP_PORT} user=rep_user password=reppsql%1475963\&m'@g" ${POSTGRESQL_DATA_DIR}/recovery.done
    
    #
    sed -i "s@^#trigger_file =.*@trigger_file = '${POSTGRESQL_DATA_DIR}/trigger_file'@g" ${POSTGRESQL_DATA_DIR}/recovery.done

    #输出pgpass
    echo "$TMP_SET_DB_MASTER_SLAVE:${TMP_PSQL_SETUP_PORT}:replication:rep_user:reppsql%1475963&m" > ~/.pgpass
    chmod 0600 ~/.pgpass

    systemctl restart postgresql-${POSTGRESQL_STP_VER}.service
	echo "Config PostgreSql-Master Over。"
	echo "------------------------------------------"
	echo "Set All Done"

	return $?
}

function set_db_slave()
{
	echo "Start Config PostgreSql-Slave"
    
    #获取从库信息
    local TMP_SET_DB_SLAVE_MASTER=$LOCAL_HOST
    input_if_empty "TMP_SET_DB_SLAVE_MASTER" "PostgreSql: Please ender ${red}postgresql master address in internal${reset}"

    #复制样例
    cp /usr/pgsql-${POSTGRESQL_STP_VER}/share/recovery.conf.sample ${POSTGRESQL_DATA_DIR}/recovery.conf
    
    #
    sed -i "s@^#recovery_target_timeline =.*@recovery_target_timeline = 'latest'@g" ${POSTGRESQL_DATA_DIR}/recovery.conf
    
    #
    sed -i "s@^#standby_mode =.*@standby_mode = on@g" ${POSTGRESQL_DATA_DIR}/recovery.conf
    
    #
    sed -i "s@^#primary_conninfo =.*@primary_conninfo = 'host=$TMP_SET_DB_SLAVE_MASTER port=${TMP_PSQL_SETUP_PORT} user=rep_user password=reppsql%1475963\&m'@g" ${POSTGRESQL_DATA_DIR}/recovery.conf
    
    #
    sed -i "s@^#trigger_file =.*@trigger_file = '${POSTGRESQL_DATA_DIR}/trigger_file'@g" ${POSTGRESQL_DATA_DIR}/recovery.conf
    
    #输出pgpass
    echo "$TMP_SET_DB_SLAVE_MASTER:${TMP_PSQL_SETUP_PORT}:replication:rep_user:reppsql%1475963&m" > ~/.pgpass
    chmod 0600 ~/.pgpass

    #修改认证
    echo "host    replication     rep_user        $TMP_SET_DB_SLAVE_MASTER/32       md5" >> ${POSTGRESQL_DATA_DIR}/pg_hba.conf

    #创建备库
    pg_basebackup -D ${POSTGRESQL_DATA_DIR}_replicate -Fp -Xs -v -P -h $TMP_SET_DB_SLAVE_MASTER -p ${TMP_PSQL_SETUP_PORT} -U rep_user
    rsync -av ${POSTGRESQL_DATA_DIR}_replicate/* ${POSTGRESQL_DATA_DIR} --exclude '*.conf *.done *.pots'

    #重新授权
    chown -R postgres:postgres ${POSTGRESQL_DATA_DIR}

    rm -rf ${POSTGRESQL_DATA_DIR}_replicate

    systemctl restart postgresql-${POSTGRESQL_STP_VER}.service
	echo "Config PostgreSql-Slave Over。"
	echo "------------------------------------------"
	echo "Set All Done"

	return $?
}

set_env_postgresql
exec_if_choice "CHOICE_POSTGRES" "Please choice which postgresql action you want to done" "...,PostgreSql,Set,Exit" "$TMP_SPLITER" "check_setup_"