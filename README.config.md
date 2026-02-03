# OpenWrt/LEDE `.config` 说明

本文件说明当前工程根目录下 `.config` 中的主要功能与选项。该文件由 `make menuconfig` 等自动生成，**请勿直接编辑**。

---

## 一、目标设备与平台

| 项目 | 说明 |
|------|------|
| **目标板** | `ramips`（Ralink/MediaTek MIPS） |
| **子目标** | `mt7621`（MT7621 双核 MIPS） |
| **设备型号** | **d-team newifi-d2**（新路由 2） |
| **架构** | `mipsel`，包架构 `mipsel_24kc` |
| **内核** | Linux 5.4 |

即本配置为 **新路由 2（Newifi D2）** 的固件构建配置。

---

## 二、镜像与分区

- **根文件系统**：SquashFS（只读），块大小 1024
- **initramfs**：启用，压缩方式 LZMA
- **内核分区**：16 MB
- **根分区**：160 MB
- **目标优化**：`-Os -pipe -mno-branch-likely -mips32r2 -mtune=24kc`

---

## 三、系统与工具链

- **C 库**：musl
- **GCC**：8.4.0
- **Binutils**：2.37
- **软浮点**：启用（SOFT_FLOAT）
- **安全**：Shadow 密码、PIE、栈保护、FORTIFY_SOURCE、RELRO、SECCOMP 等加固选项已开
- **包**：签名校验开启（SIGNED_PACKAGES、SIGNATURE_CHECK），下载校验证书开启

---

## 四、预置软件包（CONFIG_DEFAULT_*）

### 4.1 基础系统

- **base-files**：基础文件与脚本
- **busybox**：常用命令与 init
- **block-mount / fstools**：块设备挂载与文件系统工具
- **procd**：init 与进程管理
- **uci**：统一配置接口
- **ubus**：系统总线
- **netifd**：网络接口管理
- **opkg**：包管理
- **ca-bundle / ca-certificates**：CA 证书
- **urandom-seed / urngd**：随机数
- **logd**：日志
- **mtd**：Flash 分区操作

### 4.2 网络与防火墙

- **firewall**：防火墙
- **iptables / ipset**：防火墙与集合
- **iptables-mod-extra / iptables-mod-tproxy**：扩展与透明代理
- **dnsmasq-full**：DNS/DHCP
- **ip-full**：完整 ip 工具
- **ppp / ppp-mod-pppoe**：PPPoE 拨号
- **dropbear**：SSH
- **curl / uclient-fetch**：HTTP 客户端
- **libustream-openssl**：HTTPS 支持

### 4.3 无线与硬件

- **kmod-mt7603e**：MT7603 2.4G 无线驱动
- **kmod-mt76x2e**：MT76x2 5G 无线驱动
- **kmod-mtk-hnat**：MTK 硬件 NAT
- **kmod-gpio-button-hotplug**：按键
- **kmod-leds-gpio**：LED
- **kmod-usb3 / kmod-usb-ledtrig-usbport**：USB3 与 USB 指示灯
- **kmod-tun**：TUN 设备（VPN 等）
- **kmod-nf-nathelper / kmod-nf-nathelper-extra**：NAT 辅助
- **kmod-ipt-raw**：iptables raw 表
- **swconfig**：交换机配置
- **iwinfo**：无线信息

### 4.4 LuCI 与 Web 管理

- **luci**：LuCI 主框架
- **luci-newapi**：新 API
- **luci-app-accesscontrol**：访问控制（家长控制等）
- **luci-app-arpbind**：IP/MAC 绑定
- **luci-app-autoreboot**：定时重启
- **luci-app-ddns**：动态 DNS
- **luci-app-filetransfer**：文件传输
- **luci-app-mtwifi**：MTK 无线配置
- **luci-app-nlbwmon**：流量统计
- **luci-app-ssr-plus**：SSR+ 代理
- **luci-app-turboacc**：Turbo ACC 加速
- **luci-app-upnp**：UPnP
- **luci-app-vlmcsd**：KMS 激活
- **luci-app-vsftpd**：FTP 服务器
- **luci-app-wol**：网络唤醒

### 4.5 其他应用与脚本

- **ddns-scripts_aliyun**：阿里云 DDNS
- **ddns-scripts_dnspod**：DNSPod DDNS
- **default-settings**：默认 Web 与系统设置
- **coremark**：CoreMark 跑分（可选）

---

## 五、Feeds 源

- **packages**：官方包
- **luci**：LuCI
- **routing**：路由相关
- **telephony**：电话/语音
- **openclash**：OpenClash
- **helloworld**：HelloWorld（常用代理相关包）

---

## 六、内核与硬件支持（概要）

- **支持**：模块化内核（CONFIG_MODULES）、音频、GPIO、PCI、USB、RTC、NAND、设备树
- **内核特性**：cgroups、namespaces、seccomp、网络多播、SquashFS、AIO、io_uring 等
- **preinit**：失败时 2 秒超时，IP 192.168.1.1/24

---

## 七、小结

本 `.config` 面向 **新路由 2（Newifi D2）**，包含：

1. **路由基础**：防火墙、NAT、DHCP/DNS、PPPoE、双频无线（MT7603 + MT76x2）、USB、硬件加速（HNAT）。
2. **管理**：LuCI Web、SSH（Dropbear）、访问控制、ARP 绑定、定时重启、流量监控、Turbo ACC。
3. **代理与扩展**：SSR+、DDNS（阿里云/DNSPod）、UPnP、KMS、FTP、WOL、OpenClash/HelloWorld 等 feed。

恢复配置时可使用备份：`.config.bak`。
