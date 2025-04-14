#!/bin/bash

set -e

# 设置
CLIENT_NAME="user1"
STATUS_LOG="/var/log/openvpn/status.log"
WELCOME_SCRIPT="/etc/update-motd.d/99-openvpn-status"
OVPN_SCRIPT_URL="https://raw.githubusercontent.com/Nyr/openvpn-install/master/openvpn-install.sh"

echo "🟡 更新系统..."
sudo apt update && sudo apt upgrade -y

echo "🟡 安装依赖..."
sudo apt install -y curl iptables-persistent

echo "🟡 下载 OpenVPN 安装脚本..."
curl -O "$OVPN_SCRIPT_URL"
chmod +x openvpn-install.sh

echo "🟢 开始安装 OpenVPN..."
sudo AUTO_INSTALL=y ./openvpn-install.sh <<EOF
1
1194
1
$CLIENT_NAME
EOF

# 修改 OpenVPN 配置文件启用状态日志
echo "🟢 配置 OpenVPN 状态日志..."
sudo sed -i "/^status/d" /etc/openvpn/server.conf
sudo sed -i "/^status-version/d" /etc/openvpn/server.conf
echo "status $STATUS_LOG" | sudo tee -a /etc/openvpn/server.conf
echo "status-version 2" | sudo tee -a /etc/openvpn/server.conf

# 启动并启用服务
sudo systemctl restart openvpn
sudo systemctl enable openvpn

# 防火墙配置
echo "🛡️ 配置 iptables..."
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
sudo iptables -A INPUT -p udp --dport 1194 -j ACCEPT
sudo iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT
sudo iptables -A FORWARD -d 10.8.0.0/24 -j ACCEPT
sudo netfilter-persistent save

# Welcome 信息脚本
echo "🖥️ 添加登录 welcome 信息..."
sudo tee "$WELCOME_SCRIPT" > /dev/null <<'EOF'
#!/bin/bash

status_file="/var/log/openvpn/status.log"

if [ -f "$status_file" ]; then
    user_count=$(grep -c '^CLIENT_LIST' "$status_file")
    echo
    echo "            ================================="
    echo "       Shanghai Office Uptime-Kuma Server  [$user_count]"
    echo "            ================================="
    grep '^CLIENT_LIST' "$status_file" | while IFS=',' read -r _ username real_ip vpn_ip conn_time _ rx tx _ _ duration; do
        up=$(awk "BEGIN {print int($tx / 1024 / 1024) \"M↓\"}")
        down=$(awk "BEGIN {print int($rx / 1024 / 1024) \"M↑\"}")
        echo "$username         $real_ip         $down     $up     ${duration}s"
    done
    echo
fi
EOF

sudo chmod +x "$WELCOME_SCRIPT"

echo "✅ 安装完成！客户端配置文件位于 $(pwd)/${CLIENT_NAME}.ovpn"
