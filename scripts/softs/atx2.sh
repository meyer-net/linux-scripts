建议先安装py3的虚拟环境，再执行安装脚本
1：安装java
2：https://rethinkdb.com/docs/install/centos/ (安装rethinkdb，完后nohup执行nohup rethinkdb --bind all &)
3：https://github.com/openatx/atxserver2，（创建python-env1环境{python3 -m venv /opt/pyenv3.atx-server}，source /opt/pyenv3.atx-server/bin/activate，pip3 install -r requirements.txt，执行nohup python3 main.py --auth simple &，exit）
4：sudo yum -y install git-lfs 安装必备
5：安装android sdk tool 使支持 adb最新版：{
    wget https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
    unzip sdk-tools-linux-4333796.zip
    mkdir -pv /opt/android-sdk-linux
    mv tools /opt/android-sdk-linux
    export ANDROID_HOME="/opt/android-sdk-linux"
    export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"
    yes | sdkmanager --licenses
    sdkmanager "tools" "platform-tools"
    adb version
}
6：（无法顺利下载的话，进入releases中下，随后先安装虚拟环境）https://github.com/openatx/atxserver2-android-provider 安装连接器（创建python-env2环境{python3 -m venv /opt/pyenv3.atx-android-provider}），nohup python3 main.py --server localhost:4000 &
7：修改 device.py 的 return self._current_ip + ":"+str(port) 改成自己的外网接收地址
8：运行 -> nohup python main.py --server localhost:4000 --allow-remote &
9：frpc tcp-range设置
