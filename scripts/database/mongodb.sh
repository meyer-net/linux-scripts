#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 相关参考：
#		  
#------------------------------------------------
# show dbs：显示数据库列表 
# show collections：显示当前数据库中的集合（类似关系数据库中的表） 
# show users：显示用户
# 
# use <db name>：切换当前数据库，这和MS-SQL里面的意思一样 
# db.help()：显示数据库操作命令，里面有很多的命令 
# db.foo.help()：显示集合操作命令，同样有很多的命令，foo指的是当前数据库下，一个叫foo的集合，并非真正意义上的命令 
# db.foo.find()：对于当前数据库中的foo集合进行数据查找（由于没有条件，会列出所有数据） 
# db.foo.find( { a : 1 } )：对于当前数据库中的foo集合进行查找，条件是数据中有一个属性叫a，且a的值为1
# 
# MongoDB没有创建数据库的命令，但有类似的命令。
# 如：如果你想创建一个“myTest”的数据库，先运行use myTest命令，之后就做一些操作（如：db.createCollection('user')）,这样就可以创建一个名叫“myTest”的数据库。
# 
# MongoDB中，集合相当于表的概念
# 导出表数据：mongoexport -h localhost:27017 -d rocketchat -c rocketchat_message -o /tmp/rocketchat.json
# 导入表数据：mongoimport -h localhost:27017 -d rocketchat -c rocketchat_message /tmp/rocketchat.json
# 导出库数据：mongodump -h localhost:27017 -d rocketchat -o /tmp/mongodump/
# 导入库数据：mongorestore -h localhost:27017 -d rocketchat --dir /tmp/mongodump/
# 	这里需要注意三点：
# 			 1、mongodump/ 目录下放的就是以数据库名命名的文件夹，最好不要再放其他文件夹或文件。
# 			 2、数据库必须已经存在这个库。
# 			 3、需要在授权时导入：如果执行失败，可以在服务里先关闭MongoDB服务，暂时用命令行启动MongoDB服务，再执行命令即可。
# 其它：
# 连接本地数据库服务器，端口是默认的
#	mongodb://localhost
# 使用用户名fred，密码foobar登录localhost的admin数据库。
#	mongodb://fred:foobar@localhost
# 使用用户名fred，密码foobar登录localhost的baz数据库。
#	mongodb://fred:foobar@localhost/baz
# 连接 replica pair, 服务器1为example1.com服务器2为example2。
#	mongodb://example1.com:27017,example2.com:27017
# 连接 replica set 三台服务器 (端口 27017, 27018, 和27019):
#	mongodb://localhost,localhost:27018,localhost:27019
# 连接 replica set 三台服务器, 写入操作应用在主服务器 并且分布查询到从服务器。
#	mongodb://host1,host2,host3/?slaveOk=true
# 直接连接第一个服务器，无论是replica set一部分或者主服务器或者从服务器。
#	mongodb://host1,host2,host3/?connect=direct;slaveOk=true
# 当你的连接服务器有优先级，还需要列出所有服务器，你可以使用上述连接方式。安全模式连接到localhost:
#	mongodb://localhost/?safe=true
# 以安全模式连接到replica set，并且等待至少两个复制服务器成功写入，超时时间设置为2秒。
#	mongodb://host1,host2,host3/?safe=true;w=2;wtimeoutMS=2000
#------------------------------------------------
local TMP_MGDB_SETUP_PORT=27017
local TMP_MGDB_SETUP_PWD="mongo%DB^m${LOCAL_ID}~"

##########################################################################################################

