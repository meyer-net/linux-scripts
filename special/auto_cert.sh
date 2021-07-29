#!/bin/sh
####################################################################################
# Init ~/.auto-certrc config for auto-cert.
####################################################################################

# 检测根目录
AUTO_CERT_LOCAL_ROOT_DIR=`find / -name acme-v02.api.letsencrypt.org-directory | grep certificates`

CERT_CHECKER_CONFIG_PATH="~/.cert-checkerrc"
AUTO_CERT_CONFIG_PATH="~/.auto-certrc"

function check_config()
{
    convert_path "CERT_CHECKER_CONFIG_PATH"
    path_not_exits_create `dirname ${CERT_CHECKER_CONFIG_PATH}`

    convert_path "AUTO_CERT_CONFIG_PATH"
    path_not_exits_create `dirname ${AUTO_CERT_CONFIG_PATH}`
    path_not_exits_action "${AUTO_CERT_CONFIG_PATH}" "fill_config"
    
    #路径转换
    cat special/cert_checker_exec.sh > /usr/bin/cert_checker && chmod +x /usr/bin/cert_checker
    cat special/auto_cert_exec.sh > /usr/bin/auto_cert && chmod +x /usr/bin/auto_cert
}

function fill_config()
{
    input_if_empty "AUTO_CERT_LOCAL_ROOT_DIR" "AutoCert: Please ender ${red}local path which your certs root storaged${reset} like caddy"
    input_if_empty "AUTO_CERT_IGNORE_DOMAINS" "AutoCert: Please ender ${red}ignoret domain split by ','${reset}"

    echo "AUTO_CERT_LOCAL_ROOT_DIR=\"${AUTO_CERT_LOCAL_ROOT_DIR}\"" >> ${AUTO_CERT_CONFIG_PATH}
    echo "AUTO_CERT_IGNORE_DOMAINS=\"${AUTO_CERT_IGNORE_DOMAINS}\"" >> ${AUTO_CERT_CONFIG_PATH}


    # 每分钟执行1次
    echo "* * * * * auto_cert \"1min\" >> ${CRTB_LOGS_DIR}/auto-cert-1min.log 2>&1" >> /var/spool/cron/root
    # 每天凌晨执行1次
    echo "0 0 * * * auto_cert \"1day\" >> ${CRTB_LOGS_DIR}/auto-cert-1day.log 2>&1" >> /var/spool/cron/root
    # 每周日凌晨执行1次
    echo "0 0 * * sun auto_cert \"1week\" >> ${CRTB_LOGS_DIR}/auto-cert-1week.log 2>&1" >> /var/spool/cron/root

    crontab -l
    service crond restart

    config_slack ${CERT_CHECKER_CONFIG_PATH}
    config_slack ${AUTO_CERT_CONFIG_PATH}
}

check_config
auto_cert