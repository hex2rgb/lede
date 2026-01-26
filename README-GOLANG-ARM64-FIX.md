# OpenWrt/LEDE 在 ARM64 主机上构建 Go 项目的修复方案

## 问题描述

在 **ARM64 (aarch64)** 主机上构建 OpenWrt/LEDE 固件时，如果配置中包含需要 Go 语言编译的软件包（如 `v2ray-core`、`xray-core` 等），会遇到以下错误：

```
Makefile:477: *** go-bootstrap cannot be installed on linux/arm64.  Stop.
ERROR: package/feeds/packages/golang [host] failed to build.
make[2]: *** [package/Makefile:114: package/feeds/packages/golang/host/compile] Error 1
```

### 问题原因

1. OpenWrt 构建系统在编译 Go 项目时，需要先构建一个 **go-bootstrap**（Go 1.4 版本的引导编译器）
2. **go-bootstrap** 的默认版本（go1.4-bootstrap-20171003）**不支持 linux/arm64 架构**
3. 因此无法在 ARM64 主机上完成 Go 项目的编译

### 受影响的软件包

所有依赖 `golang/host` 的软件包都会受到影响，包括但不限于：
- `v2ray-core`
- `xray-core`
- `v2ray-plugin`
- `xray-plugin`
- `mosdns`
- `hysteria`
- `dnsproxy`
- 其他 Go 语言编写的软件包

---

## 解决方案

使用 **外部 Go Bootstrap** 替代系统自带的 go-bootstrap。OpenWrt 支持通过配置 `CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT` 来指定一个已安装的 Go 环境作为 bootstrap，从而跳过不支持 ARM64 的 go-bootstrap 构建。

### 方案选择

**推荐方案：使用官方 Go tarball**

- ✅ 路径固定（`/usr/local/go`），易于配置
- ✅ 版本可控，可选择合适版本
- ✅ 独立于系统包管理器
- ✅ 已验证可用

**备选方案：使用系统包管理器**

- 如果发行版提供合适版本的 Go，也可以使用
- 需要确认 Go 安装路径并正确配置

---

## 解决步骤

### 步骤 1：检查系统架构

```bash
uname -m
# 应该显示：aarch64 或 arm64
```

### 步骤 2：下载 Go（ARM64 版本）

**重要：必须下载 ARM64 版本，不是 AMD64！**

```bash
cd /tmp

# 使用官方源（如果网络允许）
wget https://go.dev/dl/go1.21.6.linux-arm64.tar.gz

# 或使用国内镜像（推荐）
wget https://mirrors.ustc.edu.cn/golang/go1.21.6.linux-arm64.tar.gz
```

**版本说明：**
- 最低要求：Go 1.4+（作为 bootstrap）
- 推荐：Go 1.17+ 或更新版本（如 1.21.6）
- 确保下载的是 **linux-arm64** 版本（不是 linux-amd64）

### 步骤 3：安装 Go 到 /usr/local/go

```bash
# 如果 /usr/local/go 已存在，先删除或备份
sudo rm -rf /usr/local/go

# 解压到 /usr/local
sudo tar -C /usr/local -xzf /tmp/go1.21.6.linux-arm64.tar.gz
```

### 步骤 4：配置环境变量

编辑 `~/.bashrc`：

```bash
vim ~/.bashrc
```

在文件末尾添加：

```bash
# Go environment variables
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin
```

保存后重新加载：

```bash
source ~/.bashrc
```

### 步骤 5：验证 Go 安装

```bash
go version
# 应该显示：go version go1.21.6 linux/arm64

# 验证环境变量
echo $GOROOT
# 应该显示：/usr/local/go

which go
# 应该显示：/usr/local/go/bin/go
```

### 步骤 6：配置 OpenWrt/LEDE

进入 OpenWrt 源码目录：

```bash
cd /home/builder/lede
make menuconfig
```

导航到：
```
Languages → Go → Configuration → External bootstrap Go root directory
```

在括号中填入：`/usr/local/go`

保存并退出（Save → Exit）。

