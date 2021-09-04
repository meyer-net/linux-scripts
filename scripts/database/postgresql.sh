#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 安装标题：PostgresQL
# 软件名称：postgresql
# 软件端口：5432
# 软件大写分组与简称：PSQL
# 软件安装名称：postgresql
# 软件授权用户名称&组：postgres/postgres
#------------------------------------------------
local TMP_PSQL_SETUP_PORT=15432
local TMP_PSQL_SETUP_STP_VERS=11

##########################################################################################################

# 1-配置环境
function set_env_postgresql()
{
    cd ${__DIR}

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_postgresql()
{
	local TMP_PSQL_SETUP_DIR=${1}

	## 源模式
    while_wget "--content-disposition https://download.postgresql.org/pub/repos/yum/reporpms/EL-${OS_VERS}-x86_64/pgdg-redhat-repo-latest.noarch.rpm" "rpm -ivh pgdg-redhat-repo-latest.noarch.rpm"

	input_if_empty "TMP_PSQL_SETUP_STP_VERS" "PostgresQL: Please ender the ${red}version 10/11/12/13${reset} for needs"
    
	soft_yum_check_setup "postgresql${TMP_PSQL_SETUP_STP_VERS}"
	soft_yum_check_setup "postgresql${TMP_PSQL_SETUP_STP_VERS}-server"

	# 创建日志软链
	local TMP_PSQL_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/postgresql
	local TMP_PSQL_SETUP_LNK_DATA_DIR=${DATA_DIR}/postgresql
	local TMP_PSQL_SETUP_LOGS_DIR=${TMP_PSQL_SETUP_DIR}/logs
	local TMP_PSQL_SETUP_DATA_DIR=${TMP_PSQL_SETUP_DIR}/data

	# 先清理文件，再创建文件
	path_not_exists_create ${TMP_PSQL_SETUP_DIR}
	rm -rf ${TMP_PSQL_SETUP_LOGS_DIR}
	rm -rf ${TMP_PSQL_SETUP_DATA_DIR}
	mkdir -pv ${TMP_PSQL_SETUP_LNK_LOGS_DIR}
	mkdir -pv ${TMP_PSQL_SETUP_LNK_DATA_DIR}
	
	ln -sf ${TMP_PSQL_SETUP_LNK_LOGS_DIR} ${TMP_PSQL_SETUP_LOGS_DIR}
	ln -sf ${TMP_PSQL_SETUP_LNK_DATA_DIR} ${TMP_PSQL_SETUP_DATA_DIR}

	# 授权权限，否则无法写入
	create_user_if_not_exists postgres postgres
	chgrp -R postgres ${TMP_PSQL_SETUP_LNK_LOGS_DIR}
	chgrp -R postgres ${TMP_PSQL_SETUP_LNK_DATA_DIR}
	chown -R postgres:postgres ${TMP_PSQL_SETUP_LNK_LOGS_DIR}
	chown -R postgres:postgres ${TMP_PSQL_SETUP_LNK_DATA_DIR}

    # 初始配置
    su - postgres -c "/usr/pgsql-${TMP_PSQL_SETUP_STP_VERS}/bin/initdb -D ${TMP_PSQL_SETUP_LNK_DATA_DIR}"    
    
	rm -rf pgdg-redhat-repo-latest.noarch.rpm

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_postgresql()
{
	local TMP_PSQL_SETUP_DIR=${1}

	cd ${TMP_PSQL_SETUP_DIR}
	
    # PSQL 的数据目录与配置目录是一致的
	local TMP_PSQL_SETUP_LNK_DATA_DIR=${DATA_DIR}/postgresql
	local TMP_PSQL_SETUP_LNK_ETC_DIR=${ATT_DIR}/postgresql
	local TMP_PSQL_SETUP_ETC_DIR=${TMP_PSQL_SETUP_DIR}/etc

	# ①-N：不存在配置文件：
	rm -rf ${TMP_PSQL_SETUP_ETC_DIR}
	# mkdir -pv ${TMP_PSQL_SETUP_LNK_ETC_DIR}
    ln -sf ${TMP_PSQL_SETUP_LNK_DATA_DIR} ${TMP_PSQL_SETUP_LNK_ETC_DIR}
	chgrp -R postgres ${TMP_PSQL_SETUP_LNK_ETC_DIR}
	chown -R postgres:postgres ${TMP_PSQL_SETUP_LNK_ETC_DIR}

	# 替换原路径链接
	# ln -sf ${TMP_PSQL_SETUP_LNK_ETC_DIR} ${TMP_PSQL_SETUP_ETC_DIR}
	ln -sf ${TMP_PSQL_SETUP_LNK_DATA_DIR} ${TMP_PSQL_SETUP_ETC_DIR}
	
    # 开始配置
	local TMP_PSQL_SETUP_LOGS_DIR=${TMP_PSQL_SETUP_DIR}/logs
	local TMP_PSQL_SETUP_DATA_DIR=${TMP_PSQL_SETUP_DIR}/data

    # -- 开启外网访问
    sed -i "s@^#listen_addresses =.*@listen_addresses = '*'@g" etc/postgresql.conf

    # -- 修改端口
    sed -i "s@^#port = 5432@port = ${TMP_PSQL_SETUP_PORT}@g" etc/postgresql.conf

    # -- 修改日志目录
    sed -i "s@^log_directory =.*@log_directory = '${TMP_PSQL_SETUP_LOGS_DIR}'@g" etc/postgresql.conf

    # -- 修改数据库目录
    sed -i "s@^#data_directory =.*@data_directory = '${TMP_PSQL_SETUP_DATA_DIR}'@g" etc/postgresql.conf

    # -- 修改启动环境
    sed -i "s@^Environment=PGDATA=.*@Environment=PGDATA=${TMP_PSQL_SETUP_DATA_DIR}@g" /usr/lib/systemd/system/postgresql-${TMP_PSQL_SETUP_STP_VERS}.service

    # -- 修改认证
    echo "host    all             all              0.0.0.0/0              trust" >> etc/pg_hba.conf

	return $?
}

function conf_postgresql_master()
{
	cd ${SETUP_DIR}/postgresql

    echo "------------------------------"
	echo "Start Config PostgresQL-Master"
    echo "------------------------------"
    
    #获取从库信息
    local TMP_PSQL_SET_DB_MASTER_SLAVE=${LOCAL_HOST}
    input_if_empty "TMP_PSQL_SET_DB_MASTER_SLAVE" "PostgresQL: Please ender ${red}postgresql slave address in internal${reset}"

    #修改最大同步用户
    sed -i "s@^#max_wal_senders =.*@max_wal_senders = 5@g" etc/postgresql.conf
    
    #
    sed -i "s@^#wal_level@wal_level@g" etc/postgresql.conf
    
    #
    sed -i "s@^#archive_mode =.*@archive_mode = on@g" etc/postgresql.conf
    
    #
    sed -i "s@^#archive_command =.*@archive_command = 'cd ./'@g" etc/postgresql.conf
    
    #
    sed -i "s@^#hot_standby@hot_standby@g" etc/postgresql.conf
    
    #
    sed -i "s@^#wal_keep_segments =.*@wal_keep_segments = 64@g" etc/postgresql.conf
    
    #
    sed -i "s@^#full_page_writes@full_page_writes@g" etc/postgresql.conf
    
    #
    sed -i "s@^#wal_log_hints =.*@wal_log_hints = on@g" etc/postgresql.conf

    #修改认证
    echo "host    replication     rep_user        ${TMP_PSQL_SET_DB_MASTER_SLAVE}/32        md5" >> etc/pg_hba.conf
    
    #创建同步用户
psql -U postgres -h localhost -p ${TMP_PSQL_SETUP_PORT} -d postgres << EOF
    CREATE USER rep_user replication LOGIN CONNECTION LIMIT 3 ENCRYPTED PASSWORD 'reppsql%1475963&m';
EOF
    
    #复制样例
    cp /usr/pgsql-${TMP_PSQL_SETUP_STP_VERS}/share/recovery.conf.sample etc/recovery.done
    
    #
    sed -i "s@^#recovery_target_timeline =.*@recovery_target_timeline = 'latest'@g" etc/recovery.done
    
    #
    sed -i "s@^#standby_mode =.*@standby_mode = on@g" etc/recovery.done
    
    #
    sed -i "s@^#primary_conninfo =.*@primary_conninfo = 'host=${TMP_PSQL_SET_DB_MASTER_SLAVE} port=${TMP_PSQL_SETUP_PORT} user=rep_user password=reppsql%1475963\&m'@g" etc/recovery.done
    
    #
    sed -i "s@^#trigger_file =.*@trigger_file = 'etc/trigger_file'@g" etc/recovery.done

    #输出pgpass
    echo "${TMP_PSQL_SET_DB_MASTER_SLAVE}:${TMP_PSQL_SETUP_PORT}:replication:rep_user:reppsql%1475963&m" > ~/.pgpass
    chmod 0600 ~/.pgpass

    systemctl restart postgresql-${TMP_PSQL_SETUP_STP_VERS}.service
	echo "Config PostgresQL-Master Over。"
	echo "-------------------------------"
	echo "Set All Done"

	return $?
}

function conf_postgresql_slave()
{
	cd ${SETUP_DIR}/postgresql
    
	local TMP_PSQL_SETUP_LNK_DATA_DIR=${DATA_DIR}/postgresql
    echo "-----------------------------"
	echo "Start Config PostgresQL-Slave"
    echo "-----------------------------"
    
    #获取从库信息
    local{TMP_PSQL_SET_DB_SLAVE_MASTER=${LOCAL_HOST}
    input_if_empty "TMP_PSQL_SET_DB_SLAVE_MASTER" "PostgresQL: Please ender ${red}postgresql master address in internal${reset}"

    #复制样例
    cp /usr/pgsql-${TMP_PSQL_SETUP_STP_VERS}/share/recovery.conf.sample etc/recovery.conf
    
    #
    sed -i "s@^#recovery_target_timeline =.*@recovery_target_timeline = 'latest'@g" etc/recovery.conf
    
    #
    sed -i "s@^#standby_mode =.*@standby_mode = on@g" etc/recovery.conf
    
    #
    sed -i "s@^#primary_conninfo =.*@primary_conninfo = 'host=${TMP_PSQL_SET_DB_SLAVE_MASTER} port=${TMP_PSQL_SETUP_PORT} user=rep_user password=reppsql%1475963\&m'@g" etc/recovery.conf
    
    #
    sed -i "s@^#trigger_file =.*@trigger_file = 'etc/trigger_file'@g" etc/recovery.conf
    
    #输出pgpass
    echo "${TMP_PSQL_SET_DB_SLAVE_MASTER}:${TMP_PSQL_SETUP_PORT}:replication:rep_user:reppsql%1475963&m" > ~/.pgpass
    chmod 0600 ~/.pgpass

    #修改认证
    echo "host    replication     rep_user        ${TMP_PSQL_SET_DB_SLAVE_MASTER}/32       md5" >> etc/pg_hba.conf

    #创建备库
    pg_basebackup -D ${TMP_PSQL_SETUP_LNK_DATA_DIR}_replicate -Fp -Xs -v -P -h ${TMP_PSQL_SET_DB_SLAVE_MASTER} -p ${TMP_PSQL_SETUP_PORT} -U rep_user
    rsync -av ${TMP_PSQL_SETUP_LNK_DATA_DIR}_replicate/* ${TMP_PSQL_SETUP_LNK_DATA_DIR} --exclude '*.conf *.done *.pots'

    #重新授权
    chown -R postgres:postgres ${TMP_PSQL_SETUP_LNK_DATA_DIR}

    rm -rf ${TMP_PSQL_SETUP_LNK_DATA_DIR}_replicate

    systemctl restart postgresql-${TMP_PSQL_SETUP_STP_VERS}.service
	echo "Config PostgresQL-Slave Over。"
	echo "------------------------------"
	echo "Set All Done"

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_postgresql()
{
	local TMP_PSQL_SETUP_DIR=${1}

	cd ${TMP_PSQL_SETUP_DIR}
	
	# 验证安装
    psql --version  # lsof -i:${TMP_PSQL_SETUP_PORT}

	# 当前启动命令
    sudo systemctl daemon-reload
    sudo systemctl enable postgresql-${TMP_PSQL_SETUP_STP_VERS}.service
    sudo systemctl start postgresql-${TMP_PSQL_SETUP_STP_VERS}.service
	# nohup bin/postgresql > logs/boot.log 2>&1 &

    # 等待启动
    echo "Starting postgresql，Waiting for a moment"
    echo "-----------------------------------------"
    sleep 5
    
    #初始化密码
    echo "PostgresQL: Please ender your system inited password of user 'postgres'"
    echo "-----------------------------------------------------------------------"
psql -U postgres -h localhost -p ${TMP_PSQL_SETUP_PORT} -d postgres << EOF
    \password postgres;
EOF

	sudo systemctl status postgresql-${TMP_PSQL_SETUP_STP_VERS}.service
    sudo chkconfig postgresql-${TMP_PSQL_SETUP_STP_VERS} on
    echo "-----------------------------------------"

	# 授权iptables端口访问
	echo_soft_port ${TMP_PSQL_SETUP_PORT}

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_postgresql()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_postgresql()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_postgresql()
{
	local TMP_PSQL_SETUP_DIR=${SETUP_DIR}/postgresql
    
	set_env_postgresql "${TMP_PSQL_SETUP_DIR}"

	setup_postgresql "${TMP_PSQL_SETUP_DIR}"

	conf_postgresql "${TMP_PSQL_SETUP_DIR}"

    # down_plugin_postgresql "${TMP_PSQL_SETUP_DIR}"

	boot_postgresql "${TMP_PSQL_SETUP_DIR}"

	return $?
}

##########################################################################################################

# x1-下载软件
function check_setup_postgresql()
{
	local TMP_PSQL_SETUP_LNK_DATA_DIR=${DATA_DIR}/postgresql
    path_not_exists_action "${TMP_PSQL_SETUP_LNK_DATA_DIR}" "exec_step_postgresql" "PostgresQL was installed"

	return $?
}

function print_postgresql()
{
    setup_soft_basic "PostgresQL" "check_setup_postgresql"

	return $?
}

function print_conf()
{
    TMP_PSQL_SETUP_STP_VERS=`psql --version | awk -F' ' '{print $NF}' | awk -F'.' '{print $NR}'`
    if [ -z "${TMP_PSQL_SETUP_STP_VERS}" ]; then
        echo "PostgresQL：Could'nt find postgresql local，please sure u setup it?"
        return $?
    fi

    exec_if_choice "TMP_SETUP_CHOICE_POSTGRESQL_CONF" "Please choice which postgresql mode you want to set" "...,Master,Slave,Exit" "${TMP_SPLITER}" "conf_postgresql_"

	return $?
}

##########################################################################################################

#安装主体

exec_if_choice "TMP_SETUP_CHOICE_POSTGRESQL" "Please choice which postgresql action you want to done" "...,PostgresQL,Conf,Exit" "${TMP_SPLITER}" "print_"