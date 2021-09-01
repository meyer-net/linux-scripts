#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 相关参数：
#         https://github.com/adnanh/webhook/blob/master/docs/Webhook-Parameters.md
# 测试：
#      curl -H "User-Agent: Mozilla/5.0 (compatible; Let's Encrypt validation server; +https://www.letsencrypt.org)" http://konga.myvnc.com/.well-known/acme-challenge/aGBNs8KUZP-RGZ6hsgB--S4V_-Om-JEkPZ9-XsUnL7c
#      curl -H "User-Agent: acme.zerossl.com/v2/DV90" http://konga.myvnc.com/.well-known/acme-challenge/aGBNs8KUZP-RGZ6hsgB--S4V_-Om-JEkPZ9-XsUnL7c
# 备注：
#      AutoHttps模式下，需要在Kong/Caddy安装后再装。
#------------------------------------------------
local TMP_WBH_SETUP_API_HTTP_PORT=19000

local TMP_WBH_SETUP_CDY_API_HTTP_PORT=12019
local TMP_WBH_SETUP_KNG_API_HTTP_PORT=18000

local TMP_WBH_SETUP_KNG_HOST="127.0.0.1"
local TMP_SETUP_CDY_HOST="127.0.0.1"

##########################################################################################################

# 1-配置环境
function set_environment()
{
    cd ${__DIR}

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_webhook()
{
	local TMP_WBH_SETUP_DIR=${1}
	local TMP_WBH_CURRENT_DIR=${2}

	## 直装模式
	cd `dirname ${TMP_WBH_CURRENT_DIR}`

	mv ${TMP_WBH_CURRENT_DIR} ${TMP_WBH_SETUP_DIR}

    cd ${TMP_WBH_SETUP_DIR}

    mkdir bin
    mv webhook bin/

	# 创建日志软链
	local TMP_WBH_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/webhook
	local TMP_WBH_SETUP_LNK_DATA_DIR=${DATA_DIR}/webhook
	local TMP_WBH_SETUP_LOGS_DIR=${TMP_WBH_SETUP_DIR}/logs
	local TMP_WBH_SETUP_DATA_DIR=${TMP_WBH_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_WBH_SETUP_LOGS_DIR}
	rm -rf ${TMP_WBH_SETUP_DATA_DIR}
	mkdir -pv ${TMP_WBH_SETUP_LNK_LOGS_DIR}
	mkdir -pv ${TMP_WBH_SETUP_LNK_DATA_DIR}
	
	ln -sf ${TMP_WBH_SETUP_LNK_LOGS_DIR} ${TMP_WBH_SETUP_LOGS_DIR}
	ln -sf ${TMP_WBH_SETUP_LNK_DATA_DIR} ${TMP_WBH_SETUP_DATA_DIR}

	# 环境变量或软连接
	echo "WEBHOOK_HOME=${TMP_WBH_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$WEBHOOK_HOME/bin:$PATH' >> /etc/profile
	echo "export PATH WEBHOOK_HOME" >> /etc/profile

    # 重新加载profile文件
    source /etc/profile
	# ln -sf ${TMP_WBH_SETUP_DIR}/bin/webhook /usr/bin/webhook

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_webhook()
{
	local TMP_WBH_SETUP_DIR=${1}

	cd ${TMP_WBH_SETUP_DIR}
    
	local TMP_WBH_SETUP_LOGS_DIR=${TMP_WBH_SETUP_DIR}/logs
	local TMP_WBH_SETUP_DATA_DIR=${TMP_WBH_SETUP_DIR}/data
    local TMP_WBH_SETUP_DATA_HOOKS_DIR=${TMP_WBH_SETUP_DATA_DIR}/hooks
    local TMP_WBH_SETUP_DATA_SCRIPTS_DIR=${TMP_WBH_SETUP_DATA_DIR}/scripts
	local TMP_WBH_SETUP_DATA_CACHE_DIR=${TMP_WBH_SETUP_DIR}/cache

    mkdir -pv ${TMP_WBH_SETUP_DATA_HOOKS_DIR}
    mkdir -pv ${TMP_WBH_SETUP_DATA_SCRIPTS_DIR}
    mkdir -pv ${TMP_WBH_SETUP_DATA_CACHE_DIR}

    # 本机装有caddy
    local TMP_WBH_SETUP_CDY_HOOKS_JSON="{}"
    local TMP_WBH_SETUP_IS_CDY_LOCAL=`lsof -i:${TMP_WBH_SETUP_CDY_API_HTTP_PORT}`
    if [ -n "${TMP_WBH_SETUP_IS_CDY_LOCAL}" ]; then    
        TMP_WBH_SETUP_CDY_HOOKS_JSON="{
            \"id\": \"cor-caddy-api\",  \
            \"execute-command\": \"${TMP_WBH_SETUP_DATA_SCRIPTS_DIR}/cor-caddy-api.sh\",  \
            \"http-methods\": [\"Get\"],  \
            \"include-command-output-in-response\": true,  \
            \"command-working-directory\": \"${TMP_WBH_SETUP_LOGS_DIR}\",  \
            \"pass-arguments-to-command\": [{  \
                \"source\": \"url\",  \
                \"name\": \"host\"  \
            }]  \
        }"
        
        conf_webhook_cor_caddy_api "${TMP_WBH_SETUP_DIR}"
    fi

    local TMP_WBH_SETUP_KNG_HOOKS_JSON="{
            \"id\": \"async-caddy-cert-to-kong\",  \
            \"execute-command\": \"${TMP_WBH_SETUP_DATA_SCRIPTS_DIR}/buffer_for_request_host.sh\",  \
            \"http-methods\": [\"Post \"],  \
            \"command-working-directory\": \"${TMP_WBH_SETUP_LOGS_DIR}\",  \
            \"pass-arguments-to-command\": [{  \
                \"source\": \"payload\",  \
                \"name\": \"request.headers.host\"  \
            }],  \
            \"trigger-rule\": {  \
                \"or\": [{  \
                        \"match\": {  \
                                \"type\": \"ip-whitelist\",  \
                                \"ip-range\": \"127.0.0.1\"  \
                        }  \
                }]  \
            }  \
        }"

    conf_webhook_buffer_for_request_host "${TMP_WBH_SETUP_DIR}"

    exec_yn_action "conf_webhook_sync_caddy_cert_to_kong" "Webhook.AutoHttps: Please sure if u want to ${green}configuare auto https here${reset}?"

    local TMP_WBH_BOOT_HOOKS_JSON=`echo "[${TMP_WBH_SETUP_CDY_HOOKS_JSON},${TMP_WBH_SETUP_KNG_HOOKS_JSON}]" | jq | sed 's@{},*@@g'`
    
    echo "##############################################################" 
    # "source": "entire-payload" #通过此打印全部
    sudo tee ${TMP_WBH_SETUP_DATA_HOOKS_DIR}/webhook_boot.json <<-EOF
${TMP_WBH_BOOT_HOOKS_JSON}
EOF
    echo "##############################################################" 

    chmod +x ${TMP_WBH_SETUP_DATA_SCRIPTS_DIR}/*.sh

	return $?
}

# 配置webhook，辅助caddy未有api（未寻到）
# 参数1：安装目录
function conf_webhook_cor_caddy_api()
{
	local TMP_WBH_SETUP_DIR=${1}

	cd ${TMP_WBH_SETUP_DIR}
    
	local TMP_WBH_SETUP_LOGS_DIR=${TMP_WBH_SETUP_DIR}/logs
	local TMP_WBH_SETUP_DATA_DIR=${TMP_WBH_SETUP_DIR}/data
    # local TMP_WBH_SETUP_DATA_HOOKS_DIR=${TMP_WBH_SETUP_DATA_DIR}/hooks
    local TMP_WBH_SETUP_DATA_SCRIPTS_DIR=${TMP_WBH_SETUP_DATA_DIR}/scripts
	local TMP_WBH_SETUP_DATA_CACHE_DIR=${TMP_WBH_SETUP_DIR}/cache

    echo "+--------------------------------------------------------------+" 
    
    sudo tee ${TMP_WBH_SETUP_DATA_SCRIPTS_DIR}/cor-caddy-api.sh <<-EOF
#!/bin/sh
#------------------------------------------------
#  Project Web hook script for cor caddy api
#------------------------------------------------
# 忽略非域名请求（简单的验证，足够用）
if [ \`echo \${1} | tr -cd "." | wc -c\` -eq 3 ]; then
    return
fi

function execute() {
    local TMP_COR_CDY_CERT_HOST=\$1 #request.headers.host
    local TMP_THIS_LOG_PATH=${TMP_WBH_SETUP_LOGS_DIR}/\`echo \$(basename "\${BASH_SOURCE[0]}") | sed "s@sh\\\\\$@log@g"\`

    # 未运行caddy的情况下，不执行脚本
    local TMP_IS_CDY_LOCAL=\`lsof -i:${TMP_WBH_SETUP_CDY_API_HTTP_PORT}\`
    if [ -z "\${TMP_IS_CDY_LOCAL}" ]; then    
        echo "Webhook.Caddy.Cor: When getting cert of '\${TMP_COR_CDY_CERT_HOST}'，Can\'t find caddy server。request break。" >> \${TMP_THIS_LOG_PATH}
        echo "{}"
        return
    fi

    local TMP_CERT_DATA_DIR=\`find / -name \${TMP_COR_CDY_CERT_HOST}.key -user caddy 2> /dev/null | grep certificates | xargs -I {} dirname {}\`
    
    # 本机不存在数据的情况下，则不执行脚本
    if [ -z "\${TMP_CERT_DATA_DIR}" ]; then    
        echo "Webhook.Caddy.Cor: When getting cert of '\${TMP_COR_CDY_CERT_HOST}'，Can't find caddy data dir。request break。" >> \${TMP_THIS_LOG_PATH}
        echo "{}"
        return
    fi

    local TMP_CERT_DATA_KEY_FROM_CDY=\`cat \${TMP_CERT_DATA_DIR}/\${TMP_COR_CDY_CERT_HOST}.key\`
    local TMP_CERT_DATA_CRT_FROM_CDY=\`cat \${TMP_CERT_DATA_DIR}/\${TMP_COR_CDY_CERT_HOST}.crt\`

    echo "{}"  \\
    | jq ".key=\"\${TMP_CERT_DATA_KEY_FROM_CDY}\""  \\
    | jq ".crt=\"\${TMP_CERT_DATA_CRT_FROM_CDY}\""
}

execute "\$1"
echo
EOF

    echo "+--------------------------------------------------------------+" 

	return $?
}

# 配置用来缓存的脚本，辅助autohttps记录请求域名等
# 参数1：安装目录
function conf_webhook_buffer_for_request_host()
{
	local TMP_WBH_SETUP_DIR=${1}

	cd ${TMP_WBH_SETUP_DIR}
    
	local TMP_WBH_SETUP_LOGS_DIR=${TMP_WBH_SETUP_DIR}/logs
	local TMP_WBH_SETUP_DATA_DIR=${TMP_WBH_SETUP_DIR}/data
    # local TMP_WBH_SETUP_DATA_HOOKS_DIR=${TMP_WBH_SETUP_DATA_DIR}/hooks
    local TMP_WBH_SETUP_DATA_SCRIPTS_DIR=${TMP_WBH_SETUP_DATA_DIR}/scripts
	local TMP_WBH_SETUP_DATA_CACHE_DIR=${TMP_WBH_SETUP_DIR}/cache

    echo "+--------------------------------------------------------------+" 
    # 用于记录证书已刷新，记录域名的脚本（接收内容时触发，相当于简单的生产者，buffer）
    sudo tee ${TMP_WBH_SETUP_DATA_SCRIPTS_DIR}/buffer_for_request_host.sh <<-EOF
#!/bin/sh
#------------------------------------------------
#  Project Web hook Script - for receive request
#------------------------------------------------
function execute() {
    local LOCAL_TIME=\`date +"%Y-%m-%d %H:%M:%S"\`
    local TMP_ASYNC_CADDY_CERT_HOST=\$1 #request.headers.host
    local TMP_THIS_LOG_PATH=${TMP_WBH_SETUP_LOGS_DIR}/\`echo \$(basename "\${BASH_SOURCE[0]}") | sed "s@sh\\\\\$@log@g"\`
    local TMP_THIS_CACHE_PATH=${TMP_WBH_SETUP_DATA_CACHE_DIR}/\`echo \$(basename "\${BASH_SOURCE[0]}") | sed "s@sh\\\\\$@cache@g"\`

    # 忽略非域名请求（简单的验证，足够用）
    if [ \`echo \${TMP_ASYNC_CADDY_CERT_HOST} | tr -cd "." | wc -c\` -eq 3 ]; then
        echo "This'nt a host for use '\${TMP_ASYNC_CADDY_CERT_HOST}', so will be return" >> \${TMP_THIS_LOG_PATH}
        return
    fi

    # 已写入的情况下，暂时不写入
    local TMP_THIS_CACHE_CONTAINS=\`cat \${TMP_THIS_CACHE_PATH} | egrep "^\${TMP_ASYNC_CADDY_CERT_HOST}\\\$"\`
    if [ -n "\${TMP_THIS_CACHE_CONTAINS}" ]; then
        echo "Host of '\${TMP_ASYNC_CADDY_CERT_HOST}' was buffered" >> \${TMP_THIS_LOG_PATH}
        return
    fi

    # 写入请求域名，等待消费者处理
    echo "\${TMP_ASYNC_CADDY_CERT_HOST}" >> \${TMP_THIS_CACHE_PATH}
    echo "Host of '\${TMP_ASYNC_CADDY_CERT_HOST}' buffered" >> \${TMP_THIS_LOG_PATH}
}

execute "\$1"
echo
EOF
    echo "+--------------------------------------------------------------+" 

	return $?
}

# 配置webhook，辅助caddy同步其证书至kong
function conf_webhook_sync_caddy_cert_to_kong()
{
	cd ${TMP_WBH_SETUP_DIR}
    
	local TMP_WBH_SETUP_LOGS_DIR=${TMP_WBH_SETUP_DIR}/logs
	local TMP_WBH_SETUP_DATA_DIR=${TMP_WBH_SETUP_DIR}/data
    # local TMP_WBH_SETUP_DATA_HOOKS_DIR=${TMP_WBH_SETUP_DATA_DIR}/hooks
    local TMP_WBH_SETUP_DATA_SCRIPTS_DIR=${TMP_WBH_SETUP_DATA_DIR}/scripts
	local TMP_WBH_SETUP_DATA_CACHE_DIR=${TMP_WBH_SETUP_DIR}/cache

    # Caddy 不在本机，则重新确认host
    if [ -z "${TMP_WBH_SETUP_IS_CDY_LOCAL}" ]; then
    	input_if_empty "TMP_SETUP_CDY_HOST" "Webhook.Caddy.Host: Please ender ${green}your caddy host address${reset}"
    fi

    # Kong 不在本机的情况下，则重新确认host
    local TMP_WBH_SETUP_IS_KNG_LOCAL=`lsof -i:${TMP_WBH_SETUP_KNG_API_HTTP_PORT}`
    if [ -z "${TMP_WBH_SETUP_IS_KNG_LOCAL}" ]; then    
    	input_if_empty "TMP_WBH_SETUP_KNG_HOST" "Webhook.Kong.Host: Please ender ${green}your kong host address${reset}"
    fi

    # 用于同步证书内容，删除记录域名的脚本（每天定时3次触发，相当于消费者，消费buffer）
    sudo tee ${TMP_WBH_SETUP_DATA_SCRIPTS_DIR}/sync-caddy-cert-to-kong.sh <<-EOF
#!/bin/sh
#------------------------------------------------
#  Project Web hook Script - for sync cert
#------------------------------------------------
TMP_REQUEST_HOST_CACHE_PATH=${TMP_WBH_SETUP_DATA_CACHE_DIR}/buffer_for_request_host.cache

# 添加/更新 Kong-Certificates
# 参数1：证书ID
# 参数2：证书绑定域名
# 参数3：证书主体crt
# 参数4：证书公钥key
function put_certificates()
{
    local tmp_certificates_id="\${1:-}"
    local tmp_certificates_snis="\${2:-}"
    local tmp_certificates_cert="\${3:-}"
    local tmp_certificates_key="\${4:-}"

    local request_code=\`curl -o /dev/null -s -w %{http_code} -X PUT http://${TMP_WBH_SETUP_KNG_HOST}:${TMP_WBH_SETUP_KNG_API_HTTP_PORT}/certificates/\${tmp_certificates_id}  \\
        -F "cert=\${tmp_certificates_cert}"  \\
        -F "key=\${tmp_certificates_key}"  \\
        -F "tags[]=\${tmp_certificates_snis}"  \\
        -F "snis[]=\${tmp_certificates_snis}"\`
        
    if [ "\${request_code::1}" != "2" ]; then
    	echo "Webhook.PutCertificates: Failure, remote response '\${request_code}'."
    	exit 9
    fi
}

# 添加/更新 Kong-Certificates-att
# 参数1：证书ID
# 参数2：证书绑定域名
function patch_certificates_att()
{
    local tmp_certificates_id="\${1:-}"
    local tmp_certificates_snis="\${2:-}"

    local request_code=\`curl -o /dev/null -s -w %{http_code} -X PATCH http://${TMP_WBH_SETUP_KNG_HOST}:${TMP_WBH_SETUP_KNG_API_HTTP_PORT}/certificates/\${tmp_certificates_id}  \\
        #-d "tags[]=by-webhook-sync"  \\
        -d "tags[]=sync-caddy-acme"  \\
        -d "tags[]=\${tmp_certificates_snis}"\`
        
    if [ "\${request_code::1}" != "2" ]; then
    	echo "Webhook.PatchCertificatesAtt: Failure, remote response '\${request_code}'."
    	# exit 9
    fi
}

function sync_crt() {
    local LOCAL_TIME=\`date +"%Y-%m-%d %H:%M:%S"\`
    local TMP_ASYNC_CADDY_CERT_HOST=\$1 #request.headers.host
    local TMP_THIS_LOG_PATH=${TMP_WBH_SETUP_LOGS_DIR}/\`echo \$(basename "\${BASH_SOURCE[0]}") | sed "s@sh\\\\\$@log@g"\`\

    #获取CADDY证书数据
    local TMP_CERT_DATA_FROM_CDY=\`curl -s ${TMP_SETUP_CDY_HOST}:${TMP_WBH_SETUP_API_HTTP_PORT}/hooks/cor-caddy-api?host=\${TMP_ASYNC_CADDY_CERT_HOST}\`
    local TMP_CERT_DATA_KEY_FROM_CDY=\`echo "\${TMP_CERT_DATA_FROM_CDY}" | jq ".key"\`

    #获取KONG证书数据
    TMP_CERT_DATA_FROM_KNG=\`curl -s ${TMP_WBH_SETUP_KNG_HOST}:${TMP_WBH_SETUP_KNG_API_HTTP_PORT}/certificates?tags=\${TMP_ASYNC_CADDY_CERT_HOST}\`
    TMP_CERT_DATA_KEY_FROM_KNG=\`echo "\${TMP_CERT_DATA_FROM_KNG}" | jq ".data[].key"\`

    # 对比key文件，判断是否更新
    if [ "\${TMP_CERT_DATA_KEY_FROM_CDY}" != "\${TMP_CERT_DATA_KEY_FROM_KNG}" ]; then
        TMP_CERT_DATA_KEY_FROM_CDY=\`echo "\${TMP_CERT_DATA_FROM_CDY}" | jq ".key" | xargs -I {} echo -e {}\`
        TMP_CERT_DATA_CRT_FROM_CDY=\`echo "\${TMP_CERT_DATA_FROM_CDY}" | jq ".crt" | xargs -I {} echo -e {}\`

        TMP_CERT_DATA_ID_FROM_KNG=\`echo "\${TMP_CERT_DATA_FROM_KNG}" | jq ".data[].id"\`
        TMP_CERT_DATA_ID_FINAL=\${TMP_CERT_DATA_ID_FROM_KNG:-\`cat /proc/sys/kernel/random/uuid\`}
        
        put_certificates "\${TMP_CERT_DATA_ID_FINAL}" "\${TMP_ASYNC_CADDY_CERT_HOST}" "\${TMP_CERT_DATA_CRT_FROM_CDY}" "\${TMP_CERT_DATA_KEY_FROM_CDY}"

        # 打印日志    
        sudo tee \${TMP_THIS_LOG_PATH} <<-EOF
Refresh cert at '\${LOCAL_TIME}'
----------------------------------------------------------------
|ID：\${TMP_CERT_DATA_ID_FROM_KNG}
|Host&Tags：\${TMP_ASYNC_CADDY_CERT_HOST}
|Key：
\${TMP_CERT_DATA_KEY_FROM_CDY}

|Cert：
\${TMP_CERT_DATA_CRT_FROM_CDY}
----------------------------------------------------------------

``EOF
        
        # 无关紧要的标记更新
        patch_certificates_att "\${TMP_CERT_DATA_ID_FINAL}" "\${TMP_ASYNC_CADDY_CERT_HOST}"

    fi
}

function execute() {
    while read line
    do
        # 忽略非域名请求（简单的验证，足够用）
        if [ \`echo \${line} | tr -cd "." | wc -c\` -eq 3 ]; then
            continue
        fi

        sync_crt "\${line}"
                
        # 如果失败不会执行到此处，脚本会在前面直接退出
        sed -i "/^\${line}\$/d" \${TMP_REQUEST_HOST_CACHE_PATH}
    done < \${TMP_REQUEST_HOST_CACHE_PATH}
}

execute "\$1"
echo
EOF
    
    # 每天凌晨，12点，18点各执行1次
    echo "0 0/12/18 * * * ${TMP_WBH_SETUP_DATA_SCRIPTS_DIR}/sync-caddy-cert-to-kong.sh >> ${TMP_WBH_SETUP_LOGS_DIR}/sync-caddy-cert-to-kong-crontab.log 2>&1" >> /var/spool/cron/root
    systemctl restart crond
    echo "+--------------------------------------------------------------+" 

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_webhook()
{
	local TMP_WBH_SETUP_DIR=${1}

	cd ${TMP_WBH_SETUP_DIR}
	
	# 验证安装
    bin/webhook -version

	# 当前启动命令
	nohup bin/webhook -port ${TMP_WBH_SETUP_API_HTTP_PORT} -hooks data/hooks/webhook_boot.json -verbose -hotreload > logs/boot.log 2>&1 &

	# 添加系统启动命令
    echo_startup_config "webhook" "${TMP_WBH_SETUP_DIR}" "bin/webhook -port ${TMP_WBH_SETUP_API_HTTP_PORT} -hooks data/hooks/webhook_boot.json -verbose" "" "1"

    # 开放端口
    echo_soft_port ${TMP_WBH_SETUP_API_HTTP_PORT}

    cat logs/boot.log

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_webhook()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_webhook()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_webhook()
{
	local TMP_WBH_SETUP_DIR=${1}
	local TMP_WBH_CURRENT_DIR=`pwd`
    
	set_environment "${TMP_WBH_SETUP_DIR}"

	setup_webhook "${TMP_WBH_SETUP_DIR}" "${TMP_WBH_CURRENT_DIR}"

	conf_webhook "${TMP_WBH_SETUP_DIR}"

    # down_plugin_webhook "${TMP_WBH_SETUP_DIR}"

	boot_webhook "${TMP_WBH_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_webhook()
{
	TMP_WBH_SETUP_NEWER="2.8.0"
	set_github_soft_releases_newer_version "TMP_WBH_SETUP_NEWER" "adnanh/webhook"
	exec_text_format "TMP_WBH_SETUP_NEWER" "https://github.com/adnanh/webhook/releases/download/%s/webhook-linux-amd64.tar.gz"
    setup_soft_wget "webhook" "${TMP_WBH_SETUP_NEWER}" "exec_step_webhook"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "Webhook" "down_webhook"
