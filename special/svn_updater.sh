#!/bin/sh
####################################################################################
# Init ~/.svn-updaterc config for svn-updater.
####################################################################################

# 检测根目录
SVN_UPDATE_LOCAL_ROOT_DIR="${PRJ_DIR}"
SVN_UPDATE_CONFIG_PATH="~/.svn-updaterc"

function check_config()
{
    convert_path "SVN_UPDATE_CONFIG_PATH"
    local SVN_UPDATE_CONFIG_DIR=`dirname $SVN_UPDATE_CONFIG_PATH`
    path_not_exits_action "$SVN_UPDATE_CONFIG_DIR" "mkdir -pv $SVN_UPDATE_CONFIG_DIR"
    path_not_exits_action "$SVN_UPDATE_CONFIG_PATH" "fill_config"
    
    #路径转换
    cat special/svn_updater_exec.sh > /usr/bin/svn_updater && chmod +x /usr/bin/svn_updater
}

function fill_config()
{
    input_if_empty "SVN_UPDATE_REMOTE_ROOT_URL" "SvnUpdater: Please ender ${red}the checkout or update svn root url${reset} of local repository"
    input_if_empty "SVN_USER" "SvnUpdater: Please ender ${red}svn username${reset} of local repository"
    input_if_empty "SVN_PASS" "SvnUpdater: Please ender ${red}svn password${reset} of local repository"
    input_if_empty "SVN_UPDATE_LOCAL_ROOT_DIR" "SvnUpdater: Please ender ${red}local path which you want to store${reset} of local repository"
    input_if_empty "SVN_UPDATE_IGNORE_DIRS" "SvnUpdater: Please ender ${red}ignore dirs split by ','${reset} of local repository"

    echo "SVN_UPDATE_REMOTE_ROOT_URL=\"$SVN_UPDATE_REMOTE_ROOT_URL\"" >> $SVN_UPDATE_CONFIG_PATH
    echo "SVN_USER=\"$SVN_USER\"" >> $SVN_UPDATE_CONFIG_PATH
    echo "SVN_PASS=\"$SVN_PASS\"" >> $SVN_UPDATE_CONFIG_PATH
    echo "SVN_UPDATE_LOCAL_ROOT_DIR=\"$SVN_UPDATE_LOCAL_ROOT_DIR\"" >> $SVN_UPDATE_CONFIG_PATH
    echo "SVN_UPDATE_IGNORE_DIRS=\"$SVN_UPDATE_IGNORE_DIRS\"" >> $SVN_UPDATE_CONFIG_PATH

    config_slack $SVN_UPDATE_CONFIG_PATH
}

check_config
svn_updater