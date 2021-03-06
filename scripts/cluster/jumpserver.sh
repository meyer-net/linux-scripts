#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

local TMP_PY3_JMS_ENV=$SETUP_DIR/pyenv3.jms
function set_env()
{
    # 需要提前安装Python
    cd ${__DIR}
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

    if [ ! -f "$TMP_PY3_JMS_ENV" ]; then
	    python3 -m venv $TMP_PY3_JMS_ENV
    fi

    # 安装 Python 库依赖
    source $TMP_PY3_JMS_ENV/bin/activate
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
    local TMP_SETUP_JMS_DBNAME="jumpserver"
    local TMP_SETUP_JMS_DBUNAME="jumpserver"

    # 不能用&，否则会被识别成读取前一个值
    local TMP_SETUP_JMS_DBPWD="jms%local!m_"
    input_if_empty "TMP_SETUP_DBADDRESS" "JumpServer.Mysql: Please ender ${red}mysql host address${reset}"
	input_if_empty "TMP_SETUP_DBUNAME" "JumpServer.Mysql: Please ender ${red}mysql user name${reset} of '$TMP_SETUP_DBADDRESS'"
	input_if_empty "TMP_SETUP_DBPWD" "JumpServer.Mysql: Please ender ${red}mysql password${reset} of $TMP_SETUP_DBUNAME@$TMP_SETUP_DBADDRESS"
	input_if_empty "TMP_SETUP_JMS_DBNAME" "JumpServer.Mysql: Please ender ${red}mysql database name${reset} of jumpserver($TMP_SETUP_DBADDRESS)"
    
    local TMP_SETUP_JMS_SCRIPTS="CREATE DATABASE $TMP_SETUP_JMS_DBNAME DEFAULT CHARACTER SET UTF8 COLLATE UTF8_GENERAL_CI;
GRANT ALL PRIVILEGES ON jumpserver.* to 'jumpserver'@'%' identified by '$TMP_SETUP_JMS_DBPWD';
GRANT ALL PRIVILEGES ON jumpserver.* to 'jumpserver'@'localhost' identified by '$TMP_SETUP_JMS_DBPWD';
FLUSH PRIVILEGES;
    "

    if [ "$TMP_SETUP_JMS_DBPWD" == "127.0.0.1" ]; then
        mysql -h $TMP_SETUP_DBADDRESS -u$TMP_SETUP_DBUNAME -p"$TMP_SETUP_DBPWD" -e"
        $TMP_SETUP_JMS_SCRIPTS
        exit"
    else
        echo "JumpServer.Mysql: Please execute ${red}mysql scripts${reset} By Follow"
        echo "$TMP_SETUP_JMS_SCRIPTS"
    fi

    # 修改 Jumpserver 配置文件
    mv config_example.yml config.yml
    
    sed -i "s@SECRET_KEY:.*@SECRET_KEY: $TMP_JMS_SECRET_KEY@g" config.yml
    sed -i "s@BOOTSTRAP_TOKEN:.*@BOOTSTRAP_TOKEN: $TMP_JMS_TOKEN@g" config.yml
    sed -i "s@DB_HOST:.*@DB_HOST: $TMP_SETUP_DBADDRESS@g" config.yml
    sed -i "s@DB_USER:.*@DB_USER: $TMP_SETUP_JMS_DBUNAME@g" config.yml
    sed -i "s@DB_PASSWORD:.*@DB_PASSWORD: '$TMP_SETUP_JMS_DBPWD'@g" config.yml
    sed -i "s@DB_NAME:.*@DB_NAME: $TMP_SETUP_JMS_DBNAME@g" config.yml

    local TMP_CMD_LINE=`awk '/cmd = / {print NR}' jms | awk 'NR==1{print}'`
    sed -i "$((TMP_CMD_LINE+1))a '--timeout', '60'," jms

    # 缓存
    local TMP_SETUP_REDIS_ADDRESS="127.0.0.1"
    input_if_empty "TMP_SETUP_REDIS_ADDRESS" "JumpServer.Redis: Please ender ${red}redis host address${reset}"

    if [ "$TMP_SETUP_REDIS_ADDRESS" == "127.0.0.1" ]; then
        redis-cli config set stop-writes-on-bgsave-error no
    else
        sed -i "s@REDIS_HOST:.*@REDIS_HOST: $TMP_SETUP_REDIS_ADDRESS@g" config.yml
    fi
    
    cd ..
    mkdir -pv $DATA_DIR/jumpserver
    mv jumpserver $SETUP_DIR/
    
    local TMP_JMS_DIR=$SETUP_DIR/jumpserver

    # 进入 jumpserver 目录时将自动载入 python 虚拟环境
    echo "source $TMP_PY3_JMS_ENV/bin/activate" > $TMP_JMS_DIR/.env
    
    cd $TMP_JMS_DIR

    #安装依赖 RPM 包
    yum -y install $(cat requirements/rpm_requirements.txt) --skip-broken

    pip install --upgrade pip setuptools
    pip install -r requirements/requirements.txt

    #生成数据库表结构和初始化数据
    # sed -i "s@pysqlite2@from pysqlite3@g" $SETUP_DIR/pyenv3/lib/python3.6/site-packages/django/db/backends/sqlite3/base.py
    
    ./jms start all -d

    echo_startup_config "jumpserver" "$TMP_JMS_DIR" "./jms start all" "" "10" "$TMP_PY3_JMS_ENV"

	return $?
}

