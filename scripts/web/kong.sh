#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# ???待修改引入psql安装逻辑，暂时不适配单机情况下安装
# kong新增配置文件无DB模式：https://docs.konghq.com/install/centos/
# konga新增配置文件选择模式进行配置
#临时区变量
local TMP_SETUP_KONG_DIR=${SETUP_DIR}/kong
local TMP_SETUP_KONG_CONF_PATH=/etc/kong/kong.conf
local TMP_SETUP_KONG_NGX_DIR=${TMP_SETUP_KONG_DIR}/nginx/sbin

local TMP_SETUP_KONG_DASHBOARD_DIR=${SETUP_DIR}/konga

local TMP_SETUP_POSTGRESQL_DBADDRESS="127.0.0.1"
local TMP_SETUP_POSTGRESQL_DBPORT="5432"
local TMP_SETUP_POSTGRESQL_ROOT_USRNAME="postgres"
local TMP_SETUP_POSTGRESQL_ROOT_USRPWD="123456"

local TMP_SETUP_POSTGRESQL_KONG_DATABASE="kong"
local TMP_SETUP_POSTGRESQL_KONG_USRNAME="kong"
local TMP_SETUP_POSTGRESQL_KONG_USRPWD="dbkng%1it"

#全局变量
local KONG_LOGS_DIR=${LOGS_DIR}/kong
local KONG_DASHBOARD_LOGS_DIR=${LOGS_DIR}/konga

function set_environment()
{
    setup_libs
    
	return $?
}

function setup_libs()
{
    #安装postgresql client包
    sudo yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

    soft_yum_check_setup "epel-release,postgresql11"

	return $?
}

