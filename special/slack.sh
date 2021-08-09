#!/usr/bin/env bash
####################################################################################
# Init ~/.slackrc config for slack.
####################################################################################

#---------- DIR ---------- {
SLACK_CONFIG_PATH="~/.slackrc"
SLACK_CONFIG_SOURCE_PATH="${SLACK_CONFIG_PATH}"
#---------- DIR ---------- }

function check_config()
{
    convert_path "SLACK_CONFIG_PATH"

    path_not_exits_create `dirname ${SLACK_CONFIG_PATH}`
    path_not_exists_action "${SLACK_CONFIG_PATH}" "fill_config"

    #路径转换
    # sed -i "s@$SLACK_CONFIG_SOURCE_PATH@$SLACK_CONFIG_PATH@g" special/slack_exec.sh
    cat special/slack_exec.sh > /usr/bin/slack && chmod +x /usr/bin/slack

    source ${SLACK_CONFIG_PATH}
}

function fill_config()
{
    config_slack "${SLACK_CONFIG_PATH}"
}

# 配置slack
# 参数1：配置写入路径
function config_slack()
{
	local TMP_CONFIG_SLACK_ECHO_PATH=$1

    # 读取初始化值
    if [ -f "${SLACK_CONFIG_PATH}" ]; then
        set_if_empty "APP_SLACK_WEBHOOK" `cat ${SLACK_CONFIG_PATH} | grep "APP_SLACK_WEBHOOK" | awk -F'=' '{print $NF}'`
        set_if_empty "APP_SLACK_CHANNEL" `cat ${SLACK_CONFIG_PATH} | grep "APP_SLACK_CHANNEL" | awk -F'=' '{print $NF}'`
        set_if_empty "APP_SLACK_USERNAME" `cat ${SLACK_CONFIG_PATH} | grep "APP_SLACK_USERNAME" | awk -F'=' '{print $NF}'`
        set_if_empty "APP_SLACK_ICON_EMOJI" `cat ${SLACK_CONFIG_PATH} | grep "APP_SLACK_ICON_EMOJI" | awk -F'=' '{print $NF}'`
    fi

    # 设置指定值
    input_if_empty "APP_SLACK_WEBHOOK" "Slack: Please ender ${red}slack webhook${reset} of local environment"
    input_if_empty "APP_SLACK_CHANNEL" "Slack: Please ender ${red}slack channel${reset} of local environment"
    input_if_empty "APP_SLACK_USERNAME" "Slack: Please ender ${red}slack user${reset} of local environment"
    input_if_empty "APP_SLACK_ICON_EMOJI" "Slack: Please ender ${red}slack icon emoji${reset} of local environment"

    # 输出指定值
    echo "APP_SLACK_WEBHOOK=${APP_SLACK_WEBHOOK}" >> ${TMP_CONFIG_SLACK_ECHO_PATH}
    echo "APP_SLACK_CHANNEL=${APP_SLACK_CHANNEL}" >> ${TMP_CONFIG_SLACK_ECHO_PATH}
    echo "APP_SLACK_USERNAME=${APP_SLACK_USERNAME}" >> ${TMP_CONFIG_SLACK_ECHO_PATH}
    echo "APP_SLACK_ICON_EMOJI=${APP_SLACK_ICON_EMOJI}" >> ${TMP_CONFIG_SLACK_ECHO_PATH}

	return $?
}

check_config