function setup_coco()
{
    git checkout master

    mkdir -pv /tmp/uploads
    
    cd ..
    mv coco $SETUP_DIR/
    
    local TMP_COCO_DIR=$SETUP_DIR/coco

    # 进入 jumpserver 目录时将自动载入 python 虚拟环境
    echo "source $TMP_PY3_JMS_ENV/bin/activate" > $TMP_COCO_DIR/.env

    cd $TMP_COCO_DIR

    local TMP_REQUIREMENTS_LIST=`cat requirements/rpm_requirements.txt`
    yum -y install $TMP_REQUIREMENTS_LIST --skip-broken
    
    source $TMP_PY3_JMS_ENV/bin/activate
    pip install -r requirements/requirements.txt -i https://pypi.python.org/simple

    mv config_example.yml config.yml
    
    sed -i "s@NAME:.*@NAME: 'coco-localhost'@g" config.yml
    sed -i "s@CORE_HOST:.*@CORE_HOST: http://127.0.0.1:8080@g" config.yml

    sed -i "s@BOOTSTRAP_TOKEN:.*@BOOTSTRAP_TOKEN: $TMP_JMS_TOKEN@g" config.yml
    sed -i "s@# SECRET_KEY:.*@SECRET_KEY: '$TMP_JMS_SECRET_KEY'@g" config.yml
    sed -i "s@# LOG_LEVEL:.*@LOG_LEVEL: 'ERROR'@g" config.yml
    
    ./cocod start -d

    echo_startup_config "coco" "$TMP_COCO_DIR" "./cocod start" "" "100" "$TMP_PY3_JMS_ENV"

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

    #域名可以有多个，用空格隔开
    server_name 127.0.0.1;

    #编码
    charset   utf-8;

    #默认访问类型
    default_type text/html;

    #开启目录浏览功能
    autoindex on;

    #文件大小从KB开始显示
    autoindex_exact_size off;

    #显示文件修改时间为服务器本地时间
    autoindex_localtime on;

    #录像及文件上传大小限制
    client_max_body_size 100m;  

    #定义本虚拟主机的访问日志
    access_log logs/luna_access.log combined buffer=1k;
    error_log logs/luna_error.log;

    location /luna/ {
        try_files \$uri / /index.html;
        alias $HTML_DIR/luna/;  # luna 路径,如果修改安装目录,此处需要修改
    }

    location /media/ {
        add_header Content-Encoding gzip;
        root $DATA_DIR/jumpserver/;  # 录像位置,如果修改安装目录,此处需要修改
    }

    location /static/ {
        root $DATA_DIR/jumpserver/;  # 静态资源,如果修改安装目录,此处需要修改
    }

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
    setup_soft_wget "Luna" "https://github.com/jumpserver/luna/releases/download/1.5.2/luna.tar.gz" "setup_luna"

	return $?
}

rand_str "TMP_JMS_SECRET_KEY" 32
local TMP_JMS_TOKEN=`cat /proc/sys/kernel/random/uuid`
setup_soft_basic "JumpServer" "down_jumpserver"
