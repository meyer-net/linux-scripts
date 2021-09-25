#!/bin/sh
#------------------------------------------------
#      Centos7 Or Project Env InitScript
#      copyright https://oshit.thiszw.com/
#      author: meyer.cheng
#------------------------------------------------
# http://blog.csdn.net/u010861514/article/details/51028220
# 命令参考：https://www.jianshu.com/p/1bbdbf1aa1bd

# $? :上一个命令的执行状态返回值
# $#：:参数的个数
# $*：参数列表，所有的变量作为一个字符串
# $@：参数列表，每个变量作为单个字符串
# $1-9,${10}：位置参数
# $$：脚本的进程号
# $_：之前命令的最后一个参数
# $0：脚本的名称
# $！：运行在后台的最后一个进程ID

# 绑定系统域名设定
# 参数1：需要设置的变量名
function bind_sysdomain () {
    local TMP_SYS_DOMAIN="mydomain.com"
	if [ -f "${SETUP_DIR}/.sys_domain" ]; then
		TMP_SYS_DOMAIN=`cat ${SETUP_DIR}/.sys_domain`
	fi

	eval ${1}=`echo '${TMP_SYS_DOMAIN}'`

	return $?
}

# 交换软连接(不是软连接的情况下执行)
# 参数1：检测的路径
# 参数2：真实的路径 
# 参数3：交换前的动作
function exchange_softlink()
{
	local TMP_EXCHANGE_SOFT_LINK_CHECK_PATH=${1}
	local TMP_EXCHANGE_SOFT_LINK_TRUE_PATH=${2}
	local TMP_EXCHANGE_SOFT_LINK_ACTION_BEFORE=${3:-}

	if [ -f ${TMP_EXCHANGE_SOFT_LINK_CHECK_PATH} ]; then
		local TMP_EXCHANGE_SOFT_LINK_CHECK_IS_LINK=`ls -il ${TMP_EXCHANGE_SOFT_LINK_CHECK_PATH} | grep '\->'`
		if [ -z "${TMP_EXCHANGE_SOFT_LINK_CHECK_IS_LINK}" ]; then
			if [ -n "${TMP_EXCHANGE_SOFT_LINK_ACTION_BEFORE}" ]; then
				eval "${TMP_EXCHANGE_SOFT_LINK_ACTION_BEFORE}"
			fi

			cp ${TMP_EXCHANGE_SOFT_LINK_CHECK_PATH} ${TMP_EXCHANGE_SOFT_LINK_TRUE_PATH} -Rp
			rm -rf ${TMP_EXCHANGE_SOFT_LINK_CHECK_PATH}
        	ln -sf ${TMP_EXCHANGE_SOFT_LINK_TRUE_PATH} ${TMP_EXCHANGE_SOFT_LINK_CHECK_PATH}

			echo "Link Changed：${TMP_EXCHANGE_SOFT_LINK_CHECK_PATH} -> ${TMP_EXCHANGE_SOFT_LINK_TRUE_PATH}"
		fi
	else
		ln -sf ${TMP_EXCHANGE_SOFT_LINK_TRUE_PATH} ${TMP_EXCHANGE_SOFT_LINK_CHECK_PATH}

		echo "Linked：${TMP_EXCHANGE_SOFT_LINK_CHECK_PATH} -> ${TMP_EXCHANGE_SOFT_LINK_TRUE_PATH}"
    fi


	return $?
}

# 免密登录远程主机
# 参数1：需要免密登录的机器
# 参数2：需要免密登录的用户
function nopwd_login () {
    local TMP_NOPWD_LOGIN_REMOTE_HOST=${1}
    local TMP_NOPWD_LOGIN_REMOTE_USER=${2:-"root"}
    local TMP_NOPWD_LOGIN_REMOTE_HOST_PORT=${1:-22}

	if [ -n "${TMP_NOPWD_LOGIN_REMOTE_HOST}" ]; then
		local TMP_NOPWD_LOGIN_ID_RSA_PATH="~/.ssh/id_rsa"

		path_not_exists_action "${TMP_NOPWD_LOGIN_ID_RSA_PATH}" "ssh-keygen -t rsa"
		
		ssh-copy-id ${TMP_NOPWD_LOGIN_REMOTE_USER}@${TMP_NOPWD_LOGIN_REMOTE_HOST} -p ${TMP_NOPWD_LOGIN_REMOTE_HOST_PORT}
	fi

	return $?
}

# 执行脚本,如果内容不存在
# 参数1：内容正则
# 参数2：内容路径
# 参数3：执行脚本
function action_if_content_not_exists() 
{
	local TMP_ECHO_IF_NOT_EXISTS_REGEX=${1}
	local TMP_ECHO_IF_NOT_EXISTS_PATH=${2}
	local TMP_ECHO_IF_NOT_EXISTS_ACTION=${3}

	#create group if not exists
	egrep "${TMP_ECHO_IF_NOT_EXISTS_REGEX}" ${TMP_ECHO_IF_NOT_EXISTS_PATH} >& /dev/null
	if [ $? -ne 0 ]; then
		if [ -n "${TMP_ECHO_IF_NOT_EXISTS_ACTION}" ]; then
			eval "${TMP_ECHO_IF_NOT_EXISTS_ACTION}"
		fi
	fi

	return $?
}

# 输出信息,如果内容不存在
# 参数1：内容正则
# 参数2：内容路径
# 参数3：输出内容
function echo_if_content_not_exists() 
{
	action_if_content_not_exists "${1}" "${2}" "echo '${3:-${1}}' >> ${2}"

	return $?
}

# 创建用户及组，如果不存在
# 参数1：组
# 参数2：用户
# 参数3：默认目录
function create_user_if_not_exists() 
{
	local TMP_CURRENT_TO_CREATE_GROUP=${1}
	local TMP_CURRENT_TO_CREATE_USER=${2}
	local TMP_CURRENT_TO_CREATE_DFT_DIR=${3}

	#create group if not exists
	egrep "^${TMP_CURRENT_TO_CREATE_GROUP}" /etc/group >& /dev/null
	if [ $? -ne 0 ]; then
		groupadd ${TMP_CURRENT_TO_CREATE_GROUP}
	fi

	#create user if not exists
	egrep "^${TMP_CURRENT_TO_CREATE_USER}" /etc/passwd >& /dev/null
	if [ $? -ne 0 ]; then
		local TMP_CURRENT_TO_CREATE_COMMAND_EXT=""
		if [ -n "${TMP_CURRENT_TO_CREATE_DFT_DIR}" ] && [ ! -d "${TMP_CURRENT_TO_CREATE_DFT_DIR}" ]; then
			TMP_CURRENT_TO_CREATE_COMMAND_EXT="-d ${TMP_CURRENT_TO_CREATE_DFT_DIR}"
		fi
		useradd -g ${TMP_CURRENT_TO_CREATE_GROUP} ${TMP_CURRENT_TO_CREATE_USER} ${TMP_CURRENT_TO_CREATE_COMMAND_EXT}
	fi

	return $?
}

#获取IP
#参数1：需要设置的变量名
function get_iplocal () {
	local TMP_LOCAL_IP=`ip a | grep inet | grep brd | grep noprefixroute | grep -v inet6 | grep -v 127 | grep -v docker | awk '{print $2}' | awk -F'/' '{print $1}' | awk 'END {print}'`
    [ -z ${TMP_LOCAL_IP} ] && TMP_LOCAL_IP=`ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1`

	if [ -n "$TMP_LOCAL_IP" ]; then
		eval ${1}=`echo '$TMP_LOCAL_IP'`
	fi

	return $?
}

#获取IPv4
#参数1：需要设置的变量名
function get_ipv4 () {
	#wget -qO- -t1 -T2 ipv4.icanhazip.com
    local TMP_LOCAL_IPV4=`curl -s ipv4.icanhazip.com | awk 'NR==1'`
    [ -z ${TMP_LOCAL_IPV4} ] && TMP_LOCAL_IPV4=`curl -s ipinfo.io/ip | awk 'NR==1'`
    [ -z ${TMP_LOCAL_IPV4} ] && TMP_LOCAL_IPV4=`curl -s ip.sb | awk 'NR==1'`

	if [ -n "$TMP_LOCAL_IPV4" ]; then
		eval ${1}=`echo '$TMP_LOCAL_IPV4'`
	fi

	return $?
}

#获取IPv6
#参数1：需要设置的变量名
function get_ipv6 () {
    local TMP_LOCAL_IPV6=`curl -s ipv6.icanhazip.com | awk 'NR==1'`

	if [ -n "$TMP_LOCAL_IPV6" ]; then
		eval ${1}=`echo '$TMP_LOCAL_IPV6'`
	fi

	return $?
}

#获取国码
#参数1：需要设置的变量名
function get_country_code () {
	if [ ! -f "/usr/sbin/jq" ]; then
		yum -y install jq
	fi

	local TMP_LOCAL_IPV4=`curl -s ip.sb`
	# local TMP_COUNTRY_JSON=`curl -s https://api.ip.sb/geoip/${TMP_LOCAL_IPV4}`
	local TMP_COUNTRY_CODE=`curl -s https://api.ip.sb/geoip/${TMP_LOCAL_IPV4} | jq '.country_code' | sed 's@\"@@g'`

	# if [ -n "${TMP_COUNTRY_JSON}" ]; then
	# 	eval ${1}=`echo "${TMP_COUNTRY_JSON}" | sed 's/,/\n/g' | grep "country_code" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g'`
	# fi

	if [ -n "${TMP_COUNTRY_CODE}" ]; then
		eval ${1}=`echo '$TMP_COUNTRY_CODE'`
	fi

	return $?
}

#关闭删除文件占用进程
function kill_deleted()
{
	if [ ! -f "/usr/sbin/lsof" ]; then
		yum -y install lsof
	fi

	`lsof -w | grep deleted | awk -F' ' '{print $2}' | awk '!a[$0]++' | xargs -I {} kill -9 {}`

	return $?
}

#随机数
#参数1：需要设置的变量名
#参数2：最小值
#参数3：最大值
#调用：rand_val "TMP_CURR_RAND" 1000 2000
function rand_val() {
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_VAR_NAME=$1

    local TMP_MIN_VAL=$2 
    local TMP_MAX_VAL=$(($3-$TMP_MIN_VAL+1))  
    local TMP_RAND_CURR_NUM=$(cat /proc/sys/kernel/random/uuid | cksum | awk -F ' ' '{print $1}')

	#$(shuf -i 9000-19999 -n 1)
    eval ${1}=$(($TMP_RAND_CURR_NUM%$TMP_MAX_VAL+$TMP_MIN_VAL))

	return $?
}

#随机数
#参数1：需要设置的变量名
#参数2：指定长度
#调用：rand_str "TMP_CURR_RAND" 1000 2000
function rand_str() {
	if [ $? -ne 0 ]; then
		return $?
	fi
	local TMP_VAR_NAME=$1

    local TMP_LEN_VAL=$2 
	# random-string()
	# {
	# 	cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1
	# }
	# $(random-string 32)
    local TMP_RAND_CURR_VAL=$(cat /dev/urandom | head -n $TMP_LEN_VAL | md5sum | head -c $TMP_LEN_VAL)

    eval ${1}=`echo '$TMP_RAND_CURR_VAL'`

	return $?
}

#转换路径
#参数1：原始路径
function convert_path () {
	local _TMP_SOURCE_PATH=`eval echo '$'$1`
	local _TMP_CONVERT_PATH=`echo "$_TMP_SOURCE_PATH" | sed "s@^~@/root@g"`
	eval ${1}=`echo '$_TMP_CONVERT_PATH'`

	return $?
}

#查询文件所在行
#参数1：需要设置的变量名
#参数2：文件位置
#参数3：关键字
function get_line()
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_GET_LINE_FILE_PATH=$2
	local TMP_GET_LINE_KEY_WORDS=$3

	local TMP_KEY_WORDS_LINE=`more $TMP_GET_LINE_FILE_PATH | grep "$TMP_GET_LINE_KEY_WORDS" -n | awk -F':' '{print $1}' | awk NR==1`
	eval ${1}=`echo '$TMP_KEY_WORDS_LINE'`

	return $?
}

