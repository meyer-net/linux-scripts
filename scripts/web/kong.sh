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
# https://www.jianshu.com/p/5049b3bb4b80
# https://docs.konghq.com/install/centos/?_ga=2.110225728.474733574.1547721700-1679220384.1547721700
#
# ???新增侦听api-CRUD 域名请求的缓存，用于同步到caddy证书
# ???待修改引入psql安装逻辑，暂时不适配单机情况下安装
# kong新增配置文件无DB模式：https://docs.konghq.com/install/centos/
# konga新增配置文件选择模式进行配置
#------------------------------------------------
local TMP_KNG_SETUP_API_HTTP_PORT=18000
local TMP_KNG_SETUP_API_HTTPS_PORT=18444

local TMP_KNGA_SETUP_HTTP_PORT=11337

local TMP_KNG_SETUP_CDY_API_HOST="${LOCAL_HOST}"
local TMP_KNG_SETUP_CDY_API_PORT=12019
local TMP_KNG_SETUP_CDY_BIND_WBH_API_PORT=19000
local TMP_KNG_SETUP_CDY_DFT_HTTP_PORT=60080

local TMP_KNG_SETUP_PSQL_SELF_DATABASE="kong"
local TMP_KNG_SETUP_WORKSPACE_ID="e4b9993d-653f-44fd-acc5-338ce807582c"
local TMP_KNG_SETUP_PSQL_HOST="${LOCAL_HOST}"
local TMP_KNG_SETUP_PSQL_PORT=15432
local TMP_KNG_SETUP_PSQL_USRNAME="postgres"

##########################################################################################################

# 1-配置环境
function set_env_kong()
{
    cd ${__DIR}

    #安装postgresql client包，便于初始化
    while_wget "--content-disposition https://download.postgresql.org/pub/repos/yum/reporpms/EL-${OS_VERS}-x86_64/pgdg-redhat-repo-latest.noarch.rpm" "rpm -ivh pgdg-redhat-repo-latest.noarch.rpm"

    set_env_check_postgresql "Kong"

    soft_yum_check_setup "epel-release,postgresql11"

	return $?
}

function set_env_konga()
{
    set_env_check_postgresql "KongA"

    cd ${__DIR} && source scripts/lang/nodejs.sh

    # konga 只认可该版本以下
    nvm install lts/erbium && nvm use lts/erbium
    
    nvm alias default lts/erbium

	return $?
}

function set_env_check_postgresql()
{	
    local TMP_KNG_OR_KNGA_SETUP_TITLE=${1}
    local TMP_IS_KNG_OR_KNGA_PSQL_LOCAL=`lsof -i:${TMP_KNG_SETUP_PSQL_PORT}`
    if [ -z "${TMP_IS_KNG_OR_KNGA_PSQL_LOCAL}" ]; then 
    	exec_yn_action "setup_postgresql" "${TMP_KNG_OR_KNGA_SETUP_TITLE}.PostgresQL: Can't find dependencies compment of ${red}postgresql${reset}，please sure if u want to get ${green}postgresql local${reset} or remote got?"
	fi

    return $?
}

##########################################################################################################

function setup_postgresql()
{   
    cd ${__DIR} && source scripts/database/postgresql.sh

    return $?
}

# 2-安装软件
function setup_kong()
{
	local TMP_KNG_SETUP_DIR=${1}

	## 源模式    
    #通过RPM安装
	local TMP_KNG_SETUP_NEWER="2.5.0"
	local TMP_KNG_SETUP_RPM_FILE_NEWER="kong-${TMP_KNG_SETUP_NEWER}.amd64.rpm"
	set_github_soft_releases_newer_version "TMP_KNG_SETUP_NEWER" "kong/kong"
    local TMP_KNG_SETUP_RPM_NEWER=$(rpm --eval "https://download.konghq.com/gateway-2.x-centos-%{centos_ver}/Packages/k/kong-${TMP_KNG_SETUP_NEWER}.el%{centos_ver}.amd64.rpm")
    while_wget "${TMP_KNG_SETUP_RPM_NEWER} -O ${TMP_KNG_SETUP_RPM_FILE_NEWER}" "yum -y install ${TMP_KNG_SETUP_RPM_FILE_NEWER}"
    
    #通过Repository安装
    # 等效如下：
    # curl -s $(rpm --eval "https://download.konghq.com/gateway-2.x-centos-%{centos_ver}/config.repo") | sudo tee /etc/yum.repos.d/kong.repo
    # while_wget "https://bintray.com/kong/kong-rpm/rpm -O bintray-kong-kong-rpm.repo" "sed -i -e 's/baseurl.*/&\/centos\/'$MAJOR_VERS''/ bintray-kong-kong-rpm.repo && sudo mv bintray-kong-kong-rpm.repo /etc/yum.repos.d/ && sudo yum install -y kong"
    # local TMP_KNG_SETUP_REPO_NEWER=$(rpm --eval "https://download.konghq.com/gateway-2.x-centos-%{centos_ver}/config.repo")
    # while_wget "${TMP_KNG_SETUP_REPO_NEWER} -O kong.repo" "sed -i '2 aname=gateway-kong - $basearch' kong.repo && sudo mv kong.repo /etc/yum.repos.d/" 
    # soft_yum_check_setup "kong.repo"

	# 创建日志软链
	local TMP_KNG_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/kong
	local TMP_KNG_SETUP_LOGS_DIR=${TMP_KNG_SETUP_DIR}/logs

	# 先清理文件，再创建文件
    ln -sf /usr/local/kong ${TMP_KNG_SETUP_DIR}
	rm -rf ${TMP_KNG_SETUP_LOGS_DIR}
	mv /usr/local/openresty/nginx/logs ${TMP_KNG_SETUP_LNK_LOGS_DIR}
    
	ln -sf ${TMP_KNG_SETUP_LNK_LOGS_DIR} /usr/local/openresty/logs
	ln -sf ${TMP_KNG_SETUP_LNK_LOGS_DIR} /usr/local/openresty/nginx/logs
	ln -sf ${TMP_KNG_SETUP_LNK_LOGS_DIR} ${TMP_KNG_SETUP_LOGS_DIR}

	# 授权权限，否则无法写入
	create_user_if_not_exists kong kong
	chgrp -R kong ${TMP_KNG_SETUP_LNK_LOGS_DIR}
	chown -R kong:kong ${TMP_KNG_SETUP_LNK_LOGS_DIR}

    # 安装初始
    # 创建源码目录
    path_not_exists_create "${NGINX_DIR}"
    path_not_exists_create "${HTML_DIR}"
    path_not_exists_create "${OR_DIR}"

	return $?
}

