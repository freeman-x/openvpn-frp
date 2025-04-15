# 使用轻量版 Debian 作为基础镜像
FROM debian:bullseye-slim

LABEL maintainer="yourname <you@example.com>"
LABEL description="Docker image for OpenVPN + FRPC + Web UI"

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要组件
RUN apt-get update && apt-get install -y --no-install-recommends \
    openvpn \
    iptables \
    iproute2 \
    curl \
    wget \
    unzip \
    ca-certificates \
    jq \
    git \
    net-tools \
    cron \
    bash \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ========= 下载 Nyr 的 openvpn-install 脚本 =========
WORKDIR /opt
RUN curl -O https://raw.githubusercontent.com/Nyr/openvpn-install/master/openvpn-install.sh \
 && chmod +x openvpn-install.sh

# ========= 下载并解压 ovpn-admin Web UI =========
RUN wget -O ovpn-admin.zip https://github.com/palark/ovpn-admin/releases/latest/download/ovpn-admin-linux.zip \
 && unzip ovpn-admin.zip -d /opt/ovpn-admin \
 && chmod +x /opt/ovpn-admin/ovpn-admin \
 && rm ovpn-admin.zip

# ========= 安装 frpc（只下载，不自动运行） =========
RUN mkdir -p /usr/local/frp \
 && curl -L https://github.com/fatedier/frp/releases/latest/download/frpc_linux_amd64.tar.gz -o frpc.tar.gz \
 && tar -zxvf frpc.tar.gz -C /usr/local/frp --strip-components=1 \
 && chmod +x /usr/local/frp/frpc \
 && rm frpc.tar.gz

# ========= 拷贝自定义脚本 =========
COPY entrypoint.sh /entrypoint.sh
COPY print-status.sh /usr/local/bin/print-status.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/print-status.sh

# ========= 创建 OpenVPN 配置目录 =========
RUN mkdir -p /etc/openvpn

# ========= 设置容器入口 =========
ENTRYPOINT ["/entrypoint.sh"]

# ========= 暴露必要端口 =========
EXPOSE 1194/udp 8080

# ========= 设定默认命令（预防） =========
CMD ["bash"]