function setup_kong()
{
    #通过RPM安装
    # local TMP_SETUP_KONG_RPM_NAME=$( rpm --eval "kong-2.5.0.el%{centos_ver}.amd64.rpm")
    # local TMP_SETUP_KONG_RPM_URL=$( rpm --eval "https://download.konghq.com/gateway-2.x-centos-%{centos_ver}/Packages/k/${TMP_SETUP_KONG_RPM_NAME}")
    # while_curl "${TMP_SETUP_KONG_RPM_URL}" "sudo yum -y install ${TMP_SETUP_KONG_RPM_NAME}"
    
    #通过Repository安装
    # 等效如下：
    # curl -s $(rpm --eval "https://download.konghq.com/gateway-2.x-centos-%{centos_ver}/config.repo") | sudo tee /etc/yum.repos.d/kong.repo
    # while_wget "https://bintray.com/kong/kong-rpm/rpm -O bintray-kong-kong-rpm.repo" "sed -i -e 's/baseurl.*/&\/centos\/'$MAJOR_VERSION''/ bintray-kong-kong-rpm.repo && sudo mv bintray-kong-kong-rpm.repo /etc/yum.repos.d/ && sudo yum install -y kong"
    local TMP_SETUP_KONG_RPM_URL=$(rpm --eval "https://download.konghq.com/gateway-2.x-centos-%{centos_ver}/config.repo")
    while_wget "${TMP_SETUP_KONG_RPM_URL} -O kong.repo" "sed -i '2 aname=gateway-kong - $basearch' kong.repo && sudo mv kong.repo /etc/yum.repos.d/ && sudo yum install -y kong" 

    #软连接
    ln -sf /usr/local/kong ${TMP_SETUP_KONG_DIR}

    mkdir -pv ${KONG_LOGS_DIR}
    ln -sf ${KONG_LOGS_DIR} ${TMP_SETUP_KONG_DIR}/logs
    
    #初始化数据库，并设置密码
	input_if_empty "TMP_SETUP_POSTGRESQL_DBADDRESS" "PostgreSql: Please ender the ${red}root host address${reset} for kong"
	input_if_empty "TMP_SETUP_POSTGRESQL_DBPORT" "PostgreSql: Please ender the ${red}root port${reset} of '${TMP_SETUP_POSTGRESQL_DBADDRESS}' for kong"
	input_if_empty "TMP_SETUP_POSTGRESQL_ROOT_USRNAME" "PostgreSql: Please ender the ${red}root user name${reset} of '${TMP_SETUP_POSTGRESQL_DBADDRESS}:${TMP_SETUP_POSTGRESQL_DBPORT}' for kong"
	input_if_empty "TMP_SETUP_POSTGRESQL_ROOT_USRPWD" "PostgreSql: Please ender the ${red}root password${reset} of ${TMP_SETUP_POSTGRESQL_ROOT_USRNAME}@${TMP_SETUP_POSTGRESQL_DBADDRESS}:${TMP_SETUP_POSTGRESQL_DBPORT} for kong"
    
	input_if_empty "TMP_SETUP_POSTGRESQL_KONG_DATABASE" "Kong.PostgreSql: Please ender ${red}kong database${reset} of '${TMP_SETUP_POSTGRESQL_DBADDRESS}:${TMP_SETUP_POSTGRESQL_DBPORT}'"
	input_if_empty "TMP_SETUP_POSTGRESQL_KONG_USRNAME" "Kong.PostgreSql: Please ender ${red}kong user name${reset} of '${TMP_SETUP_POSTGRESQL_DBADDRESS}:${TMP_SETUP_POSTGRESQL_DBPORT}'"
	input_if_empty "TMP_SETUP_POSTGRESQL_KONG_USRPWD" "Kong.PostgreSql: Please ender ${red}kong password${reset} of ${TMP_SETUP_POSTGRESQL_KONG_USRNAME}@${TMP_SETUP_POSTGRESQL_DBADDRESS}:${TMP_SETUP_POSTGRESQL_DBPORT}"

psql -U ${TMP_SETUP_POSTGRESQL_ROOT_USRNAME} -h ${TMP_SETUP_POSTGRESQL_DBADDRESS} -d postgres << EOF
    CREATE USER ${TMP_SETUP_POSTGRESQL_KONG_USRNAME} WITH PASSWORD '${TMP_SETUP_POSTGRESQL_KONG_USRPWD}'; 
    CREATE DATABASE ${TMP_SETUP_POSTGRESQL_KONG_DATABASE} OWNER ${TMP_SETUP_POSTGRESQL_KONG_USRNAME};
EOF

    #迁移配置文件
    mv /etc/kong/kong.conf.default $TMP_SETUP_KONG_CONF_PATH

    #修改默认配置
    sed -i "s@^#log_level =.*@log_level = info@g" $TMP_SETUP_KONG_CONF_PATH
    sed -i "s@^#proxy_listen =.*@proxy_listen = 0.0.0.0:80, 0.0.0.0:443 ssl@g" $TMP_SETUP_KONG_CONF_PATH
    sed -i "s@^#admin_listen =.*@admin_listen = 127.0.0.1:8000, 127.0.0.1:8444 ssl@g" $TMP_SETUP_KONG_CONF_PATH
    sed -i "s@^#real_ip_recursive =.*@real_ip_recursive = on@g" $TMP_SETUP_KONG_CONF_PATH
    sed -i "s@^#client_max_body_size =.*@client_max_body_size = 20m@g" $TMP_SETUP_KONG_CONF_PATH
    sed -i "s@^#client_body_buffer_size =.*@client_body_buffer_size = 64k@g" $TMP_SETUP_KONG_CONF_PATH

    sed -i "s@^#database =@database =@g" $TMP_SETUP_KONG_CONF_PATH
    sed -i "s@^#pg_host =.*@pg_host = $TMP_SETUP_POSTGRESQL_DBADDRESS@g" $TMP_SETUP_KONG_CONF_PATH
    sed -i "s@^#pg_port =.*@pg_port = ${TMP_SETUP_POSTGRESQL_DBPORT}@g" $TMP_SETUP_KONG_CONF_PATH
    sed -i "s@^#pg_user =.*@pg_user = ${TMP_SETUP_POSTGRESQL_KONG_USRNAME}@g" $TMP_SETUP_KONG_CONF_PATH
    sed -i "s@^#pg_password =.*@pg_password = ${TMP_SETUP_POSTGRESQL_KONG_USRPWD}@g" $TMP_SETUP_KONG_CONF_PATH
    sed -i "s@^#pg_database =.*@pg_database = ${TMP_SETUP_POSTGRESQL_KONG_DATABASE}@g" $TMP_SETUP_KONG_CONF_PATH

    # 部分机器不识别/usr/local/bin下环境
    ln -sf /usr/local/bin/kong /usr/bin/kong

    kong migrations bootstrap

    kong start
    kong health
    kong restart

    local TMP_OPENRESTY_RESTY_PATH=`sudo find / -name resty | grep 'openresty/bin'`
    echo_startup_config "kong" "/usr/local/bin" "kong start" `dirname ${TMP_OPENRESTY_RESTY_PATH}` "99"

    echo_soft_port 80

	return $?
}

