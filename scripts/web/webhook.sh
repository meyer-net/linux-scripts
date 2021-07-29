#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 安装标题：Webhook
# 软件名称：webhook
# 软件大写名称：WEBHOOK
# 软件大写分组与简称：WBH
# 软件安装名称：webhook
# 软件授权用户名称&组：webhook/webhook_group
#------------------------------------------------
local TMP_SETUP_KONG_HOST="127.0.0.1"
local TMP_SETUP_CDY_HOST="127.0.0.1"

# 1-配置环境
function set_environment()
{
    cd ${__DIR}

	return $?
}

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
	local TMP_WBH_LNK_LOGS_DIR=${LOGS_DIR}/webhook
	local TMP_WBH_LNK_DATA_DIR=${DATA_DIR}/webhook
	local TMP_WBH_LOGS_DIR=${TMP_WBH_SETUP_DIR}/logs
	local TMP_WBH_DATA_DIR=${TMP_WBH_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_WBH_LOGS_DIR}
	rm -rf ${TMP_WBH_DATA_DIR}
	mkdir -pv ${TMP_WBH_LNK_LOGS_DIR}
	mkdir -pv ${TMP_WBH_LNK_DATA_DIR}
	
	ln -sf ${TMP_WBH_LNK_LOGS_DIR} ${TMP_WBH_LOGS_DIR}
	ln -sf ${TMP_WBH_LNK_DATA_DIR} ${TMP_WBH_DATA_DIR}

	# 环境变量或软连接
	echo "WEBHOOK_HOME=${TMP_WBH_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$WEBHOOK_HOME/bin:$PATH' >> /etc/profile
	echo "export PATH WEBHOOK_HOME" >> /etc/profile

    # 重新加载profile文件
    source /etc/profile
	# ln -sf ${TMP_WBH_SETUP_DIR}/bin/webhook /usr/bin/webhook

	return $?
}

