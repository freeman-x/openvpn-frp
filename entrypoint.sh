#!/bin/bash
set -e

# 🟡 配置 OpenVPN 安装
echo "🟡 配置 OpenVPN ..."
# 去掉 sudo，因为 Docker 容器已经是 root 用户
sed -i 's/sudo //g' /opt/openvpn-install.sh

# 检查 OpenVPN 配置文件是否存在，如果不存在则运行安装脚本
if [ ! -f /etc/openvpn/server.conf ]; then
  # 使用传入的环境变量设置 OpenVPN 配置
  bash /opt/openvpn-install.sh <<EOF
1
$OVPN_PROTOCOL      # 协议类型（如 udp, tcp）
$OVPN_PORT          # OpenVPN 服务端口
$OVPN_DNS           # 配置 DNS（如 1.1.1.1）
$OVPN_USER          # 初始用户（可选）
EOF
fi

# 🟢 启动 OpenVPN 服务
echo "🟢 启动 OpenVPN 服务..."
openvpn --config /etc/openvpn/server.conf &  # 后台启动 OpenVPN

# 🟡 配置 FRPC 客户端
echo "🟡 配置 FRPC 客户端..."
cat <<EOF > /etc/frp/frpc.toml
# FRPC 客户端配置
serverAddr = "$FRPS_SERVER"         # FRPS 服务器地址
serverPort = $FRPS_PORT             # FRPS 服务器端口
auth.token = "$FRPS_TOKEN"          # FRPS 认证 token

[openvpn]
type = tcp
localIP = "127.0.0.1"               # 本地 OpenVPN 地址
localPort = $OVPN_PORT              # 本地 OpenVPN 服务端口
remotePort = $FRPC_REMOTE_PORT      # 映射到 FRPS 服务器的远程端口
EOF

# 🟢 启动 FRPC 客户端
echo "🟢 启动 FRPC 客户端..."
chmod +x /usr/local/frp/frpc  # 确保 frpc 可执行
/usr/local/frp/frpc -c /etc/frp/frpc.toml  # 启动 FRPC 客户端，连接到 FRPS 服务器
