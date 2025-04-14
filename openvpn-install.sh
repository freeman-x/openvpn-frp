#!/bin/bash
set -e

CLIENT_NAME="${OPENVPN_CLIENT_NAME:-user1}"
OVPN_SCRIPT_URL="https://raw.githubusercontent.com/Nyr/openvpn-install/master/openvpn-install.sh"
STATUS_LOG="${STATUS_LOG:-/var/log/openvpn/status.log}"

echo "🟡 更新系统（跳过 sudo）..."
apt update && apt install -y curl iptables iptables-persistent

echo "🟡 下载 OpenVPN 安装脚本..."
curl -sO "$OVPN_SCRIPT_URL"
chmod +x openvpn-install.sh

echo "🟢 自动安装 OpenVPN..."
AUTO_INSTALL=y ./openvpn-install.sh <<EOF
1
1194
1
$CLIENT_NAME
EOF

echo "🛠️ 修改 OpenVPN 配置启用状态日志..."
sed -i "/^status/d" /etc/openvpn/server.conf
sed -i "/^status-version/d" /etc/openvpn/server.conf
echo "status $STATUS_LOG" >> /etc/openvpn/server.conf
echo "status-version 2" >> /etc/openvpn/server.conf

echo "✅ 安装完成，配置完成！"
