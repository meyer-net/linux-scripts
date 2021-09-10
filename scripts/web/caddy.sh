#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 相关参考：
#		  
#------------------------------------------------
# 备注：
#      本caddy安装，全程辅助kong做自动https证书使用，不独立占用80,443
# 	   AutoHttps：PSql -> Kong -> KongA -> Caddy -> Frp -> 解析 -> Webhook
# 相关：
#      curl -s https://getcaddy.com | bash -s personal

#      mkdir -pv /logs/caddy
#      sudo chown -R caddy:caddy /logs/caddy
#      https://3mile.github.io/archives/2018/07/21/
#      https://dengxiaolong.com/caddy/zh/http.proxy.html

#------------------------------------------------
#      https://caddyserver.com/docs/install#fedora-redhat-centos
#      https://www.noip.com/support/knowledgebase/installing-the-linux-dynamic-update-client/
#------------------------------------------------
local TMP_CDY_SETUP_API_PORT=12019
local TMP_CDY_SETUP_HTTP_PORT=80
local TMP_CDY_SETUP_HTTPS_PORT=443

local TMP_CDY_SETUP_DIR=${SETUP_DIR}/caddy
local TMP_CDY_LNK_ETC_DIR=${ATT_DIR}/caddy
local TMP_CDY_LNK_LOGS_DIR=${LOGS_DIR}/caddy
local TMP_CDY_LNK_DATA_DIR=${DATA_DIR}/caddy
local TMP_CDY_LOGS_DIR=${TMP_CDY_SETUP_DIR}/logs
local TMP_CDY_DATA_DIR=${TMP_CDY_SETUP_DIR}/data

##########################################################################################################

# 1-配置环境
function set_env_caddy()
{
    cd ${__DIR}

    soft_yum_check_setup "yum-plugin-copr"
	
	# 默认80端口被占用的情况，则修改端口
	# 如果配合Kong的话，优先安装Kong再装Caddy
    local TMP_IS_CDY_HTTP_OCCUPY=`lsof -i:${TMP_CDY_SETUP_HTTP_PORT}`
    local TMP_IS_CDY_HTTPS_OCCUPY=`lsof -i:${TMP_CDY_SETUP_HTTPS_PORT}`
    if [ -n "${TMP_IS_CDY_HTTP_OCCUPY}" ]; then 
    	TMP_CDY_SETUP_HTTP_PORT=60080
		echo "Caddy：Port '${green}80${reset}' for http occupied，change to '${red}${TMP_CDY_SETUP_HTTP_PORT}${reset}'"
	fi

	echo

    if [ -n "${TMP_IS_CDY_HTTPS_OCCUPY}" ]; then 
    	TMP_CDY_SETUP_HTTPS_PORT=60443
		echo "Caddy：Port '${green}443${reset}' for https occupied，change to '${red}${TMP_CDY_SETUP_HTTPS_PORT}${reset}'"
	fi
		
	return $?
}

##########################################################################################################

