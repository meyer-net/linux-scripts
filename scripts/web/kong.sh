#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 相关文献
# ssl: 
# https://www.cnblogs.com/esofar/p/9291685.html
# https://www.sslforfree.com
#
# config:
# https://linuxops.org/blog/kong/config.html
#
# ???待修改引入psql安装逻辑，暂时不适配单机情况下安装
# kong新增配置文件无DB模式：https://docs.konghq.com/install/centos/
# konga新增配置文件选择模式进行配置
# 临时区变量
local TMP_SETUP_KONG_DIR=${SETUP_DIR}/kong
local TMP_SETUP_KONG_CONF_PATH=/etc/kong/kong.conf
local TMP_SETUP_KONG_NGX_DIR=${TMP_SETUP_KONG_DIR}/nginx/sbin

local TMP_SETUP_KONG_DASHBOARD_DIR=${SETUP_DIR}/konga

local TMP_SETUP_POSTGRESQL_DBADDRESS="127.0.0.1"
local TMP_SETUP_POSTGRESQL_DBPORT="5432"
local TMP_SETUP_POSTGRESQL_ROOT_USRNAME="postgres"
local TMP_SETUP_POSTGRESQL_ROOT_USRPWD="123456"

local TMP_SETUP_KONG_HOST="127.0.0.1"
local TMP_SETUP_POSTGRESQL_KONG_DATABASE="kong"
local TMP_SETUP_POSTGRESQL_KONG_USRNAME="kong"
local TMP_SETUP_POSTGRESQL_KONG_USRPWD="dbkng%1it"

local TMP_SETUP_KONG_WORKSPACE_ID="e4b9993d-653f-44fd-acc5-338ce807582c"

local TMP_SETUP_KONG_AUTO_HTTPS_VLD_HOST="127.0.0.1"
local TMP_SETUP_KONG_AUTO_HTTPS_VLD_PORT="60080"

#全局变量
local KONG_LOGS_DIR=${LOGS_DIR}/kong
local KONG_DASHBOARD_LOGS_DIR=${LOGS_DIR}/konga

function set_environment()
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
    sed -i "s@^#admin_listen =.*@admin_listen = 0.0.0.0:8000, 0.0.0.0:8444 ssl@g" $TMP_SETUP_KONG_CONF_PATH
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

	input_if_empty "TMP_SETUP_KONG_AUTO_HTTPS_VLD_HOST" "Kong.AutoHttps: Please ender ${red}auto https valid api host for kong${reset} of 'caddy'"
        
    # 添加kong-api的配置信息
    # 1：设置统一工作组ID
    # 2：更新初始化的工作组ID为自定义ID
    # 3：添加upstream指针：kong-api
    # 4：绑定upstream指针对应的访问地址：kong-api
    #
    # 配合autohttps部分，把所有路径规则 /.well-known 都交给caddy
# 集成默认安装webhook，由kong的请求触发webhook来异步调用caddy-api执行自动添加及更新https配置
    # 1：添加upstream指针：caddy-api
    # 2：绑定upstream指针对应的访问地址：caddy-api
    # 3：添加upstream指针：caddy-vld
    # 4：绑定upstream指针对应的访问地址：caddy-vld
    # 5：添加服务指针（表示一个nginx配置文件conf）：caddy-vld
    # 6：添加服务指针对应路由（表示一个nginx配置文件conf中的location）：caddy-vld
    # 添加webhook插件，用于同步caddy生成证书内容给与kong，webhook服务默认在本地
    # 1：添加upstream指针：webhook
    # 2：绑定upstream指针对应的访问地址：webhook
    # 3：添加全局消费者：用于针对绑定webhook同步证书信息
    # 4：添加插件：用于将日志转发给webhook服务
