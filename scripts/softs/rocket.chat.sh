#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 相关参考：
#		  https://docs.rocket.chat/installing-and-updating/manual-installation/centos
#------------------------------------------------
# 更新操作：
# sudo systemctl stop rocketchat
# curl -L https://releases.rocket.chat/latest/download -o /tmp/rocket.chat.tgz
# tar -xzf /tmp/rocket.chat.tgz -C /tmp
# 
# TMP_RC_SETUP_DFT_VERS=`cat /tmp/bundle/star.json | grep "nodeVersion" | awk -F' ' '{print $2}' | sed "s@\"@@g" | sed "s@,\\\$@@g"`
# if [ -n "${TMP_RC_SETUP_DFT_VERS}" ]; then
# 	nvm install ${TMP_RC_SETUP_DFT_VERS} && nvm use ${TMP_RC_SETUP_DFT_VERS}
# fi
#     
# cd /tmp/bundle/programs/server && npm install
# sudo rsync -av /tmp/bundle/ /opt/rocket.chat
# sudo chown -R rocketchat:rocketchat /opt/rocket.chat
# sudo systemctl start rocketchat
# rm -rf /tmp/bundle
#------------------------------------------------
local TMP_RC_SETUP_PORT=13000
local TMP_RC_SETUP_MGDB_HOST="${LOCAL_HOST}"
local TMP_RC_SETUP_MGDB_PORT=27017
local TMP_RC_SETUP_MGDB_USER="admin"
local TMP_RC_SETUP_MGDB_PWD="mongo%DB!m${LOCAL_ID}_"

##########################################################################################################

# 1-配置环境
function set_env_rocket_chat()
{
    local TMP_IS_RC_MGDB_LOCAL=`lsof -i:${TMP_RC_SETUP_MGDB_PORT}`
    if [ -z "${TMP_IS_RC_MGDB_LOCAL}" ]; then 
    	exec_yn_action "setup_mongodb" "RocketChat.MongoDB: Can't find dependencies compment of ${red}mongodb${reset}，please sure if u want to get ${green}mongodb local${reset} or remote got?"
	fi
	
    cd ${__DIR} && source scripts/lang/nodejs.sh

    soft_yum_check_setup "gcc-c++,epel-release,GraphicsMagick"

	return $?
}

##########################################################################################################

function setup_mongodb()
{   
    cd ${__DIR} && source scripts/database/mongodb.sh

	TMP_RC_SETUP_MGDB_HOST="127.0.0.1"

    return $?
}