# 2-安装软件
function setup_caddy()
{
	local TMP_CDY_SETUP_DIR=${1}

	## 源模式
    sudo yum -y copr enable @caddy/caddy

	soft_yum_check_setup "caddy"

	# 创建日志软链
	local TMP_CDY_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/caddy
	local TMP_CDY_SETUP_LNK_DATA_DIR=${DATA_DIR}/caddy
	local TMP_CDY_SETUP_LOGS_DIR=${TMP_CDY_SETUP_DIR}/logs
	local TMP_CDY_SETUP_DATA_DIR=${TMP_CDY_SETUP_DIR}/data

	# 先清理文件，再创建文件
	path_not_exists_create ${TMP_CDY_SETUP_DIR}
	rm -rf ${TMP_CDY_SETUP_LOGS_DIR}
	rm -rf ${TMP_CDY_SETUP_DATA_DIR}
	mkdir -pv ${TMP_CDY_SETUP_LNK_LOGS_DIR}
	# mv /var/log/caddy ${TMP_CDY_SETUP_LNK_LOGS_DIR}
	if [ ! -d "/var/lib/caddy" ]; then
    	mkdir -pv ${TMP_CDY_SETUP_LNK_DATA_DIR}
    else
		cp /var/lib/caddy ${TMP_CDY_SETUP_LNK_DATA_DIR} -Rp
		mv /var/lib/caddy ${TMP_CDY_SETUP_LNK_DATA_DIR}_empty
    fi

	ln -sf ${TMP_CDY_SETUP_LNK_LOGS_DIR} ${TMP_CDY_SETUP_LOGS_DIR}
	ln -sf ${TMP_CDY_SETUP_LNK_DATA_DIR} ${TMP_CDY_SETUP_DATA_DIR}
	ln -sf ${TMP_CDY_SETUP_LNK_DATA_DIR} /var/lib/caddy

	# 授权权限，否则无法写入
	create_user_if_not_exists caddy caddy
	chgrp -R caddy ${TMP_CDY_SETUP_LNK_LOGS_DIR}
	chgrp -R caddy ${TMP_CDY_SETUP_LNK_DATA_DIR}
	chown -R caddy:caddy ${TMP_CDY_SETUP_LNK_LOGS_DIR}
	chown -R caddy:caddy ${TMP_CDY_SETUP_LNK_DATA_DIR}
	
    # 安装初始
    # 创建源码目录
    path_not_exists_create "${HTML_DIR}"

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_caddy()
{
	local TMP_CDY_SETUP_DIR=${1}

	cd ${TMP_CDY_SETUP_DIR}
	
	local TMP_CDY_SETUP_LNK_ETC_DIR=${ATT_DIR}/caddy
	local TMP_CDY_SETUP_ETC_DIR=${TMP_CDY_SETUP_DIR}/etc

	# 替换原路径链接
    ln -sf /etc/caddy ${TMP_CDY_SETUP_LNK_ETC_DIR} 
    ln -sf /etc/caddy ${TMP_CDY_SETUP_ETC_DIR} 
	
    # 开始配置
    echo "------------------------------------------------------------------"
    # EOF使用单引号则禁用变量，实际有了json此处就被禁用了
    sudo tee /etc/caddy/Caddyfile <<-EOF
# The Caddyfile is an easy way to configure your Caddy web server.
#
# Unless the file starts with a global options block, the first
# uncommented line is always the address of your site.
#
# To use your own domain name (with automatic HTTPS), first make
# sure your domain's A/AAAA DNS records are properly pointed to
# this machine's public IP, then replace ":80" below with your
# domain name.
# example：
#         https://caddyserver.com/docs/caddyfile/options

{
    http_port  ${TMP_CDY_SETUP_HTTP_PORT}
    https_port ${TMP_CDY_SETUP_HTTPS_PORT}

    log {
        output file ${TMP_CDY_LOGS_DIR}/access.log {
            roll_size 128mb
            roll_keep 90
            roll_keep_for 24h
        }
    }
}

#:${TMP_CDY_SETUP_HTTP_PORT},:${TMP_CDY_SETUP_HTTPS_PORT} {
    # Set this path to your site's directory.
    # root * /usr/share/caddy

    # Enable the static file server.
    # file_server

    # Another common task is to set up a reverse proxy:
    # reverse_proxy localhost:8080

#   respond "Welcome to my security site!"

    # Or serve a PHP site through php-fpm:
    # php_fastcgi localhost:9000
#}

# Refer to the Caddy docs for more information:
# https://caddyserver.com/docs/caddyfile
EOF
    echo "------------------------------------------------------------------"

	return $?
}

function reconf_caddy()
{
	local TMP_CDY_SETUP_DIR=${1}

	cd ${TMP_CDY_SETUP_DIR}/etc

    echo "------------------------------------------------------------------"
	# listen这里修改内网IP的情况下是要变更的
	sudo tee Caddyfile.init.json <<-EOF
{
	"admin": {
		"listen": "${LOCAL_HOST}:${TMP_CDY_SETUP_API_PORT}"
	},
	"apps": {
		"http": {
			"http_port": ${TMP_CDY_SETUP_HTTP_PORT},
			"https_port": ${TMP_CDY_SETUP_HTTPS_PORT},
			"servers": {
				"autohttps": {
					"listen": [":${TMP_CDY_SETUP_HTTP_PORT}",":${TMP_CDY_SETUP_HTTPS_PORT}"],
					"routes": [],
					"logs": {
						"default_logger_name": "autohttps.log",
						"logger_names": {}
					}
				}
			}
		}
	},
	"logging": {
		"logs": {
			"default": {
				"writer": {
					"filename": "${TMP_CDY_LOGS_DIR}/caddy.log",
					"output": "file",
					"roll_keep": 90,
					"roll_keep_days": 1,
					"roll_size_mb": 128
				}
			}
		}
	}
}
EOF
    echo "------------------------------------------------------------------"

    curl localhost:2019/load -X POST -H "Content-Type: application/json" -d @Caddyfile.init.json

	mv /etc/caddy/Caddyfile /etc/caddy/Caddyfile.init.invalid
	mv Caddyfile.init.json Caddyfile.init.json.invalid

	ln -sf ${TMP_CDY_SETUP_DIR}/data/.config/caddy/autosave.json /etc/caddy/Caddyfile.autosave.json

	# 修改启动配置文件，避免服务重启配置丢失
	sed -i "s@/etc/caddy/Caddyfile@/etc/caddy/Caddyfile.autosave.json@g" /usr/lib/systemd/system/caddy.service
	
    sudo systemctl daemon-reload

	return $?
}

# 添加自动https配置
# 参考：https://caddyserver.com/docs/json
function increase_auto_https_conf()
{
    local TMP_CDY_SETUP_CONF_VLD_BIND_DOMAIN=${1:-"localhost"}

    cd ${TMP_CDY_DATA_DIR}

    echo "----------------------------------------------------------------"
	sudo tee Caddyroute_for_${TMP_CDY_SETUP_CONF_VLD_BIND_DOMAIN}.json <<-EOF
	{
		"match": [
			{
				"host": ["${TMP_CDY_SETUP_CONF_VLD_BIND_DOMAIN}"]
			}
		],
		"handle": [
			{
				"handler": "static_response",
				"body": "Welcome to my security site of '${TMP_CDY_SETUP_CONF_VLD_BIND_DOMAIN}'!"
			}
		],
		"terminal": true
	}
EOF

    curl localhost:${TMP_CDY_SETUP_API_PORT}/config/apps/http/servers/autohttps/routes -X POST -H "Content-Type: application/json" -d @Caddyroute_for_${TMP_CDY_SETUP_CONF_VLD_BIND_DOMAIN}.json
	curl localhost:${TMP_CDY_SETUP_API_PORT}/config/apps/http/servers/autohttps/logs/logger_names -X POST -H "Content-Type: application/json" -d '{"${TMP_CDY_SETUP_CONF_VLD_BIND_DOMAIN}": "${TMP_CDY_SETUP_CONF_VLD_BIND_DOMAIN}"}'

    echo "----------------------------------------------------------------"

    return $?
}

function conf_konga_auto_https()
{
    local TMP_CDY_SETUP_CONF_VLD_KONGA_BIND_DOMAIN="${LOCAL_IPV4}"
    
	input_if_empty "TMP_CDY_SETUP_CONF_VLD_KONGA_BIND_DOMAIN" "Caddy.KongA.Domain: Please ender auto https ${red}konga web domain${reset}"

    increase_auto_https_conf "${TMP_CDY_SETUP_CONF_VLD_KONGA_BIND_DOMAIN}"

    return $?
}

##########################################################################################################

# 4-启动软件
function boot_caddy()
{
	local TMP_CDY_SETUP_DIR=${1}

	cd ${TMP_CDY_SETUP_DIR}
	
	# 验证安装
    caddy version  # lsof -i:${TMP_CDY_SETUP_API_PORT}

	# 当前启动命令
    sudo systemctl daemon-reload
    sudo systemctl enable caddy.service

    # 等待启动
    echo "Starting caddy，Waiting for a moment"
    echo "--------------------------------------------"
    sudo systemctl start caddy.service
    sleep 5

	sudo systemctl status caddy.service
    sudo chkconfig caddy on
    # journalctl -u caddy --no-pager | less
    # sudo systemctl reload caddy.service
    echo "--------------------------------------------"

	# 授权iptables端口访问
	echo_soft_port ${TMP_CDY_SETUP_API_PORT}
	echo_soft_port ${TMP_CDY_SETUP_HTTP_PORT}
	echo_soft_port ${TMP_CDY_SETUP_HTTPS_PORT}

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_caddy()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_caddy()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_caddy()
{
	local TMP_CDY_SETUP_DIR=${SETUP_DIR}/caddy
    
	set_env_caddy "${TMP_CDY_SETUP_DIR}"

	setup_caddy "${TMP_CDY_SETUP_DIR}"

	conf_caddy "${TMP_CDY_SETUP_DIR}"

    # down_plugin_caddy "${TMP_CDY_SETUP_DIR}"

	boot_caddy "${TMP_CDY_SETUP_DIR}"

	reconf_caddy "${TMP_CDY_SETUP_DIR}"
	
    exec_yn_action "conf_konga_auto_https" "Caddy：Please sure you want to need ${red}configure auto https for konga${reset}"
	
	# 开放API出去，必装
    # cd ${__DIR}
    # source scripts/web/webhook.sh

	return $?
}

##########################################################################################################

# x1-下载软件
function check_setup_caddy()
{
    soft_yum_check_action "caddy" "exec_step_caddy" "Caddy was installed"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "Caddy" "check_setup_caddy"

