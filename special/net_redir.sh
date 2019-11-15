#!/bin/sh
####################################################################################
# Net redir.
# Clash：
#       net_redir clash start 7892 `cat ~/.config/clash/config.yaml | grep "server:" | awk '{print $2}' | grep -v "^$" | sed ':a;N;$!ba;s/\n/,/g'`
#       net_redir "${rule_name}" "start" ${tmp_redir_port} "1.1.1.1,2.2.2.2,3.3.3.3,x.x.x.x"
# 其它NAT转发规则参考：
# https://blog.csdn.net/zhouguoqionghai/article/details/81947603
#-A INPUT -j REJECT --reject-with icmp-host-prohibited         //这两行最好是注释掉。在一般的白名单设置中，如果这两行不注释，也会造成iptables对端口的设置无效
#-A FORWARD -j REJECT --reject-with icmp-host-prohibited
#
#sysctl -w net.ipv4.ip_forward=1
# tcpdump -i eth0 port 11020 or 80 -w result.cap.
####################################################################################

set -o pipefail
set -o errexit
set -o nounset
#set -o xtrace

# 启动
function start () {
    # 接受变量
    local tmp_redir_port="${1:-}"
    local tmp_ignore_hosts="${2:-}"

    # 找寻应用的根目录
    local program_path=`which ${program_lower_name}`
    local program_check=`echo "${program_path}" | grep "no ${program_lower_name} in"`

    # 进程不存在直接退出（找不到会自动提示错误）
    if [ -n "${program_check:-}" ]; then
    	exit 3
    fi

    # 启动 Clash
    local log_dir="/logs/${program_lower_name}"
    local log_path="${log_dir}/running.log"
    if [ ! -d ${log_dir} ]; then
        mkdir -pv ${log_dir}
    fi

    ${program_path} > ${log_path} 2>&1 &
    
    sleep 3
    
    # 设置 iptables
    iptables -t nat -N ${program_upper_name}

    # 发往 ${program_name} 服务器端口的数据不走代理，否则陷入死循环
    # iptables -t nat -A ${program_upper_name} -p tcp --dport ${tmp_redir_port} -j RETURN
    
    # 发往 ${program_name} 服务器的数据不走代理，否则陷入死循环
    local tmp_return_host_arr=()
    IFS=',' read -r -a tmp_return_host_arr <<< "${tmp_ignore_hosts}"
    for return_host in "${tmp_return_host_arr[@]:-}"; do
        iptables -t nat -A ${program_upper_name} -d ${return_host} -j RETURN
    done
        
    # 保留地址、私有地址、回环地址 不走代理
    iptables -t nat -A ${program_upper_name} -d 0/8 -j RETURN
    iptables -t nat -A ${program_upper_name} -d 10/8 -j RETURN
    iptables -t nat -A ${program_upper_name} -d 127/8 -j RETURN
    iptables -t nat -A ${program_upper_name} -d 172.16/12 -j RETURN
    iptables -t nat -A ${program_upper_name} -d 172.20/12 -j RETURN
    iptables -t nat -A ${program_upper_name} -d 172.30/12 -j RETURN
    iptables -t nat -A ${program_upper_name} -d 192.168/16 -j RETURN
    iptables -t nat -A ${program_upper_name} -d 224/4 -j RETURN
    iptables -t nat -A ${program_upper_name} -d 240/4 -j RETURN
    
    # 7892是clash_redir端口
    iptables -t nat -A ${program_upper_name} -p tcp -j REDIRECT --to-ports ${tmp_redir_port}
    iptables -t nat -A ${program_upper_name} -p udp -j REDIRECT --to-ports ${tmp_redir_port}
    
    # OUTPUT链添加一条规则，重定向至REDIR链
    iptables -t nat -I OUTPUT -p tcp -j ${program_upper_name}
    iptables -t nat -I OUTPUT -p udp -j ${program_upper_name}
    iptables -t nat -I PREROUTING -p tcp -j ${program_upper_name}
    iptables -t nat -I PREROUTING -p udp -j ${program_upper_name}

    screen tail -f ${log_path}

    # 最后显示设置
    iptables -t nat -nvL
}

# 停止
function stop () {
    # 清除 iptables
    {
        iptables -t nat -F ${program_upper_name}
    	iptables -t nat -D PREROUTING -p tcp -j ${program_upper_name}
    	iptables -t nat -D PREROUTING -p udp -j ${program_upper_name}
    	iptables -t nat -X ${program_upper_name}
    	iptables -t nat -Z ${program_upper_name}

        echo

	    # 关闭 Clash
	    kill -9 `pidof ${program_lower_name} | sed "s/$//g"` 2>/dev/null
    } || {
        echo
    }

    # 输出
    echo "${program_lower_name} killed."    
}

# 重启
function restart() {
    stop
    sleep 2
    start
}

# 执行
function exec_program() {
    # 接受变量
    local tmp_program_name="${1:-}"

    # 定义全局变量
    declare -a program_lower_name
    declare -a program_upper_name

    program_lower_name=`echo ${tmp_program_name} | tr '[A-Z]' '[a-z]'`
    program_upper_name=`echo ${tmp_program_name} | tr '[a-z]' '[A-Z]'`

    # 移除第一位选择器
    shift

    # 调用执行类型
    ${@}
}

# 鉴别脚本所需参数的正确性
function init_params() {
    # for must input params
    if [ -z "${1:-}" -o -z "${2:-}" ]; then
        echo 'error: Missed required arguments.' > /dev/stderr
        echo 'note: Please follow this example:' > /dev/stderr
        echo '  $ net_redir "${program}" "start" "${redir-port}" "${ignore-list}". ' > /dev/stderr
        echo '  $ net_redir "${program}" "restart" "${redir-port}" "${ignore-list}". ' > /dev/stderr
        echo '  $ net_redir "${program}" "stop". ' > /dev/stderr
        
        exit 1
    fi

    if [ "${2:-}" != "stop" -a -z "${3:-}" ]; then
        echo 'error: Missed required arguments of "${redir-port}".' > /dev/stderr

        exit 2
    fi

    return $?
}

# 校验启动器 cat config.yml | grep "server:" | awk '{print $2}' | grep -v "^$"
function bootstrap() {
    # Set magic variables for current file & dir
    __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
    __conf="$(cd; pwd)"
    readonly __dir __file __conf

    cd ${__dir}

    init_params "${@}"
    exec_program "${@}"

    return $?
}

if [ "${BASH_SOURCE[0]:-}" != "${0}" ]; then
    export -f bootstrap
else
    bootstrap ${@}
    exit $?
fi