# 3-设置软件
function conf_webhook()
{
	local TMP_WBH_SETUP_DIR=${1}

	cd ${TMP_WBH_SETUP_DIR}
    
	local TMP_WBH_LOGS_DIR=${TMP_WBH_SETUP_DIR}/logs
	local TMP_WBH_DATA_DIR=${TMP_WBH_SETUP_DIR}/data
    local TMP_WBH_DATA_HOOKS_DIR=${TMP_WBH_DATA_DIR}/hooks
    local TMP_WBH_DATA_SCRIPTS_DIR=${TMP_WBH_DATA_DIR}/scripts

    mkdir -pv ${TMP_WBH_DATA_HOOKS_DIR}
    mkdir -pv ${TMP_WBH_DATA_SCRIPTS_DIR}

    # 本机装有caddy
    local TMP_WBH_CDY_HOOKS_JSON="{}"
    local TMP_IS_CDY_LOCAL=`lsof -i:2019`
    if [ -z "${TMP_IS_CDY_LOCAL}" ]; then    
        TMP_WBH_CDY_HOOKS_JSON="{
            \"id\": \"cor-caddy-api\",  \
            \"execute-command\": \"${TMP_WBH_DATA_SCRIPTS_DIR}/cor-caddy-api.sh\",  \
            \"http-methods\": [\"Get\"],  \
            \"include-command-output-in-response\": true,  \
            \"command-working-directory\": \"${TMP_WBH_LOGS_DIR}\",  \
            \"pass-arguments-to-command\": [{  \
                \"source\": \"url\",  \
                \"name\": \"host\"  \
            }]  \
        }"
        
        conf_webhook_cor_caddy_api ${1}
    fi

    # 本机装有kong
    local TMP_WBH_KONG_HOOKS_JSON="{}"
    local TMP_IS_KONG_LOCAL=`lsof -i:8000`
    if [ -z "${TMP_IS_KONG_LOCAL}" ]; then    
        TMP_WBH_KONG_HOOKS_JSON="{
            \"id\": \"async-caddy-cert-to-kong\",  \
            \"execute-command\": \"${TMP_WBH_DATA_SCRIPTS_DIR}/async-caddy-cert-to-kong.sh\",  \
            \"http-methods\": [\"Post \"],  \
            \"command-working-directory\": \"${TMP_WBH_LOGS_DIR}\",  \
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
        
        conf_webhook_async_caddy_cert_to_kong ${1}
    fi

    local TMP_WBH_BOOT_HOOKS_JSON=`echo "[${TMP_WBH_CDY_HOOKS_JSON},${TMP_WBH_KONG_HOOKS_JSON}]" | sed 's@{},*@@g'`
    
    echo "##############################################################" 
    # "source": "entire-payload" #通过此打印全部
sudo tee ${TMP_WBH_DATA_HOOKS_DIR}/async-caddy-cert-to-kong.json <<-EOF
${TMP_WBH_BOOT_HOOKS_JSON}
EOF    
    echo "##############################################################" 

    chmod +x ${TMP_WBH_DATA_SCRIPTS_DIR}/*.sh

	return $?
}

# 配置webhook，辅助caddy未有api
# 参数1：安装目录
function conf_webhook_cor_caddy_api()
{
	local TMP_WBH_SETUP_DIR=${1}

	cd ${TMP_WBH_SETUP_DIR}
    
	local TMP_WBH_LOGS_DIR=${TMP_WBH_SETUP_DIR}/logs
	local TMP_WBH_DATA_DIR=${TMP_WBH_SETUP_DIR}/data
    local TMP_WBH_DATA_HOOKS_DIR=${TMP_WBH_DATA_DIR}/hooks
    local TMP_WBH_DATA_SCRIPTS_DIR=${TMP_WBH_DATA_DIR}/scripts

    echo "--------------------------------------------------------------" 
    
sudo tee ${TMP_WBH_DATA_SCRIPTS_DIR}/cor-caddy-api.sh <<-EOF
#!/bin/sh
#------------------------------------------------
#  Project Web hook script for cor caddy api
# bak：
# TMP_CERT_DATA_KEY_FROM_CDY_FORMAT=`echo \${TMP_CERT_DATA_KEY_FROM_CDY} | sed ':a;N;$!ba;s@\n@\\\\n@g'`
# TMP_CERT_DATA_CRT_FROM_CDY_FORMAT=`echo \${TMP_CERT_DATA_CRT_FROM_CDY} | sed ':a;N;$!ba;s@\n@\\\\n@g'`
#
#  | jq ".key_fmt=\"\${TMP_CERT_DATA_KEY_FROM_CDY_FORMAT}\""  \
#  | jq ".crt_fmt=\"\${TMP_CERT_DATA_CRT_FROM_CDY_FORMAT}\""
#------------------------------------------------
# 忽略非域名请求（简单的验证，足够用）
if [ `echo \${1} | tr -cd "." | wc -c` -eq 3 ]; then
    return
fi

function execute() {
    local TMP_COR_CDY_CERT_HOST=\$1 #request.headers.host

    # 未运行caddy的情况下，不执行脚本
    local TMP_IS_CDY_LOCAL=`lsof -i:2019`
    if [ -z "\${TMP_IS_CDY_LOCAL}" ]; then    
        echo "Webhook.Caddy.Cor: When getting cert of '\${TMP_COR_CDY_CERT_HOST}'，Can't find caddy server。request break。" >> ${TMP_WBH_LOGS_DIR}/async-caddy-cert-to-kong.log
        echo "{}"
        return
    fi

    local TMP_CERT_DATA_DIR=`find / -name \${TMP_COR_CDY_CERT_HOST}.key -user caddy 2> /dev/null | grep certificates | xargs -I {} dirname {}`
    
    # 本机不存在数据的情况下，则不执行脚本
    if [ -z "\${TMP_CERT_DATA_DIR}" ]; then    
        echo "Webhook.Caddy.Cor: When getting cert of '\${TMP_COR_CDY_CERT_HOST}'，Can't find caddy data dir。request break。" >> ${TMP_WBH_LOGS_DIR}/async-caddy-cert-to-kong.log
        echo "{}"
        return
    fi

    local TMP_CERT_DATA_KEY_FROM_CDY=`cat \${TMP_CERT_DATA_DIR}/\${TMP_COR_CDY_CERT_HOST}.key`
    local TMP_CERT_DATA_CRT_FROM_CDY=`cat \${TMP_CERT_DATA_DIR}/\${TMP_COR_CDY_CERT_HOST}.crt`

    echo "{}"  \
    | jq ".key=\"\${TMP_CERT_DATA_KEY_FROM_CDY}\""  \
    | jq ".crt=\"\${TMP_CERT_DATA_CRT_FROM_CDY}\""
}

echo
execute "\$1"
EOF

    echo "--------------------------------------------------------------" 

	return $?
}

# 配置webhook，辅助caddy未有api
# 参数1：安装目录
function conf_webhook_async_caddy_cert_to_kong()
{
	local TMP_WBH_SETUP_DIR=${1}

	cd ${TMP_WBH_SETUP_DIR}
    
	local TMP_WBH_LOGS_DIR=${TMP_WBH_SETUP_DIR}/logs
	local TMP_WBH_DATA_DIR=${TMP_WBH_SETUP_DIR}/data
    local TMP_WBH_DATA_HOOKS_DIR=${TMP_WBH_DATA_DIR}/hooks
    local TMP_WBH_DATA_SCRIPTS_DIR=${TMP_WBH_DATA_DIR}/scripts

    # 不在本机的情况下，需要输入地址
    local TMP_SETUP_IS_KONG_LOCAL=`lsof -i:8000`
    if [ -z "${TMP_SETUP_IS_KONG_LOCAL}" ]; then    
    	input_if_empty "TMP_SETUP_KONG_HOST" "Webhook.Kong.Host: Please ender ${red}your kong host address${reset}"
    fi

sudo tee ${TMP_WBH_DATA_SCRIPTS_DIR}/async-caddy-cert-to-kong.sh <<-EOF
#!/bin/sh
#------------------------------------------------
#  Project Web hook Script
#------------------------------------------------
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

    local request_code=`curl -o /dev/null -s -w %{http_code} -X PUT http://${TMP_SETUP_KONG_HOST}:8000/certificates/\${tmp_certificates_id}  \
        -F "cert=`echo -e \${tmp_certificates_cert}"`  \
        -F "key=`echo -e \${tmp_certificates_key}"`  \
        -F "tags[]=by-webhook-async"  \
        -F "tags[]=by-caddy-acme"  \
        -F "tags[]=\${tmp_certificates_snis}"  \
        -F "snis[]=\${tmp_certificates_snis}"`
        
    if [ "\${request_code::1}" != "2" ]; then
    	echo "Webhook.PutCertificates: Failure, remote response '\${request_code}'."
    	exit 9
    fi

	return $?
}

function execute() {
    local LOCAL_TIME=`date +"%Y-%m-%d %H:%M:%S"`
    local TMP_ASYNC_CADDY_CERT_HOST=\$1 #request.headers.host

    # 忽略非域名请求（简单的验证，足够用）
    if [ `echo \${TMP_ASYNC_CADDY_CERT_HOST} | tr -cd "." | wc -c` -eq 3 ]; then
        return
    fi

    #获取CADDY证书数据`
    TMP_CERT_DATA_FROM_CDY=`curl -s ${TMP_SETUP_CDY_HOST}:9000/hooks/cor-caddy-api?host=\${TMP_ASYNC_CADDY_CERT_HOST}`
    TMP_CERT_DATA_KEY_FROM_CDY=`echo "\${TMP_CERT_DATA_FROM_CDY}" | jq ".key"`

    # #??? 重新判断
    # # caddy未生成证书时，保持始终等待，因该web请求只执行了一次。此处待修改为临时缓存，加入定时任务队列(否则一直睡眠可能产生请求超时问题)
    # while [ ! -f "\${TMP_CERT_DATA_KEY_PATH}" ]; do
    #     echo "Can't find caddy cert of '\${TMP_ASYNC_CADDY_CERT_HOST}', sleep start" >> \${TMP_WBH_LOGS_DIR}/async-caddy-cert-to-kong.log
    #     sleep 10
    # done

    #获取KONG证书数据`
    TMP_CERT_DATA_FROM_KONG=`curl -s ${TMP_SETUP_KONG_HOST}:8000/certificates?tags=\${TMP_ASYNC_CADDY_CERT_HOST}`
    TMP_CERT_DATA_KEY_FROM_KONG=`echo "\${TMP_CERT_DATA_FROM_KONG}" | jq ".data[].key"`

    # 对比key文件，判断是否更新
    if [ "\${TMP_CERT_DATA_KEY_FROM_CDY}" != "\${TMP_CERT_DATA_KEY_FROM_KONG}" ]; then
        TMP_CERT_DATA_KEY_FROM_CDY=`echo "\${TMP_CERT_DATA_FROM_CDY}" | jq ".key" | xargs -I {} echo -e {}`
        TMP_CERT_DATA_CRT_FROM_CDY=`echo "\${TMP_CERT_DATA_FROM_CDY}" | jq ".crt" | xargs -I {} echo -e {}`
        sudo tee \${TMP_WBH_LOGS_DIR}/async-caddy-cert-to-kong.log <<-EOF

    Refresh cert at '\${LOCAL_TIME}'
    ----------------------------------------------------------------
    ID：\${TMP_CERT_DATA_ID_FROM_KONG}
    Host&Tags：\${TMP_ASYNC_CADDY_CERT_HOST}
    Key：
    \${TMP_CERT_DATA_KEY_FROM_CDY}
    Cert：
    \${TMP_CERT_DATA_CRT_FROM_CDY}
    ----------------------------------------------------------------

    \EOF

        TMP_CERT_DATA_ID_FROM_KONG=`echo "\${TMP_CERT_DATA_FROM_KONG}" | jq ".data[].id"`
        TMP_CERT_DATA_ID_FINAL=\${TMP_CERT_DATA_ID_FROM_KONG:-`cat /proc/sys/kernel/random/uuid`}
        
        put_certificates "\${TMP_CERT_DATA_ID_FINAL}" "\${TMP_ASYNC_CADDY_CERT_HOST}" "\${TMP_CERT_DATA_CRT_FROM_CDY}" "\${TMP_CERT_DATA_KEY_FROM_CDY}"
        
    fi
}

echo
execute "\$1"
EOF

    echo "--------------------------------------------------------------" 

	return $?
}

# 4-启动软件
function boot_webhook()
{
	local TMP_WBH_SETUP_DIR=${1}

	cd ${TMP_WBH_SETUP_DIR}
	
	# 验证安装
    bin/webhook -version

	# 当前启动命令
	bin/webhook -hooks data/hooks/async-caddy-cert-to-kong.json -verbose -hotreload

	# 添加系统启动命令
    echo_startup_config "webhook" "${TMP_WBH_SETUP_DIR}" "bin/webhook -hooks data/hooks/async-caddy-cert-to-kong.json -verbose -hotreload" "" "1"

    # 开放端口
    echo_soft_port 9000

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

#安装主体
setup_soft_basic "Webhook" "down_webhook"
