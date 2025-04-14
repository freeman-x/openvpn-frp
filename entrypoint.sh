#!/bin/bash
set -e

# 🌐 设置默认环境变量（可通过 docker run -e 覆盖）
: "${FRPC_CONFIG:=/etc/frp/frpc.toml}"
: "${OVPN_CONFIG:=/etc/openvpn/server.conf}"
: "${STATUS_LOG:=/var/log/openvpn/status.log}"
: "${OVPN_SCRIPT:=/opt/openvpn-install.sh}"

echo "🟡 正在运行 OpenVPN 安装脚本..."
bash "$OVPN_SCRIPT"

echo "🚀 启动 OpenVPN 服务..."
openvpn --config "$OVPN_CONFIG" &

echo "🔌 启动 FRPC..."
chmod +x /usr/local/frp/frpc
/usr/local/frp/frpc -c "$FRPC_CONFIG" &

# 🖥️ 定时打印 OpenVPN 连接状态到日志
echo "📝 启动状态输出定时任务..."
while true; do
    if [[ -f "$STATUS_LOG" ]]; then
        user_count=$(grep -c '^CLIENT_LIST' "$STATUS_LOG")
        echo "================================="
        echo "Shanghai Office Uptime-Kuma Server [$user_count]"
        echo "================================="
        grep '^CLIENT_LIST' "$STATUS_LOG" | while IFS=',' read -r _ username real_ip vpn_ip conn_time _ rx tx _ _ duration; do
            up=$(awk "BEGIN {print int($tx / 1024 / 1024) \"M↓\"}")
            down=$(awk "BEGIN {print int($rx / 1024 / 1024) \"M↑\"}")
            echo "$username  $real_ip  $down  $up  ${duration}s"
        done
        echo
    fi
    sleep 60
done
