FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 安装必要软件
RUN apt update && apt install -y \
    curl iptables openvpn easy-rsa \
    net-tools expect wget unzip gnupg lsb-release \
    && rm -rf /var/lib/apt/lists/*

# 下载 Nyr 脚本
COPY openvpn-install.sh /opt/openvpn-install.sh
RUN chmod +x /opt/openvpn-install.sh

# 下载并解压新版 frp
ARG FRP_VERSION=0.58.0
RUN wget -O /tmp/frp.tar.gz https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_arm64.tar.gz \
    && mkdir -p /usr/local/frp \
    && tar -xzf /tmp/frp.tar.gz -C /usr/local/frp --strip-components=1 \
    && rm -rf /tmp/frp.tar.gz

COPY frpc.toml /etc/frpc.toml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /usr/local/frp/frpc

VOLUME ["/etc/openvpn", "/etc/frpc"]

EXPOSE 1194/udp

ENTRYPOINT ["/entrypoint.sh"]
