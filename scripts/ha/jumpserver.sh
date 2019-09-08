#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

local TMP_PYENV3_ENVIRONMENT=$SETUP_DIR/pyenv3/bin/activate
function set_env()
{
    # 需要提前安装Python
    cd $WORK_PATH
    source scripts/lang/python.sh
    #source scripts/softs/redis.sh
    #source scripts/softs/mysql.sh
    yum -y install xz automake sqlite-devel gcc gcc-devel zlib-devel openssl-devel epel-release python-devel --skip-broken
    yum -y install pysqlite3 mariadb-devel

    setenforce 0
    sed -i "s/enforcing/disabled/g" `grep enforcing -rl /etc/selinux/config`

    # 修改字符集,否则可能报 input/output error的问题,因为日志里打印了中文
    localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8
    export LC_ALL=zh_CN.UTF-8
    echo 'LANG="zh_CN.UTF-8"' > /etc/locale.conf
    echo 'LANG=zh_CN.UTF-8' > /etc/sysconfig/i18n

    # 安装 Python 库依赖
    source $TMP_PYENV3_ENVIRONMENT
    echo "----------------------------"
    echo "Current python version is： "
    python --version
    echo "----------------------------"

	return $?
}

function setup_jumpserver()
{
    # 转入主分支，并调整虚拟环境
    git checkout master

    # 生成数据库表结构和初始化数据
    local TMP_SETUP_DBADDRESS="127.0.0.1"
    local TMP_SETUP_DBUNAME="root"
    local TMP_SETUP_DBPWD="123456"
    local TMP_SETUP_JPS_DBNAME="jumpserver"
    local TMP_SETUP_JPS_DBUNAME="jumpserver"
    local TMP_SETUP_JPS_DBPWD="jps#local&m+"
    input_if_empty "TMP_SETUP_DBADDRESS" "JumpServer.Mysql: Please ender ${red}mysql host address${reset}"
	input_if_empty "TMP_SETUP_DBUNAME" "JumpServer.Mysql: Please ender ${red}mysql user name${reset} of '$TMP_SETUP_DBADDRESS'"
	input_if_empty "TMP_SETUP_DBPWD" "JumpServer.Mysql: Please ender ${red}mysql password${reset} of $TMP_SETUP_DBUNAME@$TMP_SETUP_DBADDRESS"
	input_if_empty "TMP_SETUP_JPS_DBNAME" "JumpServer.Mysql: Please ender ${red}mysql database name${reset} of jumpserver($TMP_SETUP_DBADDRESS)"
    
    mysql -h $TMP_SETUP_DBADDRESS -u$TMP_SETUP_DBUNAME -p"$TMP_SETUP_DBPWD" -e"
    CREATE DATABASE $TMP_SETUP_JPS_DBNAME DEFAULT CHARACTER SET UTF8 COLLATE UTF8_GENERAL_CI;
	GRANT ALL PRIVILEGES ON jumpserver.* to 'jumpserver'@'%' identified by '$TMP_SETUP_JPS_DBPWD';
	GRANT ALL PRIVILEGES ON jumpserver.* to 'jumpserver'@'localhost' identified by '$TMP_SETUP_JPS_DBPWD';
    FLUSH PRIVILEGES;
    exit"

    # 修改 Jumpserver 配置文件
    mv config_example.py config.py
    sed -i "s@# BOOTSTRAP_TOKEN = .*@BOOTSTRAP_TOKEN = '$TMP_JPS_TOKEN'@g" config.py
    sed -i "s@DB_ENGINE = 'sqlite3'@#DB_ENGINE = 'sqlite3'@g" config.py
    sed -i "s@DB_NAME = os@#DB_NAME = os@g" config.py

    sed -i "s@# DB_ENGINE = 'mysql'@DB_ENGINE = 'mysql'@g" config.py
    sed -i "s@# DB_HOST =.*@DB_HOST = '$TMP_SETUP_DBADDRESS'@g" config.py
    sed -i "s@# DB_USER =.*@DB_USER = '$TMP_SETUP_JPS_DBUNAME'@g" config.py
    sed -i "s@# DB_PORT@DB_PORT@g" config.py
    sed -i "s@# DB_PASSWORD =.*@DB_PASSWORD = '$TMP_SETUP_JPS_DBPWD'@g" config.py
    sed -i "s@# DB_NAME =.*@DB_NAME = '$TMP_SETUP_JPS_DBNAME'@g" config.py

    local TMP_CMD_LINE = `awk '/cmd = / {print NR}' jms | awk 'NR==1{print}'`
    sed -i "$((TMP_CMD_LINE+1))a '--timeout', '60'," jms

    redis-cli config set stop-writes-on-bgsave-error no
    
    cd ..
    mkdir -pv $DATA_DIR/jumpserver
    mv jumpserver $PY_DIR/
    
    local TMP_JPS_DIR=$PY_DIR/jumpserver

    # 进入 jumpserver 目录时将自动载入 python 虚拟环境
    echo "source $TMP_PYENV3_ENVIRONMENT" > $TMP_JPS_DIR/.env
    
    cd $TMP_JPS_DIR

    #安装依赖 RPM 包
    yum -y install $(cat requirements/rpm_requirements.txt) --skip-broken

    pip install --upgrade pip setuptools
    pip install django
    pip install -r requirements/requirements.txt

    #生成数据库表结构和初始化数据
    sed -i "s@pysqlite2@from pysqlite3@g" $SETUP_DIR/pyenv3/lib/python3.6/site-packages/django/db/backends/sqlite3/base.py

    cd utils
    source make_migrations.sh
    cd ..
    
    ./jms start all -d

    echo_startup_config "jumpserver" "$TMP_JPS_DIR" "./jms start all" "" "10" "$TMP_PYENV3_ENVIRONMENT"

	return $?
}