psql -U ${TMP_SETUP_POSTGRESQL_ROOT_USRNAME} -h ${TMP_SETUP_POSTGRESQL_DBADDRESS} -d postgres << EOF
    \c ${TMP_SETUP_POSTGRESQL_KONG_DATABASE};
    \set kong_workspace_id '${TMP_SETUP_KONG_WORKSPACE_ID}'
    UPDATE workspaces set id=:'kong_workspace_id' WHERE name='default';
    INSERT INTO upstreams (id,created_at,name,hash_on,hash_fallback,hash_on_header,hash_fallback_header,hash_on_cookie,hash_on_cookie_path,slots,healthchecks,tags,ws_id) VALUES ('6b57ffb5-c2fb-4e4c-892f-7f77e7f688fb',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss'),'UPS-LCL-GATEWAY.KONG-API','none','none',NULL,NULL,NULL,'/',1000,'{"active": {"type": "http", "healthy": {"interval": 30, "successes": 1, "http_statuses": [200, 302]}, "timeout": 5, "http_path": "/", "https_sni": "localhost", "unhealthy": {"interval": 3, "timeouts": 0, "tcp_failures": 10, "http_failures": 10, "http_statuses": [429, 404, 500, 501, 502, 503, 504, 505]}, "concurrency": 10, "https_verify_certificate": true}, "passive": {"type": "http", "healthy": {"successes": 1, "http_statuses": [200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308]}, "unhealthy": {"timeouts": 0, "tcp_failures": 5, "http_failures": 0, "http_statuses": [429, 500, 503]}}}',NULL, :'kong_workspace_id');
    INSERT INTO targets (id,created_at,upstream_id,target,weight,tags,ws_id) VALUES ('d3a11b51-dc3c-414a-b320-95d360d56611',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss'),'6b57ffb5-c2fb-4e4c-892f-7f77e7f688fb','127.0.0.1:8000',100,NULL, :'kong_workspace_id'); 
    
    INSERT INTO upstreams (id,created_at,name,hash_on,hash_fallback,hash_on_header,hash_fallback_header,hash_on_cookie,hash_on_cookie_path,slots,healthchecks,tags,ws_id) VALUES ('2d929958-f95d-5365-a997-055c26fd122d',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min','UPS-LCL-COROUTINES.CADDY-API','none','none',NULL,NULL,NULL,'/',1000,'{"active": {"type": "http", "healthy": {"interval": 30, "successes": 1, "http_statuses": [200, 302]}, "timeout": 5, "http_path": "/", "https_sni": "localhost", "unhealthy": {"interval": 3, "timeouts": 0, "tcp_failures": 10, "http_failures": 10, "http_statuses": [429, 404, 500, 501, 502, 503, 504, 505]}, "concurrency": 10, "https_verify_certificate": true}, "passive": {"type": "http", "healthy": {"successes": 1, "http_statuses": [200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308]}, "unhealthy": {"timeouts": 0, "tcp_failures": 5, "http_failures": 0, "http_statuses": [429, 500, 503]}}}',NULL, :'kong_workspace_id');
    INSERT INTO targets (id,created_at,upstream_id,target,weight,tags,ws_id) VALUES ('5055bc0a-bdd5-59cf-a5e6-c60f3b7d680c',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min','2d929958-f95d-5365-a997-055c26fd122d','${TMP_SETUP_KONG_AUTO_HTTPS_VLD_HOST}:2019',100,NULL, :'kong_workspace_id'); 
    INSERT INTO upstreams (id,created_at,name,hash_on,hash_fallback,hash_on_header,hash_fallback_header,hash_on_cookie,hash_on_cookie_path,slots,healthchecks,tags,ws_id) VALUES ('9d68b631-2c02-5506-9e88-53e6d7975ea6',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '2 min','UPS-LCL-COROUTINES.CADDY_HTTPS_VLD','none','none',NULL,NULL,NULL,'/',1000,'{"active": {"type": "http", "healthy": {"interval": 30, "successes": 1, "http_statuses": [200, 302]}, "timeout": 5, "http_path": "/", "https_sni": "localhost", "unhealthy": {"interval": 3, "timeouts": 0, "tcp_failures": 10, "http_failures": 10, "http_statuses": [429, 404, 500, 501, 502, 503, 504, 505]}, "concurrency": 10, "https_verify_certificate": true}, "passive": {"type": "http", "healthy": {"successes": 1, "http_statuses": [200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308]}, "unhealthy": {"timeouts": 0, "tcp_failures": 5, "http_failures": 0, "http_statuses": [429, 500, 503]}}}',NULL, :'kong_workspace_id');
    INSERT INTO targets (id,created_at,upstream_id,target,weight,tags,ws_id) VALUES ('a5178e75-f6d7-59cf-bda8-290f892885ed',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '2 min','9d68b631-2c02-5506-9e88-53e6d7975ea6','${TMP_SETUP_KONG_AUTO_HTTPS_VLD_HOST}:${TMP_SETUP_KONG_AUTO_HTTPS_VLD_PORT}',100,NULL, :'kong_workspace_id');
    INSERT INTO services (id, created_at, updated_at, name, retries, protocol, host, port, path, connect_timeout, write_timeout, read_timeout, ws_id) VALUES ('8253fa0c-e329-5670-9bde-5d63eba6a92c', '${LOCAL_TIME}', '${LOCAL_TIME}', 'SERVICE.CADDY_HTTPS_VLD', 5, 'http', 'UPS-LCL-COROUTINES.CADDY_HTTPS_VLD', '80', '/', 60000, 60000, 60000, :'kong_workspace_id');
    INSERT INTO routes (id,created_at,updated_at,service_id,protocols,methods,hosts,paths,regex_priority,strip_path,preserve_host,name,snis,sources,destinations,tags,headers,ws_id) VALUES ('bb232280-811e-5c51-9f66-f10089b15565','${LOCAL_TIME}','${LOCAL_TIME}','8253fa0c-e329-5670-9bde-5d63eba6a92c','{http,https}','{}','{}','{/.well-known}',0,false,true,'ROUTE.SERVICE.CADDY_HTTPS_VLD',NULL,NULL,NULL,NULL,'{"User-Agent": ["acme.zerossl.com/v2/DV90"]}', :'kong_workspace_id');

    INSERT INTO upstreams (id,created_at,name,hash_on,hash_fallback,hash_on_header,hash_fallback_header,hash_on_cookie,hash_on_cookie_path,slots,healthchecks,tags,ws_id) VALUES ('0a79e2bc-6fc3-5d59-bbfa-cc733f836935',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '3 min','UPS-LCL-COROUTINES.WEBHOOK','none','none',NULL,NULL,NULL,'/',1000,'{"active": {"type": "http", "healthy": {"interval": 30, "successes": 1, "http_statuses": [200, 302]}, "timeout": 5, "http_path": "/", "https_sni": "localhost", "unhealthy": {"interval": 3, "timeouts": 0, "tcp_failures": 10, "http_failures": 10, "http_statuses": [429, 404, 500, 501, 502, 503, 504, 505]}, "concurrency": 10, "https_verify_certificate": true}, "passive": {"type": "http", "healthy": {"successes": 1, "http_statuses": [200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308]}, "unhealthy": {"timeouts": 0, "tcp_failures": 5, "http_failures": 0, "http_statuses": [429, 500, 503]}}}',NULL, :'kong_workspace_id');
    INSERT INTO targets (id,created_at,upstream_id,target,weight,tags,ws_id) VALUES ('07232e9f-f860-5659-afcd-cafb8580e6f6',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '3 min','0a79e2bc-6fc3-5d59-bbfa-cc733f836935','${TMP_SETUP_KONG_AUTO_HTTPS_VLD_HOST}:9000',100,NULL, :'kong_workspace_id'); 
    INSERT INTO plugins (id, created_at, name, consumer_id, service_id, route_id, config, enabled, cache_key, protocols, tags, ws_id) VALUES ('58377e23-5dea-5aaa-9c0a-b056a80381dc', '${LOCAL_TIME}', 'http-log', NULL, NULL, 'bb232280-811e-5c51-9f66-f10089b15565', '{"method": "POST", "headers": null, "timeout": 10000, "keepalive": 60000, "queue_size": 1, "retry_count": 10, "content_type": "application/json", "flush_timeout": 2, "http_endpoint": "http://127.0.0.1:9000/hooks/async-caddy-cert-to-kong", "custom_fields_by_lua": null}', true, 'plugins:http-log:bb232280-811e-5c51-9f66-f10089b15565::::e4b9993d-653f-44fd-acc5-338ce807582c', '{grpc,grpcs,http,https}', NULL, :'kong_workspace_id');
EOF

    # INSERT INTO consumers (id, created_at, username, custom_id, tags, ws_id) VALUES ('6ace2af0-8c2b-5aef-b18d-ff731507b92d', '${LOCAL_TIME}', 'webhook:async-caddy-cert', NULL, '{}', :'kong_workspace_id');
    kong start
    kong health
    
    rouse_openresty

    echo_soft_port 80
    echo_soft_port 443

    # 重新更新时间，避免VLD优先级受影响
    LOCAL_TIME=`date +"%Y-%m-%d %H:%M:%S"`

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

    # 不在本机的情况下，需要输入地址
    local TMP_SETUP_IS_KONG_LOCAL=`lsof -i:8000`
    if [ -z "${TMP_SETUP_IS_KONG_LOCAL}" ]; then
    	input_if_empty "TMP_SETUP_KONG_HOST" "Kong.Dashboard.Kong.Host: Please ender ${red}your kong host address${reset}"
    fi

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

    # 添加konga及kong绑定关系
    # konga：
    # 1：添加kong的节点
    # 2：更新默认konga自身配置功能信息
    # 3：添加当前konga对kong节点的快照配置
    # 4：konga对kong的upstream做健康检查：kong-api
    # 5：konga对caddy的upstream做健康检查：caddy-api （默认不启用，生产启用自行设定）
    # 6：konga对kong的upstream做健康检查：konga自身
    # 6：konga对webhook的upstream做健康检查：webhook
    # 
    # kong：
    # 1：设置统一工作组ID
    # 2：添加upstream指针：konga
    # 3：绑定upstream指针对应的访问地址：konga
    # 4：添加服务指针（表示一个nginx配置文件conf）：konga
    # 5：添加服务指针对应路由（表示一个nginx配置文件conf中的location）：konga
psql -U ${TMP_SETUP_POSTGRESQL_ROOT_USRNAME} -h ${TMP_SETUP_POSTGRESQL_DBADDRESS} -d postgres << EOF
    \c ${TMP_SETUP_POSTGRESQL_KONG_DASHBOARD_DATABASE};
    INSERT INTO konga_kong_nodes (id,"name","type",kong_admin_url,netdata_url,kong_api_key,jwt_algorithm,jwt_key,jwt_secret,kong_version,health_checks,health_check_details,active,"createdAt","updatedAt","createdUserId","updatedUserId") VALUES (1,'CONNECTION.KONG.LOCAL.$SYS_IP_CONNECT','default','http://${TMP_SETUP_KONG_HOST}:8000',NULL,'','HS256',NULL,NULL,'2.x.0',true,NULL,true,'${LOCAL_TIME}','${LOCAL_TIME}',1,1);
    UPDATE konga_settings SET "data"='{"signup_enable":false,"signup_require_activation":true,"info_polling_interval":1000,"email_default_sender_name":"Kong Net-Gateway","email_default_sender":"kong@gateway.com","email_notifications":false,"default_transport":"sendmail","notify_when":{"node_down":{"title":"A node is down or unresponsive","description":"Health checks must be enabled for the nodes that need to be monitored.","active":true},"api_down":{"title":"An API is down or unresponsive","description":"Health checks must be enabled for the APIs that need to be monitored.","active":true}},"user_permissions":{"apis":{"create":false,"read":true,"update":false,"delete":false},"services":{"create":false,"read":true,"update":false,"delete":false},"routes":{"create":false,"read":true,"update":false,"delete":false},"consumers":{"create":false,"read":true,"update":false,"delete":false},"plugins":{"create":false,"read":true,"update":false,"delete":false},"upstreams":{"create":false,"read":true,"update":false,"delete":false},"certificates":{"create":false,"read":true,"update":false,"delete":false},"connections":{"create":false,"read":false,"update":false,"delete":false},"users":{"create":false,"read":false,"update":false,"delete":false}},"baseUrl":"http://${TMP_SETUP_KONG_DASHBOARD_DOMAIN}","integrations":[{"id":"slack","name":"Slack","image":"slack_rgb.png","config":{"enabled":true,"fields":[{"id":"slack_webhook_url","name":"Slack Webhook URL","type":"text","required":true,"value":"https://hooks.slack.com/services/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"}],"slack_webhook_url":""}}]}' where id = 1;
    INSERT INTO konga_kong_snapshot_schedules (id,"connection",active,cron,"lastRunAt","createdAt","updatedAt","createdUserId","updatedUserId") VALUES (1,1,true,'* 1 * * *',NULL,'${LOCAL_TIME}','${LOCAL_TIME}',1,1);
    INSERT INTO konga_kong_upstream_alerts (id,upstream_id,"connection",email,slack,cron,active,"data","createdAt","updatedAt","createdUserId","updatedUserId") VALUES (1,'6b57ffb5-c2fb-4e4c-892f-7f77e7f688fb',1,true,true,NULL,true,NULL,to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min',NULL,NULL);
    INSERT INTO konga_kong_upstream_alerts (id,upstream_id,"connection",email,slack,cron,active,"data","createdAt","updatedAt","createdUserId","updatedUserId") VALUES (2,'2d929958-f95d-5365-a997-055c26fd122d',1,true,true,NULL,false,NULL,to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '2 min',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '2 min',NULL,NULL);
    INSERT INTO konga_kong_upstream_alerts (id,upstream_id,"connection",email,slack,cron,active,"data","createdAt","updatedAt","createdUserId","updatedUserId") VALUES (3,'c4f6b96c-2ccd-49ba-a76f-a05d93dde1f1',1,true,true,NULL,true,NULL,to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '3 min',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '3 min',NULL,NULL);
    INSERT INTO konga_kong_upstream_alerts (id,upstream_id,"connection",email,slack,cron,active,"data","createdAt","updatedAt","createdUserId","updatedUserId") VALUES (4,'0a79e2bc-6fc3-5d59-bbfa-cc733f836935',1,true,true,NULL,false,NULL,to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '4 min',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '4 min',NULL,NULL);
    
    \c ${TMP_SETUP_POSTGRESQL_KONG_DATABASE};
    \set kong_workspace_id '${TMP_SETUP_KONG_WORKSPACE_ID}'
    INSERT INTO upstreams (id,created_at,name,hash_on,hash_fallback,hash_on_header,hash_fallback_header,hash_on_cookie,hash_on_cookie_path,slots,healthchecks,tags,ws_id) VALUES ('c4f6b96c-2ccd-49ba-a76f-a05d93dde1f1',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '4 min','UPS-LCL-GATEWAY.KONGA','none','none',NULL,NULL,NULL,'/',1000,'{"active": {"type": "http", "healthy": {"interval": 30, "successes": 1, "http_statuses": [200, 302]}, "timeout": 5, "http_path": "/", "https_sni": "localhost", "unhealthy": {"interval": 3, "timeouts": 0, "tcp_failures": 10, "http_failures": 10, "http_statuses": [429, 404, 500, 501, 502, 503, 504, 505]}, "concurrency": 10, "https_verify_certificate": true}, "passive": {"type": "http", "healthy": {"successes": 1, "http_statuses": [200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308]}, "unhealthy": {"timeouts": 0, "tcp_failures": 5, "http_failures": 0, "http_statuses": [429, 500, 503]}}}',NULL, :'kong_workspace_id');
    INSERT INTO targets (id,created_at,upstream_id,target,weight,tags,ws_id) VALUES ('941a9b3e-72a0-4b32-854d-a3e282b33711',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '4 min','c4f6b96c-2ccd-49ba-a76f-a05d93dde1f1','127.0.0.1:${TMP_SETUP_KONG_DASHBOARD_LOCAL_PORT}',100,NULL, :'kong_workspace_id');
    INSERT INTO services (id, created_at, updated_at, name, retries, protocol, host, port, path, connect_timeout, write_timeout, read_timeout, ws_id) VALUES ('a45c36b6-ab85-47ad-ad20-022d03ff6996', to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min', to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min', 'SERVICE.KONGA', 5, 'http', 'UPS-LCL-GATEWAY.KONGA', '80', '/', 60000, 60000, 60000, :'kong_workspace_id');
    INSERT INTO routes (id,created_at,updated_at,service_id,protocols,methods,hosts,paths,regex_priority,strip_path,preserve_host,name,snis,sources,destinations,tags,ws_id) VALUES ('c834f616-4583-4bab-b3c5-10456ebd7441',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min','a45c36b6-ab85-47ad-ad20-022d03ff6996','{http,https}','{}','{${TMP_SETUP_KONG_DASHBOARD_DOMAIN}}','{/}',0,true,false,'ROUTE.SERVICE.KONGA',NULL,NULL,NULL,NULL, :'kong_workspace_id');
EOF

    kong stop
    kong start
    kong health

    nohup npm run production > ${KONG_DASHBOARD_LOGS_DIR}/boot.log 2>&1 &
    nrm use ${TMP_SOFT_NPM_NRM_REPO_CURRENT}
    
    local TMP_KONGA_NPM_PATH=`npm config get prefix`
    # echo_startup_config "konga" "${TMP_SETUP_KONG_DASHBOARD_DIR}" "nvm use lts/erbium && npm run production" "${TMP_KONGA_NPM_PATH}/bin" "999" "${NVM_PATH}"
    echo_startup_config "konga" "${TMP_SETUP_KONG_DASHBOARD_DIR}" "npm run production" "${TMP_KONGA_NPM_PATH}/bin" "999" "${NVM_PATH}"

    echo_soft_port 1337

	return $?
}

function rouse_openresty()
{
    local TMP_OPENRESTY_NGINX_BIN_PATH=`sudo find / -name nginx | grep 'openresty/nginx/sbin'`
    if [ ! -f "/usr/bin/nginx" ]; then
        ln -sf ${TMP_OPENRESTY_NGINX_BIN_PATH} /usr/bin/nginx
        
        # 修改默认nginx配置性能瓶颈问题
        local TMP_OPENRESTY_NGINX_CONF_PATH=`dirname ${TMP_OPENRESTY_NGINX_BIN_PATH%/*}`/conf/nginx.conf

sudo tee ${TMP_OPENRESTY_NGINX_CONF_PATH} <<-'EOF'
#user  nobody;
worker_processes  auto

#更改Nginx进程的最大打开文件数限制，理论值应该是最多打开文件数（ulimit -n）与nginx进程数相除，该值控制 “too many open files” 的问题
worker_rlimit_nofile 65535;  #此处为65535/4

#进程文件
pid        tmp/nginx.pid;

#工作模式与连接数上限
events {
    #参考事件模型，use [ kqueue | rtsig | epoll | /dev/poll | select | poll ]; epoll模型是Linux 2.6以上版本内核中的高性能网络I/O模型，如果跑在FreeBSD上面，就用kqueue模型。
    use epoll;
    multi_accept on; #告诉nginx收到一个新连接通知后接受尽可能多的连接。
    accept_mutex off;
    worker_connections  65535; #单个进程最大连接数（最大连接数=连接数*进程数），1核默认配8000。
}

http {
    #文件扩展名与文件类型映射表
    include mime.types;

    #默认文件类型
    default_type  text/html;

    #默认编码
    charset utf-8;

    #日志格式设定
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    log_format  json  '{"@timestamp":"$time_iso8601",'
                      '"slb_user":"$remote_user",'
                      '"slb_ip":"$remote_addr",'
                      '"client_ip":"$http_x_forwarded_for",'
                      '"server_ip":"$server_addr",'
                      '"size":$body_bytes_sent,'
                      '"response_time":$request_time,'
                      '"domain":"$host",'
                      '"method":"$request_method",'
                      '"request_uri":"$request_uri",'
                      '"url":"$uri",'
                      '"app_version":"$HTTP_APP_VERSION",'
                      '"referer":"$http_referer",'
                      '"agent":"$http_user_agent",'
                      '"status":"$status",'
                      '"device_code":"$HTTP_HA",'
                      '"upstream_response_time":$upstream_response_time,'
                      '"upstream_addr":"$upstream_addr",'
                      '"upstream_status":"$upstream_status",'
                      '"upstream_cache_status":"$upstream_cache_status"}';

    #是否开启重写日志
    rewrite_log on;


    #日志文件缓存
    #   max:设置缓存中的最大文件描述符数量，如果缓存被占满，采用LRU算法将描述符关闭。
    #   inactive:设置存活时间，默认是10s
    #   min_uses:设置在inactive时间段内，日志文件最少使用多少次后，该日志文件描述符记入缓存中，默认是1次
    #   valid:设置检查频率，默认60s
    #   off：禁用缓存
    #open_log_file_cache max=1000 inactive=20s valid=1m min_uses=2;

    #关闭在错误页面中的nginx版本数字
    server_tokens off;

    #服务器名字的hash表大小
    server_names_hash_bucket_size 128; 

    #上传文件大小限制，一般一个请求的头部大小不会超过1k
    client_header_buffer_size 4k; 

    #设定请求缓存
    large_client_header_buffers 4 64k; 

    #设定请求缓存
    client_max_body_size 8m; 

    #开启目录列表访问，合适下载服务器，默认关闭。
    autoindex off; 

    #开启高效文件传输模式，sendfile指令指定nginx是否调用sendfile函数来输出文件。
    #对于普通应用设为 on，如果用来进行下载等应用磁盘IO重负载应用，可设置为off，以平衡磁盘与网络I/O处理速度，降低系统的负载。
    #注意：如果图片显示不正常把这个改成off。
    sendfile        on;
    sendfile_max_chunk 512k;  #该指令可以减少阻塞方法 sendfile() 调用的所花费的最大时间，每次无需发送整个文件，只发送 512KB 的块数据

    #通用代理设置
    proxy_headers_hash_max_size 51200; #设置头部哈希表的最大值，不能小于你后端服务器设置的头部总数
    proxy_headers_hash_bucket_size 6400; #设置头部哈希表大小

    tcp_nopush on; #防止网络阻塞(告诉nginx在一个数据包里发送所有头文件，而不一个接一个的发送)
    tcp_nodelay on; #防止网络阻塞(告诉nginx不要缓存数据，而是一段一段的发送，当需要及时发送数据时，就应该给应用设置这个属性)

    #长连接超时时间，单位是秒
    keepalive_timeout 15; 

    #设置请求头的超时时间
    client_header_timeout 5;

    #设置请求体的超时时间
    client_body_timeout 10;

    #关闭不响应的客户端连接。这将会释放那个客户端所占有的内存空间。
    reset_timedout_connection on;

    #指定客户端的响应超时时间。这个设置不会用于整个转发器，而是在两次客户端读取操作之间。如果在这段时间内，客户端没有读取任何数据，nginx就会关闭连接。
    send_timeout 10; 

    #为FastCGI缓存指定一个路径，目录结构等级，关键字区域存储时间和非活动删除时间。
    #fastcgi_cache_path /clouddisk/attach/openresty/fastcgi_cache levels=1:2 keys_zone=cache_php:64m inactive=5m max_size=10g;  

    #gzip模块设置
    gzip on; #开启gzip压缩输出
    gzip_disable 'msie6'; #为指定的客户端禁用gzip功能。我们设置成IE6或者更低版本以使我们的方案能够广泛兼容。
    gzip_proxied any; #允许或者禁止压缩基于请求和响应的响应流。我们设置为any，意味着将会压缩所有的请求。
    gzip_min_length 1k; #最小压缩文件大小
    gzip_buffers 16 8k; #压缩缓冲区
    gzip_http_version 1.0; #压缩版本（默认1.1，前端如果是squid2.5请使用1.0）
    gzip_comp_level 6; #压缩等级
    gzip_types text/plain 
               text/css 
               text/xml 
               text/javascript 
               application/json 
               application/javascript
               application/x-httpd-php 
               application/x-javascript 
               application/xml 
               application/xml+rss 
               image/jpeg 
               image/gif 
               image/png
               image/svg+xml;

    #设置需要压缩的数据格式
    gzip_vary on;

    #limit_conn_zone $binary_remote_addr zone=addr:10m; #开启限制IP连接数的时候需要使用
    #limit_conn_log_level info;

    #指定DNS服务器的地址
    resolver 223.5.5.5 223.6.6.6;

    #定义一个名为 default 的线程池，拥有 32 个工作线程，任务队列容纳的最大请求数为 65536。一旦任务队列过载，NGINX日志会报错并拒绝这一请求
    #thread_pool default threads=32 max_queue=65536;

    # cache informations about file descriptors, frequently accessed files 
    # can boost performance, but you need to test those values 
    open_file_cache max=65536 inactive=10s; # 打开缓存的同时也指定了缓存最大数目，以及缓存的时间
    open_file_cache_valid 30s; #在open_file_cache中指定检测正确信息的间隔时间
    open_file_cache_min_uses 1; #定义了open_file_cache中指令参数不活动时间期间里最小的文件数
    open_file_cache_errors on; #指定了当搜索一个文件时是否缓存错误信息，也包括再次给配置中添加文件

    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}
}

EOF
    fi
    nginx -v
    
    local TMP_OPENRESTY_RESTY_BIN_PATH=`sudo find / -name resty | grep 'openresty/bin'`
    if [ ! -f "/usr/bin/resty" ]; then
        ln -sf ${TMP_OPENRESTY_RESTY_BIN_PATH} /usr/bin/resty 
    fi
    resty -v

    local TMP_OPENRESTY_LUAJIT_BIN_PATH=`sudo find / -name luajit | grep 'openresty/luajit/bin'`
    if [ ! -f "/usr/bin/luajit" ]; then
        ln -sf ${TMP_OPENRESTY_LUAJIT_BIN_PATH} /usr/bin/luajit 
    fi
    luajit -v

    echo_startup_config "kong" "/usr/local/bin" "kong start" `dirname ${TMP_OPENRESTY_RESTY_PATH}` "99"

	return $?
}

function check_setup_kong()
{
    path_not_exits_action "${TMP_SETUP_KONG_DIR}" "setup_kong" "Kong was installed"
    
    # 绑定证书同步，需装
    # cd ${__DIR}
    # source scripts/web/webhook.sh

	return $?
}

function check_setup_kong_dashboard()
{
    setup_soft_git "KongA" "https://github.com/pantsel/konga" "setup_kong_dashboard"

	return $?
}

set_environment
setup_soft_basic "Kong" "check_setup_kong"
exec_yn_action "check_setup_kong_dashboard" "Please sure you want to need ${red}Kong-Dashboard${reset}"