# 🌐 OpenVPN + FRP Docker 镜像

一个用于快速部署 VPN 服务并通过 FRP 实现内网穿透的多合一 Docker 镜像，基于 [Nyr/openvpn-install](https://github.com/Nyr/openvpn-install) 和 [fatedier/frp](https://github.com/fatedier/frp)。

⚡ 支持多平台架构构建（`amd64` / `arm64`），适用于 x86 服务器、树莓派等设备！

---

## 📦 镜像地址

```bash
docker pull freemanxyz/openvpn-frp:latest
```

---

## ✨ 功能说明

- ✅ 内置 OpenVPN Server（基于 Nyr 脚本）
- ✅ 内置 frpc 客户端（新版配置格式支持 TOML）
- ✅ 外部挂载配置文件，启动灵活
- ✅ 支持动态添加 OpenVPN 用户
- ✅ 启动时自动运行 OpenVPN 和 frpc

---

## 🛠 环境变量 / 映射目录

| 项目        | 说明                           |
|-------------|--------------------------------|
| `/etc/openvpn` | OpenVPN 配置及用户证书目录    |
| `/etc/frp/frpc.toml` | frpc 配置文件路径（可挂载） |
| 1194/udp    | OpenVPN 默认端口                |

---

## 🚀 快速启动示例

```bash
docker run -d \
  --name openvpn-frp \
  --cap-add=NET_ADMIN \
  -v $(pwd)/openvpn-data:/etc/openvpn \
  -v $(pwd)/frpc.toml:/etc/frp/frpc.toml \
  -p 1194:1194/udp \
  freemanxyz/openvpn-frp:latest
```

---

## 🔐 添加 OpenVPN 用户

```bash
docker exec -it openvpn-frp bash
# 然后执行脚本添加新用户
./openvpn-install.sh
```

---

## 📡 查看连接用户状态（可选）

可通过 `status.log` 或自定义 `welcome` 脚本展示在线用户状态：

```bash
cat /etc/openvpn/openvpn-status.log
```

---

## 🤝 多平台支持

已构建并发布以下架构镜像：

- `linux/amd64`
- `linux/arm64`
- `linux/arm/v7`（可选，需添加支持）

---

## 🛠 TODO（计划支持）

- [ ] OpenVPN 状态页面或 API
- [ ] frpc 热更新配置
- [ ] Web UI 管理用户（未来扩展）

---

## 📝 License

MIT License. 部分内容基于 Nyr/openvpn-install 和 fatedier/frp。