function setup_coco()
{
    git checkout master

    mkdir -pv /tmp/uploads
    
    cd ..
    mv coco $PY_DIR/
    
    local TMP_COCO_DIR=$PY_DIR/coco

    # 进入 jumpserver 目录时将自动载入 python 虚拟环境
    echo "source $TMP_PYENV3_ENVIRONMENT" > $TMP_COCO_DIR/.env

    cd $TMP_COCO_DIR

    local TMP_REQUIREMENTS_LIST=`cat requirements/rpm_requirements.txt`
    yum -y install $TMP_REQUIREMENTS_LIST --skip-broken
    
    source $TMP_PYENV3_ENVIRONMENT
    pip install -r requirements/requirements.txt -i https://pypi.python.org/simple

    mv conf_example.py conf.py
    
    sed -i "s@/tmp@/tmp/uploads@g" coco/sftp.py
    sed -i "s@# NAME = .*@NAME = 'coco'@g" conf.py
    sed -i "s@# CORE_HOST = .*@CORE_HOST = 'http://127.0.0.1:8080'@g" conf.py

    sed -i "s@# BOOTSTRAP_TOKEN = .*@BOOTSTRAP_TOKEN = '$TMP_JPS_TOKEN'@g" conf.py
    sed -i "s@# LOG_LEVEL = .*@LOG_LEVEL = 'ERROR'@g" conf.py
    
    ./cocod start -d

    echo_startup_config "coco" "$TMP_COCO_DIR" "./cocod start" "" "100" "$TMP_PYENV3_ENVIRONMENT"

    echo "Please entry 'http://localhost:8080/terminal/terminal/' to accept regist request。"

	return $?
}

function setup_luna()
{
    cd ..
    mv luna $HTML_DIR/

    local TMP_NGX_APP_PORT=""
	rand_val "TMP_NGX_APP_PORT" 1024 2048
	cp_nginx_starter "luna" "$HTML_DIR/luna" "$TMP_NGX_APP_PORT"

	cat >$NGINX_DIR/luna_$TMP_NGX_APP_PORT/conf/vhosts/luna.conf<<EOF
server {
    #代理端口,以后将通过此端口进行访问,不再通过8080端口
    listen $TMP_NGX_APP_PORT;  

    # 修改成你的域名或者注释掉
    # server_name demo.jumpserver.org; 

    #编码
    charset   utf-8;

    #默认访问类型
    default_type text/html;

    #域名可以有多个，用空格隔开
    server_name 127.0.0.1;

    #开启目录浏览功能
    #autoindex on;

    #文件大小从KB开始显示
    autoindex_exact_size off;

    #显示文件修改时间为服务器本地时间
    autoindex_localtime on;

    #录像及文件上传大小限制
    client_max_body_size 100m;  

    #定义本虚拟主机的访问日志
    access_log logs/luna_access.log combined buffer=1k;
    error_log logs/luna_access.log;

    location /luna/ {
        try_files $uri $uri/ =404;
        alias $HTML_DIR/luna/;  # luna 路径,如果修改安装目录,此处需要修改
    }

    location /media/ {
        add_header Content-Encoding gzip;
        root $DATA_DIR/jumpserver/;  # 录像位置,如果修改安装目录,此处需要修改
    }

    #location /static/ {
    #    root $DATA_DIR/jumpserver/;  # 静态资源,如果修改安装目录,此处需要修改
    #}

    location /socket.io/ {
        proxy_pass       http://localhost:5000/socket.io/;  # 如果coco安装在别的服务器,请填写它的ip
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        access_log off;
    }

    location /coco/ {
        proxy_pass       http://localhost:5000/coco/;  # 如果coco安装在别的服务器,请填写它的ip
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        access_log off;
    }

    location /guacamole/ {
        proxy_pass       http://localhost:8081/;  # 如果guacamole安装在别的服务器,请填写它的ip
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        access_log off;
    }

    location / {
        proxy_pass http://localhost:8080;  # 如果jumpserver安装在别的服务器,请填写它的ip
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
    echo "The nginx conf output at '$NGINX_DIR/luna_$TMP_NGX_APP_PORT/conf/vhosts/luna.conf'"

    cd $NGINX_DIR/luna_$TMP_NGX_APP_PORT && bash start.sh master

	return $?
}

function down_jumpserver()
{
    set_env
    #http://docs.jumpserver.org/zh/latest/step_by_step.html
    setup_soft_git "JumpServer" "https://github.com/jumpserver/jumpserver" "setup_jumpserver"
    setup_soft_git "Coco" "https://github.com/jumpserver/coco" "setup_coco"
    setup_soft_wget "Luna" "https://github.com/jumpserver/luna/releases/download/1.5.0/luna.tar.gz" "setup_luna"

	return $?
}

local TMP_JPS_TOKEN=`cat /proc/sys/kernel/random/uuid`
setup_soft_basic "JumpServer" "down_jumpserver"
