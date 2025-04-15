#!/bin/bash
set -e

# ========= 🔧 读取环境变量并设置默认值 =========
OVPN_SERVER=${OVPN_SERVER:-"auto"}                  # VPN 服务端地址，auto 表示使用当前主机 IP
OVPN_PROTOCOL=${OVPN_PROTOCOL:-"udp"}
OVPN_PORT=${OVPN_PORT:-"1194"}
OVPN_DNS=${OVPN_DNS:-"1.1.1.1"}
OVPN_USER=${OVPN_USER:-"freemanxyz"}

ENABLE_FRPC=${ENABLE_FRPC:-"false"}                 # 是否启用 FRPC
FRPS_SERVER=${FRPS_SERVER:-""}
FRPS_PORT=${FRPS_PORT:-"7000"}
FRPS_TOKEN=${FRPS_TOKEN:-"secret"}
FRPC_REMOTE_PORT=${FRPC_REMOTE_PORT:-"60000"}

ADMIN_USER=${ADMIN_USER:-"admin"}                   # OpenVPN Web UI 的管理员账户
ADMIN_PASSWORD=${ADMIN_PASSWORD:-"admin123"}

# ========= 🌐 自动获取当前主机 IP =========
if [ "$OVPN_SERVER" == "auto" ]; then
    OVPN_SERVER=$(hostname -I | awk '{print $1}')
fi

# ========= ⚙️ 安装并配置 OpenVPN =========
echo "🟢 安装 OpenVPN..."
curl -O https://raw.githubusercontent.com/Nyr/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh

export AUTO_INSTALL=y
bash openvpn-install.sh <<EOF
$OVPN_PROTOCOL
$OVPN_PORT
$OVPN_DNS
$OVPN_USER
EOF

# 如果启用了 FRPC，强制将 OVPN_SERVER 改为 FRPS 地址，端口改为 FRPC_REMOTE_PORT
if [[ "$ENABLE_FRPC" == "true" ]]; then
    OVPN_SERVER=$FRPS_SERVER
    OVPN_PORT=$FRPC_REMOTE_PORT
    echo "🔁 使用 FRP 反代地址：$OVPN_SERVER:$OVPN_PORT"
fi

# ========= 🧠 修改 OpenVPN server 配置，启用状态日志 =========
echo "🔧 启用 OpenVPN 状态日志..."
echo "status /var/log/openvpn/status.log" >> /etc/openvpn/server.conf
echo "status-version 2" >> /etc/openvpn/server.conf

# ========= 🚀 启动 OpenVPN =========
echo "🚀 启动 OpenVPN..."
systemctl start openvpn
systemctl enable openvpn

# ========= 📦 下载并运行 ovpn-admin =========
echo "📦 启动 Web UI：ovpn-admin"
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) BIN_URL="https://github.com/palark/ovpn-admin/releases/latest/download/ovpn-admin-linux-amd64" ;;
    aarch64) BIN_URL="https://github.com/palark/ovpn-admin/releases/latest/download/ovpn-admin-linux-arm64" ;;
    armv7l) BIN_URL="https://github.com/palark/ovpn-admin/releases/latest/download/ovpn-admin-linux-arm" ;;
    *) echo "❌ 不支持的架构: $ARCH"; exit 1 ;;
esac

curl -L "$BIN_URL" -o /usr/local/bin/ovpn-admin
chmod +x /usr/local/bin/ovpn-admin

cat <<EOF > /etc/ovpn-admin.env
OVPN_DATA=/etc/openvpn
OVPN_ADMIN_USER=$ADMIN_USER
OVPN_ADMIN_PASS=$ADMIN_PASSWORD
EOF

echo "🔐 Web UI 管理员账户: $ADMIN_USER / $ADMIN_PASSWORD"

# 启动 Web UI
nohup /usr/local/bin/ovpn-admin --listen :8080 --config /etc/ovpn-admin.env >/var/log/ovpn-admin.log 2>&1 &

# ========= 🔄 安装并启动 FRPC（可选） =========
if [[ "$ENABLE_FRPC" == "true" ]]; then
    echo "🟢 下载并配置 FRPC..."
    case "$ARCH" in
        x86_64) FRPC_URL="https://github.com/fatedier/frp/releases/latest/download/frpc_linux_amd64.tar.gz" ;;
        aarch64) FRPC_URL="https://github.com/fatedier/frp/releases/latest/download/frpc_linux_arm64.tar.gz" ;;
        armv7l) FRPC_URL="https://github.com/fatedier/frp/releases/latest/download/frpc_linux_arm.tar.gz" ;;
    esac

    curl -L "$FRPC_URL" -o frpc.tar.gz
    mkdir -p /opt/frpc
    tar -xzvf frpc.tar.gz -C /opt/frpc --strip-components=1
    rm frpc.tar.gz

    cat <<EOF > /opt/frpc/frpc.toml
[common]
server_addr = "$FRPS_SERVER"
server_port = $FRPS_PORT
token = "$FRPS_TOKEN"

[openvpn]
type = udp
local_ip = 127.0.0.1
local_port = 1194
remote_port = $FRPC_REMOTE_PORT
EOF

    nohup /opt/frpc/frpc -c /opt/frpc/frpc.toml >/var/log/frpc.log 2>&1 &
    echo "✅ FRPC 启动完成，远程端口：$FRPC_REMOTE_PORT"
fi

# ========= 📋 定时打印 OpenVPN 连接状态 =========
echo "⏲️ 启动状态监控器..."
while true; do
    if [ -f /var/log/openvpn/status.log ]; then
        echo "================ OpenVPN 连接状态 $(date) ================"
        grep '^CLIENT_LIST' /var/log/openvpn/status.log | while IFS=',' read -r _ username real_ip vpn_ip conn_time _ rx tx _ _ duration; do
            down=$(awk "BEGIN {print int($rx / 1024 / 1024) \"MB↓\"}")
            up=$(awk "BEGIN {print int($tx / 1024 / 1024) \"MB↑\"}")
            echo "$username  $real_ip  $vpn_ip  $down / $up  在线 ${duration}s"
        done
    fi
    sleep 60
done
