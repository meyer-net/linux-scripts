#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------

# 1-配置环境
function set_environment()
{
    soft_yum_check_setup "gcc,libpng,libjpeg,libpng-devel,libjpeg-devel,ghostscript,libtiff,libtiff-devel,freetype,freetype-devel"

	return $?
}

# 2-安装软件
function setup_graphics_magick()
{
	local TMP_GRAPHICS_MAGICK_SETUP_DIR=${1}
	local TMP_GRAPHICS_MAGICK_CURRENT_DIR=`pwd`

	# 编译模式
	./configure --prefix=${TMP_GRAPHICS_MAGICK_SETUP_DIR} --with-quantum-depth=8 --enable-shared --enable-static
	sudo make -j4 && make -j4 install

	# 环境变量或软连接
	echo "GMAGICK_HOME=${TMP_GRAPHICS_MAGICK_SETUP_DIR}" >> /etc/profile
	echo 'LD_LIBRARY_PATH=$GMAGICK_HOME/lib:$LD_LIBRARY_PATH' >> /etc/profile
	echo 'PATH=$GMAGICK_HOME/bin:$PATH' >> /etc/profile
	echo "export PATH GMAGICK_HOME LD_LIBRARY_PATH" >> /etc/profile
	source /etc/profile
    
	ln -sf ${TMP_TL_GM_SETUP_DIR}/bin/graphicsmagick /usr/bin/graphicsmagick

	# 移除源文件
	rm -rf ${TMP_GRAPHICS_MAGICK_CURRENT_DIR}

	return $?
}

# 3-设置软件
function conf_graphics_magick()
{
	cd ${1}

	return $?
}

# 4-启动软件
function boot_graphics_magick()
{
	local TMP_TL_GM_SETUP_DIR=${1}

	cd ${TMP_TL_GM_SETUP_DIR}

    # 验证安装
    gm version

    # echo_startup_config "graphics_magick" "${TMP_TL_GM_SETUP_DIR}" "bin/graphics_magick" "" "100"

	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_graphics_magick()
{
	local TMP_TL_GM_SETUP_DIR=${1}
    
	set_environment "${TMP_TL_GM_SETUP_DIR}"

	setup_graphics_magick "${TMP_TL_GM_SETUP_DIR}"

	conf_graphics_magick "${TMP_TL_GM_SETUP_DIR}"

	boot_graphics_magick "${TMP_TL_GM_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_graphics_magick()
{
	local TMP_TL_GM_SETUP_NEWER="ftp://ftp.graphicsmagick.org/pub/GraphicsMagick/GraphicsMagick-LATEST.tar.gz"
    setup_soft_wget "graphicsmagick" "${TMP_TL_GM_SETUP_NEWER}" "exec_step_graphics_magick"

	return $?
}

#安装主体
setup_soft_basic "GraphicsMagick" "down_graphics_magick"