# konga 安装初始化存在psql版本问题，目前仅最高兼容10
function setup_kong_dashboard()
{
    cd ..
    mv konga ${TMP_SETUP_KONG_DASHBOARD_DIR}

    #安装依赖库
    cd ${__DIR}
    source scripts/lang/nodejs.sh
    nvm install lts/erbium && nvm use lts/erbium

    #初始化项目
    cd ${TMP_SETUP_KONG_DASHBOARD_DIR}
    
    #重复执行
	#while_exec "su - root -c 'cd ${TMP_SETUP_KONG_DASHBOARD_DIR} && nvm install 8.11.3 && nvm use 8.11.3 && npm install > $DOWN_DIR/konga_install.log'" "cat $DOWN_DIR/konga_install.log | grep -o \"up to date\" | awk 'END{print NR}' | xargs -I {} [ {} -eq 1 ] && echo 1" "npm uninstall && rm -rf node_modules package-lock.json && rm -rf $NVM_DIR/versions/node/v8.11.3 && rm -rf $NVM_DIR/.cache"
    #国内镜像源无法安装完全，故先切换到官方源，再还原
    npm install -g nrm
    local TMP_SOFT_NPM_NRM_REPO_CURRENT=`nrm current`
    nrm use npm
    npm install
    #npm rebuild node-sass

    mkdir -pv ${KONG_DASHBOARD_LOGS_DIR}
    ln -sf ${KONG_DASHBOARD_LOGS_DIR} ${TMP_SETUP_KONG_DASHBOARD_DIR}/logs

    #配置参数录入
    local TMP_SETUP_KONG_DASHBOARD_LOCAL_PORT="1337"
    local TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_DATABASE="konga"
    local TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_USRPWD="dbknga!1it"

    local TMP_SETUP_KONG_DASHBOARD_DOMAIN="${LOCAL_IPV4}"

	input_if_empty "TMP_SETUP_KONG_DASHBOARD_DOMAIN" "Kong.Dashboard.Web.Domain: Please ender ${red}kong dashboard web domain${reset}"
	input_if_empty "TMP_SETUP_KONG_DASHBOARD_LOCAL_PORT" "Kong.Dashboard.Web: Please ender ${red}kong dashboard web local port${reset}, except '80'"
	input_if_empty "TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_DATABASE" "Kong.Dashboard.PostgreSql: Please ender ${red}kong dashboard database${reset} of '${TMP_SETUP_POSTGRESQL_DBADDRESS}:${TMP_SETUP_POSTGRESQL_DBPORT}'"
    
    local TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_USRNAME="${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_DATABASE}"
	input_if_empty "TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_USRNAME" "Kong.Dashboard.PostgreSql: Please ender ${red}kong dashboard user name${reset} of '${TMP_SETUP_POSTGRESQL_DBADDRESS}:${TMP_SETUP_POSTGRESQL_DBPORT}'"
	input_if_empty "TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_USRPWD" "Kong.Dashboard.PostgreSql: Please ender ${red}kong dashboard password${reset} of $TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_USRNAME@${TMP_SETUP_POSTGRESQL_DBADDRESS}:${TMP_SETUP_POSTGRESQL_DBPORT}"

    #初始化配置
    mv .env_example .env
    local TMP_KONGA_TOKEN_SECURITY=`cat /proc/sys/kernel/random/uuid`
    #sed -i "/^KONGA_HOOK_TIMEOUT/d" .env
    sed -i "s@^PORT=.*@PORT=${TMP_SETUP_KONG_DASHBOARD_LOCAL_PORT}@g" .env
    # 解决 api-health-checks 健康检查超时问题
    sed -i "s@^KONGA_HOOK_TIMEOUT=.*@KONGA_HOOK_TIMEOUT=180000@g" .env
    sed -i "s@^DB_URI=.*@DB_URI=postgresql://${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_USRNAME}\@${TMP_SETUP_POSTGRESQL_DBADDRESS}:${TMP_SETUP_POSTGRESQL_DBPORT}/${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_DATABASE}@g" .env
    echo "DB_HOST=${TMP_SETUP_POSTGRESQL_DBADDRESS}" >> .env
    echo "DB_USER=${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_USRNAME}" >> .env
    echo "DB_PASSWORD=${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_USRPWD}" >> .env
    echo "DB_DATABASE=${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_DATABASE}" >> .env
    sed -i "s@^KONGA_LOG_LEVEL=.*@KONGA_LOG_LEVEL=info@g" .env
    sed -i "s@^TOKEN_SECRET=.*@TOKEN_SECRET=${TMP_KONGA_TOKEN_SECURITY}@g" .env

    sed -i "s@secret:.*@secret: 'extremely-secure-keyboard-cat'@g" config/session.js

    #数据库初始化
psql -U ${TMP_SETUP_POSTGRESQL_ROOT_USRNAME} -h ${TMP_SETUP_POSTGRESQL_DBADDRESS} -d postgres << EOF
    CREATE USER ${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_USRNAME} WITH PASSWORD '${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_USRPWD}'; 
    CREATE DATABASE ${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_DATABASE} OWNER ${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_USRNAME};
    GRANT ALL PRIVILEGES ON DATABASE ${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_DATABASE} TO ${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_USRNAME};
EOF

    # 解决sails.config.pubsub._hookTimeout 引发超时连接问题 config/pubsub.js，config/orm.js
    sed -i "s@_hookTimeout: .*@_hookTimeout: 999999@g" config/orm.js
    sed -i "s@_hookTimeout: .*@_hookTimeout: 999999@g" config/pubsub.js
    node ./bin/konga.js prepare  #不能加sudo

    sudo npm run bower-deps

psql -U ${TMP_SETUP_POSTGRESQL_ROOT_USRNAME} -h ${TMP_SETUP_POSTGRESQL_DBADDRESS} -d postgres << EOF
    \c ${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_DATABASE};
    INSERT INTO konga_kong_nodes (id,"name","type",kong_admin_url,netdata_url,kong_api_key,jwt_algorithm,jwt_key,jwt_secret,kong_version,health_checks,health_check_details,active,"createdAt","updatedAt","createdUserId","updatedUserId") VALUES (1,'CONNECTION.KONG.LOCAL.$SYS_IP_CONNECT','default','http://localhost:8000',NULL,'','HS256',NULL,NULL,'2.2.0',true,NULL,true,'${LOCAL_TIME}','${LOCAL_TIME}',1,1);
    UPDATE konga_settings SET "data"='{"signup_enable":true,"signup_require_activation":true,"info_polling_interval":1000,"email_default_sender_name":"Kong Net-Gateway","email_default_sender":"kong@gateway.com","email_notifications":false,"default_transport":"sendmail","notify_when":{"node_down":{"title":"A node is down or unresponsive","description":"Health checks must be enabled for the nodes that need to be monitored.","active":true},"api_down":{"title":"An API is down or unresponsive","description":"Health checks must be enabled for the APIs that need to be monitored.","active":true}},"user_permissions":{"apis":{"create":false,"read":true,"update":false,"delete":false},"services":{"create":false,"read":true,"update":false,"delete":false},"routes":{"create":false,"read":true,"update":false,"delete":false},"consumers":{"create":false,"read":true,"update":false,"delete":false},"plugins":{"create":false,"read":true,"update":false,"delete":false},"upstreams":{"create":false,"read":true,"update":false,"delete":false},"certificates":{"create":false,"read":true,"update":false,"delete":false},"connections":{"create":false,"read":false,"update":false,"delete":false},"users":{"create":false,"read":false,"update":false,"delete":false}},"baseUrl":"http://${TMP_SETUP_KONG_DASHBOARD_DOMAIN}","integrations":[{"id":"slack","name":"Slack","image":"slack_rgb.png","config":{"enabled":true,"fields":[{"id":"slack_webhook_url","name":"Slack Webhook URL","type":"text","required":true,"value":"https://hooks.slack.com/services/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"}],"slack_webhook_url":""}}]}' where id = 1;
    INSERT INTO konga_kong_snapshot_schedules (id,"connection",active,cron,"lastRunAt","createdAt","updatedAt","createdUserId","updatedUserId") VALUES (1,1,true,'* 1 * * *',NULL,'${LOCAL_TIME}','${LOCAL_TIME}',1,1);
    INSERT INTO konga_kong_upstream_alerts (id,upstream_id,"connection",email,slack,cron,active,"data","createdAt","updatedAt","createdUserId","updatedUserId") VALUES (1,'6b57ffb5-c2fb-4e4c-892f-7f77e7f688fb',1,true,true,NULL,true,NULL,'${LOCAL_TIME}','${LOCAL_TIME}',NULL,NULL);
    INSERT INTO konga_kong_upstream_alerts (id,upstream_id,"connection",email,slack,cron,active,"data","createdAt","updatedAt","createdUserId","updatedUserId") VALUES (2,'c4f6b96c-2ccd-49ba-a76f-a05d93dde1f1',1,true,true,NULL,true,NULL,'${LOCAL_TIME}','${LOCAL_TIME}',NULL,NULL);
    
    \c ${TMP_SETUP_POSTGRESQL_KONG_DATABASE};
    \set kong_workspace_id 'e4b9993d-653f-44fd-acc5-338ce807582c'
    UPDATE workspaces set id=:'kong_workspace_id' WHERE name='default';
    INSERT INTO services (id, created_at, updated_at, name, retries, protocol, host, port, path, connect_timeout, write_timeout, read_timeout, ws_id) VALUES ('a45c36b6-ab85-47ad-ad20-022d03ff6996', '${LOCAL_TIME}', '${LOCAL_TIME}', 'SERVICE.KONGA', 5, 'http', 'UPS-LCL-GATEWAY.KONGA', '80', '/', 60000, 60000, 60000, :'kong_workspace_id');
    INSERT INTO routes (id,created_at,updated_at,service_id,protocols,methods,hosts,paths,regex_priority,strip_path,preserve_host,name,snis,sources,destinations,tags,ws_id) VALUES ('c834f616-4583-4bab-b3c5-10456ebd7441','${LOCAL_TIME}','${LOCAL_TIME}','a45c36b6-ab85-47ad-ad20-022d03ff6996','{http,https}','{}','{${TMP_SETUP_KONG_DASHBOARD_DOMAIN}}','{/}',0,true,false,'ROUTE.SERVICE.KONGA',NULL,NULL,NULL,NULL, :'kong_workspace_id');
    INSERT INTO upstreams (id,created_at,name,hash_on,hash_fallback,hash_on_header,hash_fallback_header,hash_on_cookie,hash_on_cookie_path,slots,healthchecks,tags,ws_id) VALUES ('6b57ffb5-c2fb-4e4c-892f-7f77e7f688fb','${LOCAL_TIME}','UPS-LCL-GATEWAY.KONG','none','none',NULL,NULL,NULL,'/',1000,'{"active": {"type": "http", "healthy": {"interval": 30, "successes": 1, "http_statuses": [200, 302]}, "timeout": 5, "http_path": "/", "https_sni": "localhost", "unhealthy": {"interval": 3, "timeouts": 0, "tcp_failures": 10, "http_failures": 10, "http_statuses": [429, 404, 500, 501, 502, 503, 504, 505]}, "concurrency": 10, "https_verify_certificate": true}, "passive": {"type": "http", "healthy": {"successes": 1, "http_statuses": [200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308]}, "unhealthy": {"timeouts": 0, "tcp_failures": 5, "http_failures": 0, "http_statuses": [429, 500, 503]}}}',NULL, :'kong_workspace_id');
    INSERT INTO upstreams (id,created_at,name,hash_on,hash_fallback,hash_on_header,hash_fallback_header,hash_on_cookie,hash_on_cookie_path,slots,healthchecks,tags,ws_id) VALUES ('c4f6b96c-2ccd-49ba-a76f-a05d93dde1f1','${LOCAL_TIME}','UPS-LCL-GATEWAY.KONGA','none','none',NULL,NULL,NULL,'/',1000,'{"active": {"type": "http", "healthy": {"interval": 30, "successes": 1, "http_statuses": [200, 302]}, "timeout": 5, "http_path": "/", "https_sni": "localhost", "unhealthy": {"interval": 3, "timeouts": 0, "tcp_failures": 10, "http_failures": 10, "http_statuses": [429, 404, 500, 501, 502, 503, 504, 505]}, "concurrency": 10, "https_verify_certificate": true}, "passive": {"type": "http", "healthy": {"successes": 1, "http_statuses": [200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308]}, "unhealthy": {"timeouts": 0, "tcp_failures": 5, "http_failures": 0, "http_statuses": [429, 500, 503]}}}',NULL, :'kong_workspace_id');
    INSERT INTO targets (id,created_at,upstream_id,target,weight,tags,ws_id) VALUES ('d3a11b51-dc3c-414a-b320-95d360d56611','${LOCAL_TIME}','6b57ffb5-c2fb-4e4c-892f-7f77e7f688fb','127.0.0.1:8000',100,NULL, :'kong_workspace_id');
    INSERT INTO targets (id,created_at,upstream_id,target,weight,tags,ws_id) VALUES ('941a9b3e-72a0-4b32-854d-a3e282b33711','${LOCAL_TIME}','c4f6b96c-2ccd-49ba-a76f-a05d93dde1f1','127.0.0.1:$TMP_SETUP_KONG_DASHBOARD_LOCAL_PORT',100,NULL, :'kong_workspace_id');
EOF

    kong reload

    nohup npm run production > ${KONG_DASHBOARD_LOGS_DIR}/boot.log 2>&1 &
    nrm use ${TMP_SOFT_NPM_NRM_REPO_CURRENT}

    #缺少激活面板active命令
    #sleep 5
    #curl http://127.0.0.1:1337/kong?connection_id=1
    
    local TMP_KONGA_NPM_PATH=`npm config get prefix`

    # echo_startup_config "konga" "${TMP_SETUP_KONG_DASHBOARD_DIR}" "nvm use lts/erbium && npm run production" "${TMP_KONGA_NPM_PATH}/bin" "999" "${NVM_PATH}"
    echo_startup_config "konga" "${TMP_SETUP_KONG_DASHBOARD_DIR}" "npm run production" "${TMP_KONGA_NPM_PATH}/bin" "999"

    echo_soft_port 1337

	return $?
}