#关键行插入
#参数1：需要设置的变量名
#参数2：文件位置
#参数3：关键字
#参数4：插入内容
function curx_line_insert()
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	get_line "$1" "$2" "$3"

	local CURX_LINE=`eval echo '$'$1`

	if [ ${#CURX_LINE} -gt 0 ]; then
		# 插入行内容相同则不插入
		local TMP_CURX_TO_INSERT_LINE=$((CURX_LINE+1))
		local TMP_CURX_LINE_SAME=`cat $2 | awk "NR==${TMP_CURX_TO_INSERT_LINE}"`
		if [ "$TMP_CURX_LINE_SAME" != "$4" ]; then
			sed -i "${TMP_CURX_TO_INSERT_LINE}i $4" $2
		fi
	else
		eval ${1}=`echo -1`
	fi

	return $?
}

# 获取挂载根路径，取第一个挂载的磁盘
# 参数1：需要设置的变量名
function get_mount_root() {
	local TMP_MOUNT_ROOT=""
	local TMP_LSBLK_DISKS_STR=`lsblk | grep "disk" | grep -v ":0" | awk 'NR==1{print \$1}' | xargs -I {} echo '/dev/{}'`
	if [ -n "${TMP_LSBLK_DISKS_STR}" ]; then
		TMP_MOUNT_ROOT=`df -h | grep "${TMP_LSBLK_DISKS_STR}" | awk -F' ' '{print \$NF}'`
	fi

	eval ${1}=`echo '${TMP_MOUNT_ROOT}'`

	return $?
}

# 识别磁盘挂载
# 参数1：磁盘挂载数组，当带入参数时，以带入的参数来决定脚本挂载几块硬盘
function resolve_unmount_disk () {

	local TMP_FUNC_TITLE="MountDisk"
	local TMP_ARR_MOUNT_PATH_PREFIX_STR=${1:-}
	# http://wxnacy.com/2018/05/26/shell-split/
	local TMP_ARR_MOUNT_PATH_PREFIX=(${TMP_ARR_MOUNT_PATH_PREFIX_STR//,/ })
	
	# 获取当前磁盘的格式，例如sd,vd
	local TMP_LSBLK_DISKS_STR=`lsblk | grep disk | awk 'NR>=2{print $1}'`
	
	local TMP_ARR_DISK_POINT=(${TMP_LSBLK_DISKS_STR// / })
	
	for I in ${!TMP_ARR_DISK_POINT[@]};  
	do
		local TMP_DISK_POINT="/dev/${TMP_ARR_DISK_POINT[$I]}"

		# 判断未格式化
		local TMP_DISK_FORMATED_COUNT=`fdisk -l | grep "^${TMP_DISK_POINT}" | wc -l`

		if [ ${TMP_DISK_FORMATED_COUNT} -eq 0 ]; then
			echo "${TMP_FUNC_TITLE}: Checked there's one of disk[$((I+1))/${#TMP_ARR_DISK_POINT[@]}] '${TMP_DISK_POINT}' ${red}not format${reset}"
			echo "${TMP_FUNC_TITLE}: Suggest step："
			echo "                                Type ${green}n${reset}, ${red}enter${reset}"
			echo "                                Type ${green}p${reset}, ${red}enter${reset}"
			echo "                                Type ${green}1${reset}, ${red}enter${reset}"
			echo "                                Type ${red}enter${reset}"
			echo "                                Type ${red}enter${reset}"
			echo "                                Type ${green}w${reset}, ${red}enter${reset}"
			echo "---------------------------------------------"

			fdisk ${TMP_DISK_POINT}
			
			echo "---------------------------------------------"

			# 格式化：
			mkfs.ext4 ${TMP_DISK_POINT}

			fdisk -l | grep "^${TMP_DISK_POINT}1"
			echo "${TMP_FUNC_TITLE}: Disk of '${TMP_DISK_POINT}' ${green}formated${reset}"
	
			echo "---------------------------------------------"
		fi

		# 判断未挂载
		local TMP_DISK_MOUNTED_COUNT=`df -h | grep "^${TMP_DISK_POINT}" | wc -l`
		if [ ${TMP_DISK_MOUNTED_COUNT} -eq 0 ]; then
			echo "${TMP_FUNC_TITLE}: Checked there's one of disk[$((I+1))/${#TMP_ARR_DISK_POINT[@]}] '${TMP_DISK_POINT}' ${red}no mount${reset}"

			# 必要判断项
			# 1：数组为空，检测到所有项都提示
			# 2：数组不为空，多余的略过

			local TMP_MOUNT_PATH_PREFIX_CURRENT=""
			if [ ${#TMP_ARR_MOUNT_PATH_PREFIX_STR} -eq 0 ]; then
				input_if_empty "TMP_MOUNT_PATH_PREFIX_CURRENT" "${TMP_FUNC_TITLE}: Please ender the disk of '${TMP_DISK_POINT}' mount path prefix like '/tmp/downloads'"
			else
				TMP_MOUNT_PATH_PREFIX_CURRENT=${TMP_ARR_MOUNT_PATH_PREFIX[$I]}
				# [ ${TMP_ARR_MOUNT_PATH_PREFIX_LEN} -gt $((I+1)) ];
			fi

			if [ -n "${TMP_MOUNT_PATH_PREFIX_CURRENT}" ]; then
				# 挂载
				mkdir -pv ${TMP_MOUNT_PATH_PREFIX_CURRENT}
				echo "${TMP_DISK_POINT} ${TMP_MOUNT_PATH_PREFIX_CURRENT} ext4 defaults 0 0" >> /etc/fstab
				mount -a
		
				df -h | grep "${TMP_MOUNT_PATH_PREFIX_CURRENT}"
				echo "${TMP_FUNC_TITLE}: Disk of '${TMP_DISK_POINT}' ${green}mounted${reset}"
			else
				echo "${TMP_FUNC_TITLE}: Path of '${TMP_MOUNT_PATH_PREFIX_CURRENT}' error，the disk '${TMP_DISK_POINT}' ${red}not mount${reset}"
			fi

			echo "---------------------------------------------"
		fi

	done

	return $?
}

#复制nginx启动器
#参数1：程序命名
#参数2：程序启动的目录
#参数3：程序启动的端口
function cp_nginx_starter()
{
	local TMP_CP_NGX_STT_NAME=$1
	local TMP_CP_NGX_STT_RUNNING_DIR=$2
	local TMP_CP_NGX_STT_RUNNING_PORT=$3

	local TMP_CP_NGX_STT_CONTAINER_DIR=${NGINX_DIR}/${1}_${3}

	mkdir -pv $NGINX_DIR

	echo "Copy '${__DIR}/templates/nginx/server' To '${TMP_CP_NGX_STT_CONTAINER_DIR}'"
	cp -r ${__DIR}/templates/nginx/server ${TMP_CP_NGX_STT_CONTAINER_DIR}
	
	if [ ! -d "$TMP_CP_NGX_STT_RUNNING_DIR" ]; then
		echo "Copy '${__DIR}/templates/nginx/template' To '${TMP_CP_NGX_STT_RUNNING_DIR}'"
		cp -r ${__DIR}/templates/nginx/template ${TMP_CP_NGX_STT_RUNNING_DIR}
	fi

	cd ${TMP_CP_NGX_STT_CONTAINER_DIR}

	sed -i "s@\%prj_port\%@${TMP_CP_NGX_STT_RUNNING_PORT}@g" conf/vhosts/project.conf
	sed -i "s@\%prj_name\%@${TMP_CP_NGX_STT_NAME}@g" conf/vhosts/project.conf
	sed -i "s@\%prj_dir\%@${TMP_CP_NGX_STT_RUNNING_DIR}@g" conf/vhosts/project.conf

	mv conf/vhosts/project.conf conf/vhosts/${TMP_CP_NGX_STT_NAME}.conf
	bash start.sh master

    echo_soft_port ${TMP_CP_NGX_STT_RUNNING_PORT}
    echo_startup_config "${TMP_CP_NGX_STT_NAME}" "${TMP_CP_NGX_STT_CONTAINER_DIR}" "bash start.sh master" "" "99"

	return $?
}

#生成nginx启动器
function gen_nginx_starter()
{
    local TMP_DATE=`date +%Y%m%d%H%M%S`

    local TMP_NGX_BOOT_NAME="tmp"
    local TMP_NGX_BOOT_PORT=""
	rand_val "TMP_NGX_BOOT_PORT" 1024 2048
    
    input_if_empty "TMP_NGX_BOOT_NAME" "NGX_CONF: Please ender application name"
	set_if_empty "TMP_NGX_BOOT_NAME" "prj_${TMP_DATE}"
    
    local TMP_NGX_BOOT_PATH="${NGINX_DIR}/${TMP_NGX_BOOT_NAME}"
    input_if_empty "TMP_NGX_BOOT_PATH" "NGX_CONF: Please ender application path"
	set_if_empty "TMP_NGX_BOOT_PATH" "${NGINX_DIR}"
    
    input_if_empty "TMP_NGX_BOOT_PORT" "Please ender application port Like '8080'"
	set_if_empty "TMP_NGX_BOOT_PORT" "${TMP_NGX_CONF_PORT}"

	cp_nginx_starter "${TMP_NGX_BOOT_NAME}" "${TMP_NGX_BOOT_PATH}" "${TMP_NGX_BOOT_PORT}"
	
	# 添加系统启动命令
    echo_startup_config "ngx_${TMP_NGX_BOOT_NAME}" "${TMP_NGX_BOOT_PATH}" "bash start.sh" "" "999"

    # 生成web授权访问脚本
    echo_web_service_init_scripts "${TMP_NGX_BOOT_NAME}${LOCAL_ID}" "${TMP_NGX_BOOT_NAME}${LOCAL_ID}.${SYS_DOMAIN}" ${TMP_NGX_BOOT_PORT} "${LOCAL_HOST}"

	return $?
}

#安装软件基础
#参数1：软件安装名称
#参数2：软件安装需调用的函数
function setup_soft_basic()
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_SOFT_SETUP_CURRENT=`pwd`
	local TMP_SOFT_SETUP_NAME=$1
	local TMP_SOFT_SETUP_FUNC=$2

	local TMP_SOFT_SETUP_NAME_LEN=${#TMP_SOFT_SETUP_NAME}
	local TMP_VAR_SPLITER=""
	#TMP_SOFT_

	fill_right "TMP_VAR_SPLITER" "-" $((TMP_SOFT_SETUP_NAME_LEN+20))
	echo $TMP_VAR_SPLITER
	echo "Start To Install ${green}$TMP_SOFT_SETUP_NAME${reset}"
	echo $TMP_VAR_SPLITER
	
	if [ -n "$TMP_SOFT_SETUP_FUNC" ]; then
		cd ${DOWN_DIR}
		$TMP_SOFT_SETUP_FUNC
	fi

	echo $TMP_VAR_SPLITER
	echo "Install ${green}$TMP_SOFT_SETUP_NAME${reset} Completed"
	echo $TMP_VAR_SPLITER

	cd ${TMP_SOFT_SETUP_CURRENT}

	return $?
}

#路径不存在执行
#参数1：检测路径
#参数2：执行函数或脚本
#参数3：路径存在时输出信息
function path_not_exists_action() 
{
	local _TMP_NOT_EXITS_PATH="$1"
	local _TMP_NOT_EXITS_PATH_SCRIPT="$2"
	local _TMP_NOT_EXITS_PATH_ECHO="$3"

	convert_path "_TMP_NOT_EXITS_PATH"

	# 缺失了对文件夹的判断，修复20-12.25
	local _TMP_EXISTS_PATH_VAL=$([ -a "$_TMP_NOT_EXITS_PATH" ] && echo 1 || echo 0)
	if [ ${_TMP_EXISTS_PATH_VAL} -eq 0 ]; then
	# if [ ! -f "$_TMP_NOT_EXITS_PATH" ]; then
		if [ "$(type -t $_TMP_NOT_EXITS_PATH_SCRIPT)" = "function" ] ; then
			$_TMP_NOT_EXITS_PATH_SCRIPT $_TMP_NOT_EXITS_PATH
		else
			eval "$_TMP_NOT_EXITS_PATH_SCRIPT"
		fi
	else
		if [ ${#_TMP_NOT_EXITS_PATH_ECHO} -gt 0 ]; then
			echo $_TMP_NOT_EXITS_PATH_ECHO
		fi

		return 0;
	fi

	return $?
}

#路径不存在则创建
#参数1：检测路径
#参数2：路径存在时输出信息
function path_not_exists_create() 
{
	local _TMP_NOT_EXITS_PATH="$1"
	local _TMP_NOT_EXITS_PATH_ECHO="$2"

    path_not_exists_action "${_TMP_NOT_EXITS_PATH}" "mkdir -pv ${_TMP_NOT_EXITS_PATH}" "${_TMP_NOT_EXITS_PATH_ECHO}"

	return $?
}

#Rpm不存在执行
#参数1：包名称
#参数2：执行函数名称
#参数3：包存在时输出信息
function soft_rpm_check_action() 
{
	local TMP_RPM_CHECK_SOFT=$1
	local TMP_RPM_CHECK_SOFT_FUNC=$2

    local TMP_RPM_FIND_RESULTS=`rpm -qa | grep $TMP_RPM_CHECK_SOFT`
	if [ -z "$TMP_RPM_FIND_RESULTS" ]; then
		$TMP_RPM_CHECK_SOFT_FUNC
	else
		echo $3

		return 0;
	fi

	return $?
}

#Yum不存在时执行
#参数1：包名称
#参数2：执行函数名称
#参数3：包存在时输出信息
#示例：
#	 soft_yum_check_action "vvv" "yum -y install %s" "%s was installed"
#	 soft_yum_check_action "sss" "test" "%s was installed"
#	 soft_yum_check_action "wget,vim" "echo '%s setup'" "%s was installed"
function soft_yum_check_action() 
{    
	local TMP_YUM_CHECK_SOFTS=${1}
	local TMP_YUM_CHECK_ACTION_SCRIPT=${2}
    local TMP_YUM_CHECK_SOFT_STD=${3}

    # 如果是函数的情况下，附加参数传递
	if [ "$(type -t ${TMP_YUM_CHECK_ACTION_SCRIPT})" = "function" ] ; then
		TMP_YUM_CHECK_ACTION_SCRIPT="${TMP_YUM_CHECK_ACTION_SCRIPT} \"%s\""
	fi

    local TMP_YUM_CHECK_EXEC_SCRIPT="
        echo \${TMP_SPLITER}
        echo \"Checking the yum installed repos of '${red}%s${reset}'\"
        echo \${TMP_SPLITER}

        local TMP_YUM_FIND_RESULTS=\`yum list installed | grep '%s'\`
        if [ -z \"\${TMP_YUM_FIND_RESULTS}\" ]; then
            ${TMP_YUM_CHECK_ACTION_SCRIPT}
        else
            # 此处如果是取用变量而不是实际值，则split_action中的printf不会进行格式化
            # print \"${TMP_YUM_CHECK_SOFT_STD}\" \"\${TMP_YUM_CHECK_SOFT}\"
            echo \"${TMP_YUM_CHECK_SOFT_STD}\"
        fi

        echo"

    exec_split_action "${TMP_YUM_CHECK_SOFTS}" "${TMP_YUM_CHECK_EXEC_SCRIPT}"

	return $?
}

#Yum不存在时安装
#参数1：包名称
#参数2：包存在时输出信息
#示例：
#    soft_yum_check_setup "vvv" "%s was installed"
#    soft_yum_check_setup "wget,vim" "%s was installed"
function soft_yum_check_setup() 
{
	local TMP_YUM_CHECK_SOFTS=${1}
	local TMP_YUM_CHECK_SOFT_STD=${2:-"%s was installed"}
        
    soft_yum_check_action "${1}" "yum -y install %s" "${TMP_YUM_CHECK_SOFT_STD}"

	return $?
}

#Npm不存在执行
#参数1：包名称
#参数2：执行函数名称
#参数3：包存在时输出信息
#参数4：模式
function soft_npm_check_action() 
{
	local TMP_NPM_CHECK_SOFT=$1
	local TMP_NPM_CHECK_SOFT_FUNC=$2
	local TMP_NPM_CHECK_MODE=$4

    local TMP_NPM_FIND_RESULTS=`npm list --depth=0 $TMP_NPM_CHECK_MODE | grep $TMP_NPM_CHECK_SOFT`
	if [ -z "$TMP_NPM_FIND_RESULTS" ]; then
		$TMP_NPM_CHECK_SOFT_FUNC
	else
		echo $3

		return 0;
	fi

	return $?
}

#安装软件下载模式
#参数1：软件下载地址
#参数2：软件下载后，需移动的文件夹名
#参数3：目标文件夹
#参数4：解包后执行脚本
function wget_unpack_dist() 
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_WGET_UNPACK_DIST_PWD=`pwd`
	local TMP_WGET_UNPACK_DIST_URL=$1
	local TMP_WGET_UNPACK_DIST_SOURCE=$2
	local TMP_WGET_UNPACK_DIST_PATH=$3
	local TMP_WGET_UNPACK_DIST_SCRIPT=$4

	local TMP_WGET_UNPACK_FILE_NAME=`echo "$TMP_WGET_UNPACK_DIST_URL" | awk -F'/' '{print $NF}'`

	cd ${DOWN_DIR}

	if [ ! -f "$TMP_WGET_UNPACK_FILE_NAME" ]; then
		wget -c --tries=0 --timeout=60 $TMP_WGET_UNPACK_DIST_URL
	fi

	local TMP_WGET_UNPACK_DIST_FILE_EXT=`echo ${TMP_WGET_UNPACK_FILE_NAME##*.}`
	if [ "$TMP_WGET_UNPACK_DIST_FILE_EXT" = "zip" ]; then
		TMP_WGET_PACK_DIR_LINE=`unzip -v $TMP_WGET_UNPACK_FILE_NAME | awk '/----/{print NR}' | awk 'NR==1{print}'`
		TMP_WGET_UNPACK_FILE_NAME_NO_EXTS=`unzip -v $TMP_WGET_UNPACK_FILE_NAME | awk 'NR==LINE{print $NF}' LINE=$((TMP_WGET_PACK_DIR_LINE+1)) | sed s@/@""@g`
		if [ ! -d "$TMP_WGET_UNPACK_FILE_NAME_NO_EXTS" ]; then
			unzip -o $TMP_WGET_UNPACK_FILE_NAME
		fi
	else
		TMP_WGET_UNPACK_FILE_NAME_NO_EXTS=`tar -tf $TMP_WGET_UNPACK_FILE_NAME | awk 'NR==1{print}' | sed s@/@""@g`
		if [ ! -d "$TMP_WGET_UNPACK_FILE_NAME_NO_EXTS" ]; then
			tar -xvf $TMP_WGET_UNPACK_FILE_NAME
		fi
	fi

	cd $TMP_WGET_UNPACK_FILE_NAME_NO_EXTS

	exec_check_action "$TMP_WGET_UNPACK_DIST_SCRIPT"

	cp -rf $TMP_WGET_UNPACK_DIST_SOURCE $TMP_WGET_UNPACK_DIST_PATH

	#rm -rf ${DOWN_DIR}/$TMP_WGET_UNPACK_FILE_NAME
	cd $TMP_WGET_UNPACK_DIST_PWD

	return $?
}

#无限循环重试下载
#参数1：软件下载地址
#参数2：软件下载后执行函数名称
function while_wget()
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_SOFT_WGET_URL=$1
	local TMP_SOFT_WGET_SCRIPT=$2
	local TMP_SOFT_WGET_CURRENT_DIR=`pwd`

	#包含指定参数
	local TMP_SOFT_WGET_FILE_DEST_NAME=`echo "${TMP_SOFT_WGET_URL}" | awk -F'-O' '{print $2}' | awk '{sub("^ *","");sub(" *$","");print}' | awk -F' ' '{print $1}'`
	
	#原始链接名
	local TMP_SOFT_WGET_FILE_SOUR_NAME=`echo "${TMP_SOFT_WGET_URL}" | awk -F'/' '{print $NF}' | awk -F' ' '{print $NR}'`

	if [ "${TMP_SOFT_WGET_FILE_SOUR_NAME}" == "download.rpm" ]; then
		TMP_SOFT_WGET_FILE_SOUR_NAME=`echo "${TMP_SOFT_WGET_URL}" | awk -F'/' '{print $(NF-1)}'`
	fi

	#提取真实URL链接
	local TMP_SOFT_WGET_TRUE_URL=`echo "${TMP_SOFT_WGET_URL}" | grep -oh -E "https?://[a-zA-Z0-9\.\+\/_&=@$%?~#-]*"`

	#最终名
	TMP_SOFT_WGET_FILE_DEST_NAME=${TMP_SOFT_WGET_FILE_DEST_NAME:-${TMP_SOFT_WGET_FILE_SOUR_NAME}}
	# TMP_SOFT_WGET_FILE_DEST_NAME=$([ -n "$TMP_SOFT_WGET_FILE_DEST_NAME" ] && echo "$TMP_SOFT_WGET_FILE_DEST_NAME" || echo ${TMP_SOFT_WGET_FILE_SOUR_NAME})
	
	echo "-------------------------------------------------------------------------------------------------------------------"
	echo "Start to get file from '${red}${TMP_SOFT_WGET_TRUE_URL}${reset}' named '${green}${TMP_SOFT_WGET_FILE_DEST_NAME}${reset}'"
	echo "-------------------------------------------------------------------------------------------------------------------"
	echo "${green}Current Dir${reset}：`pwd`"
	local TMP_SOFT_WGET_DIST_FILE_EXT=`echo ${TMP_SOFT_WGET_FILE_DEST_NAME##*.}`	
	case ${TMP_SOFT_WGET_DIST_FILE_EXT} in
		"rpm")
			cd ${RPMS_DIR}
		;;
		"repo")
			cd ${REPO_DIR}
		;;
		*)
		cd ${DOWN_DIR}
	esac

	local TMP_SOFT_WGET_COMMAND="wget -c --tries=0 --timeout=60 ${TMP_SOFT_WGET_TRUE_URL} -O ${TMP_SOFT_WGET_FILE_DEST_NAME}"
	echo "${green}Wget Command${reset}：${TMP_SOFT_WGET_COMMAND}"
	echo "${green}Wget/Current Dir${reset}：`pwd`"
	echo

	# 循环执行wget命令，直到成功
	while [ ! -f "${TMP_SOFT_WGET_FILE_DEST_NAME}" ]; do
		#https://wenku.baidu.com/view/64f7d302b52acfc789ebc936.html
		${TMP_SOFT_WGET_COMMAND}

		# 网络错误大小为0则清空文件
		local TMP_SOFT_WGET_FILE_SIZE=`ls -l ${TMP_SOFT_WGET_FILE_DEST_NAME} | awk '{ print $5 }'`
		if [ ${TMP_SOFT_WGET_FILE_SIZE} -eq 0 ]; then
			rm -rf ${TMP_SOFT_WGET_FILE_DEST_NAME}
		fi
	done

	# 执行wget后的脚本
	if [ ${#TMP_SOFT_WGET_SCRIPT} -gt 0 ]; then
		eval "${TMP_SOFT_WGET_SCRIPT}"
	fi

	# 回到wget之前的目录
	cd ${TMP_SOFT_WGET_CURRENT_DIR}

	return $?
}

#无限循环重试下载
#参数1：软件下载地址
#参数2：软件下载后执行函数名称
function while_curl()
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_SOFT_CURL_URL=$1
	local TMP_SOFT_CURL_SCRIPT=$2
	local TMP_SOFT_CURL_CURRENT_DIR=`pwd`

	#包含指定参数
	local TMP_SOFT_CURL_FILE_DEST_NAME=`echo "${TMP_SOFT_CURL_URL}" | awk -F'-o' '{print $2}' | awk '{sub("^ *","");sub(" *$","");print}' | awk -F' ' '{print $1}'`

	#原始链接名
	local TMP_SOFT_CURL_FILE_NAME=`echo "${TMP_SOFT_CURL_URL}" | awk -F'/' '{print $NF}' | awk -F' ' '{print $NR}'`

	#提取真实URL链接
	local TMP_SOFT_CURL_TRUE_URL=`echo "${TMP_SOFT_CURL_URL}" | grep -oh -E "https?://[a-zA-Z0-9\.\+\/_&=@$%?~#-]*"`

	#最终名
	TMP_SOFT_CURL_FILE_DEST_NAME=${TMP_SOFT_CURL_FILE_DEST_NAME:-${TMP_SOFT_CURL_FILE_NAME}}
	# TMP_SOFT_CURL_FILE_DEST_NAME=$([ -n "$TMP_SOFT_CURL_FILE_DEST_NAME" ] && echo "$TMP_SOFT_CURL_FILE_DEST_NAME" || echo $TMP_SOFT_CURL_FILE_NAME)
	
	echo "-------------------------------------------------------------------------------------------------------------------------"
	echo "Start to curl file from '${red}${TMP_SOFT_CURL_TRUE_URL}${reset}' named '${green}${TMP_SOFT_CURL_FILE_DEST_NAME}${reset}'"
	echo "-------------------------------------------------------------------------------------------------------------------------"
	echo "${green}Current Dir${reset}：`pwd`"

	cd ${CURL_DIR}
	local TMP_SOFT_CURL_COMMAND="curl -4sSkL ${TMP_SOFT_CURL_TRUE_URL} -o ${TMP_SOFT_CURL_FILE_DEST_NAME}"
	echo "${green}Curl Command${reset}：${TMP_SOFT_CURL_COMMAND}"
	echo "${green}Curl/Current Dir${reset}：`pwd`"
	echo

	while [ ! -f "${TMP_SOFT_CURL_FILE_DEST_NAME}" ]; do
		${TMP_SOFT_CURL_COMMAND}
		
		# 网络错误大小为0则清空文件
		local TMP_SOFT_CURL_FILE_SIZE=`ls -l ${TMP_SOFT_CURL_FILE_DEST_NAME} | awk '{ print $5 }'`
		if [ ${TMP_SOFT_CURL_FILE_SIZE} -eq 0 ]; then
			rm -rf ${TMP_SOFT_CURL_FILE_DEST_NAME}
		fi
	done

	if [ ${#TMP_SOFT_CURL_SCRIPT} -gt 0 ]; then
		eval "${TMP_SOFT_CURL_SCRIPT}"
	fi
	cd ${TMP_SOFT_CURL_CURRENT_DIR}

	# rm -rf ${TMP_SOFT_CURL_FILE_DEST_NAME}

	return $?
}

#无限循环尝试启动程序
#参数1：程序启动命令
#参数2：程序检测命令（返回1）
#参数3：失败后执行
#例子：TMP=1 && while_exec "TMP=\$((TMP+1))" "[ \$TMP -eq 10 ] && echo 1" "echo \$TMP"
function while_exec()
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_SOFT_EXEC_SCRIPT=$1
	local TMP_SOFT_EXEC_CHECK_SCRIPT=$2
	local TMP_SOFT_EXEC_FAILURE_SCRIPT=$3

	echo "----------------------------------------------------------------"
	echo "Start to exec check script '${green}$TMP_SOFT_EXEC_CHECK_SCRIPT${reset}'"
	local TMP_EXEC_CHECK_RESULT=`eval "$TMP_SOFT_EXEC_CHECK_SCRIPT"`
	if [ $I -eq 1 ] && [ "$TMP_EXEC_CHECK_RESULT" == "1" ]; then
		echo "Script is '${green}Running${reset}', exec exit"
		break
	fi

	echo "Start to exec script '${green}$TMP_SOFT_EXEC_SCRIPT${reset}'"
	echo "----------------------------------------------------------------"

	for I in $(seq 99);
	do
		echo "Execute sequence：'${green}$I${reset}'"
		echo "----------------------"
		eval "$TMP_SOFT_EXEC_SCRIPT"

		TMP_EXEC_CHECK_RESULT=`eval "$TMP_SOFT_EXEC_CHECK_SCRIPT"`

		if [ "$TMP_EXEC_CHECK_RESULT" != "1" ]; then
			echo "Execute ${red}failure${reset}, the result response '${red}${TMP_EXEC_CHECK_RESULT}${reset}', this will wait for 30s to try again"
			sleep 30s
			if [ ${#TMP_SOFT_EXEC_FAILURE_SCRIPT} -gt 0 ]; then
				eval "$TMP_SOFT_EXEC_FAILURE_SCRIPT"
				echo "----------------------------------------------------------------"
			fi
		else
			echo "----------------------------------------------------------------"
			echo "Execute ${green}success${reset}"
			echo "---------------"
			break
		fi
	done

	return $?
}

#安装软件下载模式
#参数1：软件安装名称
#参数2：软件下载地址
#参数3：软件下载后执行函数名称
#参数4：软件安装路径（不填入默认识别为 $SETUP_DIR）
function setup_soft_wget() 
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_SOFT_WGET_NAME=$1
	local TMP_SOFT_WGET_URL=$2
	local TMP_SOFT_WGET_SETUP_FUNC=$3
	local TMP_SOFT_SETUP_DIR=$([ -n "$4" ] && echo "$4" || echo $SETUP_DIR)
	
	typeset -l TMP_SOFT_LOWER_NAME
	local TMP_SOFT_LOWER_NAME=${TMP_SOFT_WGET_NAME}

	local TMP_SOFT_SETUP_PATH=${TMP_SOFT_SETUP_DIR}/${TMP_SOFT_LOWER_NAME}

    ls -d ${TMP_SOFT_SETUP_PATH}   #ps -fe | grep ${TMP_SOFT_WGET_NAME} | grep -v grep
	if [ $? -ne 0 ]; then
		local TMP_SOFT_WGET_FILE_NAME=
		local TMP_SOFT_WGET_FILE_DIR="${DOWN_DIR}"
		while_wget "${TMP_SOFT_WGET_URL}" 'TMP_SOFT_WGET_FILE_DIR=`pwd` && TMP_SOFT_WGET_FILE_NAME=${TMP_SOFT_WGET_FILE_DEST_NAME}'
		
		# 回到while_wget下载的目录中去
		cd ${TMP_SOFT_WGET_FILE_DIR}

		local TMP_SOFT_WGET_FILE_NAME_NO_EXTS="${DOWN_DIR}/tmp"
		local TMP_SOFT_WGET_UNPACK_FILE_EXT=`echo ${TMP_SOFT_WGET_FILE_NAME##*.}`
		if [ "$TMP_SOFT_WGET_UNPACK_FILE_EXT" = "zip" ]; then
			TMP_SOFT_WGET_PACK_DIR_LINE=`unzip -v ${TMP_SOFT_WGET_FILE_NAME} | awk '/----/{print NR}' | awk 'NR==1{print}'`
			local TMP_SOFT_WGET_FILE_NAME_UNZIP=`unzip -v ${TMP_SOFT_WGET_FILE_NAME} | awk 'NR==LINE{print $NF}' LINE=$((TMP_SOFT_WGET_PACK_DIR_LINE+1))`
			TMP_SOFT_WGET_FILE_NAME_NO_EXTS=${TMP_SOFT_WGET_FILE_NAME_UNZIP%/*}
			
			# 没有层级的情况
			local TMP_SOFT_WGET_FILE_NAME_UNZIP_ARGS=""
			if [ "${TMP_SOFT_WGET_FILE_NAME_UNZIP}" == "${TMP_SOFT_WGET_FILE_NAME_NO_EXTS}" ]; then
				TMP_SOFT_WGET_FILE_NAME_NO_EXTS="${TMP_SOFT_LOWER_NAME}"
				TMP_SOFT_WGET_FILE_NAME_UNZIP_ARGS="-d ${TMP_SOFT_LOWER_NAME}"
			fi

			# 本地是否存在目录
			if [ ! -d "${TMP_SOFT_WGET_FILE_NAME_NO_EXTS}" ]; then
				unzip -o ${TMP_SOFT_WGET_FILE_NAME} ${TMP_SOFT_WGET_FILE_NAME_UNZIP_ARGS}
			fi
		else
			TMP_SOFT_WGET_FILE_NAME_NO_EXTS=`tar -tf ${TMP_SOFT_WGET_FILE_NAME} | grep '/' | awk 'NR==1{print}' | sed s@/.*@""@g`
			if [ ! -d "${TMP_SOFT_WGET_FILE_NAME_NO_EXTS}" ]; then
				if [ "$TMP_SOFT_WGET_UNPACK_FILE_EXT" = "xz" ]; then
					xz -d ${TMP_SOFT_WGET_FILE_NAME}
					local TMP_SOFT_WGET_FILE_NAME_TAR=${TMP_SOFT_WGET_FILE_NAME%%.xz*}
					tar -xvf ${TMP_SOFT_WGET_FILE_NAME_TAR}
					rm -rf ${TMP_SOFT_WGET_FILE_NAME_TAR}
				else
					tar -zxvf ${TMP_SOFT_WGET_FILE_NAME}
				fi
			fi
		fi
		
		cd ${TMP_SOFT_WGET_FILE_NAME_NO_EXTS}

		#安装函数调用
		${TMP_SOFT_WGET_SETUP_FUNC} "${TMP_SOFT_SETUP_PATH}"
	
		echo "Complete."
	fi

	return $?
}

#安装软件下载模式
#参数1：软件安装名称
#参数2：软件下载地址
#参数3：软件下载后执行函数名称
#参数4：软件下载附加参数
function setup_soft_git() 
{	
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_SOFT_GIT_NAME=$1
	local TMP_SOFT_GIT_URL=$2
	local TMP_SOFT_GIT_SETUP_FUNC=$3
	local TMP_SOFT_GIT_URL_PARAMS=$4
	
	typeset -l TMP_SOFT_LOWER_NAME
	local TMP_SOFT_LOWER_NAME=$TMP_SOFT_GIT_NAME

	local TMP_SOFT_SETUP_PATH=$SETUP_DIR/${TMP_SOFT_LOWER_NAME}

    ls -d ${TMP_SOFT_SETUP_PATH}   #ps -fe | grep $TMP_SOFT_GIT_NAME | grep -v grep
	if [ $? -ne 0 ]; then
		local TMP_SOFT_GIT_FOLDER_NAME=`echo "$TMP_SOFT_GIT_URL" | awk -F'/' '{print $NF}'`

		cd ${DOWN_DIR}
		if [ ! -f "$TMP_SOFT_GIT_FOLDER_NAME" ]; then
			git clone $TMP_SOFT_GIT_URL ${TMP_SOFT_GIT_URL_PARAMS}
		fi
		
		cd $TMP_SOFT_GIT_FOLDER_NAME

		#安装函数调用
		$TMP_SOFT_GIT_SETUP_FUNC "${TMP_SOFT_SETUP_PATH}"
	
		echo "Complete."
	fi

	return $?
}

# PIP安装软件下载模式
# 参数1：软件安装名称
# 参数2：软件下载后执行函数名称
# 参数3：pip版本，默认2
function setup_soft_pip() 
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_SOFT_PIP_NAME=`echo "${1}" | awk -F',' '{print $1}'`
	local TMP_SOFT_PIP_PATH=`echo "${1}" | awk -F',' '{print $NF}'`
	local TMP_SOFT_PIP_SETUP_FUNC=${2}
	local TMP_SOFT_PIP_VERS=${3:-2}
	
	# 版本2为linux系统默认自带，所以未装py3时判断
	if [ ${TMP_SOFT_PIP_VERS} -eq 2 ] && [ ! -f "/usr/bin/pip" ]; then
		while_curl "https://bootstrap.pypa.io/pip/2.7/get-pip.py -o get-pip.py" "python get-pip.py && rm -rf get-pip.py"
		pip install --upgrade pip
		pip install --upgrade setuptools
		
		local TMP_PY_DFT_SETUP_PATH=`pip show pip | grep "Location" | awk -F' ' '{print $2}'`
		mv ${TMP_PY_DFT_SETUP_PATH} ${PY_PKGS_SETUP_DIR}
		ln -sf ${PY_PKGS_SETUP_DIR} ${TMP_PY_DFT_SETUP_PATH}
	fi

	typeset -l TMP_SOFT_LOWER_NAME
	local TMP_SOFT_LOWER_NAME=${TMP_SOFT_PIP_NAME}
	local TMP_SOFT_SETUP_PATH=`pip show ${TMP_SOFT_LOWER_NAME} | grep "Location" | awk -F' ' '{print $2}' | xargs -I {} echo "{}/${TMP_SOFT_LOWER_NAME}"`

	# pip show supervisor
	# pip freeze | grep "supervisor=="
	if [ -z "${TMP_SOFT_SETUP_PATH}" ]; then
		echo "Pip start to install ${TMP_SOFT_PIP_NAME}"
		pip install ${TMP_SOFT_LOWER_NAME}
		echo "Pip installed ${TMP_SOFT_PIP_NAME}"

		#安装后配置函数
		${TMP_SOFT_PIP_SETUP_FUNC} "${PY_PKGS_SETUP_DIR}/${TMP_SOFT_LOWER_NAME}"
	else
    	ls -d ${TMP_SOFT_SETUP_PATH}   #ps -fe | grep ${TMP_SOFT_PIP_NAME} | grep -v grep

		return 1
	fi

	return $?
}

#安装软件下载模式
#参数1：软件安装名称
#参数2：软件下载后执行函数名称
#参数3：指定node版本（node有兼容性问题）
function setup_soft_npm() 
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_SOFT_NPM_SETUP_NAME=`echo "$1" | awk -F',' '{print $1}'`
	local TMP_SOFT_NPM_SETUP_PATH=`echo "$1" | awk -F',' '{print $NF}'`
	local TMP_SOFT_NPM_SETUP_FUNC=$2
	local TMP_SOFT_NPM_NODE_VERS=$3
	
	typeset -l TMP_SOFT_NPM_SETUP_NAME_LOWER
	local TMP_SOFT_NPM_SETUP_NAME_LOWER=${TMP_SOFT_NPM_SETUP_NAME}

	# 提前检查命令是否存在
	source ${__DIR}/scripts/lang/nodejs.sh

	npm install -g npm@next
	npm audit fix

	# 指定版本
	if [ -n "${TMP_SOFT_NPM_NODE_VERS}" ]; then
		nvm install ${TMP_SOFT_NPM_NODE_VERS}
		nvm use ${TMP_SOFT_NPM_NODE_VERS}
	else
		TMP_SOFT_NPM_NODE_VERS=`nvm current`
	fi

	local TMP_SOFT_NPM_SETUP_INFO=`npm list -g --depth 0 | grep -o ${TMP_SOFT_NPM_SETUP_NAME_LOWER}.*`
	# 在当前指定安装版本的目录下找是否安装
	local TMP_SOFT_NPM_SETUP_DIR=`dirname $(npm config get prefix)`/${TMP_SOFT_NPM_NODE_VERS}/lib/node_modules/${TMP_SOFT_NPM_SETUP_NAME_LOWER}

	if [ -z "${TMP_SOFT_NPM_SETUP_INFO}" ]; then
		npm update

		echo "Npm start to install ${TMP_SOFT_NPM_SETUP_NAME}"
	
		# 谨防网速慢的情况，重复安装
		while [ ! -d "${TMP_SOFT_NPM_SETUP_DIR}" ]; do
			npm cache clean --force
			npm install --verbose -g ${TMP_SOFT_NPM_SETUP_NAME}
		done
		
		echo "Npm installed ${TMP_SOFT_NPM_SETUP_NAME}"

		#安装后配置函数
		${TMP_SOFT_NPM_SETUP_FUNC} "${TMP_SOFT_NPM_SETUP_DIR}" "${TMP_SOFT_NPM_NODE_VERS}"
	else
    	echo ${TMP_SOFT_NPM_SETUP_INFO}

		return 1
	fi

	return $?
}

# #循环执行
# #参数1：提示标题
# #参数2：函数名称
# function cycle_exec()
# {
# 	if [ $? -ne 0 ]; then
# 		return $?
# 	fi

# 	return $?
# }

#设置变量值函数如果为空
#参数1：需要设置的变量名
#参数2：需要设置的变量值
function set_if_empty()
{
	TMP_VAR_NAME=$1
	TMP_VAR_VAL=$2

	TMP_DFT=`eval echo '$'$TMP_VAR_NAME`

	if [ -n "$TMP_VAR_VAL" ]; then
		eval ${1}=`echo '$TMP_DFT'`
	fi

	return $?
}

#设置变量值函数如果相同
#参数1：需要设置的变量名
#参数2：需要对比的变量名/值
#参数3：需要对比的变量值
function set_if_equals()
{
	local TMP_SOURCE_VAR_NAME=$1
	local TMP_COMPARE_VAR_NAME=$2
	local TMP_SET_VAR_VAL=$3

	local TMP_SOURCE_VAR_VAL=`eval echo '$'$TMP_SOURCE_VAR_NAME`
	local TMP_COMPARE_VAR_VAL=`eval echo '$'$TMP_COMPARE_VAR_NAME`

	if [ -z "$TMP_COMPARE_VAR_VAL" ]; then
		TMP_COMPARE_VAR_VAL="$TMP_COMPARE_VAR_NAME"
	fi

	if [ "$TMP_SOURCE_VAR_VAL" = "$TMP_COMPARE_VAR_VAL" ]; then
		eval ${1}=`echo '$TMP_SET_VAR_VAL'`
	fi

	return $?
}

#是否类型的弹出动态设置变量值函数
#参数1：需要设置的变量名
#参数2：提示信息
function input_if_empty()
{
	local TMP_VAR_NAME=$1
	local TMP_NOTICE=$2
	local INPUT_CURRENT=""

	local TMP_DFT=`eval echo '$'$TMP_VAR_NAME`
	echo "${TMP_NOTICE}, default '${green}`eval echo ${TMP_DFT}`${reset}'"
	read -e INPUT_CURRENT
	echo ""

	if [ -n "${INPUT_CURRENT}" ]; then
		eval ${1}='${INPUT_CURRENT}'
	fi

	return $?
}

#查找网页文件列表中，最新的文件名
#描述：本函数先获取关键字最新的发布日期，再找对应行的文件名，最后提取href，适合比较通用型的文件列表
#参数1：需要设置的变量名
#参数2：需要找寻的URL路径
#参数3：查找关键字
#示例：
# 	set_url_list_newer_date_link_filename "TMP_NEWER_LINK" "http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/" "clickhouse-common-static-dbg-.*.x86_64.rpm"
function set_url_list_newer_date_link_filename()
{
	local TMP_VAR_NAME=$1
	local TMP_VAR_FIND_URL=$2
	local TMP_VAR_KEY_WORDS=$3

	local TMP_NEWER_VERS_VAR_YET_VAL=`eval echo '$'${TMP_VAR_NAME}`

    echo ${TMP_SPLITER}
    echo "Checking the soft version by date link in url of '${red}${TMP_VAR_FIND_URL}${reset}'， default val is '${green}${TMP_NEWER_VERS_VAR_YET_VAL}${reset}'"    
	#  | awk '{if (NR>2) {print}}' ，缺失无效行去除的判断
    local TMP_NEWER_DATE=`curl -s $TMP_VAR_FIND_URL | grep "$TMP_VAR_KEY_WORDS" | awk -F'</a>' '{print $2}' | awk '{sub("^ *","");sub(" *$","");print}' | sed '/^$/d' | awk -F' ' '{print $1}' | awk 'function t_f(t){"date -d \""t"\" +%s" | getline ft; return ft}{print t_f($1)}' | awk 'BEGIN {max = 0} {if ($1+0 > max+0) {max=$1 ;content=$0} } END {print content}' | xargs -I {} env LC_ALL=en_US.en date -d@{} "+%d-%h-%Y"`
    local TMP_NEWER_DATE_LINK_FILENAME=`curl -s $TMP_VAR_FIND_URL | grep "$TMP_VAR_KEY_WORDS" | grep "$TMP_NEWER_DATE" | sed 's/\(.*\)href="\([^"\n]*\)"\(.*\)/\2/g'`

	if [ -n "${TMP_NEWER_DATE_LINK_FILENAME}" ]; then
		echo "Upgrade the soft version by date link in url of '${red}${TMP_VAR_FIND_URL}${reset}'， release newer version to '${green}${TMP_NEWER_DATE_LINK_FILENAME}${reset}'"

		input_if_empty "TMP_NEWER_DATE_LINK_FILENAME" "Please sure the checked soft version by date link newer ${green}${TMP_NEWER_DATE_LINK_FILENAME}${reset}，if u want to change"

		eval ${1}=`echo '$TMP_NEWER_DATE_LINK_FILENAME'`
	fi
    echo ${TMP_SPLITER}


	return $?
}

#查找网页文件列表中，最新的文件名
#描述：本函数先获取href标签行，再提取href内容，最后提取文本关键字中最新的发布日期，该方法合适比较简单的数字关键字版本信息
#参数1：需要设置的变量名
#参数2：需要找寻的URL路径
#参数3：查找关键字（必须在关键字中将版本号括起‘()’，否则无法匹配具体的版本）
#示例：
# 	set_url_list_newer_href_link_filename "TMP_NEWER_LINK" "http://repo.yandex.ru/clickhouse/rpm/stable/x86_64/" "clickhouse-common-static-dbg-().x86_64.rpm"
# 	set_url_list_newer_href_link_filename "TMP_NEWER_LINK" "https://services.gradle.org/distributions/" "gradle-()-bin.zip"
function set_url_list_newer_href_link_filename()
{
	local TMP_VAR_NAME=$1
	local TMP_VAR_FIND_URL=$2
	local TMP_VAR_KEY_WORDS=$(echo ${3} | sed 's@()@[0-9.-]*@g')  #‘gradle-()-bin.zip’ -> 'gradle-.*-bin.zip'
	
	# 零宽断言，参考两篇即明白：https://segmentfault.com/q/1010000009346369，https://blog.csdn.net/iteye_5616/article/details/81855906
	local TMP_VAR_KEY_WORDS_ZREG_LEFT=$(echo ${3} | grep -o ".*(" | sed 's@(@@g' | xargs -I {} echo '(?<={})')
	local TMP_VAR_KEY_WORDS_ZREG_RIGHT=$(echo ${3} | grep -o ").*" | sed 's@)@@g' | xargs -I {} echo '(?={})')
	local TMP_VAR_KEY_WORDS_ZREG="${TMP_VAR_KEY_WORDS_ZREG_LEFT}\d.*${TMP_VAR_KEY_WORDS_ZREG_RIGHT}"
	
	# local TMP_VAR_KEY_WORDS_ZREG_RIGHT=$(echo ${3} | grep -o ")." | sed 's@)@@g' | xargs -I {} echo '[^{}]+')
	# local TMP_VAR_KEY_WORDS_ZREG="${TMP_VAR_KEY_WORDS_ZREG_LEFT}${TMP_VAR_KEY_WORDS_ZREG_RIGHT}"

	local TMP_NEWER_VERS_VAR_YET_VAL=`eval echo '$'${TMP_VAR_NAME}`

    echo ${TMP_SPLITER}
    echo "Checking the soft version by href link in url of '${red}${TMP_VAR_FIND_URL}${reset}'， default val is '${green}${TMP_NEWER_VERS_VAR_YET_VAL}${reset}'"
	# 清除字母开头： | tr -d "a-zA-Z-"
    local TMP_NEWER_VERS=`curl -s ${TMP_VAR_FIND_URL} | grep "href=" | sed 's/\(.*\)href="\([^"\n]*\)"\(.*\)/\2/g' | grep "${TMP_VAR_KEY_WORDS}" | grep -oP "${TMP_VAR_KEY_WORDS_ZREG}" | sort -rV | awk 'NR==1'`
	local TMP_NEWER_FILENAME=$(echo ${3} | sed "s@()@${TMP_NEWER_VERS}.*@g")
    local TMP_NEWER_HREF_LINK_FILENAME=`curl -s ${TMP_VAR_FIND_URL} | grep "href=" | sed 's/\(.*\)href="\([^"\n]*\)"\(.*\)/\2/g' | grep "${TMP_VAR_KEY_WORDS}" | grep "${TMP_NEWER_FILENAME}\$" | awk 'NR==1' | sed 's@.*/@@g'`

	if [ -n "${TMP_NEWER_HREF_LINK_FILENAME}" ]; then
		echo "Upgrade the soft version by href link in url of '${red}${TMP_VAR_FIND_URL}${reset}'， release newer version to '${green}${TMP_NEWER_HREF_LINK_FILENAME}${reset}'"
		
		input_if_empty "TMP_NEWER_HREF_LINK_FILENAME" "Please sure the checked soft version by href link newer ${green}${TMP_NEWER_HREF_LINK_FILENAME}${reset}，if u want to change"

		eval ${1}=`echo '$TMP_NEWER_HREF_LINK_FILENAME'`
	fi
    echo ${TMP_SPLITER}

	return $?
}

#检测github最新版本
#参数1：需要设置的变量名
#参数2：Github仓储/项目，例如meyer.cheng/linux_scripts
#示例：
#	TMP_ELASTICSEARCH_NEWER_VERS="0.0.1"
#	set_github_soft_releases_newer_version "TMP_ELASTICSEARCH_NEWER_VERS" "elastic/elasticsearch"
#	echo "The github soft of 'elastic/elasticsearch' releases newer version is $TMP_ELASTICSEARCH_NEWER_VERS"
# ??? 兼容没有tag标签的情况，类似filebeat
function set_github_soft_releases_newer_version() 
{
	local TMP_GITHUB_SOFT_NEWER_VERS_VAR_NAME=$1
	local TMP_GITHUB_SOFT_PATH=$2

	local TMP_GITHUB_SOFT_HTTPS_PATH="https://github.com/${TMP_GITHUB_SOFT_PATH}/releases"
	local TMP_GITHUB_SOFT_TAG_PATH="${TMP_GITHUB_SOFT_PATH}/releases/tag/"

	# 提取href中值，如需提取标签内值，则使用： sed 's/="[^"]*[><][^"]*"//g;s/<[^>]*>//g' | awk '{sub("^ *","");sub(" *$","");print}' | awk NR==1
	
	local TMP_GITHUB_SOFT_NEWER_VERS_VAR_YET_VAL=`eval echo '$'${TMP_GITHUB_SOFT_NEWER_VERS_VAR_NAME}`

    echo ${TMP_SPLITER}
    echo "Checking the soft in github repos of '${red}${TMP_GITHUB_SOFT_PATH}${reset}'， default val is '${green}${TMP_GITHUB_SOFT_NEWER_VERS_VAR_YET_VAL}${reset}'"
	local TMP_GITHUB_SOFT_NEWER_VERS=`curl -s ${TMP_GITHUB_SOFT_HTTPS_PATH} | grep "${TMP_GITHUB_SOFT_TAG_PATH}" | awk '{sub("^ *","");sub(" *$","");sub("<a href=\".*/tag/v", "");sub("<a href=\".*/tag/", "");sub("\">.*", "");print}' | awk NR==1`

	if [ -n "${TMP_GITHUB_SOFT_NEWER_VERS}" ]; then
		echo "Upgrade the soft in github repos of '${red}${TMP_GITHUB_SOFT_PATH}${reset}'， release newer version to '${green}${TMP_GITHUB_SOFT_NEWER_VERS}${reset}'"

		input_if_empty "TMP_GITHUB_SOFT_NEWER_VERS" "Please sure the checked soft in github repos newer ${green}${TMP_GITHUB_SOFT_NEWER_VERS}${reset}，if u want to change"

		eval ${1}=`echo '$TMP_GITHUB_SOFT_NEWER_VERS'`
	fi
    echo ${TMP_SPLITER}
	
	return $?
}

#查找列表中，获取关键字首行
#参数1：需要设置的变量名
#参数2：需要查找的内容
#参数3：查找关键字
function find_content_list_first_line()
{
	local TMP_VAR_NAME=$1
	local TMP_VAR_FIND_CONTENT=$2
	local TMP_VAR_KEY_WORDS=$3

    local TMP_MATCH_CONTENT_FIRST_LINE=`echo $TMP_VAR_FIND_CONTENT | grep "$TMP_VAR_KEY_WORDS" | awk 'NR==1'`

	if [ -n "$TMP_MATCH_CONTENT_FIRST_LINE" ]; then
		eval ${1}='$TMP_MATCH_CONTENT_FIRST_LINE'
	fi

	return $?
}

#填充右处
#参数1：需要设置的变量名
#参数2：填充字符
#参数3：总长度
function fill_right()
{
	local TMP_VAR_NAME=$1
	local TMP_VAR_VAL=`eval echo '$'$TMP_VAR_NAME`
	local TMP_FILL_CHR=$2
	local TMP_TOTAL_LEN=$3

	local TMP_ITEM_LEN=${#TMP_VAR_VAL}
	local TMP_OUTPUT_SPACE_COUNT=$((TMP_TOTAL_LEN-TMP_ITEM_LEN))	
	local TMP_SPACE_STR=`eval printf %.s'$TMP_FILL_CHR' {1..$TMP_OUTPUT_SPACE_COUNT}`
	
	eval $TMP_VAR_NAME='$'TMP_VAR_VAL'$'TMP_SPACE_STR
	
	# eval $TMP_VAR_NAME='$'TMP_VAR_VAL'$'TMP_SPACE_STR
	return $?
}

#填充并输出
#参数1：需要填充的实际值
#参数2：填充字符
#参数3：总长度
#参数4：格式化字符
function echo_fill_right()
{
	local TMP_VAR_FILL_RIGHT=$1
	fill_right "TMP_VAR_FILL_RIGHT" $2 $3

	if [ -n "$4" ]; then
		echo "$4" | sed s@%@"$TMP_VAR_FILL_RIGHT"@g
		return $?
	fi

	echo $TMP_VAR_FILL_RIGHT
	return $?
}

#按键选择类型的弹出动态设置变量值函数
#参数1：需要设置的变量名
#参数2：提示信息
#参数3：选项参数
#参数4：自定义的Spliter
function set_if_choice()
{
	local TMP_VAR_NAME=$1
	local TMP_NOTICE=$2
	local TMP_CHOICE=$3

	#参数4：函数调用
	#TMP_PREFIX=$4 
	
	local TMP_CHOICE_SPLITER=$([ -n "${TMP_SPLITER}" ] && echo "${TMP_SPLITER}" || echo "-------------------------------------------------")
	set_if_empty "TMP_CHOICE_SPLITER" "$4"
	local TMP_CHOICE_SPLITER_LEN=${#TMP_CHOICE_SPLITER}
	
	echo $TMP_CHOICE_SPLITER
	local arr=(${TMP_CHOICE//,/ })
	local arr_len=${#arr[@]}
	
	local TMP_SPACE=""
	for I in ${!arr[@]};  
	do
		# TMP_ITEM_LEN=${#arr[$I]}
		# TMP_OUTPUT_SPACE_COUNT=$((TMP_CHOICE_SPLITER_LEN-TMP_ITEM_LEN-10))	
		# TMP_SPACE_STR=`eval printf %.s'' {1..$TMP_OUTPUT_SPACE_COUNT}`

		TMP_COLOR="${red}"
		if [ $(($I%2)) -eq 0 ]; then
			TMP_COLOR="${green}"
		fi

		# echo "|     $((I+1)). ${TMP_COLOR}${arr[$I]}${reset}$TMP_SPACE_STR|"
		TMP_SIGN=$((I+1))
		
		if [ $I -ge 9 ]; then
			TMP_SPACE=""
		fi

		TMP_SET_IF_CHOICE_ITEM=${arr[$I]}
		if [ `echo "$TMP_SET_IF_CHOICE_ITEM" | tr 'A-Z' 'a-z'` = "exit" ]; then
			echo $TMP_CHOICE_SPLITER
			TMP_SIGN="x"
		fi

		echo_fill_right "$TMP_SET_IF_CHOICE_ITEM" "" $((TMP_CHOICE_SPLITER_LEN-13)) "|     [$TMP_SIGN].$TMP_SPACE${TMP_COLOR}%${reset}|"
	done
	
	echo $TMP_CHOICE_SPLITER
	if [ -n "$TMP_NOTICE" ]; then
		echo "$TMP_NOTICE, by above keys, then enter it"
	fi
	
	if [ $arr_len -le 9 ]; then
		read -n 1 KEY
	else
		read KEY
	fi
	echo
	
	typeset -l NEW_VAL
	local NEW_VAL=${arr[$((KEY-1))]}
	eval ${1}='$NEW_VAL'
	echo "Choice of '$NEW_VAL' checked"

	# if [ -n "$TMP_PREFIX" ]; then
	# 	if [ "$NEW_VAL" = "exit" ]; then
	# 		exit 1
	# 	fi
	# 	$TMP_PREFIX$NEW_VAL
	# fi

	return $?
}

#按键选择类型的弹出动态设置变量值函数
#参数1：需要设置的变量名
#参数2：提示信息
#参数3：选项参数
#参数4：自定义的Spliter
#参数5：脚本路径/前缀
#参数6：执行脚本后的操作
function exec_if_choice_custom()
{
	set_if_choice "$1" "$2" "$3" "$4"

	local NEW_VAL=`eval echo '$'$1`
	if [ -n "${NEW_VAL}" ]; then
		if [ "${NEW_VAL}" = "exit" ]; then
			exit 1
		fi

		if [ "${NEW_VAL}" = "..." ]; then
			return $?
		fi

		if [ -n "$5" ]; then
			local TMP_EXEC_IF_CHOICE_SCRIPT_PATH="${5}/${NEW_VAL}"
			local TMP_EXEC_IF_CHOICE_SCRIPT_PATH_ARR=(${TMP_EXEC_IF_CHOICE_SCRIPT_PATH})
			TMP_EXEC_IF_CHOICE_SCRIPT_PATH_ARR[1]=`echo "${TMP_EXEC_IF_CHOICE_SCRIPT_PATH}" | sed "s@-@.@g"`
			TMP_EXEC_IF_CHOICE_SCRIPT_PATH_ARR[2]=`echo "${TMP_EXEC_IF_CHOICE_SCRIPT_PATH}" | sed "s@-@_@g"`
			TMP_EXEC_IF_CHOICE_SCRIPT_PATH_ARR[3]=`echo "${TMP_EXEC_IF_CHOICE_SCRIPT_PATH}" | sed "s@_@-@g"`
			TMP_EXEC_IF_CHOICE_SCRIPT_PATH_ARR[4]=`echo "${TMP_EXEC_IF_CHOICE_SCRIPT_PATH}" | sed "s@_@.@g"`
			TMP_EXEC_IF_CHOICE_SCRIPT_PATH_ARR[5]=`echo "${TMP_EXEC_IF_CHOICE_SCRIPT_PATH}" | sed "s@\.@-@g"`
			TMP_EXEC_IF_CHOICE_SCRIPT_PATH_ARR[6]=`echo "${TMP_EXEC_IF_CHOICE_SCRIPT_PATH}" | sed "s@\.@_@g"`
			TMP_EXEC_IF_CHOICE_SCRIPT_PATH_ARR[7]=`echo "${TMP_EXEC_IF_CHOICE_SCRIPT_PATH}" | sed "s@ @-@g"`
			TMP_EXEC_IF_CHOICE_SCRIPT_PATH_ARR[8]=`echo "${TMP_EXEC_IF_CHOICE_SCRIPT_PATH}" | sed "s@ @_@g"`
			TMP_EXEC_IF_CHOICE_SCRIPT_PATH_ARR[9]=`echo "${TMP_EXEC_IF_CHOICE_SCRIPT_PATH}" | sed "s@ @.@g"`

			# 识别文件转换
			for TMP_EXEC_IF_CHOICE_SCRIPT_PATH in ${TMP_EXEC_IF_CHOICE_SCRIPT_PATH_ARR[@]}; do
				if [ -f "${TMP_EXEC_IF_CHOICE_SCRIPT_PATH}.sh" ]; then
					TMP_EXEC_IF_CHOICE_SCRIPT_PATH="${TMP_EXEC_IF_CHOICE_SCRIPT_PATH}.sh"
					break
				fi
			done

			if [ ! -f "${TMP_EXEC_IF_CHOICE_SCRIPT_PATH}" ];then
				exec_check_action "${5}${NEW_VAL}"
			else
				source ${TMP_EXEC_IF_CHOICE_SCRIPT_PATH}
			fi
		else
			exec_check_action "${NEW_VAL}"
		fi
		
		local TMP_RETURN=$?
		#返回非0，跳出循环，指导后续请求不再进行
		if [ ${TMP_RETURN} != 0 ]; then
			return ${TMP_RETURN}
		fi

		if [ "${NEW_VAL}" != "..." ]; then
			read -n 1 -p "Press <Enter> go on..."
		fi

		if [ -n "${6}" ]; then
			eval "${6}"
		fi
	fi


	return $?
}

#按键选择类型的弹出动态设置变量值函数
#参数1：需要设置的变量名
#参数2：提示信息
#参数3：选项参数
#参数4：自定义的Spliter
#参数5：脚本路径/前缀
function exec_if_choice()
{
	exec_if_choice_custom "$1" "$2" "$3" "$4" "$5" 'exec_if_choice "$1" "$2" "$3" "$4" "$5"'
}

#按键选择类型的弹出动态设置变量值函数
#参数1：需要设置的变量名
#参数2：提示信息
#参数3：选项参数
#参数4：自定义的Spliter
#参数5：脚本路径/前缀
function exec_if_choice_onece()
{
	exec_if_choice_custom "$1" "$2" "$3" "$4" "$5"
}

#检测并执行指令
#要执行的函数/脚本名称
function exec_check_action() {
	if [ "$(type -t ${1})" = "function" ] ; then
		${1}
	else
		eval "${1}"
	fi

	return $?
}

#分割并执行动作
#参数1：用于分割的字符串
#参数2：对分割字符串执行脚本
#例子：TMP=1 && while_exec "TMP=\$((TMP+1))" "[ \$TMP -eq 10 ] && echo 1" "echo \$TMP"
function exec_split_action()
{
	if [ $? -ne 0 ]; then
		return $?
	fi
    
	local TMP_WHILE_SPLIT_ARR=(${1//,/ })
	local TMP_WHILE_EXEC_SCRIPT=${2}
	local TMP_WHILE_EXEC_SCRIPT_FORMAT_COUNT=$(echo "${2}" | grep -o "%s" | wc -l)
	
	for TMP_WHILE_SPLIT_ITEM in ${TMP_WHILE_SPLIT_ARR[@]}; do
		# 附加动态参数
		local TMP_WHILE_EXEC_SCRIPT_FORMAT_PARAMS="${TMP_WHILE_SPLIT_ITEM}"
		for ((TMP_WHILE_EXEC_SCRIPT_FORMAT_PATAMS_COUNT_INDEX=1;TMP_WHILE_EXEC_SCRIPT_FORMAT_PATAMS_COUNT_INDEX<${TMP_WHILE_EXEC_SCRIPT_FORMAT_COUNT};TMP_WHILE_EXEC_SCRIPT_FORMAT_PATAMS_COUNT_INDEX++)); do
			TMP_WHILE_EXEC_SCRIPT_FORMAT_PARAMS=$(printf "${TMP_WHILE_EXEC_SCRIPT_FORMAT_PARAMS} %s" "${TMP_WHILE_SPLIT_ITEM}")
		done
		
		# 格式化运行动态脚本
        local TMP_WHILE_EXEC_SCRIPT_CURRENT=`printf "${TMP_WHILE_EXEC_SCRIPT}" ${TMP_WHILE_EXEC_SCRIPT_FORMAT_PARAMS}`
        if [ "$(type -t ${TMP_WHILE_EXEC_SCRIPT_CURRENT})" = "function" ] ; then
            ${TMP_WHILE_EXEC_SCRIPT_CURRENT} "${TMP_WHILE_SPLIT_ITEM}"
        else
            eval "${TMP_WHILE_EXEC_SCRIPT_CURRENT}"
        fi
    done

	return $?
}

#执行需要判断的Y/N逻辑函数
#参数1：并行逻辑执行参数/脚本
#参数2：提示信息
function exec_yn_action()
{
	TMP_FUNCS_ON_Y=$1
	TMP_NOTICE=$2
	echo "$TMP_NOTICE, by follow key ('${red}yes(y) or enter key/no(n) or else${reset}')?"
	read -n 1 Y_N
	echo ""

	case $Y_N in
		"y" | "Y" | "")
		;;
		*)
		return 1
	esac

	local TMP_ARR_FUNCS_OR_SCRIPTS=(${TMP_FUNCS_ON_Y//,/ })
	#echo ${#TMP_ARR_FUNCS_OR_SCRIPTS[@]} 
	for TMP_FUNC_ON_Y in ${TMP_ARR_FUNCS_OR_SCRIPTS[@]}; do
		exec_check_action "$TMP_FUNC_ON_Y"
		RETURN=$?
		#返回非0，跳出循环，指导后续请求不再进行
		if [ $RETURN != 0 ]; then
			return $RETURN
		fi
	done

	return $?
}

#检测是否值
function check_yn_action() {
	TMP_VAR_NAME=$1
	YN_VAL=`eval expr '$'$TMP_VAR_NAME`
	
	if [ "$YN_VAL" = false ] || [ "$YN_VAL" = 0 ]; then
		return $?
	fi

	return 1
}

#按数组循环执行函数
#参数1：需要针对存放的变量名
#参数2：循环数组
#参数3：循环执行脚本函数
#exec_repeat_funcs "TMP_EXEC_REPS_RESULT" "1000,2000" "num_sum"
function exec_repeat_funcs()
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_VAR_NAME=$1
	local TMP_ARRAY_STR=$2
	local TMP_FORMAT_FUNC=$3
	
	local arr=(${TMP_ARRAY_STR//,/ })
	for I in ${!arr[@]};  
	do
		TMP_OUTPUT=`$TMP_FORMAT_FUNC "${arr[$I]}"`

		if [ $I -gt 0 ]; then
			eval ${1}=`eval expr '$'$TMP_VAR_NAME,$TMP_OUTPUT`
		else
			eval ${1}='$TMP_OUTPUT'
		fi
	done

	return $?
}

#循环执行函数，执行true时终止(函数的入参列表必须一致)
#参数1：需要针对存放的变量名
#参数2：循环函数数组
#参数3：函数入参(不定长)
#exec_funcs_repeat_until_output "TMP_EXEC_FUNCS_REPS_UNTIL_OUTPUT_RESULT" "funa,funb" "parama" "paramc" ...
function exec_funcs_repeat_until_output()
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_VAR_NAME=$1
	local TMP_ARRAY_FUNCS=$2
	local TMP_FUNC_PARAMS=()

	local i=0
	for param in "$@";
	do
		if [ $i -gt 1 ]; then
			TMP_FUNC_PARAMS[$i-2]="\"$param\""
		fi
	    let i++
	done
	
	arr=(${TMP_ARRAY_FUNCS//,/ })
	for I in ${!arr[@]};  
	do
		local TMP_EXEC="${arr[$I]} ${TMP_FUNC_PARAMS[*]}"
		local TMP_OUTPUT=`eval $TMP_EXEC`
		if [ -n "$TMP_OUTPUT" ]; then
			break
		fi
	done

	return $?
}

#执行文本格式化
#参数1：需要格式化的变量名
#参数2：格式化字符串规格
#示例：
#	TMP_TEST_FORMATED_TEXT="World"
#	exec_text_format "TMP_TEST_FORMATED_TEXT" "Hello %s"
#	echo "The formated text is ‘$TMP_TEST_FORMATED_TEXT’"
function exec_text_format()
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_EXEC_TEXT_FORMAT_VAR_NAME=${1}
	local TMP_EXEC_TEXT_FORMAT_VAR_FORMAT=${2}
	local TMP_EXEC_TEXT_FORMAT_VAR_VAL=`eval echo '$'${TMP_EXEC_TEXT_FORMAT_VAR_NAME}`
	
	# 判断格式化模板是否为空，为空不继续执行
	if [ -z "${TMP_EXEC_TEXT_FORMAT_VAR_FORMAT}" ]; then
		return $?
	fi
	
	# 附加动态参数
	local TMP_EXEC_TEXT_FORMAT_COUNT=$(echo ${TMP_EXEC_TEXT_FORMAT_VAR_FORMAT} | grep -o "%" | wc -l)
	local TMP_EXEC_TEXT_FORMATED_VAL=`seq -s "{}" $((TMP_EXEC_TEXT_FORMAT_COUNT+1)) | sed 's@[0-9]@ @g' | sed "s@{}@${TMP_EXEC_TEXT_FORMAT_VAR_VAL}@g"`
	
	local TMP_EXEC_TEXT_FORMAT_FORMATED_VAL=`echo "${TMP_EXEC_TEXT_FORMAT_VAR_FORMAT}" | xargs -I {} printf {} ${TMP_EXEC_TEXT_FORMATED_VAL}`

	eval ${1}='${TMP_EXEC_TEXT_FORMAT_FORMATED_VAL:-${TMP_EXEC_TEXT_FORMAT_VAR_VAL}}'

	return $?
}

#循环读取值
#参数1：需要设置的变量名（即是默认值，也是逗号分隔的数组字符串）
#参数2：提示信息
#参数3：格式化字符串
#参数4：需执行的脚本
function exec_while_read() 
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	local TMP_EXEC_WHILE_READ_VAR_NAME=$1
	local TMP_EXEC_WHILE_READ_NOTICE=$2
	local TMP_EXEC_WHILE_READ_FORMAT=$3
	local TMP_EXEC_WHILE_READ_SCRIPTS=$4
	local TMP_EXEC_WHILE_READ_DFT=`eval echo '$'$TMP_EXEC_WHILE_READ_VAR_NAME`

	local I=1
	for I in $(seq 99);
	do
		local TMP_EXEC_WHILE_READ_CURRENT_NOTICE=`eval echo "$TMP_EXEC_WHILE_READ_NOTICE"`
		echo "${TMP_EXEC_WHILE_READ_CURRENT_NOTICE} Or '${red}enter key${reset}' To Quit"
		read -e CURRENT

		echo "Item of '${red}$CURRENT${reset}' inputed"
		
		if [ -z "$CURRENT" ]; then
			if [ $I -eq 1 ] && [ -n "$TMP_EXEC_WHILE_READ_DFT" ]; then
				echo "No input, set value to default '$TMP_EXEC_WHILE_READ_DFT'"
				CURRENT="$TMP_EXEC_WHILE_READ_DFT"
			else
				TMP_EXEC_WHILE_READ_BREAK_ACTION=true
			fi
		fi

		TMP_EXEC_WHILE_READ_FORMAT_CURRENT="$CURRENT"
	
		exec_text_format "TMP_EXEC_WHILE_READ_FORMAT_CURRENT" "$TMP_EXEC_WHILE_READ_FORMAT"

		if [ -n "$CURRENT" ]; then
			if [ $I -gt 1 ]; then
				eval ${TMP_EXEC_WHILE_READ_VAR_NAME}=`eval echo '$'$TMP_EXEC_WHILE_READ_VAR_NAME,$TMP_EXEC_WHILE_READ_FORMAT_CURRENT`
			else
				eval ${TMP_EXEC_WHILE_READ_VAR_NAME}="$TMP_EXEC_WHILE_READ_FORMAT_CURRENT"
			fi
			
			exec_check_action "$TMP_EXEC_WHILE_READ_SCRIPTS"
			echo
		fi

		if [ $TMP_EXEC_WHILE_READ_BREAK_ACTION ]; then
			break
		fi
	done

	# TMP_FORMAT_VAL="$TMP_WRAP_CHAR$CURRENT$TMP_WRAP_CHAR"
	local NEW_VAL=`eval echo '$'$TMP_EXEC_WHILE_READ_VAR_NAME`
	NEW_VAL=`echo "$NEW_VAL" | sed "s/^[,]\{1,\}//g;s/[,]\{1,\}$//g"`
	eval ${1}='$NEW_VAL'
	
	if [ -z "$NEW_VAL" ]; then
		echo "${red}Items not set${reset}"
		# exit 1
	fi

	# eval ${1}=`echo "${1}" | sed "s/^[,]\{1,\}//g;s/[,]\{1,\}$//g"`
	echo "Final value is '$NEW_VAL'"

	return $?
}

#循环读取JSON值
#参数1：需要设置的变量名
#参数2：提示信息
#参数3：选项参数
function exec_while_read_json() 
{
	if [ $? -ne 0 ]; then
		return $?
	fi

	TMP_VAR_NAME=$1
	TMP_NOTICE=$2
	TMP_ITEMS=$3

	arr=(${TMP_ITEMS//,/ })
	TMP_ITEM_LEN=${#arr[@]}
	for i in $(seq 99);
	do
		echo "Please sure you will input items by '${red}yes(y) or enter key/no(n)${reset}'"
		read -n 1 Y_N
		echo ""

		case $Y_N in
			"y" | "Y" | "")
			;;
			*)
			break
		esac

		TMP_ITEM="$TMP_ITEM{ "
		for I in ${!arr[@]}; do
			TMP_KEY=${arr[$I]}
			echo $TMP_NOTICE | sed 's@\$i@'$i'@g' | sed 's@\$@'\'$TMP_KEY\''@g'
			read -e CURRENT

			TMP_ITEM="$TMP_ITEM\"$TMP_KEY\": \"$CURRENT\""
			if [ $((I+1)) -ne $TMP_ITEM_LEN ]; then
				TMP_ITEM="$TMP_ITEM, "
			fi
		done
		TMP_ITEM="$TMP_ITEM }"

		eval ${1}='$TMP_ITEM'
		echo "Item of '${red}$TMP_ITEM${reset}' inputed"
	done

	NEW_VAL=`echo "$TMP_ITEM" | sed 's@}{@}, {@g'`
	eval ${1}='$NEW_VAL'
	
	if [ -z "$NEW_VAL" ]; then
		echo "${red}Items not set, script exit${reset}"
		exit 1
	fi

	# eval ${1}=`echo "${1}" | sed "s/^[,]\{1,\}//g;s/[,]\{1,\}$//g"`
	echo "Final value is '$NEW_VAL'"
}

#生成启动配置文件
#参数1：程序命名
#参数2：程序启动的目录
#参数3：程序启动的命令
#参数4：程序启动的环境
#参数5：优先级序号
#参数6：运行环境，默认/etc/profile
#参数7：运行所需的用户，默认root
function echo_startup_config()
{
	set_if_empty "SUPERVISOR_ATT_DIR" "${ATT_DIR}/supervisor"

	local TMP_STARTUP_SUPERVISOR_NAME=${1}
	local TMP_STARTUP_SUPERVISOR_FILENAME=${TMP_STARTUP_SUPERVISOR_NAME}.conf
	local TMP_STARTUP_SUPERVISOR_BOOT_DIR=${2}
	local TMP_STARTUP_SUPERVISOR_COMMAND=${3}
	local TMP_STARTUP_SUPERVISOR_ENV=${4}
	local TMP_STARTUP_SUPERVISOR_PRIORITY=${5:-99}
	local TMP_STARTUP_SUPERVISOR_SOURCE=${6}
	local TMP_STARTUP_SUPERVISOR_USER=${7:-root}

	local TMP_STARTUP_SUPERVISOR_DFT_ENV="/usr/bin:/usr/local/bin:"
    # 设置默认的源环境，并检测是否为NPM启动方式
	if [ -z "${TMP_STARTUP_SUPERVISOR_SOURCE}" ]; then
		TMP_STARTUP_SUPERVISOR_SOURCE="/etc/profile"

		# 因konga的关系，此处启动暂时注释自动修改环境的操作（建议可自动修改环境变量至当前的npm版本，并取消原始bin环境）
		# local TMP_STARTUP_BY_NPM_CHECK=`echo "${TMP_STARTUP_SUPERVISOR_COMMAND}" | sed "s@^sudo@@g" | awk '{sub("^ *","");sub(" *$","");print}' | grep -o "^npm"`
		# if [ "${TMP_STARTUP_BY_NPM_CHECK}" == "npm" ]; then
		# 	TMP_STARTUP_SUPERVISOR_SOURCE=`dirname ${NVM_PATH}`
		# fi

		# 上述调整后，解决环境冲突问题
		local TMP_STARTUP_BY_NPM_CHECK=`echo "${TMP_STARTUP_SUPERVISOR_COMMAND}" | sed "s@^sudo@@g" | awk '{sub("^ *","");sub(" *$","");print}' | grep -o "^npm"`
		if [ "${TMP_STARTUP_BY_NPM_CHECK}" == "npm" ]; then
			TMP_STARTUP_SUPERVISOR_DFT_ENV=""
		fi
	fi

	if [ -n "${TMP_STARTUP_SUPERVISOR_BOOT_DIR}" ]; then
		TMP_STARTUP_SUPERVISOR_BOOT_DIR="directory = ${TMP_STARTUP_SUPERVISOR_BOOT_DIR}  ; 程序的启动目录"
	fi

	if [ -n "${TMP_STARTUP_SUPERVISOR_ENV}" ]; then
		TMP_STARTUP_SUPERVISOR_ENV="${TMP_STARTUP_SUPERVISOR_ENV}:"
	fi

	# 类似的：environment = ANDROID_HOME="/opt/android-sdk-linux",PATH="/usr/bin:/usr/local/bin:%(ENV_ANDROID_HOME)s/tools:%(ENV_ANDROID_HOME)s/tools/bin:%(ENV_ANDROID_HOME)s/platform-tools:%(ENV_PATH)s"
	TMP_STARTUP_SUPERVISOR_ENV="environment = PATH=\"${TMP_STARTUP_SUPERVISOR_DFT_ENV}${TMP_STARTUP_SUPERVISOR_ENV}%(ENV_PATH)s\"  ; 程序启动的环境变量信息"

	TMP_STARTUP_SUPERVISOR_PRIORITY="priority = ${TMP_STARTUP_SUPERVISOR_PRIORITY}"
	
	local TMP_STARTUP_SUPERVISOR_CONF_DIR=${SUPERVISOR_ATT_DIR}/conf
	local TMP_STARTUP_SUPERVISOR_CONF_CURRENT_OUTPUT_PATH=${TMP_STARTUP_SUPERVISOR_CONF_DIR}/${TMP_STARTUP_SUPERVISOR_FILENAME}
    local TMP_STARTUP_SUPERVISOR_LNK_LOGS_DIR=${LOGS_DIR}/supervisor
	
	path_not_exists_create `dirname ${TMP_STARTUP_SUPERVISOR_CONF_CURRENT_OUTPUT_PATH}`

	path_not_exists_create "${TMP_STARTUP_SUPERVISOR_LNK_LOGS_DIR}"

	echo
    echo ${TMP_SPLITER}
	if [ ! -f "${TMP_STARTUP_SUPERVISOR_CONF_CURRENT_OUTPUT_PATH}" ]; then
		echo "Supervisor：Gen startup config of '${green}${TMP_STARTUP_SUPERVISOR_CONF_CURRENT_OUTPUT_PATH}${reset}'"
		echo
		tee ${TMP_STARTUP_SUPERVISOR_CONF_CURRENT_OUTPUT_PATH} <<-EOF
[program:${TMP_STARTUP_SUPERVISOR_NAME}]
command = /bin/bash -c 'source "\$0" && exec "\$@"' ${TMP_STARTUP_SUPERVISOR_SOURCE} ${TMP_STARTUP_SUPERVISOR_COMMAND} ; 启动命令，可以看出与手动在命令行启动的命令是一样的
autostart = true                                                                     ; 在 supervisord 启动的时候也自动启动
startsecs = 240                                                                      ; 启动 60 秒后没有异常退出，就当作已经正常启动了
autorestart = true                                                                   ; 程序异常退出后自动重启
startretries = 10                                                                    ; 启动失败自动重试次数，默认是 3
user = ${TMP_STARTUP_SUPERVISOR_USER}                                                ; 用哪个用户启动
redirect_stderr = true                                                               ; 把 stderr 重定向到 stdout，默认 false
stdout_logfile_maxbytes = 20MB                                                       ; stdout 日志文件大小，默认 50MB
stdout_logfile_backups = 20                                                          ; stdout 日志文件备份数

${TMP_STARTUP_SUPERVISOR_PRIORITY}                                                     ; 启动优先级，默认999
${TMP_STARTUP_SUPERVISOR_BOOT_DIR}                                                        

${TMP_STARTUP_SUPERVISOR_ENV}                                                        

stdout_logfile = ${TMP_STARTUP_SUPERVISOR_LNK_LOGS_DIR}/${TMP_STARTUP_SUPERVISOR_NAME}_stdout.log  ; stdout 日志文件，需要注意当指定目录不存在时无法正常启动，所以需要手动创建目录（supervisord 会自动创建日志文件）
numprocs = 1                                                                           ;
EOF
	else
		echo "Supervisor：The startup config of '${red}${TMP_STARTUP_SUPERVISOR_CONF_CURRENT_OUTPUT_PATH}${reset}' created"
		echo
		cat ${TMP_STARTUP_SUPERVISOR_CONF_CURRENT_OUTPUT_PATH}
	fi

    echo ${TMP_SPLITER}
	echo

	return $?
}

# 输出WEB映射生成脚本（必须在KONG所在机器下运行）
# 参数1：WEB命名
# 参数2：WEB域名
# 参数3：WEB端口
# 参数4：WEB地址
# 参数5：Kong地址
# 参数6：Caddy地址
function echo_web_service_init_scripts()
{
	local TMP_WEB_SERVICE_NAME=${1}
	local TMP_WEB_SERVICE_UPPER_NAME=`echo ${TMP_WEB_SERVICE_NAME} | sed 's/[a-z]/\u&/g'`
	local TMP_WEB_SERVICE_DOMAIN=${2}
	local TMP_WEB_SERVICE_HOST_PORT=${3}
	local TMP_WEB_SERVICE_HOST=${4:-"${LOCAL_HOST}"}
	
	local TMP_WEB_SERVICE_KONG_HOST=${5}
	local TMP_WEB_SERVICE_CDY_HOST=${6}

	# 开放端口给kong所在服务器
	if [ -n "${TMP_WEB_SERVICE_KONG_HOST}" ]; then
		echo_soft_port ${TMP_WEB_SERVICE_HOST_PORT} "${TMP_WEB_SERVICE_KONG_HOST}"
	fi

	path_not_exists_create "${WWW_INIT_DIR}"
    echo ${TMP_SPLITER}
	tee ${WWW_INIT_DIR}/init_web_service_for_${TMP_WEB_SERVICE_UPPER_NAME}_by_caddy_webhook.sh <<-EOF
#!/bin/sh
#----------------------------------------------------
#  Project init script - for web service or autohttps
#----------------------------------------------------
TMP_INIT_WEB_SERVICE_CDY_HOST="${TMP_WEB_SERVICE_CDY_HOST}"
TMP_INIT_WEB_SERVICE_LOCAL_HOST=\`ip a | grep inet | grep -v inet6 | grep -v 127 | grep -v docker | awk '{print $2}' | awk -F'/' '{print $1}' | awk 'END {print}'\`
[ -z \${TMP_INIT_WEB_SERVICE_LOCAL_HOST} ] && TMP_INIT_WEB_SERVICE_LOCAL_HOST=\`ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1\`

# 本机未有kong_api直接退出执行
if [ ! -f "/usr/bin/kong_api" ]; then
	echo "Can't find 'kong_api' command in '/usr/bin/kong_api'，please sure u exec at 'kong host'"
	return
fi

# 未定义caddy-host	
if [ -z "\${TMP_INIT_WEB_SERVICE_CDY_HOST}" ]; then	
	echo "Can't find 'caddy host' in var defined，please sure which your caddy host"
	return
fi

# 先添加域名，避免被caddy-webhook的autohttps解析覆盖
kong_api "service" "${TMP_WEB_SERVICE_KONG_HOST}" "${TMP_WEB_SERVICE_UPPER_NAME}" "${TMP_WEB_SERVICE_HOST}:${TMP_WEB_SERVICE_HOST_PORT}" "${TMP_WEB_SERVICE_DOMAIN}"

# 添加防火墙授权许可
echo "${TMP_SPLITER}"
echo "Please allow your iptables or cloud firewall for port '${TMP_WEB_SERVICE_HOST_PORT}' on host '${TMP_WEB_SERVICE_HOST}'"
echo "${TMP_SPLITER}"
echo "iptables："
echo "          sed -i "11a-A INPUT -s \${TMP_INIT_WEB_SERVICE_LOCAL_HOST} -p tcp -m state --state NEW -m tcp --dport ${TMP_WEB_SERVICE_HOST_PORT} -j ACCEPT" /etc/sysconfig/iptables"
echo "          sed -i "11a-A INPUT -s \${TMP_INIT_WEB_SERVICE_LOCAL_HOST} -p udp -m state --state NEW -m udp --dport ${TMP_WEB_SERVICE_HOST_PORT} -j ACCEPT" /etc/sysconfig/iptables"
echo "          systemctl restart iptables.service"
echo "firewall-cmd："
echo "              firewall-cmd --permanent --add-port=${TMP_WEB_SERVICE_HOST_PORT}/tcp"
echo "              firewall-cmd --permanent --add-port=${TMP_WEB_SERVICE_HOST_PORT}/udp"
echo "              firewall-cmd --reload"
echo "${TMP_SPLITER}"

# 添加autohttps维护
tee ${WWW_INIT_DIR}/Caddyroute_for_${TMP_WEB_SERVICE_DOMAIN}.json <<-\EOF
{
	"match": [
		{
			"host": ["${TMP_WEB_SERVICE_DOMAIN}"]
		}
	],
	"handle": [
		{
			"handler": "static_response",
			"body": "Welcome to my security site of '${TMP_WEB_SERVICE_DOMAIN}'!"
		}
	],
	"terminal": true
}
\EOF

	curl \${TMP_INIT_WEB_SERVICE_CDY_HOST}:${CDY_API_PORT}/config/apps/http/servers/autohttps/routes -X POST -H "Content-Type: application/json" -d @Caddyroute_for_${TMP_WEB_SERVICE_DOMAIN}.json
	curl \${TMP_INIT_WEB_SERVICE_CDY_HOST}:${CDY_API_PORT}/config/apps/http/servers/autohttps/logs/logger_names -X POST -H "Content-Type: application/json" -d '{"${TMP_WEB_SERVICE_DOMAIN}": "${TMP_WEB_SERVICE_DOMAIN}"}'
EOF
    echo ${TMP_SPLITER}
	tee ${WWW_INIT_DIR}/init_web_service_for_${TMP_WEB_SERVICE_UPPER_NAME}_by_acme_plugin.sh <<-EOF
#!/bin/sh
#----------------------------------------------------
#  Project init script - for web service or autohttps
#----------------------------------------------------
TMP_INIT_WEB_SERVICE_LOCAL_HOST=\`ip a | grep inet | grep -v inet6 | grep -v 127 | grep -v docker | awk '{print $2}' | awk -F'/' '{print $1}' | awk 'END {print}'\`
[ -z \${TMP_INIT_WEB_SERVICE_LOCAL_HOST} ] && TMP_INIT_WEB_SERVICE_LOCAL_HOST=\`ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1\`

# 本机未有kong_api直接退出执行
if [ ! -f "/usr/bin/kong_api" ]; then
	echo "Can't find 'kong_api' command in '/usr/bin/kong_api'，please sure u exec at 'kong host'"
	return
fi

# 先添加域名
kong_api "service" "${TMP_WEB_SERVICE_KONG_HOST}" "${TMP_WEB_SERVICE_UPPER_NAME}" "${TMP_WEB_SERVICE_HOST}:${TMP_WEB_SERVICE_HOST_PORT}" "${TMP_WEB_SERVICE_DOMAIN}"

# 添加防火墙授权许可
echo "${TMP_SPLITER}"
echo "Please allow your iptables or cloud firewall for port '${TMP_WEB_SERVICE_HOST_PORT}' on host '${TMP_WEB_SERVICE_HOST}'"
echo "${TMP_SPLITER}"
echo "iptables："
echo "          sed -i "11a-A INPUT -s \${TMP_INIT_WEB_SERVICE_LOCAL_HOST} -p tcp -m state --state NEW -m tcp --dport ${TMP_WEB_SERVICE_HOST_PORT} -j ACCEPT" /etc/sysconfig/iptables"
echo "          sed -i "11a-A INPUT -s \${TMP_INIT_WEB_SERVICE_LOCAL_HOST} -p udp -m state --state NEW -m udp --dport ${TMP_WEB_SERVICE_HOST_PORT} -j ACCEPT" /etc/sysconfig/iptables"
echo "          systemctl restart iptables.service"
echo "firewall-cmd："
echo "              firewall-cmd --permanent --add-port=${TMP_WEB_SERVICE_HOST_PORT}/tcp"
echo "              firewall-cmd --permanent --add-port=${TMP_WEB_SERVICE_HOST_PORT}/udp"
echo "              firewall-cmd --reload"
echo "${TMP_SPLITER}"
EOF
    echo ${TMP_SPLITER}
	echo
	
	chmod +x ${WWW_INIT_DIR}/*.sh

	return $?
}

#新增一个授权端口
#参数1：需放开端口
#参数2：授权IP
#参数3：ALL/TCP/UDP
function echo_soft_port()
{
	local TMP_ECHO_SOFT_PORT=${1}
	local TMP_ECHO_SOFT_PORT_IP=${2}
	local TMP_ECHO_SOFT_PORT_TYPE=${3}

	# 非VmWare产品的情况下，不安装iptables，给个假iptables文件
	if [ "${SYSTEMD_DETECT_VIRT}" != "vmware" ]; then	
		if [ ! -f "/etc/sysconfig/iptables" ]; then
			cat >/etc/sysconfig/iptables<<EOF
# sample configuration for iptables service
# you can edit this manually or use system-config-firewall
# please do not ask us to add additional ports/services to this default configuration
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
# [[[[[[[[[[[A EMPTY FILE]]]]]]]]]]

# [[[[[[[[[[[A EMPTY FILE]]]]]]]]]]
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
EOF
		fi
	else
		if [ ! -f "/etc/sysconfig/iptables" ]; then
			soft_yum_check_setup "iptables-services"
		fi
	fi

	# 判断是否加端口类型
	local TMP_ECHO_SOFT_PORT_GREP_TYPE="-p ${TMP_ECHO_SOFT_PORT_TYPE}"

	#cat /etc/sysconfig/iptables | grep "\-A INPUT -p" | awk -F' ' '{print $(NF-2)}' | awk '{for (i=1;i<=NF;i++) {if ($i=="801") {print i}}}'
	local TMP_QUERY_IPTABLES_EXISTS="cat /etc/sysconfig/iptables | grep \"\-A INPUT ${TMP_ECHO_SOFT_PORT_GREP_TYPE}\" | grep \"\-\-dport ${TMP_ECHO_SOFT_PORT}\""

	if [ -n "$TMP_ECHO_SOFT_PORT_IP" ]; then
		TMP_ECHO_SOFT_PORT_IP="-s $TMP_ECHO_SOFT_PORT_IP "
		TMP_QUERY_IPTABLES_EXISTS="${TMP_QUERY_IPTABLES_EXISTS} | grep '\\${TMP_ECHO_SOFT_PORT_IP}'"
	fi

	local TMP_QUERY_IPTABLES_EXISTS_RESULT=$(eval ${TMP_QUERY_IPTABLES_EXISTS})
	if [ -n "${TMP_QUERY_IPTABLES_EXISTS_RESULT}" ]; then
		echo -e "Port ${TMP_ECHO_SOFT_PORT} for '${TMP_ECHO_SOFT_PORT_IP:-"all"}' exists。\nGet data \"${red}${TMP_QUERY_IPTABLES_EXISTS_RESULT}${reset}\""
		return $?
	fi
	
	# firewall-cmd --zone=public --add-port=80/tcp --permanent  # nginx 端口
	# firewall-cmd --zone=public --add-port=2222/tcp --permanent  # 用户SSH登录端口 coco
	sed -i "11a-A INPUT $TMP_ECHO_SOFT_PORT_IP-p tcp -m state --state NEW -m tcp --dport $TMP_ECHO_SOFT_PORT -j ACCEPT" /etc/sysconfig/iptables

	# firewall-cmd --reload  # 重新载入规则
	if [ "${SYSTEMD_DETECT_VIRT}" == "vmware" ]; then	
		service iptables restart
	fi

	# local TMP_FIREWALL_STATE=`firewall-cmd --state`
	
	# firewall-cmd --permanent --add-port=${TMP_ECHO_SOFT_PORT}/tcp
	# firewall-cmd --permanent --add-port=${TMP_ECHO_SOFT_PORT}/udp
	# firewall-cmd --reload

	sleep 2

	lsof -i:${TMP_ECHO_SOFT_PORT}

	return $?
}

#构建shadowsocks服务
#参数1：构建模式（默认自检）
function proxy_by_ss()
{
	local TMP_SHADOWSOCK_MODE="$1"

    #加载脚本
    source ${__DIR}/scripts/tools/shadowsocks.sh

	# 判断境外网络，决定为客户端或服务端
    echo "---------------------------------------------------------------------"
    echo "Shadowsocks: System start check your internet to switch your run mode"
    echo "---------------------------------------------------------------------"
	local TMP_IS_WANT_CROSS_FIREWALL=`curl -I -m 10 -o /dev/null -s -w %{http_code} https://www.facebook.com`
    echo "Shadowsocks: The remote returns '$TMP_IS_WANT_CROSS_FIREWALL'"
    echo "---------------------------------------------------------------------"

    # 选择启动模式
    # exec_if_choice "TMP_SHADOWSOCK_MODE" "Please choice your shadowsocks run mode on this computer" "Server,Client,Exit" "${TMP_SPLITER}" "boot_shadowsocks_"
	local TMP_SHADOWSOCK_MODE_NECESSARY_CHECK=""
	if [ "$TMP_IS_WANT_CROSS_FIREWALL" == "000" ]; then
		TMP_SHADOWSOCK_MODE_NECESSARY_CHECK="client"
    else
        if [ ${#all_proxy} -gt 0 ]; then
			TMP_SHADOWSOCK_MODE_NECESSARY_CHECK="client"
        else
			TMP_SHADOWSOCK_MODE_NECESSARY_CHECK="server"
        fi
	fi

	if [ ${#TMP_SHADOWSOCK_MODE} -eq 0 ] || [ "$TMP_SHADOWSOCK_MODE" == "$TMP_SHADOWSOCK_MODE_NECESSARY_CHECK" ]; then
		boot_shadowsocks_$TMP_SHADOWSOCK_MODE_NECESSARY_CHECK
	fi

	return $?
}

#---------- SYSTEM ---------- {
MAJOR_VERS=`grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | cut -d "." -f1`
LOCAL_TIME=`date +"%Y-%m-%d %H:%M:%S"`
#---------- SYSTEM ---------- }

#---------- HARDWARE ---------- { 
# 主机名称
SYS_NAME=`hostname`

# 系统产品名称
SYS_PRODUCT_NAME=`dmidecode -t system | grep "Product Name" | awk -F':' '{print $NF}' | awk '{sub("^ *","");sub(" *$","");print}'`

# 系统位数
CPU_ARCHITECTURE=`lscpu | awk NR==1 | awk -F' ' '{print $NF}'`

# 系统版本
OS_VERS=`cat /etc/redhat-release | awk -F'release' '{print $2}' | awk -F'.' '{print $1}' | awk -F' ' '{print $1}'`

# 处理器核心数
PROCESSOR_COUNT=`cat /proc/cpuinfo | grep "processor"| wc -l`

# 空闲内存数
MEMORY_FREE=`awk '($1 == "MemFree:"){print $2/1048576}' /proc/meminfo`

# GB -> BYTES
MEMORY_GB_FREE=${MEMORY_FREE%.*}

# 机器环境信息
SYSTEMD_DETECT_VIRT=`systemd-detect-virt`

# 本机IP
# NET_HOST=`ping -c 1 -t 1 enginx.net | grep 'PING' | awk '{print $3}' | sed 's/[(,)]//g'`

# NR==1 第一行
LOCAL_IPV4="0.0.0.0"
get_ipv4 "LOCAL_IPV4"

LOCAL_IPV6="0:0:0:0:0:0:0:0"
get_ipv6 "LOCAL_IPV6"

# ip addr | grep "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*/[0-9]*.*brd" | awk '{print $2}' | awk -F'/' '{print $1}' | awk 'END {print}'
LOCAL_HOST="0.0.0.0"
get_iplocal "LOCAL_HOST"

# 城市代码
COUNTRY_CODE="CN"
get_country_code "COUNTRY_CODE"

LOCAL_ID=`echo \${LOCAL_HOST##*.}`

SYS_IP_CONNECT=`echo ${LOCAL_HOST} | sed 's@\.@-@g' | xargs -I {} echo "{}"`
SYS_NEW_NAME="ip-${SYS_IP_CONNECT}"

SYS_DOMAIN=
bind_sysdomain "SYS_DOMAIN"
#---------- HARDWARE ---------- }