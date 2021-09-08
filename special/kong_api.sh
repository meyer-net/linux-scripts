#!/bin/sh
####################################################################################
# Manual operate kongapi.
####################################################################################

# 检测根目录
KONG_ADMIN_LISTEN_HOST="127.0.0.1:8000"
TMP_CURRENT_RC_FILE_PATH="~/.kong-apirc"

function check_config()
{
    convert_path "TMP_CURRENT_RC_FILE_PATH"
    local TMP_RC_FILE_CONFIG_DIR=`dirname ${TMP_CURRENT_RC_FILE_PATH}`
    path_not_exists_create "${TMP_RC_FILE_CONFIG_DIR}"
    path_not_exists_action "${TMP_CURRENT_RC_FILE_PATH}" "fill_config"
    
    #路径转换
    cat special/kong_api_exec.sh > /usr/bin/kong_api && chmod +x /usr/bin/kong_api
}

function fill_config()
{
    input_if_empty "KONG_ADMIN_LISTEN_HOST" "KongApi: Please ender ${red}the admin listen host ${reset} of kong"

    echo "KONG_ADMIN_LISTEN_HOST=\"${KONG_ADMIN_LISTEN_HOST}\"" >> ${TMP_CURRENT_RC_FILE_PATH}
}

function boot_main()
{
    clear
    
    while [ 1 == 1 ]; do
	    clear
        echo "------------------------------------------------------------------------------------"
        typeset -u TMP_UPSTREAM_NAME
        local TMP_UPSTREAM_NAME=`cat /proc/sys/kernel/random/uuid`
        input_if_empty "TMP_UPSTREAM_NAME" "Kong: Please ender ${red}your upstream name${reset}"
            
        local TMP_KONG_UPSTREAM_TARGETS="127.0.0.1:8080"
        input_if_empty "TMP_KONG_UPSTREAM_TARGETS" "Kong: Please ender ${red}target host${reset} like '${red}www.baidu.com${reset}' or '${red}10.113.9.9${reset}' or array split by ',' of upstream '${red}$TMP_UPSTREAM_NAME${reset}'"

        local TMP_ROUTE_HOSTS_URL=""
        input_if_empty "TMP_ROUTE_HOSTS_URL" "Kong: Please ender ${red}your route host url${reset} or array split by ','"

        kong_api "upstream" "${TMP_UPSTREAM_NAME}" "${TMP_KONG_UPSTREAM_TARGETS}" "" "${TMP_ROUTE_HOSTS_URL}"

        echo -e " \n"
        echo "[*]Please sure you will input upstream by '${red}yes(y) or enter key/no(n)${reset}'"
        read -n 1 Y_N
        echo -e " \n"

        case $Y_N in
            "y" | "Y" | "")
            ;;
            *)
            break
        esac
        echo "------------------------------------------------------------------------------------"
    done

    return $?
}

check_config
boot_main