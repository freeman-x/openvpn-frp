#!/bin/bash
# 🧾 文件说明：定时打印 OpenVPN 客户端连接状态，每分钟执行一次
# 📍 路径：/usr/local/bin/print-status.sh（建议放在这个路径下方便引用）

STATUS_LOG="/var/log/openvpn/status.log"

print_status() {
  echo "================ OpenVPN 连接状态 $(date '+%Y-%m-%d %H:%M:%S') ================"
  if [[ -f "$STATUS_LOG" ]]; then
    grep '^CLIENT_LIST' "$STATUS_LOG" | while IFS=',' read -r _ username real_ip vpn_ip conn_time _ rx tx _ _ duration; do
      down=$(awk "BEGIN {print int($rx / 1024 / 1024) \"MB↓\"}")
      up=$(awk "BEGIN {print int($tx / 1024 / 1024) \"MB↑\"}")
      echo "$username  $real_ip  $vpn_ip  $down / $up  在线 ${duration}s"
    done
  else
    echo "⚠️ 无法找到状态文件 $STATUS_LOG，OpenVPN 服务可能未启动或日志未配置"
  fi
}

# 🔁 每 60 秒打印一次
while true; do
  print_status
  sleep 60
done