# 2-安装软件
function setup_konga()
{
	local TMP_KNGA_SETUP_DIR=${1}
	local TMP_KNGA_CURRENT_DIR=${2}

	## 直装模式
	cd `dirname ${TMP_KNGA_CURRENT_DIR}`

	mv ${TMP_KNGA_CURRENT_DIR} ${TMP_KNGA_SETUP_DIR}

    cd ${TMP_KNGA_SETUP_DIR}

	# 创建日志软链
	local TMP_KNGA_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/konga
	local TMP_KNGA_SETUP_LOGS_DIR=${TMP_KNGA_SETUP_DIR}/logs

	# 先清理文件，再创建文件
	rm -rf ${TMP_KNGA_SETUP_LOGS_DIR}
	mkdir -pv ${TMP_KNGA_SETUP_LNK_LOGS_DIR}
	
	ln -sf ${TMP_KNGA_SETUP_LNK_LOGS_DIR} ${TMP_KNGA_SETUP_LOGS_DIR}
    
    # 开始安装
    #while_exec "su - root -c 'cd ${TMP_KNGA_SETUP_DASHBOARD_DIR} && nvm install 8.11.3 && nvm use 8.11.3 && npm install > $DOWN_DIR/konga_install.log'" "cat $DOWN_DIR/konga_install.log | grep -o \"up to date\" | awk 'END{print NR}' | xargs -I {} [ {} -eq 1 ] && echo 1" "npm uninstall && rm -rf node_modules package-lock.json && rm -rf $NVM_DIR/versions/node/v8.11.3 && rm -rf $NVM_DIR/.cache"
    #国内镜像源无法安装完全，故先切换到官方源，再还原
    npm install -g nrm

    local TMP_KNGA_SETUP_NPM_NRM_REPO_CURRENT=`nrm current`
    nrm use npm
    npm install
    nrm use ${TMP_KNGA_SETUP_NPM_NRM_REPO_CURRENT}
    
	return $?
}

##########################################################################################################

