# 使用轻量基础镜像（Ubuntu 20.04）
FROM ubuntu:20.04

# 设置时区、避免 tzdata 交互
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    curl iptables iproute2 openvpn iptables-persistent unzip net-tools \
    cron jq wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 创建运行目录
WORKDIR /opt

# 下载并添加 openvpn-install 脚本（你可以替换为 fork 地址）
ADD https://raw.githubusercontent.com/Nyr/openvpn-install/master/openvpn-install.sh /opt/openvpn-install.sh

# 添加 FRPC（二进制方式，需后续根据架构注入）
COPY frpc /usr/local/frp/frpc
COPY frpc.toml /etc/frp/frpc.toml

# 添加轻量 Web UI：openvpn-admin-ui
RUN mkdir -p /opt/openvpn-admin-ui
WORKDIR /opt/openvpn-admin-ui
# 可自定义替换为你 fork 的版本或版本号
RUN wget https://github.com/flant/openvpn-admin/releases/download/v1.0.0/openvpn-admin-linux-amd64 -O openvpn-admin \
    && chmod +x openvpn-admin

# 回到工作目录
WORKDIR /opt

# 拷贝本地脚本到容器中
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 添加 OpenVPN 状态日志定时器
COPY openvpn-status.sh /usr/local/bin/openvpn-status.sh
RUN chmod +x /usr/local/bin/openvpn-status.sh && \
    echo "* * * * * root /usr/local/bin/openvpn-status.sh >> /var/log/openvpn/status.log 2>&1" > /etc/cron.d/openvpn-log && \
    chmod 0644 /etc/cron.d/openvpn-log && \
    crontab /etc/cron.d/openvpn-log

# 暴露 OpenVPN 和 Web UI 默认端口
EXPOSE 1194/udp
EXPOSE 8080

# 可选暴露 frpc 的远程端口
ENV FRPC_REMOTE_PORT=6000
EXPOSE ${FRPC_REMOTE_PORT}

# 设置入口
ENTRYPOINT ["/entrypoint.sh"]
