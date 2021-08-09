#!/bin/sh
####################################################################################
# Init ~/.svn-packrc config for svn-packager.
####################################################################################

# 检测根目录
SVN_PACKAGE_CHECK_LOCAL_ROOT_DIR="${PRJ_DIR}"
SVN_PACKAGE_IGNORE_FILES="\\.svn|\\.yml|\\.xml|\\.txt|\\.conf|\\.properties|\\.log|\\.zip|\\.out|\\.sh|\\.sql"
SVN_PACKAGE_CONFIG_PATH="~/.svn-packrc"

function check_config()
{
    convert_path "SVN_PACKAGE_CONFIG_PATH"
    local SVN_PACKAGE_CONFIG_DIR=`dirname $SVN_PACKAGE_CONFIG_PATH`
    path_not_exits_create "${SVN_PACKAGE_CONFIG_DIR}"
    path_not_exists_action "${SVN_PACKAGE_CONFIG_PATH}" "fill_config"
    
    #路径转换
    cat special/svn_packager_exec.sh > /usr/bin/svn_packager && chmod +x /usr/bin/svn_packager
}

function fill_config()
{
    input_if_empty "SVN_PACKAGE_CHECK_LOCAL_ROOT_DIR" "SvnPackager: Please ender ${red}local check root path${reset} of local repository"
    input_if_empty "SVN_PACKAGE_IGNORE_FILES" "SvnPackager: Please ender ${red}ignore files${reset} of local repository"

    echo "SVN_PACKAGE_CHECK_LOCAL_ROOT_DIR=\"$SVN_PACKAGE_CHECK_LOCAL_ROOT_DIR\"" >> $SVN_PACKAGE_CONFIG_PATH
    echo "SVN_PACKAGE_IGNORE_FILES=\"$SVN_PACKAGE_IGNORE_FILES\"" >> $SVN_PACKAGE_CONFIG_PATH

    config_slack $SVN_PACKAGE_CONFIG_PATH
}

check_config
svn_packager