# 1-配置环境
function set_env_mongodb()
{
    cd ${__DIR}

    soft_yum_check_setup "check-update"

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_mongodb()
{
	## 源模式
	cat << EOF | tee -a /etc/yum.repos.d/mongodb-org-5.0.repo
[mongodb-org-5.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/5.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc
EOF

	soft_yum_check_setup "mongodb-org"

	# 创建日志软链
	local TMP_MGDB_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/mongodb
	local TMP_MGDB_SETUP_LNK_DATA_DIR=${DATA_DIR}/mongodb
	local TMP_MGDB_SETUP_LOGS_DIR=${TMP_MGDB_SETUP_DIR}/logs
	local TMP_MGDB_SETUP_DATA_DIR=${TMP_MGDB_SETUP_DIR}/data

	# 先清理文件，再创建文件
    rm -rf ${TMP_MGDB_SETUP_LOGS_DIR}
	path_not_exists_create ${TMP_MGDB_SETUP_DIR}
	
	cd ${TMP_MGDB_SETUP_DIR}
	
	rm -rf ${TMP_MGDB_SETUP_LOGS_DIR}
	rm -rf ${TMP_MGDB_SETUP_DATA_DIR}
	path_not_exists_create ${TMP_MGDB_SETUP_LNK_LOGS_DIR}
	
	cp /var/lib/mongo ${TMP_MGDB_SETUP_LNK_DATA_DIR} -Rp
    mv /var/lib/mongo ${TMP_MGDB_SETUP_LNK_DATA_DIR}_empty
	
	ln -sf ${TMP_MGDB_SETUP_LNK_LOGS_DIR} ${TMP_MGDB_SETUP_LOGS_DIR}
	ln -sf ${TMP_MGDB_SETUP_LNK_DATA_DIR} ${TMP_MGDB_SETUP_DATA_DIR}
	ln -sf ${TMP_MGDB_SETUP_LNK_DATA_DIR} /var/lib/mongo

	# 授权权限，否则无法写入
	create_user_if_not_exists mongod mongod
	chown -R mongod:mongod ${TMP_MGDB_SETUP_LNK_LOGS_DIR}
	chown -R mongod:mongod ${TMP_MGDB_SETUP_LNK_DATA_DIR}

	rm -rf /etc/yum.repos.d/mongodb.repo
	
    yum clean all && yum makecache fast
	
    # 安装初始

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_mongodb()
{
	cd ${TMP_MGDB_SETUP_DIR}
	
	local TMP_MGDB_SETUP_LNK_ETC_DIR=${ATT_DIR}/mongodb
	local TMP_MGDB_SETUP_ETC_DIR=${TMP_MGDB_SETUP_DIR}/etc

	# ①-Y：存在配置文件：原路径文件放给真实路径
	rm -rf ${TMP_MGDB_SETUP_ETC_DIR}
	path_not_exists_create "${TMP_MGDB_SETUP_LNK_ETC_DIR}"
    
    # 开始配置(默认依照rc需求安装配置) - 必须先修改
    sed -i "s@^#  engine:@  engine: mmapv1@" /etc/mongod.conf
    sed -i "s@^#replication:@replication:\n  replSetName: rs01@" /etc/mongod.conf 

    sed -i "s@^  port:.*@  port: ${TMP_MGDB_SETUP_PORT}@" /etc/mongod.conf
    sed -i "s@^  bindIp:.*@  bindIp: 127.0.0.1,${LOCAL_HOST}@" /etc/mongod.conf

	# 替换原路径链接
    ln -sf /etc/mongod.conf ${TMP_MGDB_SETUP_LNK_ETC_DIR}/mongod.conf
	ln -sf ${TMP_MGDB_SETUP_LNK_ETC_DIR} ${TMP_MGDB_SETUP_ETC_DIR}
	

    # exchange_softlink "`pwd`/etc/mongod.conf" "/etc/mongod.conf" "rm -rf /etc/mongod.conf"

	return $?
}

function reconf_mongodb()
{
	cd ${TMP_MGDB_SETUP_DIR}
	
    mongo --host ${LOCAL_HOST} --eval "printjson(rs.initiate())"
    sleep 5
	
	# local TMP_MGDB_SETUP_DATA_DIR=${TMP_MGDB_SETUP_DIR}/data
	# mongod --bind_ip ${LOCAL_HOST} --dbpath=${TMP_MGDB_SETUP_DATA_DIR} --auth  # 启用认证

	input_if_empty "TMP_MGDB_SETUP_PWD" "MongoDB: Please ender ${green}mongodb password${reset} of ${red}root user(admin)${reset} for auth"

    cat > mongodb_init.js <<EOF
use admin
db.createUser({user:"admin",pwd:"${TMP_MGDB_SETUP_PWD}",roles:["root"]})
db.createUser({user:"super",pwd:"${TMP_MGDB_SETUP_PWD}",roles:[{ role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase"]})
db.auth("admin", "${TMP_MGDB_SETUP_PWD}")
db.auth("super", "${TMP_MGDB_SETUP_PWD}")
EOF

	cat mongodb_init.js | mongo --host ${LOCAL_HOST} --shell
	
	rm -rf mongodb_init.js
	
	# 开启持久验证
    sed -i "s@^#security:@security:\n  authorization: enabled@" /etc/mongod.conf 

	# 重启
    systemctl restart mongod.service
	
	return $?
}

##########################################################################################################

# 4-启动软件
function boot_mongodb()
{
	cd ${TMP_MGDB_SETUP_DIR}
	
	# 验证安装
    mongo --version  # lsof -i:${TMP_MGDB_SETUP_PORT}

	# 当前启动命令
    systemctl daemon-reload
    systemctl enable mongod.service

    # 等待启动
    echo "Starting mongodb，Waiting for a moment"
    echo "--------------------------------------------"
    systemctl start mongod.service
    sleep 5

	systemctl status mongod.service
    chkconfig mongod on
    # journalctl -u mongod --no-pager | less
    # systemctl reload mongod.service
    echo "--------------------------------------------"

	# 授权iptables端口访问
	echo_soft_port ${TMP_MGDB_SETUP_PORT}

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_mongodb()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_mongodb()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_mongodb()
{
	# 变量覆盖特性，其它方法均可读取
	local TMP_MGDB_SETUP_DIR=${SETUP_DIR}/mongodb
    
	set_env_mongodb 

	setup_mongodb 

	conf_mongodb 

    # down_plugin_mongodb 
    # setup_plugin_mongodb 

	boot_mongodb 

	reconf_mongodb 

	return $?
}

##########################################################################################################

# x1-下载软件
function check_setup_mongodb()
{
    soft_yum_check_action "mongodb-org" "exec_step_mongodb" "MongoDB was installed"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "MongoDB" "check_setup_mongodb"

