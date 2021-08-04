#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 安装标题：Caddy
# 软件名称：caddy
# 软件大写名称：CADDY
# 软件大写分组与简称：CDY
# 软件安装名称：caddy
# 软件授权用户名称&组：caddy/caddy_group
#------------------------------------------------
# 备注：
#      本caddy安装，全程辅助kong做自动https证书使用，不独立占用80,443
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
local TMP_CDY_SETUP_DIR=${SETUP_DIR}/caddy
local TMP_CDY_LNK_ETC_DIR=${ATT_DIR}/caddy
local TMP_CDY_LNK_LOGS_DIR=${LOGS_DIR}/caddy
local TMP_CDY_LNK_DATA_DIR=${DATA_DIR}/caddy
local TMP_CDY_LOGS_DIR=${TMP_CDY_SETUP_DIR}/logs
local TMP_CDY_DATA_DIR=${TMP_CDY_SETUP_DIR}/data

# 1-配置环境
function set_environment()
{
    cd ${__DIR}

    soft_yum_check_setup "yum-plugin-copr"

	return $?
}

# 2-安装软件
function setup_caddy()
{
    sudo yum -y copr enable @caddy/caddy
	sudo yum -y install caddy

    mkdir -pv ${TMP_CDY_SETUP_DIR}

	# 先清理文件，再创建文件
	rm -rf ${TMP_CDY_LOGS_DIR}
	rm -rf ${TMP_CDY_DATA_DIR}
	mkdir -pv ${TMP_CDY_LNK_LOGS_DIR}

    if [ ! -d "/var/lib/caddy" ]; then
    	mkdir -pv ${TMP_CDY_LNK_DATA_DIR}
	    chown -R caddy:caddy ${TMP_CDY_LNK_DATA_DIR}
    else
        mv /var/lib/caddy ${TMP_CDY_LNK_DATA_DIR}
    fi

    mv /etc/caddy ${TMP_CDY_LNK_ETC_DIR}

	# 环境变量或软连接
    ln -sf ${TMP_CDY_LNK_ETC_DIR} /etc/caddy
	ln -sf ${TMP_CDY_LNK_LOGS_DIR} ${TMP_CDY_LOGS_DIR}
	ln -sf ${TMP_CDY_LNK_DATA_DIR} /var/lib/caddy
	ln -sf ${TMP_CDY_LNK_DATA_DIR} ${TMP_CDY_DATA_DIR}

	# 授权权限，否则无法写入
	chown -R caddy:caddy ${TMP_CDY_LNK_LOGS_DIR}

	return $?
}

# 3-设置软件
function conf_caddy()
{
    echo "------------------------------------------------------------------"
    # EOF使用单引号则禁用变量，实际有了json此处就被禁用了
    sudo tee ${TMP_CDY_LNK_ETC_DIR}/Caddyfile <<-EOF
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
    http_port  60080
    https_port 60443

    log {
        output file ${TMP_CDY_LOGS_DIR}/access.log {
            roll_size 128mb
            roll_keep 90
            roll_keep_for 24h
        }
    }
}

#:60080,:60443 {
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

# 4-启动软件
function boot_caddy()
{
	cd ${TMP_CDY_SETUP_DIR}
	
    sudo systemctl daemon-reload
    sudo systemctl enable caddy
    sudo systemctl start caddy
    sudo systemctl status caddy
    #journalctl -u caddy --no-pager | less
    #sudo systemctl reload caddy

    exec_yn_action "conf_kong_dashboard_auto_https" "Please sure you want to need ${red}configure auto https for konga${reset}"

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

# 添加自动https配置
# 参考：https://caddyserver.com/docs/json
function increase_auto_https_conf()
{
    local TMP_SETUP_CDD_CONF_VLD_BIND_DOMAIN=${1:-"localhost"}

    cd ${TMP_CDY_DATA_DIR}

    echo "----------------------------------------------------------------"
sudo tee Caddyfile.json <<-EOF
{
	"apps": {
		"http": {
			"http_port": 60080,
			"https_port": 60443,
			"servers": {
				"autohttps": {
					"listen": [":60080",":60443"],
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
    echo "----------------------------------------------------------------"

    curl localhost:2019/load -X POST -H "Content-Type: application/json" -d @Caddyfile.json

    echo "----------------------------------------------------------------"
sudo tee Caddyroute_for_${TMP_SETUP_CDD_CONF_VLD_BIND_DOMAIN}.json <<-EOF
	{
		"match": [
			{
				"host": ["${TMP_SETUP_CDD_CONF_VLD_BIND_DOMAIN}"]
			}
		],
		"handle": [
			{
				"handler": "static_response",
				"body": "Welcome to my security site of '${TMP_SETUP_CDD_CONF_VLD_BIND_DOMAIN}'!"
			}
		],
		"terminal": true
	}
EOF

    curl localhost:2019/config/apps/http/servers/autohttps/routes -X POST -H "Content-Type: application/json" -d @Caddyroute_for_${TMP_SETUP_CDD_CONF_VLD_BIND_DOMAIN}.json
	curl localhost:2019/config/apps/http/servers/autohttps/logs/logger_names -X POST -H "Content-Type: application/json" -d '{"${TMP_SETUP_CDD_CONF_VLD_BIND_DOMAIN}": "${TMP_SETUP_CDD_CONF_VLD_BIND_DOMAIN}"}'

    echo "----------------------------------------------------------------"

    return $?
}

function conf_kong_dashboard_auto_https()
{
    local TMP_SETUP_CDD_CONF_VLD_KONG_DASHBOARD_BIND_DOMAIN="${LOCAL_IPV4}"
    
	input_if_empty "TMP_SETUP_CDD_CONF_VLD_KONG_DASHBOARD_BIND_DOMAIN" "Caddy.Kong.Dashboard.Domain: Please ender auto https ${red}konga web domain${reset}"

    increase_auto_https_conf "${TMP_SETUP_CDD_CONF_VLD_KONG_DASHBOARD_BIND_DOMAIN}"

    return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_caddy()
{    
	set_environment

	setup_caddy

	conf_caddy

    # down_plugin_caddy

	boot_caddy

    echo_soft_port 2019

	return $?
}

# x1-下载软件
function check_setup_caddy()
{
    soft_yum_check_action "caddy" "exec_step_caddy"

	# 开放API出去，必装
    # cd ${__DIR}
    # source scripts/web/webhook.sh

	return $?
}

#安装主体
setup_soft_basic "Caddy" "check_setup_caddy"