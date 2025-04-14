#!/bin/bash

# 如果第一次启动容器，执行 openvpn 安装（可自动化）
if [ ! -f /etc/openvpn/server.conf ]; then
    /opt/openvpn-install.sh <<EOF
1
1194
1
client
EOF
fi

# 启动 OpenVPN 服务
echo "Starting OpenVPN..."
openvpn --config /etc/openvpn/server.conf &

# 启动 frpc
echo "Starting FRPC..."
frpc -c /etc/frpc.ini &

# 挂起保持容器运行
tail -f /dev/null
