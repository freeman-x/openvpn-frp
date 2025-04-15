# 使用一个轻量级 Debian 作为基础镜像
FROM debian:bullseye-slim

# 设置环境变量，避免构建过程中的交互提示
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要软件包（OpenVPN 相关工具、frpc 运行依赖、web UI 依赖）
RUN apt-get update && \
    apt-get install -y \
        curl \
        iptables \
        openvpn \
        unzip \
        git \
        cron \
        iproute2 \
        net-tools \
        procps \
        wget \
        lsb-release \
        gnupg \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 设置默认环境变量（用户可以在运行时通过 -e 来覆盖这些值）
# ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
ENV FRP_SERVER_ADDR="frps.example.com"
ENV FRP_SERVER_PORT="7000"
ENV FRP_TOKEN="your_default_token"
ENV OVPN_PORT="1194"
ENV FRPC_REMOTE_PORT="6000"
# ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

# 下载并安装 Nyr 的 OpenVPN 安装脚本
RUN curl -o /usr/local/bin/openvpn-install.sh https://raw.githubusercontent.com/Nyr/openvpn-install/master/openvpn-install.sh && \
    chmod +x /usr/local/bin/openvpn-install.sh

# 复制安装脚本到容器
COPY install_frpc.sh /usr/local/bin/install_frpc.sh

# 使安装脚本可执行
RUN chmod +x /usr/local/bin/install_frpc.sh

# 执行安装脚本
RUN /usr/local/bin/install_frpc.sh

# 克隆 OpenVPN Web UI (palark/ovpn-admin)
RUN git clone https://github.com/palark/ovpn-admin.git /opt/ovpn-admin

# 创建运行时需要的目录
RUN mkdir -p /etc/openvpn /var/log/openvpn /etc/frp

# 拷贝启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 暴露常用端口
EXPOSE 1194 8080 6000

# 设置容器启动入口
ENTRYPOINT ["/entrypoint.sh"]

# 设置容器启动时的默认命令
CMD ["bash"]
