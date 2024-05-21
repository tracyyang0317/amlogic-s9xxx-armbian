#!/bin/sh

chmod +x /etc/custom_service/arm_linux_agent
chmod +x /etc/custom_service/arm_linux_client
chmod +x /etc/custom_service/start_agent.sh
cgmod +x /etc/custom_service/arm_linux_agent.service

cp -rf /etc/custom_service/arm_linux_agent.service       /usr/lib/systemd/system/
ln -s  /usr/lib/systemd/system/arm_linux_agent.service   /etc/systemd/system/multi-user.target.wants/arm_linux_agent.service

while true
do
    ping mfyw.oss-cn-beijing.aliyuncs.com -c 5 -W 1
    if [ $? -eq 0 ]; then
    	echo "network ok"
    	break
    fi
    sleep 10
done

apt update
apt install python3-pip -y
pip install pillow qrcode -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install qrcode-terminal -i https://pypi.tuna.tsinghua.edu.cn/simple

cd /tmp/ || exit
curl -k -m 5 --retry 3 -o boxinstall.sh https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/boxinstall.sh && chmod 755 boxinstall.sh && ./boxinstall.sh > /tmp/boxinstall.log
sed -i '/init.sh/d' /etc/custom_service/start_service.sh