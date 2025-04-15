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

# 下载并安装 Nyr 的 OpenVPN 安装脚本
RUN curl -o /usr/local/bin/openvpn-install.sh https://raw.githubusercontent.com/Nyr/openvpn-install/master/openvpn-install.sh && \
    chmod +x /usr/local/bin/openvpn-install.sh

# 选择并下载 frpc 对应平台版本
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        wget https://github.com/fatedier/frp/releases/download/v0.61.2/frp_0.61.2_linux_amd64.tar.gz -O /tmp/frpc.tar.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
        wget https://github.com/fatedier/frp/releases/download/v0.61.2/frp_0.61.2_linux_arm64.tar.gz -O /tmp/frpc.tar.gz; \
    else \
        echo "Unsupported architecture: $ARCH"; exit 1; \
    fi && \
    ls -lh /tmp && \
    tar -xzvf /tmp/frpc.tar.gz -C /tmp && \
    ls -lh /tmp && \
    mv /tmp/frpc /usr/local/bin/frpc && \
    chmod +x /usr/local/bin/frpc

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
