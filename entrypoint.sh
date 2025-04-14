#!/bin/bash

# 默认环境变量
VPN_PORT=${VPN_PORT:-1194}
CLIENT_NAME=${VPN_CLIENT_NAME:-client}
PROTOCOL=${VPN_PROTOCOL:-udp}

# 首次运行：安装 OpenVPN
if [ ! -f /etc/openvpn/server.conf ]; then
    echo "🛠 正在运行 OpenVPN 安装脚本..."
    /opt/openvpn-install.sh <<EOF
1
${VPN_PORT}
1
${CLIENT_NAME}
EOF
fi

# 启动 OpenVPN 服务
echo "🚀 启动 OpenVPN 服务..."
openvpn --config /etc/openvpn/server.conf &

# 启动 frpc（新版 TOML 格式）
echo "🔌 启动 FRPC..."
/usr/local/frp/frpc -c /etc/frpc.toml &

# 保持容器运行
tail -f /dev/null
