#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
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

local TMP_WBH_SETUP_CDY_HTTP_PORT=80
local TMP_WBH_SETUP_CDY_API_HTTP_PORT=12019
local TMP_WBH_SETUP_KNG_API_HTTP_PORT=18000
local TMP_WBH_SETUP_KNG_API_RC_FILE_PATH="~/.kong-apirc"

local TMP_WBH_SETUP_KNG_HOST="127.0.0.1"
local TMP_WBH_SETUP_CDY_HOST="127.0.0.1"

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

	# 移动bin
    mkdir bin
    mv webhook bin/
    
    # 重新加载profile文件
    source /etc/profile
    
    # 安装初始

    # 创建源码目录
    path_not_exists_create "${HTML_DIR}"

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
	local TMP_WBH_SETUP_DATA_CACHE_DIR=${TMP_WBH_SETUP_DATA_DIR}/cache
	local TMP_WBH_SETUP_ETC_DIR=${TMP_WBH_SETUP_DIR}/etc
    local TMP_WBH_SETUP_ETC_HOOKS_DIR=${TMP_WBH_SETUP_ETC_DIR}/hooks
    local TMP_WBH_SETUP_ETC_SCRIPTS_DIR=${TMP_WBH_SETUP_ETC_DIR}/scripts

    mkdir -pv ${TMP_WBH_SETUP_ETC_HOOKS_DIR}
    mkdir -pv ${TMP_WBH_SETUP_ETC_SCRIPTS_DIR}
    mkdir -pv ${TMP_WBH_SETUP_DATA_CACHE_DIR}

    # 默认的测试脚本(添加请求来源，方便回请kong)
    local TMP_WBH_SETUP_TEST_HOOKS_JSON="{
        \"id\": \"test\",  \
        \"execute-command\": \"${TMP_WBH_SETUP_ETC_SCRIPTS_DIR}/test.sh\",  \
        \"include-command-output-in-response\": true,  \
        \"include-command-output-in-response-on-error\":true,  \
        \"command-working-directory\": \"${TMP_WBH_SETUP_LOGS_DIR}\",  \
        \"pass-arguments-to-command\": [{  \
            \"source\": \"entire-headers\",  \
            \"name\": \"all-headers\"  \
        },{  \
            \"source\": \"entire-query\",  \
            \"name\": \"all-query\"  \
        },{  \
            \"source\": \"entire-payload\",  \
            \"name\": \"all-json\"  \
        },{  \
            \"source\": \"request\",  \
            \"name\": \"remote-addr\"  \
        }]  \
    }"

    conf_webhook_test "${TMP_WBH_SETUP_DIR}"

    # 本机装有caddy
    local TMP_WBH_SETUP_CDY_HOOKS_JSON="{}"
    local TMP_WBH_SETUP_IS_CDY_LOCAL=`lsof -i:${TMP_WBH_SETUP_CDY_API_HTTP_PORT}`
    if [ -n "${TMP_WBH_SETUP_IS_CDY_LOCAL}" ]; then    
        TMP_WBH_SETUP_CDY_HOOKS_JSON="{
            \"id\": \"cor-caddy-api\",  \
            \"execute-command\": \"${TMP_WBH_SETUP_ETC_SCRIPTS_DIR}/cor-caddy-api.sh\",  \
            \"http-methods\": [\"Get\"],  \
            \"include-command-output-in-response\": true,  \
            \"command-working-directory\": \"${TMP_WBH_SETUP_LOGS_DIR}\",  \
            \"pass-arguments-to-command\": [{  \
                \"source\": \"url\",  \
                \"name\": \"domain\"  \
            }]  \
        }"
        
        conf_webhook_cor_caddy_api "${TMP_WBH_SETUP_DIR}"
    fi

    local TMP_WBH_SETUP_KNG_BUFFER_JSON="{}"

    conf_webhook_buffer_for_request_host "${TMP_WBH_SETUP_DIR}"

    exec_yn_action "conf_webhook_sync_caddy_cert_to_kong" "Webhook.AutoHttps: Please sure if u want to ${green}configuare auto https assist for kong${reset} here?"

    local TMP_WBH_BOOT_HOOKS_JSON=`echo "[${TMP_WBH_SETUP_TEST_HOOKS_JSON},${TMP_WBH_SETUP_CDY_HOOKS_JSON},${TMP_WBH_SETUP_KNG_BUFFER_JSON}]" | jq | sed 's@{},*@@g' | sed '/^[[:space:]]*\$/d'`
    
    echo "##############################################################" 
    # "source": "entire-payload" #通过此打印全部
    tee ${TMP_WBH_SETUP_ETC_HOOKS_DIR}/webhook_boot.json <<-EOF
