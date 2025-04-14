#!/bin/bash
set -e

# ========== 环境变量初始化 ==========
OVPN_SERVER=${OVPN_SERVER:-vpn.example.com}
OVPN_PROTOCOL=${OVPN_PROTOCOL:-udp}
OVPN_PORT=${OVPN_PORT:-1194}
OVPN_DNS=${OVPN_DNS:-1.1.1.1}
OVPN_USER=${OVPN_USER:-freemanxyz}

USE_FRPC=${USE_FRPC:-false}
FRPS_SERVER=${FRPS_SERVER:-frps.example.com}
FRPS_PORT=${FRPS_PORT:-7000}
FRPS_TOKEN=${FRPS_TOKEN:-yourtoken}
FRPC_REMOTE_PORT=${FRPC_REMOTE_PORT:-6000}

ADMIN_USER=${ADMIN_USER:-admin}
ADMIN_PASS=${ADMIN_PASS:-admin123}

# ========== 安装并配置 OpenVPN ==========
echo "\n🛠 安装 OpenVPN..."
chmod +x /opt/openvpn-install.sh
AUTO_INSTALL=y \
OVPN_SERVER="$OVPN_SERVER" \
OVPN_PROTOCOL="$OVPN_PROTOCOL" \
OVPN_PORT="$OVPN_PORT" \
OVPN_DNS="$OVPN_DNS" \
OVPN_USER="$OVPN_USER" \
/opt/openvpn-install.sh

# 打开 OpenVPN 状态日志功能
if ! grep -q '^status' /etc/openvpn/server.conf; then
  echo "status /var/log/openvpn/status.log" >> /etc/openvpn/server.conf
  echo "status-version 2" >> /etc/openvpn/server.conf
fi

# 启动 OpenVPN
echo "\n🚀 启动 OpenVPN 服务..."
openvpn --config /etc/openvpn/server.conf &

# ========== 安装并启动 OpenVPN Admin Web UI ==========
echo "\n🖥 启动 OpenVPN Admin Web UI..."
nohup /opt/openvpn-admin-ui/openvpn-admin \
  --username $ADMIN_USER \
  --password $ADMIN_PASS \
  --conf /etc/openvpn/server.conf \
  --log /var/log/openvpn-admin.log \
  > /dev/null 2>&1 &
echo "🔐 OpenVPN Web UI 登录账号: $ADMIN_USER 密码: $ADMIN_PASS"

# ========== 判断是否启用 FRPC ==========
if [ "$USE_FRPC" = "true" ]; then
  echo "\n🔌 启动 FRPC..."
  mkdir -p /etc/frp
  cat <<EOF > /etc/frp/frpc.toml
serverAddr = "$FRPS_SERVER"
serverPort = $FRPS_PORT
token = "$FRPS_TOKEN"

[openvpn]
type = tcp
localIP = "127.0.0.1"
localPort = $OVPN_PORT
remotePort = $FRPC_REMOTE_PORT
EOF
  chmod +x /usr/local/frp/frpc
  /usr/local/frp/frpc -c /etc/frp/frpc.toml &
else
  echo "\nℹ️ 未启用 FRPC 功能"
fi

# ========== 每分钟打印 OpenVPN 状态 ==========
status_file="/var/log/openvpn/status.log"
while true; do
  if [ -f "$status_file" ]; then
    echo -e "\n============================="
    echo -e "🌐 当前 VPN 连接用户统计"
    user_count=$(grep -c '^CLIENT_LIST' "$status_file")
    echo "连接用户数: $user_count"
    grep '^CLIENT_LIST' "$status_file" | while IFS=',' read -r _ username real_ip vpn_ip conn_time _ rx tx _ _ duration; do
      up=$(awk "BEGIN {print int($tx / 1024 / 1024) \"M↓\"}")
      down=$(awk "BEGIN {print int($rx / 1024 / 1024) \"M↑\"}")
      echo "$username | $real_ip | $down | $up | ${duration}s"
    done
    echo "=============================\n"
  fi
  sleep 60
done