# 2-安装软件
function setup_rocket_chat()
{
	## 直装模式
	cd ${TMP_RC_CURRENT_DIR}/programs/server && npm install

	cd `dirname ${TMP_RC_CURRENT_DIR}`

	mv ${TMP_RC_CURRENT_DIR} ${TMP_RC_SETUP_DIR}

	cd ${TMP_RC_SETUP_DIR}

	# 创建日志软链
	local TMP_RC_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/rocket.chat
	local TMP_RC_SETUP_LNK_DATA_DIR=${DATA_DIR}/rocket.chat
	local TMP_RC_SETUP_LOGS_DIR=${TMP_RC_SETUP_DIR}/logs
	local TMP_RC_SETUP_DATA_DIR=${TMP_RC_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_RC_SETUP_LOGS_DIR}
	rm -rf ${TMP_RC_SETUP_DATA_DIR}
	mkdir -pv ${TMP_RC_SETUP_LNK_LOGS_DIR}
	mkdir -pv ${TMP_RC_SETUP_LNK_DATA_DIR}
	
	ln -sf ${TMP_RC_SETUP_LNK_LOGS_DIR} ${TMP_RC_SETUP_LOGS_DIR}
	ln -sf ${TMP_RC_SETUP_LNK_DATA_DIR} ${TMP_RC_SETUP_DATA_DIR}

	# 授权权限，否则无法写入
	create_user_if_not_exists rocketchat rocketchat
	chown -R rocketchat:rocketchat ${TMP_RC_SETUP_DIR}
	chown -R rocketchat:rocketchat ${TMP_RC_SETUP_LNK_LOGS_DIR}
	chown -R rocketchat:rocketchat ${TMP_RC_SETUP_LNK_DATA_DIR}
	
    # 安装初始
    # 参照 rocket.chat 自己的版本安装使用
    local TMP_RC_SETUP_DFT_VERS=`cat star.json | grep "nodeVersion" | awk -F' ' '{print $2}' | sed "s@\"@@g" | sed "s@,\\\$@@g"`
    nvm install ${TMP_RC_SETUP_DFT_VERS} && nvm use ${TMP_RC_SETUP_DFT_VERS}
    
    # nvm alias default ${TMP_RC_SETUP_DFT_VERS}

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_rocket_chat()
{
	cd ${TMP_RC_SETUP_DIR}
	
	local TMP_RC_SETUP_LNK_ETC_DIR=${ATT_DIR}/rocket.chat
	local TMP_RC_SETUP_ETC_DIR=${TMP_RC_SETUP_DIR}/etc

	# ①-N：不存在配置文件：
	rm -rf ${TMP_RC_SETUP_ETC_DIR}
	mkdir -pv ${TMP_RC_SETUP_LNK_ETC_DIR}

	ln -sf ${TMP_RC_SETUP_LNK_ETC_DIR} ${TMP_RC_SETUP_ETC_DIR}

	# 开始配置
    setsebool -P httpd_can_network_connect 1

	input_if_empty "TMP_RC_SETUP_MGDB_HOST" "Rocket.Chat.MongoDB: Please ender the ${red}mongodb host address${reset} for rocket.chat"
    set_if_equals "TMP_RC_SETUP_MGDB_HOST" "LOCAL_HOST" "127.0.0.1"
	
	input_if_empty "TMP_RC_SETUP_MGDB_PORT" "Rocket.Chat.MongoDB: Please ender the ${red}mongodb host address port${reset} of '${TMP_RC_SETUP_MGDB_HOST}' for rocket.chat"
	input_if_empty "TMP_RC_SETUP_MGDB_USER" "Rocket.Chat.MongoDB: Please ender the ${red}mongodb user${reset} of '${TMP_RC_SETUP_MGDB_HOST}:${TMP_RC_SETUP_MGDB_PORT}' for rocket.chat"
	input_if_empty "TMP_RC_SETUP_MGDB_PWD" "Rocket.Chat.MongoDB: Please ender the ${red}mongodb password${reset} of '${TMP_RC_SETUP_MGDB_USER}@${TMP_RC_SETUP_MGDB_HOST}:${TMP_RC_SETUP_MGDB_PORT}' for rocket.chat"
    
	local TMP_RC_SETUP_LOGS_DIR=${TMP_RC_SETUP_DIR}/logs
	local TMP_RC_SETUP_NODE_PATH=`nvm which current`

	# 启动配置加载(修改为其默认node版本启动)
	# "MONGO_URL": "mongodb://<db_username>:<db_password>@<db_server_host>:<db_server_port>/<db_name>",
	# "MONGO_OPLOG_URL": "mongodb://<oplog_username>:<oplog_password>@<db_server_host>:<db_server_port>/<oplog_db_name>?authSource=admin"
	local TMP_RC_SETUP_MGDB_URL="mongodb://${TMP_RC_SETUP_MGDB_HOST}:${TMP_RC_SETUP_MGDB_PORT}/rocketchat?replicaSet=rs01"
	local TMP_RC_SETUP_MGDB_OPLOG_URL="mongodb://${TMP_RC_SETUP_MGDB_HOST}:${TMP_RC_SETUP_MGDB_PORT}/local?replicaSet=rs01"

	# 判断有密码的情况
	if [ -n "${TMP_RC_SETUP_MGDB_PWD}" ]; then
		TMP_RC_SETUP_MGDB_URL="mongodb://${TMP_RC_SETUP_MGDB_USER}:${TMP_RC_SETUP_MGDB_PWD}@${TMP_RC_SETUP_MGDB_HOST}:${TMP_RC_SETUP_MGDB_PORT}/rocketchat?replicaSet=rs01"
		TMP_RC_SETUP_MGDB_OPLOG_URL="mongodb://${TMP_RC_SETUP_MGDB_USER}:${TMP_RC_SETUP_MGDB_PWD}@${TMP_RC_SETUP_MGDB_HOST}:${TMP_RC_SETUP_MGDB_PORT}/local?replicaSet=rs01&authSource=admin"
	fi

	cat << EOF | sudo tee -a /lib/systemd/system/rocketchat.service
[Unit]
Description=The Rocket.Chat server
After=network.target remote-fs.target nss-lookup.target nginx.service mongod.service
[Service]
ExecStart=${TMP_RC_SETUP_NODE_PATH} ${TMP_RC_SETUP_DIR}/main.js > ${TMP_RC_SETUP_LOGS_DIR}/rocket.chat.log
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=rocketchat
User=rocketchat
Environment=MONGO_URL=${TMP_RC_SETUP_MGDB_URL} MONGO_OPLOG_URL=${TMP_RC_SETUP_MGDB_OPLOG_URL} ROOT_URL=http://${LOCAL_HOST}:${TMP_RC_SETUP_PORT}/ PORT=${TMP_RC_SETUP_PORT}
[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload

	# 授权权限，否则无法写入
	# chown -R rocketchat:rocketchat ${TMP_RC_SETUP_LNK_ETC_DIR}

    cat > update.sh <<EOF
#!/bin/bash
sudo systemctl stop rocketchat.service
curl -L https://releases.rocket.chat/latest/download -o /tmp/rocket.chat.tgz
tar -xzf /tmp/rocket.chat.tgz -C /tmp

TMP_RC_UPDATE_DFT_VERS=`cat /tmp/bundle/star.json | grep "nodeVersion" | awk -F' ' '{print $2}' | sed "s@\"@@g" | sed "s@,\\\$@@g"`
if [ -n "${TMP_RC_UPDATE_DFT_VERS}" ]; then
	nvm install ${TMP_RC_UPDATE_DFT_VERS} && nvm use ${TMP_RC_UPDATE_DFT_VERS}
fi
    
cd /tmp/bundle/programs/server && npm install
sudo rsync -av /tmp/bundle/ ${TMP_RC_SETUP_DIR}
sudo chown -R rocketchat:rocketchat ${TMP_RC_SETUP_DIR}
sudo systemctl start rocketchat.service
rm -rf /tmp/bundle
EOF

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_rocket_chat()
{
	cd ${TMP_RC_SETUP_DIR}
	
    # 当前启动命令 && 等待启动
    chkconfig rocket.chat on
    chkconfig --list | grep rocket.chat
	echo
    echo "Starting rocket.chat，Waiting for a moment"
    echo "--------------------------------------------"
    nohup systemctl start rocketchat.service > logs/boot.log 2>&1 &
    sleep 15

    cat logs/boot.log
    echo "--------------------------------------------"

	# 启动状态检测
    systemctl status rocketchat.service
	lsof -i:${TMP_RC_SETUP_PORT}

	# 设定启动运行
    systemctl enable rocketchat.service
	
	# 授权iptables端口访问
	echo_soft_port ${TMP_RC_SETUP_PORT}

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_rocket_chat()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_rocket_chat()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_rocket_chat()
{
	# 变量覆盖特性，其它方法均可读取
	local TMP_RC_SETUP_DIR=${1}
	local TMP_RC_CURRENT_DIR=`pwd`
    
	set_env_rocket_chat 

	setup_rocket_chat 

	conf_rocket_chat 

    # down_plugin_rocket_chat 
    # setup_plugin_rocket_chat 

	boot_rocket_chat 

	# reconf_rocket_chat 

	return $?
}

##########################################################################################################

# x1-下载软件
function down_rocket_chat()
{
    setup_soft_wget "rocket.chat" "https://releases.rocket.chat/latest/download -O rocket.chat.tgz" "exec_step_rocket_chat"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "Rocket.Chat" "down_rocket_chat"