# 3-设置软件
function conf_kong()
{
	local TMP_KNG_SETUP_DIR=${1}

	cd ${TMP_KNG_SETUP_DIR}
	
	local TMP_KNG_SETUP_LNK_ETC_DIR=${ATT_DIR}/kong
	local TMP_KNG_SETUP_LNK_GLOBAL_ETC_DIR=${TMP_KNG_SETUP_LNK_ETC_DIR}/global
	local TMP_KNG_SETUP_LNK_NGX_ETC_DIR=${TMP_KNG_SETUP_LNK_ETC_DIR}/nginx
	local TMP_KNG_SETUP_ETC_DIR=${TMP_KNG_SETUP_DIR}/etc

	# 替换原路径链接
    path_not_exists_create ${TMP_KNG_SETUP_LNK_ETC_DIR}
    mv .kong_env ${TMP_KNG_SETUP_LNK_ETC_DIR}/
    mv nginx*.conf ${TMP_KNG_SETUP_LNK_ETC_DIR}/
    ln -sf /etc/kong ${TMP_KNG_SETUP_LNK_GLOBAL_ETC_DIR}
    mv /usr/local/openresty/nginx/conf ${TMP_KNG_SETUP_LNK_NGX_ETC_DIR}
    
    ln -sf ${TMP_KNG_SETUP_LNK_ETC_DIR}/.kong_env `pwd`/.kong_env
    ln -sf ${TMP_KNG_SETUP_LNK_ETC_DIR}/nginx.conf `pwd`/nginx.conf
    ln -sf ${TMP_KNG_SETUP_LNK_ETC_DIR}/nginx-kong.conf `pwd`/nginx-kong.conf
    ln -sf ${TMP_KNG_SETUP_LNK_ETC_DIR}/nginx-kong-stream.conf `pwd`/nginx-kong-stream.conf
	ln -sf ${TMP_KNG_SETUP_LNK_ETC_DIR} ${TMP_KNG_SETUP_ETC_DIR}
    
	ln -sf ${TMP_KNG_SETUP_LNK_NGX_ETC_DIR} /usr/local/openresty/conf
	ln -sf ${TMP_KNG_SETUP_LNK_NGX_ETC_DIR} /usr/local/openresty/nginx/conf
	
    # 开始配置
    # -- 初始化数据库，并设置密码
	input_if_empty "TMP_KNG_SETUP_PSQL_HOST" "PostgresQL: Please ender the ${red}postgres host address${reset} for kong"
    set_if_equals "TMP_KNG_SETUP_PSQL_HOST" "LOCAL_HOST" "127.0.0.1"
	input_if_empty "TMP_KNG_SETUP_PSQL_PORT" "PostgresQL: Please ender the ${red}postgres port${reset} of '${TMP_KNG_SETUP_PSQL_HOST}' for kong"
	input_if_empty "TMP_KNG_SETUP_PSQL_USRNAME" "PostgresQL: Please ender the ${red}postgres user name${reset} of '${TMP_KNG_SETUP_PSQL_HOST}:${TMP_KNG_SETUP_PSQL_PORT}' for kong"
    
    local TMP_KNG_SETUP_PSQL_SELF_USRNAME="kong"
    local TMP_KNG_SETUP_PSQL_SELF_USRPWD="kng%DB!m${LOCAL_ID}_"
	input_if_empty "TMP_KNG_SETUP_PSQL_SELF_DATABASE" "Kong.PostgresQL: Please ender ${red}kong used database${reset} of '${TMP_KNG_SETUP_PSQL_HOST}:${TMP_KNG_SETUP_PSQL_PORT}'"
	input_if_empty "TMP_KNG_SETUP_PSQL_SELF_USRNAME" "Kong.PostgresQL: Please ender ${red}kong used user name${reset} of '${TMP_KNG_SETUP_PSQL_HOST}:${TMP_KNG_SETUP_PSQL_PORT}'"
	input_if_empty "TMP_KNG_SETUP_PSQL_SELF_USRPWD" "Kong.PostgresQL: Please ender ${red}kong used password${reset} of ${TMP_KNG_SETUP_PSQL_SELF_USRNAME}@${TMP_KNG_SETUP_PSQL_HOST}:${TMP_KNG_SETUP_PSQL_PORT}"

    # 创建初始DB
    psql -U ${TMP_KNG_SETUP_PSQL_USRNAME} -h ${TMP_KNG_SETUP_PSQL_HOST} -p ${TMP_KNG_SETUP_PSQL_PORT} -d postgres << EOF
    CREATE USER ${TMP_KNG_SETUP_PSQL_SELF_USRNAME} WITH PASSWORD '${TMP_KNG_SETUP_PSQL_SELF_USRPWD}'; 
    CREATE DATABASE ${TMP_KNG_SETUP_PSQL_SELF_DATABASE} OWNER ${TMP_KNG_SETUP_PSQL_SELF_USRNAME};
EOF

    # -- 迁移配置文件
    cp /etc/kong/kong.conf.default /etc/kong/kong.conf
    
    sed -i "s@^#log_level =.*@log_level = info@g" /etc/kong/kong.conf
    sed -i "s@^#proxy_listen =.*@proxy_listen = 0.0.0.0:80, 0.0.0.0:443 ssl@g" /etc/kong/kong.conf
    sed -i "s@^#admin_listen =.*@admin_listen = ${LOCAL_HOST}:${TMP_KNG_SETUP_API_HTTP_PORT}, ${LOCAL_HOST}:${TMP_KNG_SETUP_API_HTTPS_PORT} ssl@g" /etc/kong/kong.conf
    sed -i "s@^#real_ip_recursive =.*@real_ip_recursive = on@g" /etc/kong/kong.conf
    sed -i "s@^#client_max_body_size =.*@client_max_body_size = 20m@g" /etc/kong/kong.conf
    sed -i "s@^#client_body_buffer_size =.*@client_body_buffer_size = 64k@g" /etc/kong/kong.conf

    sed -i "s@^#database =@database =@g" /etc/kong/kong.conf
    sed -i "s@^#pg_host =.*@pg_host = $TMP_KNG_SETUP_PSQL_HOST@g" /etc/kong/kong.conf
    sed -i "s@^#pg_port =.*@pg_port = ${TMP_KNG_SETUP_PSQL_PORT}@g" /etc/kong/kong.conf
    sed -i "s@^#pg_user =.*@pg_user = ${TMP_KNG_SETUP_PSQL_SELF_USRNAME}@g" /etc/kong/kong.conf
    sed -i "s@^#pg_password =.*@pg_password = ${TMP_KNG_SETUP_PSQL_SELF_USRPWD}@g" /etc/kong/kong.conf
    sed -i "s@^#pg_database =.*@pg_database = ${TMP_KNG_SETUP_PSQL_SELF_DATABASE}@g" /etc/kong/kong.conf
    
    # -- 部分机器不识别/usr/local/bin下环境
    if [ ! -f "/usr/bin/kong" ]; then
        ln -sf /usr/local/bin/kong /usr/bin/kong
    fi

    kong migrations bootstrap

	input_if_empty "TMP_KNG_SETUP_CDY_API_HOST" "Kong.AutoHttps: Please ender ${red}auto https valid api host for kong${reset} of 'caddy'"
        
    # -- 添加kong-api的配置信息
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
    psql -U ${TMP_KNG_SETUP_PSQL_USRNAME} -h ${TMP_KNG_SETUP_PSQL_HOST} -p ${TMP_KNG_SETUP_PSQL_PORT} -d postgres << EOF
    \c ${TMP_KNG_SETUP_PSQL_SELF_DATABASE};
    \set kong_workspace_id '${TMP_KNG_SETUP_WORKSPACE_ID}'
    UPDATE workspaces set id=:'kong_workspace_id' WHERE name='default';
    INSERT INTO upstreams (id,created_at,name,hash_on,hash_fallback,hash_on_header,hash_fallback_header,hash_on_cookie,hash_on_cookie_path,slots,healthchecks,tags,ws_id) VALUES ('6b57ffb5-c2fb-4e4c-892f-7f77e7f688fb',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss'),'UPS-LCL-GATEWAY.KONG-API','none','none',NULL,NULL,NULL,'/',1000,'{"active": {"type": "http", "healthy": {"interval": 30, "successes": 1, "http_statuses": [200, 302]}, "timeout": 5, "http_path": "/", "https_sni": "localhost", "unhealthy": {"interval": 3, "timeouts": 0, "tcp_failures": 10, "http_failures": 10, "http_statuses": [429, 404, 500, 501, 502, 503, 504, 505]}, "concurrency": 10, "https_verify_certificate": true}, "passive": {"type": "http", "healthy": {"successes": 1, "http_statuses": [200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308]}, "unhealthy": {"timeouts": 0, "tcp_failures": 5, "http_failures": 0, "http_statuses": [429, 500, 503]}}}',NULL, :'kong_workspace_id');
    INSERT INTO targets (id,created_at,upstream_id,target,weight,tags,ws_id) VALUES ('d3a11b51-dc3c-414a-b320-95d360d56611',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss'),'6b57ffb5-c2fb-4e4c-892f-7f77e7f688fb','127.0.0.1:${TMP_KNG_SETUP_API_HTTP_PORT}',100,NULL, :'kong_workspace_id'); 
    
    INSERT INTO upstreams (id,created_at,name,hash_on,hash_fallback,hash_on_header,hash_fallback_header,hash_on_cookie,hash_on_cookie_path,slots,healthchecks,tags,ws_id) VALUES ('2d929958-f95d-5365-a997-055c26fd122d',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min','UPS-LCL-COROUTINES.CADDY-API','none','none',NULL,NULL,NULL,'/',1000,'{"active": {"type": "http", "healthy": {"interval": 30, "successes": 1, "http_statuses": [200, 302]}, "timeout": 5, "http_path": "/", "https_sni": "localhost", "unhealthy": {"interval": 3, "timeouts": 0, "tcp_failures": 10, "http_failures": 10, "http_statuses": [429, 404, 500, 501, 502, 503, 504, 505]}, "concurrency": 10, "https_verify_certificate": true}, "passive": {"type": "http", "healthy": {"successes": 1, "http_statuses": [200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308]}, "unhealthy": {"timeouts": 0, "tcp_failures": 5, "http_failures": 0, "http_statuses": [429, 500, 503]}}}',NULL, :'kong_workspace_id');
    INSERT INTO targets (id,created_at,upstream_id,target,weight,tags,ws_id) VALUES ('5055bc0a-bdd5-59cf-a5e6-c60f3b7d680c',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min','2d929958-f95d-5365-a997-055c26fd122d','${TMP_KNG_SETUP_CDY_API_HOST}:${TMP_KNG_SETUP_CDY_API_PORT}',100,NULL, :'kong_workspace_id'); 
    INSERT INTO upstreams (id,created_at,name,hash_on,hash_fallback,hash_on_header,hash_fallback_header,hash_on_cookie,hash_on_cookie_path,slots,healthchecks,tags,ws_id) VALUES ('9d68b631-2c02-5506-9e88-53e6d7975ea6',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '2 min','UPS-LCL-COROUTINES.CADDY_HTTPS_VLD','none','none',NULL,NULL,NULL,'/',1000,'{"active": {"type": "http", "healthy": {"interval": 30, "successes": 1, "http_statuses": [200, 302]}, "timeout": 5, "http_path": "/", "https_sni": "localhost", "unhealthy": {"interval": 3, "timeouts": 0, "tcp_failures": 10, "http_failures": 10, "http_statuses": [429, 404, 500, 501, 502, 503, 504, 505]}, "concurrency": 10, "https_verify_certificate": true}, "passive": {"type": "http", "healthy": {"successes": 1, "http_statuses": [200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308]}, "unhealthy": {"timeouts": 0, "tcp_failures": 5, "http_failures": 0, "http_statuses": [429, 500, 503]}}}',NULL, :'kong_workspace_id');
    INSERT INTO targets (id,created_at,upstream_id,target,weight,tags,ws_id) VALUES ('a5178e75-f6d7-59cf-bda8-290f892885ed',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '2 min','9d68b631-2c02-5506-9e88-53e6d7975ea6','${TMP_KNG_SETUP_CDY_API_HOST}:${TMP_KNG_SETUP_CDY_DFT_HTTP_PORT}',100,NULL, :'kong_workspace_id');
    INSERT INTO services (id, created_at, updated_at, name, retries, protocol, host, port, path, connect_timeout, write_timeout, read_timeout, ws_id) VALUES ('8253fa0c-e329-5670-9bde-5d63eba6a92c', '${LOCAL_TIME}', '${LOCAL_TIME}', 'SERVICE.CADDY_HTTPS_VLD', 5, 'http', 'UPS-LCL-COROUTINES.CADDY_HTTPS_VLD', '80', '/', 60000, 60000, 60000, :'kong_workspace_id');
    INSERT INTO routes (id,created_at,updated_at,service_id,protocols,methods,hosts,paths,regex_priority,strip_path,preserve_host,name,snis,sources,destinations,tags,headers,ws_id) VALUES ('bb232280-811e-5c51-9f66-f10089b15565','${LOCAL_TIME}','${LOCAL_TIME}','8253fa0c-e329-5670-9bde-5d63eba6a92c','{http}','{GET}','{}','{/.well-known}',0,false,true,'ROUTE.SERVICE.CADDY_HTTPS_VLD',NULL,NULL,NULL,NULL,'{"User-Agent": ["acme.zerossl.com/v2/DV90","Mozilla/5.0 (compatible; Let''s Encrypt validation server; +https://www.letsencrypt.org)"]}', :'kong_workspace_id');

    INSERT INTO upstreams (id,created_at,name,hash_on,hash_fallback,hash_on_header,hash_fallback_header,hash_on_cookie,hash_on_cookie_path,slots,healthchecks,tags,ws_id) VALUES ('0a79e2bc-6fc3-5d59-bbfa-cc733f836935',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '3 min','UPS-LCL-COROUTINES.WEBHOOK','none','none',NULL,NULL,NULL,'/',1000,'{"active": {"type": "http", "healthy": {"interval": 30, "successes": 1, "http_statuses": [200, 302]}, "timeout": 5, "http_path": "/", "https_sni": "localhost", "unhealthy": {"interval": 3, "timeouts": 0, "tcp_failures": 10, "http_failures": 10, "http_statuses": [429, 404, 500, 501, 502, 503, 504, 505]}, "concurrency": 10, "https_verify_certificate": true}, "passive": {"type": "http", "healthy": {"successes": 1, "http_statuses": [200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308]}, "unhealthy": {"timeouts": 0, "tcp_failures": 5, "http_failures": 0, "http_statuses": [429, 500, 503]}}}',NULL, :'kong_workspace_id');
    INSERT INTO targets (id,created_at,upstream_id,target,weight,tags,ws_id) VALUES ('07232e9f-f860-5659-afcd-cafb8580e6f6',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '3 min','0a79e2bc-6fc3-5d59-bbfa-cc733f836935','${TMP_KNG_SETUP_CDY_API_HOST}:${TMP_KNG_SETUP_CDY_BIND_WBH_API_PORT}',100,NULL, :'kong_workspace_id'); 
    INSERT INTO plugins (id, created_at, name, consumer_id, service_id, route_id, config, enabled, cache_key, protocols, tags, ws_id) VALUES ('58377e23-5dea-5aaa-9c0a-b056a80381dc', '${LOCAL_TIME}', 'http-log', NULL, NULL, 'bb232280-811e-5c51-9f66-f10089b15565', '{"method": "POST", "headers": null, "timeout": 10000, "keepalive": 60000, "queue_size": 1, "retry_count": 10, "content_type": "application/json", "flush_timeout": 2, "http_endpoint": "http://${TMP_KNG_SETUP_CDY_API_HOST}:${TMP_KNG_SETUP_CDY_BIND_WBH_API_PORT}/hooks/async-caddy-cert-to-kong", "custom_fields_by_lua": null}', true, 'plugins:http-log:bb232280-811e-5c51-9f66-f10089b15565::::e4b9993d-653f-44fd-acc5-338ce807582c', '{grpc,grpcs,http,https}', NULL, :'kong_workspace_id');
EOF

    # 重新更新时间，避免VLD优先级受影响
    LOCAL_TIME=`date +"%Y-%m-%d %H:%M:%S"`

	return $?
}

# 环境绑定openresty，作为附加安装
function rouse_openresty()
{
	local TMP_KNG_SETUP_DIR=${1}

    cd ${TMP_KNG_SETUP_DIR}

    # 先引用环境变量，调取信息
    source /etc/profile

    # 指向openresty到安装目录
	local TMP_KNG_SETUP_ORST_DIR=`dirname ${TMP_KNG_SETUP_DIR}`/openresty
    if [ ! -d "${TMP_KNG_SETUP_ORST_DIR}" ]; then
        ln -sf /usr/local/openresty ${TMP_KNG_SETUP_ORST_DIR}
    fi
    
    if [ -z "${OPENRESTY_HOME}" ] || [ ! -f "/usr/bin/openresty" ] || [ ! -f "/usr/local/bin/openresty" ]; then
        echo "OPENRESTY_HOME=${TMP_KNG_SETUP_ORST_DIR}" >> /etc/profile
	    echo 'PATH=$OPENRESTY_HOME/bin:$PATH' >> /etc/profile
    fi
    
    # 指向nginx到安装目录
	local TMP_KNG_SETUP_ORST_NGX_DIR=`dirname ${TMP_KNG_SETUP_DIR}`/nginx
    if [ ! -d "${TMP_KNG_SETUP_ORST_NGX_DIR}" ]; then
        ln -sf /usr/local/openresty/nginx ${TMP_KNG_SETUP_ORST_NGX_DIR}
    fi
    
    if [ -z "${NGINX_SBIN}" ] || [ ! -f "/usr/bin/nginx" ] || [ ! -f "/usr/local/bin/nginx" ]; then
        echo "NGINX_SBIN=${TMP_KNG_SETUP_ORST_NGX_DIR}/sbin" >> /etc/profile
	    echo 'PATH=$NGINX_SBIN:$PATH' >> /etc/profile
        
        # 修改默认nginx配置性能瓶颈问题
        local TMP_KNG_SETUP_ORST_NGX_CONF_PATH=${TMP_KNG_SETUP_ORST_NGX_DIR}/conf/nginx.conf
        
        # 备份初始文件
        mv ${TMP_KNG_SETUP_ORST_NGX_CONF_PATH} ${TMP_KNG_SETUP_ORST_NGX_CONF_PATH}.bak

        # 覆写优化配置(???相关参数待优化为按机器计算数值)
        sudo tee ${TMP_KNG_SETUP_ORST_NGX_CONF_PATH} <<-'EOF'
user  kong;
worker_processes  auto;

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
    #resolver 223.5.5.5 223.6.6.6;

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
        local TMP_KNG_SETUP_NGX_CONF_WORKER_RLIMIT_NOFILE=$(($(ulimit -n)/4))
        sed -i "s@^worker_rlimit_nofile.*@worker_rlimit_nofile ${TMP_KNG_SETUP_NGX_CONF_WORKER_RLIMIT_NOFILE};@g" ${TMP_KNG_SETUP_ORST_NGX_CONF_PATH}
    fi

    ##########################################################################################
    # 指向resty到环境变量
    if [ -z "${RESTY_BIN}" ] || [ ! -f "/usr/bin/resty" ] || [ ! -f "/usr/local/bin/resty" ]; then
        echo "RESTY_BIN=${TMP_KNG_SETUP_ORST_DIR}/bin" >> /etc/profile
	    echo 'PATH=$RESTY_BIN:$PATH' >> /etc/profile
    fi
    ##########################################################################################
    # 指向luajit到安装目录及环境变量    
	local TMP_KNG_SETUP_ORST_LJ_DIR=`dirname ${TMP_KNG_SETUP_DIR}`/luajit
    if [ ! -d "${TMP_KNG_SETUP_ORST_LJ_DIR}" ]; then
        ln -sf /usr/local/openresty/luajit ${TMP_KNG_SETUP_ORST_LJ_DIR}
    fi
    
    if [ -z "${LUAJIT_HOME}" ] || [ ! -f "/usr/bin/luajit" ] || [ ! -f "/usr/local/bin/luajit" ]; then
        echo "LUAJIT_HOME=${TMP_KNG_SETUP_ORST_LJ_DIR}" >> /etc/profile
        echo "LUALIB_HOME=${TMP_KNG_SETUP_ORST_DIR}/lualib" >> /etc/profile
        echo 'LUAJIT_LIB=${LUAJIT_HOME}/lib' >> /etc/profile
        echo 'LUAJIT_INC=${LUAJIT_HOME}/include/luajit-2.1' >> /etc/profile
	    echo 'PATH=$LUAJIT_HOME/bin:$PATH' >> /etc/profile
    fi
    ##########################################################################################
    
	echo 'export PATH' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

    openresty -v
    nginx -v
    resty -v
    luajit -v

	return $?
}

function conf_konga()
{
	local TMP_KNGA_SETUP_DIR=${1}

	cd ${TMP_KNGA_SETUP_DIR}
	
	local TMP_KNGA_SETUP_LNK_ETC_DIR=${ATT_DIR}/konga
	local TMP_KNGA_SETUP_ETC_DIR=${TMP_KNGA_SETUP_DIR}/etc

	# ①-N：不存在配置文件：
	rm -rf ${TMP_KNGA_SETUP_ETC_DIR}
	mkdir -pv ${TMP_KNGA_SETUP_LNK_ETC_DIR}
    cp .env_example ${TMP_KNGA_SETUP_LNK_ETC_DIR}/.env

	# 替换原路径链接（存在etc下时，不能作为软连接存在）
    ln -sf ${TMP_KNGA_SETUP_LNK_ETC_DIR}/.env `pwd`/.env
	ln -sf ${TMP_KNGA_SETUP_LNK_ETC_DIR} ${TMP_KNGA_SETUP_ETC_DIR}

	# 开始配置
    local TMP_KNGA_SETUP_DOMAIN="${LOCAL_IPV4}"
    local TMP_KNGA_SETUP_PSQL_HOST="${TMP_KNG_SETUP_PSQL_HOST}"
    local TMP_KNGA_SETUP_PSQL_PORT=${TMP_KNG_SETUP_PSQL_PORT}    
    local TMP_KNGA_SETUP_PSQL_USRNAME="${TMP_KNG_SETUP_PSQL_USRNAME}"

    local TMP_KNGA_SETUP_PSQL_SELF_DATABASE="konga"
    local TMP_KNGA_SETUP_PSQL_SELF_USRNAME="${TMP_KNGA_SETUP_PSQL_SELF_DATABASE}"
    local TMP_KNGA_SETUP_PSQL_SELF_USRPWD="knga%DB!m${LOCAL_ID}_"

    # 不在本机的情况下，需要输入地址
    local TMP_KNGA_SETUP_KNG_HOST="${LOCAL_HOST}"
    local TMP_KNGA_SETUP_IS_KONG_LOCAL=`lsof -i:${TMP_KNG_SETUP_API_HTTP_PORT}`
    if [ -z "${TMP_KNGA_SETUP_IS_KONG_LOCAL}" ]; then
    	input_if_empty "TMP_KNGA_SETUP_KNG_HOST" "KongA.Kong.Host: Please ender ${red}your kong host address${reset}"
    fi
    set_if_equals "TMP_KNGA_SETUP_KNG_HOST" "LOCAL_HOST" "127.0.0.1"

	input_if_empty "TMP_KNGA_SETUP_PSQL_HOST" "PostgresQL: Please ender the ${red}postgres host address${reset} for konga"
    set_if_equals "TMP_KNGA_SETUP_PSQL_HOST" "LOCAL_HOST" "127.0.0.1"
	input_if_empty "TMP_KNGA_SETUP_PSQL_PORT" "PostgresQL: Please ender the ${red}postgres port${reset} of '${TMP_KNGA_SETUP_PSQL_HOST}' for konga"
	input_if_empty "TMP_KNGA_SETUP_PSQL_USRNAME" "PostgresQL: Please ender the ${red}postgres user name${reset} of '${TMP_KNGA_SETUP_PSQL_HOST}:${TMP_KNGA_SETUP_PSQL_PORT}' for konga"
    
	input_if_empty "TMP_KNGA_SETUP_DOMAIN" "KongA.Web.Domain: Please ender ${red}kong dashboard web domain${reset}"
	input_if_empty "TMP_KNGA_SETUP_HTTP_PORT" "KongA.Web.Port: Please ender ${red}kong dashboard web local port${reset}, except '80'&'443'"
	input_if_empty "TMP_KNGA_SETUP_PSQL_SELF_DATABASE" "KongA.PostgreSql: Please ender ${red}kong dashboard database${reset} of '${TMP_KNGA_SETUP_PSQL_HOST}:${TMP_KNGA_SETUP_PSQL_PORT}'"
	input_if_empty "TMP_KNGA_SETUP_PSQL_SELF_USRNAME" "KongA.PostgreSql: Please ender ${red}kong dashboard user name${reset} of '${TMP_KNGA_SETUP_PSQL_HOST}:${TMP_KNGA_SETUP_PSQL_PORT}'"
	input_if_empty "TMP_KNGA_SETUP_PSQL_SELF_USRPWD" "KongA.PostgreSql: Please ender ${red}kong dashboard password${reset} of $TMP_KNGA_SETUP_PSQL_SELF_USRNAME@${TMP_KNGA_SETUP_PSQL_HOST}:${TMP_KNGA_SETUP_PSQL_PORT}"

    #初始化配置
    local TMP_KONGA_TOKEN_SECURITY=`cat /proc/sys/kernel/random/uuid`
    #sed -i "/^KONGA_HOOK_TIMEOUT/d" .env
    sed -i "s@^PORT=.*@PORT=${TMP_KNGA_SETUP_HTTP_PORT}@g" .env
    # 解决 api-health-checks 健康检查超时问题
    sed -i "s@^KONGA_HOOK_TIMEOUT=.*@KONGA_HOOK_TIMEOUT=180000@g" .env
    sed -i "s@^DB_URI=.*@DB_URI=postgresql://${TMP_KNGA_SETUP_PSQL_SELF_USRNAME}\@${TMP_KNGA_SETUP_PSQL_HOST}:${TMP_KNGA_SETUP_PSQL_PORT}/${TMP_KNGA_SETUP_PSQL_SELF_DATABASE}@g" .env
    echo "DB_HOST=${TMP_KNGA_SETUP_PSQL_HOST}" >> .env
    echo "DB_USER=${TMP_KNGA_SETUP_PSQL_SELF_USRNAME}" >> .env
    echo "DB_PASSWORD=${TMP_KNGA_SETUP_PSQL_SELF_USRPWD}" >> .env
    echo "DB_DATABASE=${TMP_KNGA_SETUP_PSQL_SELF_DATABASE}" >> .env
    sed -i "s@^KONGA_LOG_LEVEL=.*@KONGA_LOG_LEVEL=info@g" .env
    sed -i "s@^TOKEN_SECRET=.*@TOKEN_SECRET=${TMP_KONGA_TOKEN_SECURITY}@g" .env
    sed -i "s@secret:.*@secret: 'extremely-secure-keyboard-cat'@g" config/session.js

    #数据库初始化
    psql -U ${TMP_KNGA_SETUP_PSQL_USRNAME} -h ${TMP_KNGA_SETUP_PSQL_HOST} -p ${TMP_KNGA_SETUP_PSQL_PORT} -d postgres << EOF
    CREATE USER ${TMP_KNGA_SETUP_PSQL_SELF_USRNAME} WITH PASSWORD '${TMP_KNGA_SETUP_PSQL_SELF_USRPWD}'; 
    CREATE DATABASE ${TMP_KNGA_SETUP_PSQL_SELF_DATABASE} OWNER ${TMP_KNGA_SETUP_PSQL_SELF_USRNAME};
    GRANT ALL PRIVILEGES ON DATABASE ${TMP_KNGA_SETUP_PSQL_SELF_DATABASE} TO ${TMP_KNGA_SETUP_PSQL_SELF_USRNAME};
EOF

    # 解决sails.config.pubsub._hookTimeout 引发超时连接问题 config/pubsub.js，config/orm.js
    sed -i "s@_hookTimeout: .*@_hookTimeout: 999999@g" config/orm.js
    sed -i "s@_hookTimeout: .*@_hookTimeout: 999999@g" config/pubsub.js
    node ./bin/konga.js prepare  #不能加sudo

    local TMP_KNGA_SETUP_PSQL_KNG_DATABASE="${TMP_KNG_SETUP_PSQL_SELF_DATABASE}"
	input_if_empty "TMP_KNGA_SETUP_PSQL_KNG_DATABASE" "KongA.Kong: Please sure ${red}kong database name ${reset} of '${TMP_KNGA_SETUP_PSQL_HOST}:${TMP_KNGA_SETUP_PSQL_PORT}'"

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
    psql -U ${TMP_KNGA_SETUP_PSQL_USRNAME} -h ${TMP_KNGA_SETUP_PSQL_HOST} -p ${TMP_KNGA_SETUP_PSQL_PORT} -d postgres << EOF
    \c ${TMP_KNGA_SETUP_PSQL_SELF_DATABASE};
    INSERT INTO konga_kong_nodes (id,"name","type",kong_admin_url,netdata_url,kong_api_key,jwt_algorithm,jwt_key,jwt_secret,kong_version,health_checks,health_check_details,active,"createdAt","updatedAt","createdUserId","updatedUserId") VALUES (1,'CONNECTION.KONG.LOCAL.$SYS_IP_CONNECT','default','http://${TMP_KNGA_SETUP_KNG_HOST}:${TMP_KNG_SETUP_API_HTTP_PORT}',NULL,'','HS256',NULL,NULL,'2.x.0',true,NULL,true,'${LOCAL_TIME}','${LOCAL_TIME}',1,1);
    UPDATE konga_settings SET "data"='{"signup_enable":false,"signup_require_activation":true,"info_polling_interval":1000,"email_default_sender_name":"Kong Net-Gateway","email_default_sender":"kong@gateway.com","email_notifications":false,"default_transport":"sendmail","notify_when":{"node_down":{"title":"A node is down or unresponsive","description":"Health checks must be enabled for the nodes that need to be monitored.","active":true},"api_down":{"title":"An API is down or unresponsive","description":"Health checks must be enabled for the APIs that need to be monitored.","active":true}},"user_permissions":{"apis":{"create":false,"read":true,"update":false,"delete":false},"services":{"create":false,"read":true,"update":false,"delete":false},"routes":{"create":false,"read":true,"update":false,"delete":false},"consumers":{"create":false,"read":true,"update":false,"delete":false},"plugins":{"create":false,"read":true,"update":false,"delete":false},"upstreams":{"create":false,"read":true,"update":false,"delete":false},"certificates":{"create":false,"read":true,"update":false,"delete":false},"connections":{"create":false,"read":false,"update":false,"delete":false},"users":{"create":false,"read":false,"update":false,"delete":false}},"baseUrl":"https://${TMP_KNGA_SETUP_DOMAIN}","integrations":[{"id":"slack","name":"Slack","image":"slack_rgb.png","config":{"enabled":true,"fields":[{"id":"slack_webhook_url","name":"Slack Webhook URL","type":"text","required":true,"value":"https://hooks.slack.com/services/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"}],"slack_webhook_url":""}}]}' where id = 1;
    INSERT INTO konga_kong_snapshot_schedules (id,"connection",active,cron,"lastRunAt","createdAt","updatedAt","createdUserId","updatedUserId") VALUES (1,1,true,'* 1 * * *',NULL,'${LOCAL_TIME}','${LOCAL_TIME}',1,1);
    INSERT INTO konga_kong_upstream_alerts (id,upstream_id,"connection",email,slack,cron,active,"data","createdAt","updatedAt","createdUserId","updatedUserId") VALUES (1,'6b57ffb5-c2fb-4e4c-892f-7f77e7f688fb',1,true,true,NULL,true,NULL,to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min',NULL,NULL);
    INSERT INTO konga_kong_upstream_alerts (id,upstream_id,"connection",email,slack,cron,active,"data","createdAt","updatedAt","createdUserId","updatedUserId") VALUES (2,'2d929958-f95d-5365-a997-055c26fd122d',1,true,true,NULL,false,NULL,to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '2 min',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '2 min',NULL,NULL);
    INSERT INTO konga_kong_upstream_alerts (id,upstream_id,"connection",email,slack,cron,active,"data","createdAt","updatedAt","createdUserId","updatedUserId") VALUES (3,'c4f6b96c-2ccd-49ba-a76f-a05d93dde1f1',1,true,true,NULL,true,NULL,to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '3 min',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '3 min',NULL,NULL);
    INSERT INTO konga_kong_upstream_alerts (id,upstream_id,"connection",email,slack,cron,active,"data","createdAt","updatedAt","createdUserId","updatedUserId") VALUES (4,'0a79e2bc-6fc3-5d59-bbfa-cc733f836935',1,true,true,NULL,false,NULL,to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '4 min',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '4 min',NULL,NULL);
    
    \c ${TMP_KNGA_SETUP_PSQL_KNG_DATABASE};
    \set kong_workspace_id '${TMP_KNGA_SETUP_WORKSPACE_ID}'
    INSERT INTO upstreams (id,created_at,name,hash_on,hash_fallback,hash_on_header,hash_fallback_header,hash_on_cookie,hash_on_cookie_path,slots,healthchecks,tags,ws_id) VALUES ('c4f6b96c-2ccd-49ba-a76f-a05d93dde1f1',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '4 min','UPS-LCL-GATEWAY.KONGA','none','none',NULL,NULL,NULL,'/',1000,'{"active": {"type": "http", "healthy": {"interval": 30, "successes": 1, "http_statuses": [200, 302]}, "timeout": 5, "http_path": "/", "https_sni": "localhost", "unhealthy": {"interval": 3, "timeouts": 0, "tcp_failures": 10, "http_failures": 10, "http_statuses": [429, 404, 500, 501, 502, 503, 504, 505]}, "concurrency": 10, "https_verify_certificate": true}, "passive": {"type": "http", "healthy": {"successes": 1, "http_statuses": [200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308]}, "unhealthy": {"timeouts": 0, "tcp_failures": 5, "http_failures": 0, "http_statuses": [429, 500, 503]}}}',NULL, :'kong_workspace_id');
    INSERT INTO targets (id,created_at,upstream_id,target,weight,tags,ws_id) VALUES ('941a9b3e-72a0-4b32-854d-a3e282b33711',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '4 min','c4f6b96c-2ccd-49ba-a76f-a05d93dde1f1','127.0.0.1:${TMP_KNGA_SETUP_HTTP_PORT}',100,NULL, :'kong_workspace_id');
    INSERT INTO services (id, created_at, updated_at, name, retries, protocol, host, port, path, connect_timeout, write_timeout, read_timeout, ws_id) VALUES ('a45c36b6-ab85-47ad-ad20-022d03ff6996', to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min', to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min', 'SERVICE.KONGA', 5, 'http', 'UPS-LCL-GATEWAY.KONGA', '80', '/', 60000, 60000, 60000, :'kong_workspace_id');
    INSERT INTO routes (id,created_at,updated_at,service_id,protocols,methods,hosts,paths,regex_priority,strip_path,preserve_host,name,snis,sources,destinations,tags,ws_id) VALUES ('c834f616-4583-4bab-b3c5-10456ebd7441',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min',to_timestamp('${LOCAL_TIME}', 'yyyy-MM-dd hh24:mi:ss') + INTERVAL '1 min','a45c36b6-ab85-47ad-ad20-022d03ff6996','{https}','{}','{${TMP_KNGA_SETUP_DOMAIN}}','{/}',0,true,false,'ROUTE.SERVICE.KONGA',NULL,NULL,NULL,NULL, :'kong_workspace_id');
EOF

    # 本地存在Kong，则直接命令重启。不存在则提醒重启。
    if [ -z "${TMP_KNGA_SETUP_IS_KONG_LOCAL}" ]; then
        echo "KongA.Notice: Please ender ${red}kong reload${reset} in your kong host address of '${red}${TMP_KNGA_SETUP_KNG_HOST}${reset}'"
        read -n 1 -p "Press <Enter> go on，When u restart your kong server..."
    else
        kong stop
        kong start
        kong health
    fi

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_kong()
{
	local TMP_KNG_SETUP_DIR=${1}

	cd ${TMP_KNG_SETUP_DIR}
	
	# 验证安装
    kong version  # lsof -i:${TMP_KNG_SETUP_API_HTTP_PORT}

	# 当前启动命令
	nohup kong start > logs/boot.log 2>&1 &

    # 等待启动
    echo "Starting kong，Waiting for a moment"
    echo "--------------------------------------------"
    sleep 10

	kong health
    echo "--------------------------------------------"

	# 添加系统启动命令（RPM还是需要）
    echo_startup_config "kong" "${TMP_KNG_SETUP_DIR}" "kong start" "" "100"

	# 授权iptables端口访问
	echo_soft_port 80
	echo_soft_port 443
	echo_soft_port ${TMP_KNG_SETUP_API_HTTP_PORT} "${LOCAL_HOST}"
	echo_soft_port ${TMP_KNG_SETUP_API_HTTPS_PORT} "${LOCAL_HOST}"

	return $?
}

# 4-启动软件
function boot_konga()
{
	local TMP_KNGA_SETUP_DIR=${1}

	cd ${TMP_KNGA_SETUP_DIR}
	
	# # 验证安装
    # bin/konga -v

	# 当前启动命令
    nohup npm run bower-deps && npm run production > logs/boot.log 2>&1 &
	
    # 等待启动
    echo "Starting konga，Waiting for a moment"
    echo "--------------------------------------------"
    sleep 15

    cat logs/boot.log
    echo "--------------------------------------------"

	# 启动状态检测
	lsof -i:${TMP_KNGA_SETUP_HTTP_PORT}

	# 添加系统启动命令(???重启会被默认的高级版本覆盖从而无法启动)
    local TMP_KNGA_SETUP_NPM_PATH=`npm config get prefix`
    # echo_startup_config "konga" "${TMP_KNGA_SETUP_DIR}" "nvm use lts/erbium && npm run production" "${TMP_KNGA_SETUP_NPM_PATH}/bin" "999" "${NVM_PATH}"
    echo_startup_config "konga" "${TMP_KNGA_SETUP_DIR}" "npm run production" "${TMP_KNGA_SETUP_NPM_PATH}/bin" "999" "${NVM_PATH}"
		
	# 授权iptables端口访问
	echo_soft_port ${TMP_KNGA_SETUP_HTTP_PORT}

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_kong()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_kong()
{
	cd ${__DIR}
	
    source scripts/web/openresty_frame.sh

	return $?
}

# 下载驱动/插件
function down_plugin_konga()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_konga()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_kong()
{
	local TMP_KNG_SETUP_DIR=${SETUP_DIR}/kong
    
	set_env_kong "${TMP_KNG_SETUP_DIR}"

	setup_kong "${TMP_KNG_SETUP_DIR}"

	conf_kong "${TMP_KNG_SETUP_DIR}"
    
    rouse_openresty "${TMP_KNG_SETUP_DIR}"

    setup_plugin_kong "${TMP_KNG_SETUP_DIR}"

	boot_kong "${TMP_KNG_SETUP_DIR}"

	return $?
}

function exec_step_konga()
{
	local TMP_KNGA_SETUP_DIR=${1}
	local TMP_KNGA_CURRENT_DIR=`pwd`
    
	set_env_konga "${TMP_KNGA_SETUP_DIR}"

	setup_konga "${TMP_KNGA_SETUP_DIR}" "${TMP_KNGA_CURRENT_DIR}"

	conf_konga "${TMP_KNGA_SETUP_DIR}"

    # down_plugin_konga "${TMP_KNGA_SETUP_DIR}"

	boot_konga "${TMP_KNGA_SETUP_DIR}"

	return $?
}

##########################################################################################################

# x1-下载软件
function check_setup_kong()
{
	soft_yum_check_action "kong" "exec_step_kong" "Kong was installed"

	return $?
}

function down_konga()
{
    setup_soft_git "konga" "https://github.com/pantsel/konga" "exec_step_konga"

	return $?
}

function check_setup_konga()
{
	setup_soft_basic "KongA" "down_konga"

	return $?
}

##########################################################################################################

#安装主体
exec_if_choice "TMP_KNG_SETUP_CHOICE" "Please choice which kong compoment you want to setup" "...,Kong,KongA,Exit" "${TMP_SPLITER}" "check_setup_"