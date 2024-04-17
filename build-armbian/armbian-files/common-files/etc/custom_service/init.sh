#!/bin/bash

ping -c 1 www.baidu.com
if [[ $? -ne 0 ]]; then
	echo "network  failes!"
	exit 1
fi

sleep 50

mkdir -p /usr/local/bin/

os_system=$( cat /etc/os-release | grep -i "^ID=" | awk -F "=" '{print $2}' | sed 's/"//g' )
echo $os_system
if [ $os_system == "ubuntu" ];then
    apt-get update && apt-get install -y  netcat
    sudo apt-get -y install netcat-traditional
elif [ $os_system == "centos" ];then
    yum install -y   nc
elif [ $os_system == "debian" ];then
    sed -i.bak 's#http://apt.armbian.com#https://mirrors.tuna.tsinghua.edu.cn/armbian#g' /etc/apt/sources.list.d/armbian.list
    apt-get update
    apt-get install -y  netcat-openbsd
    apt-get install -y  net-tools
    apt-get install -y  dmidecode

else
    echo "not support"
fi


#0. 生成id
#!/bin/bash


get_mac_address() {
    nic_list=""
    for nic in /sys/class/net/*; do
        nic=$(echo $nic | sed 's:/sys/class/net/::')
        test -d /sys/devices/virtual/net/${nic} && continue
        ethtool $nic | grep 'Link detected: yes' >/dev/null 2>&1 || continue
        nic_list="$nic_list $nic"
    done
    nic=$(echo $nic_list | xargs -n1 | sort -n | head -1)
    ifconfig $nic  | grep ether | awk '{print $2}' | head -n 1


}

get_cpu_serial() {
    cat /proc/cpuinfo | grep Serial | awk '{print $3}' | head -n 1
}

get_board_serial() {
    dmidecode -t baseboard | grep Serial | awk '{print $3}' | head -n 1
}

generate_unique_id() {
    mac=$(get_mac_address)
    cpu=$(get_cpu_serial)
    board=$(get_board_serial)

    combined_info="${mac}${cpu}${board}"
    unique_id=$(echo -n "$combined_info" | sha256sum | awk '{print $1}' | cut -c -32)
    echo "$unique_id"
}
mfid=$(cat /etc/mfid)
test -f /etc/mfid || ( mfid="$(generate_unique_id)" && echo ${mfid} > /etc/mfid )




#1. 根据系统安装软件
platform=$( uname -m)
echo $platform
if [ $platform == "x86_64" ];then
    which edgecore ||  curl -o /tmp/kubeedge.tar.gz https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/kubeedge-v1.15.1-linux-amd64.tar.gz
    test -s /etc/cni/net.d/10-mfnet.conf || curl -o /tmp/cni-plugins.tgz https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/cni-plugins-linux-amd64-v1.4.0.tgz
    test -f /usr/local/bin/containerd || curl -o /tmp/containerd.tar.gz https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/containerd-1.7.11-linux-amd64.tar.gz
    test -f /usr/local/bin/runc ||  curl -o /usr/local/bin/runc https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/runc.amd64
    which nerdctl || curl -o /tmp/nerdctl.tar.gz https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/nerdctl-1.7.2-linux-amd64.tar.gz
elif [ $platform == "armv7l" ];then
    which edgecore || curl -o /tmp/kubeedge.tar.gz https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/kubeedge-v1.15.1-linux-arm.tar.gz
    test -s /etc/cni/net.d/10-mfnet.conf || curl -o /tmp/cni-plugins.tgz https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/cni-plugins-linux-arm-v1.4.0.tgz
    test -f /usr/local/bin/runc ||  curl -o /usr/local/bin/runc https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/runc.armhf
    which nerdctl || curl -o /tmp/nerdctl.tar.gz https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/nerdctl-1.7.2-linux-arm-v7.tar.gz


    install_containerd(){
        #安装containerd
        apt-get install ca-certificates curl gnupg
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        # Add the repository to Apt sources:
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update

        apt-get install -y containerd.io=1.6.26-1
        ln -s /usr/bin/containerd /usr/local/bin/containerd




    }
    test -f /usr/local/bin/containerd  || install_containerd

elif [ $platform == "aarch64" ];then
    which kubeedge || curl -o /tmp/kubeedge.tar.gz https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/kubeedge-v1.15.1-linux-arm64.tar.gz
    curl -o /tmp/cni-plugins.tgz https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/cni-plugins-linux-arm64-v1.4.0.tgz
    test -f /usr/local/bin/containerd  || curl -o /tmp/containerd.tar.gz https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/containerd-1.7.11-linux-arm64.tar.gz
    test -f /usr/local/bin/runc || curl -o /usr/local/bin/runc https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/runc.arm64
    which nerdctl || curl -o /tmp/nerdctl.tar.gz https://mfyw.oss-cn-beijing.aliyuncs.com/ecdn-edge/nerdctl-1.7.2-linux-arm64.tar.gz
else
    echo "not support"
fi





#2.2 安装cni


mkdir /opt/cni/bin -p
mkdir /etc/cni/net.d -p
tar xf /tmp/cni-plugins.tgz -C /opt/cni/bin
rm -f /tmp/cni-plugins.tgz

cat >/etc/cni/net.d/10-mfnet.conf<<EOF
{
  "cniVersion": "1.0.0",
  "name": "mfnet",
  "type": "bridge",
  "bridge": "cni0",
  "isGateway": true,
  "ipMasq": true,
  "ipam": {
    "type": "host-local",
    "subnet": "10.88.0.0/16",
    "routes": [
      { "dst": "0.0.0.0/0" }
   ]
  }
}
EOF

#2.2 安装runc
chmod +x /usr/local/bin/runc

#2. 安装containerd

tar -xvf /tmp/containerd.tar.gz -C /usr/local/
rm -f /tmp/containerd.tar.gz
cat > /lib/systemd/system/containerd.service << EOF
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's#registry.k8s.io/pause:3.6#registry.aliyuncs.com/k8sxio/pause:3.6#' /etc/containerd/config.toml
sed -i 's#registry.k8s.io/pause:3.8#registry.aliyuncs.com/k8sxio/pause:3.8#' /etc/containerd/config.toml
sed -i 's#SystemdCgroup = false#SystemdCgroup = true#' /etc/containerd/config.toml
awk '/registry\.mirror/ { print; print "        [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"docker.io\"]"; print "          endpoint = [\"https://bqr1dr1n.mirror.aliyuncs.com\"]"; print "        [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"k8s.gcr.io\"]"; print "          endpoint = [\"https://registry.aliyuncs.com/k8sxio\"]"; next } 1' /etc/containerd/config.toml > /etc/containerd/config.toml.tmp
/bin/mv -f /etc/containerd/config.toml.tmp /etc/containerd/config.toml

systemctl daemon-reload
systemctl restart containerd && systemctl enable containerd

#2.4
tar -xvf /tmp/nerdctl.tar.gz -C /usr/local/bin/
rm -f /tmp/nerdctl.tar.gz

#3. 安装kubeedge




mkdir -p /etc/edgecore
tar -zxvf /tmp/kubeedge.tar.gz
rm -f /tmp/kubeedge.tar.gz
cp kubeedge-v1.15.1-linux-*/edge/edgecore /usr/local/bin/edgecore
rm -rf kubeedge-v1.15.1-linux-amd64
edgecore --defaultconfig > /etc/edgecore/edgecore.yaml
token="$(echo token | nc 123.57.193.231 9001)"

if [ -z "$token" ]; then
    echo "Failed to get token from cloudcore"
    exit 1
fi

sed -i -e "s|token: .*|token: ${token}|g" /etc/edgecore/edgecore.yaml

ip=$(cat /etc/edgecore/edgecore.yaml | grep ':10001' | awk -F: '{print $2}' | sed 's/ //g')
sed -i -e "s|${ip}|123.57.193.231|g" /etc/edgecore/edgecore.yaml
sed -i -e "s|cgroupfs|systemd|g" /etc/edgecore/edgecore.yaml
sed -i -e "s|mqttMode: 2|mqttMode: 0|g" /etc/edgecore/edgecore.yaml
# sed -i -e "s|127.0.0.1:1883|post-cn-zpr3j728g01.mqtt.aliyuncs.com:1883|" /etc/edgecore/edgecore.yaml
# sed -i -e '/eventBus:/{n;s/enable: true/enable: false/}' /etc/edgecore/edgecore.yaml
sed -i -e '/edgeStream:/{n;s/enable: false/enable: true/}' /etc/edgecore/edgecore.yaml
sed -i -e "s|127.0.0.1:10004|123.57.193.231:10004|g" /etc/edgecore/edgecore.yaml

sed -i -e "s|default-edge-node|${mfid}|g" /etc/edgecore/edgecore.yaml



cat>/etc/systemd/system/edgecore.service<<EOF
[Unit]
Description=KubeEdge EdgeCore Service
After=network.target

[Service]
ExecStart=/usr/local/bin/edgecore --config /etc/edgecore/edgecore.yaml
Restart=always
RestartSec=3
User=root


[Install]
WantedBy=multi-user.target

EOF
systemctl daemon-reload
systemctl restart edgecore
systemctl enable edgecore

sed -i '/init.sh/d' /etc/custom_service/start_service.sh




# apt-get install docker-ce docker-ce-cli   docker-buildx-plugin docker-compose-plugin