#!/bin/bash

set -e  # 遇到错误立即退出

# ========= 基础变量 =========
OVPN_DATA_DIR="/etc/openvpn"
FRPC_CONFIG="/etc/frp/frpc.toml"
PRINT_STATUS_SCRIPT="/usr/local/bin/print-status.sh"
WEB_UI_DIR="/opt/ovpn-admin"
WEB_UI_PORT=${WEB_UI_PORT:-8080}

# ========= 日志函数 =========
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# ========= 初始化 OpenVPN =========
init_openvpn() {
  log "🟡 开始配置 OpenVPN..."

  # 检查配置是否存在（首次初始化才执行）
  if [ ! -f "${OVPN_DATA_DIR}/server.conf" ]; then
    log "🔧 运行安装器初始化 OpenVPN..."

    # 运行自动安装脚本，注入环境变量
    OVPN_SERVER=${OVPN_SERVER:-"127.0.0.1"}
    OVPN_PROTOCOL=${OVPN_PROTOCOL:-udp}
    OVPN_PORT=${OVPN_PORT:-1194}
    OVPN_DNS=${OVPN_DNS:-1.1.1.1}
    OVPN_USER=${OVPN_USER:-freemanxyz}

    export AUTO_INSTALL=y
    export APPROVE_INSTALL=y
    export ENDPOINT=$OVPN_SERVER
    export APPROVE_IP=y
    export DNS=$OVPN_DNS
    export PORT=$OVPN_PORT
    export PROTOCOL=$OVPN_PROTOCOL
    export CLIENT=$OVPN_USER
    export SERVER_NAME="server"

    bash /opt/openvpn-install.sh --auto

    log "✅ OpenVPN 配置完成"
  fi

  log "🚀 启动 OpenVPN 服务..."
  openvpn --config "${OVPN_DATA_DIR}/server.conf" &
}

# ========= 启动 OpenVPN Admin Web UI =========
start_web_ui() {
  log "🔧 启动 Web UI (ovpn-admin)..."

  ADMIN_USER=${WEB_ADMIN_USER:-admin}
  ADMIN_PASS=${WEB_ADMIN_PASS:-admin}

  cd "$WEB_UI_DIR"
  ./ovpn-admin \
    --listen 0.0.0.0:$WEB_UI_PORT \
    --openvpn-config "${OVPN_DATA_DIR}" \
    --users "${WEB_UI_DIR}/users.json" \
    --log \
    --user $ADMIN_USER \
    --pass $ADMIN_PASS &
  
  log "✅ Web UI 启动成功：用户 $ADMIN_USER"
}

# ========= 初始化 frpc（如果需要） =========
init_frpc() {
  if [[ "$ENABLE_FRPC" == "true" ]]; then
    log "🔌 启动 FRPC..."

    mkdir -p /etc/frp

    # 生成 frpc 配置文件
    cat > "$FRPC_CONFIG" <<EOF
[common]
server_addr = ${FRPS_SERVER}
server_port = ${FRPS_PORT}
token = ${FRPS_TOKEN}

[openvpn]
type = udp
local_ip = 127.0.0.1
local_port = ${OVPN_PORT}
remote_port = ${FRPC_REMOTE_PORT}
EOF

    /usr/local/frp/frpc -c "$FRPC_CONFIG" &
    log "✅ FRPC 启动完成，连接 ${FRPS_SERVER}:${FRPS_PORT}"
  fi
}

# ========= 打印 OpenVPN 状态 =========
start_status_logging() {
  if [[ -f "$PRINT_STATUS_SCRIPT" ]]; then
    log "📈 启动状态日志定时器..."
    watch -n 60 "$PRINT_STATUS_SCRIPT" &
  fi
}

# ========= 主流程 =========
init_openvpn
init_frpc
start_web_ui
start_status_logging

# ========= 阻塞前台 =========
log "✅ 所有服务已启动，日志持续中..."
tail -f /dev/null
