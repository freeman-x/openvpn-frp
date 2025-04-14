FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 安装依赖
RUN apt update && apt install -y \
    curl iptables openvpn easy-rsa \
    net-tools expect wget unzip lsb-release \
    && rm -rf /var/lib/apt/lists/*

# 下载 FRP 客户端
RUN wget -O /tmp/frp.tar.gz https://github.com/fatedier/frp/releases/download/v0.58.0/frp_0.58.0_linux_arm64.tar.gz \
    && tar -xzf /tmp/frp.tar.gz -C /usr/local/bin --strip-components=1 --wildcards "*/frpc" \
    && rm -rf /tmp/frp.tar.gz

# 添加脚本和配置
COPY openvpn-install.sh /opt/openvpn-install.sh
COPY frpc.ini /etc/frpc.ini
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /opt/openvpn-install.sh /entrypoint.sh /usr/local/bin/frpc

# 配置持久化目录
VOLUME ["/etc/openvpn", "/etc/frpc"]

# 容器监听 OpenVPN 端口
EXPOSE 1194/udp

ENTRYPOINT ["/entrypoint.sh"]