${TMP_WBH_BOOT_HOOKS_JSON}
EOF
    echo "##############################################################" 

    chmod +x ${TMP_WBH_SETUP_ETC_SCRIPTS_DIR}/*.sh

	return $?
}

# 添加webhook对kong_api的依赖
function conf_webhook_kong_api()
{
    cd ${__DIR}

    # Kong 不在本机的情况下，则重新确认host
    if [ -z "${TMP_WBH_SETUP_IS_KNG_LOCAL}" ]; then    
    	input_if_empty "TMP_WBH_SETUP_KNG_HOST" "Webhook.Kong.Host: Please ender ${green}your kong host address default${reset}"
    fi
    
    local TMP_WBH_SETUP_KPI_API_LISTEN_HOST="${TMP_WBH_SETUP_KNG_HOST}:${TMP_WBH_SETUP_KNG_API_HTTP_PORT}"

    convert_path "TMP_WBH_SETUP_KNG_API_RC_FILE_PATH"
    path_not_exists_create `dirname ${TMP_WBH_SETUP_KNG_API_RC_FILE_PATH}`

    if [ ! -d "${TMP_WBH_SETUP_KNG_API_RC_FILE_PATH}"]; then
        echo "KONG_ADMIN_LISTEN_HOST=\"${TMP_WBH_SETUP_KPI_API_LISTEN_HOST}\"" >> ${TMP_WBH_SETUP_KNG_API_RC_FILE_PATH}
    fi

    #路径转换
    cat special/kong_api_exec.sh > /usr/bin/kong_api && chmod +x /usr/bin/kong_api

	return $?
}

# 配置webhook，测试
# curl localhost:12019/hooks//test?a=1&b=2&c=3
# 参数1：安装目录
function conf_webhook_test()
{
	local TMP_WBH_SETUP_DIR=${1}

	cd ${TMP_WBH_SETUP_DIR}
    
	local TMP_WBH_SETUP_LOGS_DIR=${TMP_WBH_SETUP_DIR}/logs
	local TMP_WBH_SETUP_DATA_DIR=${TMP_WBH_SETUP_DIR}/data
    # local TMP_WBH_SETUP_ETC_HOOKS_DIR=${TMP_WBH_SETUP_ETC_DIR}/hooks
    local TMP_WBH_SETUP_ETC_SCRIPTS_DIR=${TMP_WBH_SETUP_ETC_DIR}/scripts
	local TMP_WBH_SETUP_DATA_CACHE_DIR=${TMP_WBH_SETUP_DATA_DIR}/cache

    echo "+--------------------------------------------------------------+" 
    
    tee ${TMP_WBH_SETUP_ETC_SCRIPTS_DIR}/test.sh <<-EOF
#!/bin/sh
#------------------------------------------------
#  Project Web hook script for test
#------------------------------------------------
function execute() {
    local TMP_TEST_ARGS_HEADERS=\$1
    local TMP_TEST_ARGS_QUERY=\$2
    local TMP_TEST_ARGS_PAYLOAD=\$3
    local TMP_TEST_ARGS_REQUESTS=\$4

    echo "entire-headers："
    echo "               \${TMP_TEST_ARGS_HEADERS}"
    echo

    echo "entire-query："
    echo "             \${TMP_TEST_ARGS_QUERY}"
    echo

    echo "entire-payload："
    echo "               \${TMP_TEST_ARGS_PAYLOAD}"
    echo

    echo "requests-remote："
    echo "               \${TMP_TEST_ARGS_REQUESTS}"
    echo
}

execute "\$1" "\$2" "\$3" "\$4"
echo
EOF

    echo "+--------------------------------------------------------------+" 

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
    # local TMP_WBH_SETUP_ETC_HOOKS_DIR=${TMP_WBH_SETUP_ETC_DIR}/hooks
    local TMP_WBH_SETUP_ETC_SCRIPTS_DIR=${TMP_WBH_SETUP_ETC_DIR}/scripts
	local TMP_WBH_SETUP_DATA_CACHE_DIR=${TMP_WBH_SETUP_DATA_DIR}/cache

    echo "+--------------------------------------------------------------+" 
    
    tee ${TMP_WBH_SETUP_ETC_SCRIPTS_DIR}/cor-caddy-api.sh <<-EOF
#!/bin/sh
#------------------------------------------------
#  Project Web hook script for cor caddy api
#------------------------------------------------
# 忽略非域名请求（简单的验证，足够用）
if [ \`echo \${1} | tr -cd "." | wc -c\` -eq 3 ]; then
    return
fi

function execute() {
    local TMP_COR_CDY_CERT_DOMAIN=\$1 #url.domain
    local TMP_THIS_LOG_PATH=${TMP_WBH_SETUP_LOGS_DIR}/\`echo \$(basename "\${BASH_SOURCE[0]}") | sed "s@sh\\\\\$@log@g"\`

    # 未运行caddy的情况下，不执行脚本
    local TMP_IS_CDY_LOCAL=\`lsof -i:${TMP_WBH_SETUP_CDY_API_HTTP_PORT}\`
    if [ -z "\${TMP_IS_CDY_LOCAL}" ]; then    
        echo "Webhook.Caddy.Cor: When getting cert of '\${TMP_COR_CDY_CERT_DOMAIN}'，Can\'t find caddy server。request break。" >> \${TMP_THIS_LOG_PATH}
        echo "{}"
        return
    fi

    local TMP_CERT_DATA_DIR=\`find / -name \${TMP_COR_CDY_CERT_DOMAIN}.key -user caddy 2> /dev/null | grep certificates | xargs -I {} dirname {}\`
    
    # 本机不存在数据的情况下，则不执行脚本
    if [ -z "\${TMP_CERT_DATA_DIR}" ]; then    
        echo "Webhook.Caddy.Cor: When getting cert of '\${TMP_COR_CDY_CERT_DOMAIN}'，Can't find caddy data dir。request break。" >> \${TMP_THIS_LOG_PATH}
        echo "{}"
        return
    fi

    local TMP_CERT_DATA_KEY_FROM_CDY=\`cat \${TMP_CERT_DATA_DIR}/\${TMP_COR_CDY_CERT_DOMAIN}.key\`
    local TMP_CERT_DATA_CRT_FROM_CDY=\`cat \${TMP_CERT_DATA_DIR}/\${TMP_COR_CDY_CERT_DOMAIN}.crt\`

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
	local TMP_WBH_SETUP_ETC_DIR=${TMP_WBH_SETUP_DIR}/etc
    # local TMP_WBH_SETUP_ETC_HOOKS_DIR=${TMP_WBH_SETUP_ETC_DIR}/hooks
    local TMP_WBH_SETUP_ETC_SCRIPTS_DIR=${TMP_WBH_SETUP_ETC_DIR}/scripts
	local TMP_WBH_SETUP_DATA_CACHE_DIR=${TMP_WBH_SETUP_DATA_DIR}/cache

    echo "+--------------------------------------------------------------+" 
    # 用于记录证书已刷新，记录域名的脚本（接收内容时触发，相当于简单的生产者，buffer）
    tee ${TMP_WBH_SETUP_ETC_SCRIPTS_DIR}/buffer_for_request_host.sh <<-EOF
#!/bin/sh
#------------------------------------------------
#  Project Web hook Script - for receive request
#------------------------------------------------
function execute() {
    local LOCAL_TIME=\`date +"%Y-%m-%d %H:%M:%S"\`
    local TMP_BUFFER_REQ_HOST=\$1 #request.headers.host
    local TMP_BUFFER_REQ_FROM=\$2 #request -> remote-addr
    local TMP_BUFFER_REQ_LOG_PATH=${TMP_WBH_SETUP_LOGS_DIR}/\`echo \$(basename "\${BASH_SOURCE[0]}") | sed "s@sh\\\\\$@log@g"\`
    local TMP_BUFFER_REQ_CACHE_PATH=${TMP_WBH_SETUP_DATA_CACHE_DIR}/\`echo \$(basename "\${BASH_SOURCE[0]}") | sed "s@sh\\\\\$@cache@g"\`

    # 忽略非域名请求（简单的验证，足够用）
    if [ \`echo \${TMP_BUFFER_REQ_HOST} | tr -cd "." | wc -c\` -eq 3 ]; then
        echo "This'nt a host for use '\${TMP_BUFFER_REQ_HOST}', so will be return" >> \${TMP_BUFFER_REQ_LOG_PATH}
        return
    fi

    # 已写入的情况下，暂时不写入
    local TMP_BUFFER_REQ_CACHE_CONTAINS=\`cat \${TMP_BUFFER_REQ_CACHE_PATH} | egrep "^\${TMP_BUFFER_REQ_HOST}"\`
    if [ -n "\${TMP_BUFFER_REQ_CACHE_CONTAINS}" ]; then
        echo "Host of '\${TMP_BUFFER_REQ_HOST}' was buffered" >> \${TMP_BUFFER_REQ_LOG_PATH}
        return
    fi

    # 写入请求域名，等待消费者处理
    echo "\${TMP_BUFFER_REQ_HOST}@\${TMP_BUFFER_REQ_FROM%:*}" >> \${TMP_BUFFER_REQ_CACHE_PATH}
    echo "Host of '\${TMP_BUFFER_REQ_HOST}' buffered" >> \${TMP_BUFFER_REQ_LOG_PATH}
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
    # local TMP_WBH_SETUP_ETC_HOOKS_DIR=${TMP_WBH_SETUP_ETC_DIR}/hooks
    local TMP_WBH_SETUP_ETC_SCRIPTS_DIR=${TMP_WBH_SETUP_ETC_DIR}/scripts
	local TMP_WBH_SETUP_DATA_CACHE_DIR=${TMP_WBH_SETUP_DATA_DIR}/cache

    TMP_WBH_SETUP_KNG_BUFFER_JSON="{
        \"id\": \"async-caddy-conf-to-kong\",  \
        \"execute-command\": \"${TMP_WBH_SETUP_ETC_SCRIPTS_DIR}/buffer_for_request_host.sh\",  \
        \"http-methods\": [\"Post\"],  \
        \"command-working-directory\": \"${TMP_WBH_SETUP_LOGS_DIR}\",  \
        \"pass-arguments-to-command\": [{  \
            \"source\": \"payload\",  \
            \"name\": \"request.headers.host\"  \
        },{  \
            \"source\": \"request\",  \
            \"name\": \"remote-addr\"  \
        }]  \
    }"

    # ??? 修改成内网
            # \"trigger-rule\": {  \
            #     \"or\": [{  \
            #             \"match\": {  \
            #                     \"type\": \"ip-whitelist\",  \
            #                     \"ip-range\": \"127.0.0.1\"  \
            #             }  \
            #     }]  \
            # }  \

    # 配置kong-webhook
    local TMP_WBH_SETUP_IS_KNG_LOCAL=`lsof -i:${TMP_WBH_SETUP_KNG_API_HTTP_PORT}`
    conf_webhook_kong_api

    # caddy 不在本机，则重新确认host
    if [ -z "${TMP_WBH_SETUP_IS_CDY_LOCAL}" ]; then
    	input_if_empty "TMP_WBH_SETUP_CDY_HOST" "Webhook.Caddy.Host: Please ender ${green}your caddy host address${reset}"
    	input_if_empty "TMP_WBH_SETUP_CDY_HTTP_PORT" "Webhook.Caddy.Port: Please ender ${green}your caddy http port${reset} of '${red}${TMP_WBH_SETUP_CDY_HOST}${reset}'"
    else
        # Caddy在本机，Kong也在本机的情况下，Caddy端口是变更的
        if [ -n "${TMP_WBH_SETUP_IS_KNG_LOCAL}" ]; then
            TMP_WBH_SETUP_CDY_HTTP_PORT=60080
        fi
    fi
    
    # Cache一定要写入本机才生效
    # 用于同步证书内容，删除记录域名的脚本（每天定时3次触发，相当于消费者，消费buffer）
    tee ${TMP_WBH_SETUP_ETC_SCRIPTS_DIR}/sync-caddy-conf-to-kong.sh <<-EOF
#!/bin/sh
#------------------------------------------------
#  Project Web hook Script - for sync cert
#------------------------------------------------
TMP_REQUEST_HOST_CACHE_PATH=${TMP_WBH_SETUP_DATA_CACHE_DIR}/buffer_for_request_host.cache

# 添加/更新 Kong-Certificates
# 参数0：Kong地址
# 参数1：证书ID
# 参数2：证书绑定域名
# 参数3：证书主体crt
# 参数4：证书公钥key
function put_cert()
{
    local TMP_SYNC_KNG_CERT_HOST="\${1:-}"
    local TMP_SYNC_KNG_CERT_ID="\${2:-}"
    local TMP_SYNC_KNG_CERT_SNIS="\${3:-}"
    local TMP_SYNC_KNG_CERT_VAL="\${4:-}"
    local TMP_SYNC_KNG_CERT_KEY="\${5:-}"

    local TMP_SYNC_KNG_CERT_REQUEST_CODE=\`curl -o /dev/null -s -w %{http_code} -X PUT http://\${TMP_SYNC_KNG_CERT_HOST}:${TMP_WBH_SETUP_KNG_API_HTTP_PORT}/certificates/\${TMP_SYNC_KNG_CERT_ID}  \\
        -F "cert=\${TMP_SYNC_KNG_CERT_VAL}"  \\
        -F "key=\${TMP_SYNC_KNG_CERT_KEY}"  \\
        -F "tags[]=\${TMP_SYNC_KNG_CERT_SNIS}"  \\
        -F "snis[]=\${TMP_SYNC_KNG_CERT_SNIS}"\`
        
    if [ "\${TMP_SYNC_KNG_CERT_REQUEST_CODE::1}" != "2" ]; then
    	echo "Webhook.PutCert: Failure, remote response '\${TMP_SYNC_KNG_CERT_REQUEST_CODE}'."
    	exit 9
    fi
}

# 添加/更新 Kong-Certificates-att
# 参数0：Kong地址
# 参数1：证书ID
# 参数2：证书绑定域名
function patch_cert_att()
{
    local TMP_SYNC_KNG_CERT_HOST="\${1:-}"
    local TMP_SYNC_KNG_CERT_ID="\${2:-}"
    local TMP_SYNC_KNG_CERT_SNIS="\${3:-}"

    local TMP_SYNC_KNG_CERT_REQUEST_CODE=\`curl -o /dev/null -s -w %{http_code} -X PATCH http://\${TMP_SYNC_KNG_CERT_HOST}:${TMP_WBH_SETUP_KNG_API_HTTP_PORT}/certificates/\${TMP_SYNC_KNG_CERT_ID}  \\
        #-d "tags[]=by-webhook-sync"  \\
        -d "tags[]=sync-caddy-acme"  \\
        -d "tags[]=\${TMP_SYNC_KNG_CERT_SNIS}"\`
        
    if [ "\${TMP_SYNC_KNG_CERT_REQUEST_CODE::1}" != "2" ]; then
    	echo "Webhook.PatchCertAtt: Failure, remote response '\${TMP_SYNC_KNG_CERT_REQUEST_CODE}'."
    	# exit 9
    fi
}

function sync_conf() {
    local LOCAL_TIME=\`date +"%Y-%m-%d %H:%M:%S"\`
    local TMP_ASYNC_KNG_BUF_DOMAIN=\$1 #url.domain
    local TMP_ASYNC_KNG_CFG_HOST=\${2:-"${TMP_WBH_SETUP_KNG_HOST}"} #request -> remote-addr
    local TMP_THIS_LOG_PATH=${TMP_WBH_SETUP_LOGS_DIR}/\`echo \$(basename "\${BASH_SOURCE[0]}") | sed "s@sh\\\\\$@log@g"\`\

    # 域名同步部分
    # -- 查询Kong中是否存在域名
    # -- 将默认域名访问指向Caddy(如果Kong中不存在的话，如果是微服务网关且SAAS模式，需记录为分组（也可修改BUFFER传递），并作为更新的模式进行路由操作)
    local TMP_ASYNC_SERVICE_NAME=\`echo \${TMP_ASYNC_KNG_BUF_DOMAIN} | sed "s@\.@_@g" | sed 's/[a-z]/\u&/g'\`
    local TMP_ASYNC_IS_KNG_HAS_ROUTE=\`curl -s \${TMP_ASYNC_KNG_CFG_HOST}:${TMP_WBH_SETUP_KNG_API_HTTP_PORT}/routes | jq ".data[].hosts" | grep -o "\\\"\${TMP_ASYNC_KNG_BUF_DOMAIN}\\\""\`

    if [ -z "\${TMP_ASYNC_IS_KNG_HAS_ROUTE}" ]; then
        # 修改临时变量
        local TMP_KONG_ADMIN_LISTEN_HOST="\${TMP_ASYNC_KNG_CFG_HOST}"
        kong_api "service" "\${TMP_ASYNC_KNG_CFG_HOST}" "" "\${TMP_ASYNC_SERVICE_NAME}" "\${TMP_WBH_SETUP_CDY_HOST}:\${TMP_WBH_SETUP_CDY_HTTP_PORT}" "\${TMP_ASYNC_KNG_BUF_DOMAIN}"
    fi

    # 证书同步部分
    # -- 获取CADDY证书数据
    local TMP_CERT_DATA_FROM_CDY=\`curl -s ${TMP_WBH_SETUP_CDY_HOST}:${TMP_WBH_SETUP_API_HTTP_PORT}/hooks/cor-caddy-api?domain=\${TMP_ASYNC_KNG_BUF_DOMAIN}\`
    local TMP_CERT_DATA_KEY_FROM_CDY=\`echo "\${TMP_CERT_DATA_FROM_CDY}" | jq ".key"\`

    # -- 获取KONG证书数据
    TMP_CERT_DATA_FROM_KNG=\`curl -s ${TMP_ASYNC_KNG_CFG_HOST}:${TMP_WBH_SETUP_KNG_API_HTTP_PORT}/certificates?tags=\${TMP_ASYNC_KNG_BUF_DOMAIN}\`
    TMP_CERT_DATA_KEY_FROM_KNG=\`echo "\${TMP_CERT_DATA_FROM_KNG}" | jq ".data[].key"\`

    # -- 对比key文件，判断是否更新
    if [ "\${TMP_CERT_DATA_KEY_FROM_CDY}" != "\${TMP_CERT_DATA_KEY_FROM_KNG}" ]; then
        TMP_CERT_DATA_KEY_FROM_CDY=\`echo "\${TMP_CERT_DATA_FROM_CDY}" | jq ".key" | xargs -I {} echo -e {}\`
        TMP_CERT_DATA_CRT_FROM_CDY=\`echo "\${TMP_CERT_DATA_FROM_CDY}" | jq ".crt" | xargs -I {} echo -e {}\`

        TMP_CERT_DATA_ID_FROM_KNG=\`echo "\${TMP_CERT_DATA_FROM_KNG}" | jq ".data[].id"\`
        TMP_CERT_DATA_ID_FINAL=\${TMP_CERT_DATA_ID_FROM_KNG:-\`cat /proc/sys/kernel/random/uuid\`}
        
        put_cert "\${TMP_ASYNC_KNG_CFG_HOST}" "\${TMP_CERT_DATA_ID_FINAL}" "\${TMP_ASYNC_KNG_BUF_DOMAIN}" "\${TMP_CERT_DATA_CRT_FROM_CDY}" "\${TMP_CERT_DATA_KEY_FROM_CDY}"

        # 打印日志    
        tee \${TMP_THIS_LOG_PATH} <<-EOF
Refresh cert at '\${LOCAL_TIME}'
----------------------------------------------------------------
|ID：\${TMP_CERT_DATA_ID_FROM_KNG}
|Host&Tags：\${TMP_ASYNC_KNG_BUF_DOMAIN}
|Key：
\${TMP_CERT_DATA_KEY_FROM_CDY}

|Cert：
\${TMP_CERT_DATA_CRT_FROM_CDY}
----------------------------------------------------------------

``EOF
        
        # 无关紧要的标记更新
        patch_cert_att "\${TMP_ASYNC_KNG_CFG_HOST}" "\${TMP_CERT_DATA_ID_FINAL}" "\${TMP_ASYNC_KNG_BUF_DOMAIN}"
    fi

    # 添加日志区分
    curl -s ${TMP_WBH_SETUP_CDY_HOST}:${TMP_WBH_SETUP_API_HTTP_PORT}/config/apps/http/servers/autohttps/logs/logger_names -X POST -H "Content-Type: application/json" -d '{"\${TMP_ASYNC_KNG_BUF_DOMAIN}": "\${TMP_ASYNC_KNG_BUF_DOMAIN}"}'
}

function execute() {
    # line=\${url.domain}@\${request.remote-addr}
    while read line
    do
        local TMP_LINE_HOST=`echo \${line} | awk -F'@' '{print \$NR}'`
        local TMP_LINE_FROM=`echo \${line} | awk -F'@' '{print \$NF}'`

        # 忽略非域名请求（简单的验证，足够用）
        if [ \`echo \${TMP_LINE_HOST} | tr -cd "." | wc -c\` -eq 3 ]; then
            continue
        fi

        local TMP_LINE_HOST_CDY_SOURCE=\`curl -s ${TMP_WBH_SETUP_CDY_HOST}:${TMP_WBH_SETUP_CDY_API_HTTP_PORT}/config/apps/http/servers/autohttps/routes | grep -o "\\\"host\\\":\[\\\"\${TMP_LINE_HOST}\\\"\]"\`    
        # -- 未添加路由，直接返回不做处理(正常来说，由caddy-api获取到添加域名证书的请求，则触发openssl给出证书验证，才有本地数据)
        if [ -z "\${TMP_LINE_HOST_CDY_SOURCE}" ]; then
            echo "Can't find host '\${TMP_LINE_HOST}' route from caddy."
            continue
        fi

        sync_conf "\${TMP_LINE_HOST}" "\${TMP_LINE_FROM}"
                
        # 如果失败不会执行到此处，脚本会在前面直接退出
        sed -i "/^\${line}\$/d" \${TMP_REQUEST_HOST_CACHE_PATH}
    done < \${TMP_REQUEST_HOST_CACHE_PATH}
}

execute
echo
EOF
    
    # 每天凌晨，12点，18点各执行1次。新增的需要手动执行脚本。
    # echo "0 0/12/18 * * * ${TMP_WBH_SETUP_ETC_SCRIPTS_DIR}/sync-caddy-conf-to-kong.sh >> ${TMP_WBH_SETUP_LOGS_DIR}/sync-caddy-conf-to-kong-crontab.log 2>&1" >> /var/spool/cron/root
    echo "* * * * * ${TMP_WBH_SETUP_ETC_SCRIPTS_DIR}/sync-caddy-conf-to-kong.sh >> ${TMP_WBH_SETUP_LOGS_DIR}/sync-caddy-conf-to-kong-crontab.log 2>&1" >> /var/spool/cron/root
    
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
	nohup bin/webhook -port ${TMP_WBH_SETUP_API_HTTP_PORT} -hooks etc/hooks/webhook_boot.json -verbose -hotreload > logs/boot.log 2>&1 &

    curl http://localhost:${TMP_WBH_SETUP_API_HTTP_PORT}/hooks/test

    # 查看启动状态
    lsof -i:${TMP_WBH_SETUP_API_HTTP_PORT}
    cat logs/boot.log

	# 添加系统启动命令
    echo_startup_config "webhook" "${TMP_WBH_SETUP_DIR}" "bin/webhook -port ${TMP_WBH_SETUP_API_HTTP_PORT} -hooks etc/hooks/webhook_boot.json -verbose" "" "1"

    # 开放端口
    echo_soft_port ${TMP_WBH_SETUP_API_HTTP_PORT}
    
    # 生成web授权访问脚本
    echo_web_service_init_scripts "webhook${LOCAL_ID}" "webhook${LOCAL_ID}-webui.${SYS_DOMAIN}" ${TMP_WBH_SETUP_API_HTTP_PORT} "${LOCAL_HOST}"

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
