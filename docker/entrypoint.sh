#!/bin/bash

set -e

echo "=== 🐧 OpenVPN + FRPC 容器启动中 ==="

#######################################
# 函数：启动 OpenVPN 并自动配置
#######################################
start_openvpn() {
  echo "🔧 正在初始化 OpenVPN 配置..."

  export AUTO_INSTALL=y
  export APPROVE_INSTALL=y
  export APPROVE_IP=${OVPN_SERVER:-$(curl -s ifconfig.me)}
  export APPROVE_PROTOCOL=${OVPN_PROTOCOL:-udp}
  export APPROVE_PORT=${OVPN_PORT:-1194}
  export DNS=${OVPN_DNS:-1.1.1.1}
  export CLIENT=${OVPN_USER:-freemanxyz}
  export ENDPOINT="${APPROVE_IP}"

  if [ ! -f "/etc/openvpn/server.conf" ]; then
    echo "📦 安装 OpenVPN..."
    /usr/local/bin/openvpn-install.sh
  else
    echo "✅ OpenVPN 已配置，跳过安装"
  fi

  echo "🚀 启动 OpenVPN 服务..."
  openvpn --config /etc/openvpn/server.conf > /var/log/openvpn/server.log 2>&1 &
}

#######################################
# 函数：启动 FRPC（如果启用）
#######################################
start_frpc() {
  if [[ "$INSTALL_FRPC" == "true" ]]; then
    echo "🔧 检测到 INSTALL_FRPC=true，正在生成 frpc 配置..."

    cat <<EOF > /etc/frp/frpc.toml
serverAddr = "${FRPS_SERVER}"
serverPort = ${FRPS_PORT}
auth.token = "${FRPS_TOKEN}"

[[proxies]]
name = "openvpn"
type = "tcp"
localIP = "127.0.0.1"
localPort = ${OVPN_PORT:-1194}
remotePort = ${FRPC_REMOTE_PORT}
EOF

    echo "🚀 启动 frpc ..."
    frpc -c /etc/frp/frpc.toml > /var/log/openvpn/frpc.log 2>&1 &
  else
    echo "🟡 未启用 frpc，跳过"
  fi
}

#######################################
# 函数：启动 Web UI（ovpn-admin）
#######################################
start_web_ui() {
  echo "🌐 启动 Web UI ovpn-admin..."

  export WEB_ADMIN_USER=${WEB_ADMIN_USER:-admin}
  export WEB_ADMIN_PASS=${WEB_ADMIN_PASS:-admin123}

  cd /opt/ovpn-admin

  # 创建配置文件
  cat <<EOF > config.json
{
  "Host": "0.0.0.0",
  "Port": 8080,
  "Log": "stdout",
  "DB": "/etc/openvpn/ovpn.db",
  "Users": {
    "${WEB_ADMIN_USER}": "${WEB_ADMIN_PASS}"
  },
  "OVConfigPath": "/etc/openvpn"
}
EOF

  ./ovpn-admin > /var/log/openvpn/webui.log 2>&1 &
}

#######################################
# 函数：打印连接状态
#######################################
monitor_status() {
  echo "📈 启动状态监控循环：每60秒打印一次连接状态"
  while true; do
    echo "🕒 $(date '+%Y-%m-%d %H:%M:%S') - 当前 OpenVPN 连接用户："
    if [ -f /etc/openvpn/openvpn-status.log ]; then
      grep -E '^CLIENT_LIST' /etc/openvpn/openvpn-status.log | awk -F',' '{print " - 用户: " $2 ", IP: " $3 ", 连接时间: " $8}'
    else
      echo "⚠️ 尚未生成 openvpn-status.log"
    fi
    echo "-------------------------------------------"
    sleep 60
  done
}

#######################################
# 启动顺序
#######################################
start_openvpn
start_frpc
start_web_ui
monitor_status
