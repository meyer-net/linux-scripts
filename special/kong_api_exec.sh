#!/bin/sh
####################################################################################
# Consul operate kong_api.
####################################################################################

#配置RC文件
TMP_CURRENT_RC_FILE_NAME=".kong-apirc"

set -o pipefail
set -o errexit
set -o nounset
#set -o xtrace

#添加Kong-Upstream-Service-Route
#参数1：ServiceName
#post_routes "$tmp_service_name" "$tmp_router_hosts"
function post_routes()
{
    local tmp_service_name="${1:-}"
    local tmp_route_name="ROUTE.${tmp_service_name}"
    local tmp_router_hosts="${2:-}"

    if [ -n "${tmp_router_hosts}" ]; then
        local tmp_router_hosts_arr=()
        IFS=',' read -r -a tmp_router_hosts_arr <<< "${tmp_router_hosts}"

        tmp_router_hosts=""
        for router_host in "${tmp_router_hosts_arr[@]:-}"; do
            echo "KongApi.PostRoutes: S@$tmp_service_name R@$tmp_route_name H@$router_host"
            local post_param="-d \"hosts[]=${router_host}\"  \\"
            tmp_router_hosts="${tmp_router_hosts}"`echo -e "\n${post_param}"`
        done

        local request_code=`curl -o /dev/null -s -w %{http_code} -X POST http://$KONG_ADMIN_LISTEN_HOST/services/${tmp_service_name}/routes/  \
            -d "name=$tmp_route_name"  \
            -d "strip_path=false"  \
            -d "preserve_host=true"  \
            -d "paths[]=/"  \
            -d "protocols[]=http" \
            -d "protocols[]=https" \
            "${tmp_router_hosts}"`

        echo "KongApi.PostRoutes: Remote response '${request_code}'."
    fi

    return $?
}

#添加Kong-Upstream-Service
#参数1：UpstreamName
#调用：post_service "$tmp_service_name" "$tmp_upstream_name" "$tmp_router_hosts"
function post_service()
{
    local tmp_upstream_name="${2:-}"
    local tmp_service_name="SERVICE.${1:-${tmp_upstream_name}}"
    local tmp_router_hosts="${3:-}"
    
    if [ -n "${2:-}" ]; then
        echo "KongApi.PostService: U@$tmp_upstream_name S@$tmp_service_name"
        local request_code=`curl -o /dev/null -s -w %{http_code} -X POST http://$KONG_ADMIN_LISTEN_HOST/services/  \
            -d "name=${tmp_service_name}"  \
            -d "host=UPS-ITL-SERVICE.${tmp_upstream_name}"`

        if [ "${request_code::1}" != "2" ]; then
            echo "KongApi.PostService: Faild, remote response '${request_code}'."
            exit 9
        fi

        post_routes ${tmp_service_name} ${tmp_router_hosts}
    fi

    return $?
}

#添加Kong-Upstream-Target
#参数1：UpstreamName
#调用：post_targets "$tmp_upstream_name" "$tmp_upstream_target"
function post_targets() 
{
    local tmp_upstream_name="${1:-}"
    local tmp_upstream_targets="${2:-}"
    local tmp_upstream_targets_arr=()
    IFS=',' read -r -a tmp_upstream_targets_arr <<< "${tmp_upstream_targets}"

    for target in "${tmp_upstream_targets_arr[@]:-}"; do
        echo "KongApi.PostTargets: U@$tmp_upstream_name T@$target"
        local request_code=`curl -o /dev/null -s -w %{http_code} -X POST http://$KONG_ADMIN_LISTEN_HOST/upstreams/UPS-ITL-SERVICE.$tmp_upstream_name/targets  \
            --data "target=$target"  \
            --data "weight=10"`
    	echo "KongApi.PostTargets: Remote response '${request_code}'."
    done

	return $?
}

#添加Kong-Upstream-Target
#参数1：UpstreamName
#调用：post_upstream "$tmp_upstream_name" "$tmp_upstream_targets" "$tmp_service_name" "$tmp_router_host"
function post_upstream() 
{
    typeset -u tmp_upstream_name
    local tmp_upstream_name="${1:-}"
    local tmp_upstream_targets="${2:-}"
    local tmp_service_name="${3:-}"
    local tmp_router_hosts="${4:-}"

    echo "KongApi.PostUpstream: U@$tmp_upstream_name T@$tmp_upstream_targets S@$tmp_service_name H@$tmp_router_hosts"
    local request_code=`curl -o /dev/null -s -w %{http_code} -X POST http://$KONG_ADMIN_LISTEN_HOST/upstreams  \
        -d "name=UPS-ITL-SERVICE.$tmp_upstream_name"  \
        -d "slots=1000"  \
        -d "healthchecks.active.healthy.interval=30"  \
        -d "healthchecks.active.healthy.successes=1"  \
        -d "healthchecks.active.unhealthy.tcp_failures=10"  \
        -d "healthchecks.active.unhealthy.http_failures=10"  \
        -d "healthchecks.active.unhealthy.timeouts=5"  \
        -d "healthchecks.active.unhealthy.interval=3"  \
        -d "healthchecks.active.https_sni=localhost"  \
        -d "healthchecks.passive.unhealthy.tcp_failures=5"  \
        -d "healthchecks.passive.healthy.successes=1"`
        
    if [ "${request_code::1}" != "2" ]; then
    	echo "KongApi.PostUpstream: Faild, remote response '${request_code}'."
    	exit 9
    fi

    post_targets "$tmp_upstream_name" "${tmp_upstream_targets:-}"
    post_service "$tmp_service_name" "$tmp_upstream_name" "${tmp_router_hosts:-}"

	return $?
}

function exec_program()
{
    typeset -l tmp_api_type
    local tmp_api_type="${1:-}"

    # 移除第一位选择器
    shift

    # 调用执行类型
    post_$tmp_api_type "${@}"
}

#鉴别脚本所需参数的正确性
function init_params() {

    # must defined，you may declare ENV vars in /etc/profile.d/template.sh
    if [ -z "${KONG_ADMIN_LISTEN_HOST:-}" ]; then
        echo 'error: Please configure environment "KONG_ADMIN_LISTEN_HOST": ' > /dev/stderr
        echo '  KONG_ADMIN_LISTEN_HOST' > /dev/stderr
        exit 2
    fi

    # for must input params
    if [ -z "${1:-}" -o -z "${2:-}" ]; then
        echo 'error: Missed required arguments.' > /dev/stderr
        echo 'note: Please follow this example:' > /dev/stderr
        echo '  $ kong_api "api-type {upstream}(*)" "upstream name(*)" "target host&port(*)". ' > /dev/stderr
        echo '  $ kong_api "api-type {upstream}(*)" "upstream name(*)" "target host&port(*)" "service name(*?)" "router url". ' > /dev/stderr
        echo '  $ kong_api "api-type {service}(*)" "service name(*)" "target upstream name or host&port(*)" "router url". ' > /dev/stderr
        exit 3
    fi

    return $?
}

#校验启动器
function bootstrap() {
    # Set magic variables for current file & dir
    __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
    __conf="$(cd; pwd)"
    readonly __dir __file __conf

    cd ${__dir}

    if [ -f $(cd; pwd)/${TMP_CURRENT_RC_FILE_NAME} ]; then
        . $(cd; pwd)/${TMP_CURRENT_RC_FILE_NAME}
    fi

    init_params "${@}"
    exec_program "${@}"

    return $?
}

if [ "${BASH_SOURCE[0]:-}" != "${0}" ]; then
    export -f bootstrap
else
    bootstrap "${@}"
    exit $?
fi