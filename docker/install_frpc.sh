#!/bin/bash

ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    echo "Downloading frpc for x86_64"
    curl -LO https://github.com/fatedier/frp/releases/download/v0.61.2/frp_0.61.2_linux_amd64.tar.gz
elif [ "$ARCH" = "aarch64" ]; then
    echo "Downloading frpc for aarch64"
    curl -LO https://github.com/fatedier/frp/releases/download/v0.61.2/frp_0.61.2_linux_arm64.tar.gz
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Extract and install
tar -xzvf frp_0.61.2_linux_*.tar.gz -C /tmp
mv /tmp/frp_0.61.2_linux_*/frpc /usr/local/bin/frpc
chmod +x /usr/local/bin/frpc

# Clean up
rm -rf /tmp/frp_0.61.2_linux_*