### 步骤 7：验证配置

检查 `.config` 文件：

```bash
grep GOLANG_EXTERNAL_BOOTSTRAP_ROOT .config
# 应该显示：CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT="/usr/local/go"
```

### 步骤 8：测试构建

```bash
# 测试编译 golang host（可选）
make V=s package/feeds/packages/golang/host/compile

# 或开始完整构建
make V=s -j$(nproc)
```

如果配置正确，应该不再出现 `go-bootstrap cannot be installed on linux/arm64` 错误。

---

## 验证清单

修复完成后，请确认以下各项：

- [ ] Go 已安装：`go version` 显示正确版本和架构（linux/arm64）
- [ ] 环境变量已设置：`echo $GOROOT` 显示 `/usr/local/go`
- [ ] PATH 包含 Go：`which go` 显示 `/usr/local/go/bin/go`
- [ ] OpenWrt 配置已更新：`.config` 中 `CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT="/usr/local/go"`
- [ ] 构建不再报错：`go-bootstrap cannot be installed on linux/arm64` 错误消失

---

## 常见问题

### Q1: 下载了错误的架构版本怎么办？

**A:** 如果下载了 `linux-amd64` 版本，在 ARM64 主机上无法运行。请重新下载 `linux-arm64` 版本。

### Q2: 使用系统包管理器安装的 Go 可以吗？

**A:** 可以，但需要：
1. 确认 Go 安装路径（通常为 `/usr/lib/go` 或 `/usr/share/go`）
2. 在 menuconfig 中将 External bootstrap 设置为该路径
3. 确保版本 >= Go 1.4

### Q3: 为什么 `source ~/.bashrc` 后 `go` 命令还是找不到？

**A:** `.bashrc` 在非交互式 shell 中会提前退出。解决方法：
- 重新打开终端（推荐）
- 或手动执行：`export GOROOT=/usr/local/go && export PATH=$PATH:$GOROOT/bin`

### Q4: 可以同时使用 v2ray-core 和 xray-core 吗？

**A:** 可以，但两者都是 Go 项目，都需要 golang/host。只要按照本方案配置好外部 bootstrap，两者都可以正常编译。

### Q5: 如果不想用 Go 项目，有其他替代方案吗？

**A:** 可以关闭 v2ray-core/xray-core，改用：
- `shadowsocks-libev`（C 语言，不依赖 Go）
- `shadowsocksr-libev`（C 语言，不依赖 Go）

这些替代方案不需要 Go，因此不会触发 go-bootstrap 构建。

---

## 技术说明

### 为什么 go-bootstrap 不支持 ARM64？

- Go 1.4 是最后一个用 C 编写的 Go 编译器版本
- 该版本的 bootstrap 二进制文件只支持有限的架构组合
- linux/arm64 不在支持列表中

### 外部 Bootstrap 的工作原理

1. 当设置 `CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT` 后，OpenWrt 构建系统会：
   - 跳过下载和构建 go-bootstrap（Go 1.4）
   - 使用指定的外部 Go 作为 bootstrap
   - 继续构建后续的 Go 版本（1.17 → 1.20 → 1.22 → Host Go）

2. 外部 Go 需要满足：
   - 版本 >= Go 1.4
   - 架构匹配主机架构（ARM64 主机需要 ARM64 Go）
   - 包含完整的 Go 安装（bin、src、pkg 目录）

---

## 相关资源

- [Go 官方下载页面](https://go.dev/dl/)
- [Go 国内镜像（中科大）](https://mirrors.ustc.edu.cn/golang/)
- [OpenWrt 官方文档](https://openwrt.org/docs/guide-developer/toolchain/building_openwrt_on_openwrt)
- [GitHub Issue #11731](https://github.com/openwrt/packages/issues/11731) - golang: Enable build on aarch64(arm64) host

---

## 更新日志

- **2026-01-25**: 初始版本，记录 ARM64 主机上构建 Go 项目的修复方案

---

## 贡献

如果发现文档有误或需要补充，欢迎提交 Issue 或 Pull Request。
