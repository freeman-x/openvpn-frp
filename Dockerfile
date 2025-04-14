# 基于官方的 Alpine Linux 镜像
FROM ubuntu:20.04

# 设置环境变量默认值，可以被 docker run 时覆盖
ENV OVPN_PROTOCOL=udp
ENV OVPN_PORT=1194
ENV OVPN_DNS=1.1.1.1
ENV OVPN_USER=testuser

ENV FRPS_SERVER=your.frps.com
ENV FRPS_PORT=7000
ENV FRPS_TOKEN=yourtoken
ENV FRPC_REMOTE_PORT=6000

# 更新并安装所需的依赖项
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    sudo \
    iproute2 \
    iputils-ping \
    openvpn \
    && rm -rf /var/lib/apt/lists/*

# 安装 FRP 客户端
RUN curl -L https://github.com/fatedier/frp/releases/download/v0.58.0/frp_0.58.0_linux_amd64.tar.gz | tar zx --strip-components=1 -C /usr/local/frp

# 下载并安装 OpenVPN 安装脚本
RUN curl -L https://github.com/Nyr/openvpn-install/releases/download/v3.1.0/openvpn-install.sh -o /opt/openvpn-install.sh
RUN chmod +x /opt/openvpn-install.sh

# 复制 entrypoint 脚本到容器
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 暴露 OpenVPN 默认端口
EXPOSE 1194/udp

# 设置容器启动时运行 entrypoint 脚本
ENTRYPOINT ["/entrypoint.sh"]