function rouse_openresty()
{
    local TMP_OPENRESTY_NGINX_PATH=`sudo find / -name nginx | grep 'openresty/nginx/sbin'`
    if [ ! -f "/usr/bin/nginx" ]; then
        ln -sf ${TMP_OPENRESTY_NGINX_PATH} /usr/bin/nginx 
    fi
    nginx -v
    
    local TMP_OPENRESTY_RESTY_PATH=`sudo find / -name resty | grep 'openresty/bin'`
    if [ ! -f "/usr/bin/resty" ]; then
        ln -sf ${TMP_OPENRESTY_RESTY_PATH} /usr/bin/resty 
    fi
    resty -v

    local TMP_OPENRESTY_LUAJIT_PATH=`sudo find / -name luajit | grep 'openresty/luajit/bin'`
    if [ ! -f "/usr/bin/luajit" ]; then
        ln -sf ${TMP_OPENRESTY_LUAJIT_PATH} /usr/bin/luajit 
    fi
    luajit -v

	return $?
}

function check_setup_kong()
{
    path_not_exits_action "${TMP_SETUP_KONG_DIR}" "setup_kong" "Kong was installed"

	return $?
}

function check_setup_kong_dashboard()
{
    setup_soft_git "KongA" "https://github.com/pantsel/konga" "setup_kong_dashboard"

	return $?
}

set_environment
setup_soft_basic "Kong" "check_setup_kong"
exec_yn_action "check_setup_kong_dashboard" "Please Sure You Want To Need ${red}Kong-Dashboard${reset}"
rouse_openresty

#ssl: 
#https://www.cnblogs.com/esofar/p/9291685.html
#https://www.sslforfree.com

#config:
#https://linuxops.org/blog/kong/config.html