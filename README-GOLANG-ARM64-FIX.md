# ARM64 主机构建 Go 项目修复

## 问题
ARM64 主机上构建 OpenWrt 时，Go 项目报错：`go-bootstrap cannot be installed on linux/arm64`

## 原理
Go 编译器是自举的（用 Go 编译 Go），构建流程：go-bootstrap (Go 1.4, C 写) → Go 1.17 → Go 1.20 → Host Go。OpenWrt 自带的 go-bootstrap 二进制不支持 linux/arm64。配置外部 bootstrap 后，系统跳过 go-bootstrap 构建，直接使用已安装的 Go 作为 bootstrap。

## 解决步骤

1. **下载 ARM64 版 Go**（必须 linux-arm64，不是 amd64）
   ```bash
   wget https://mirrors.ustc.edu.cn/golang/go1.21.6.linux-arm64.tar.gz -O /tmp/go.tar.gz
   ```

2. **安装到 /usr/local/go**
   ```bash
   sudo rm -rf /usr/local/go
   sudo tar -C /usr/local -xzf /tmp/go.tar.gz
   ```

3. **配置 OpenWrt**
   ```bash
   make menuconfig
   # Languages → Go → Configuration → External bootstrap Go root directory
   # 填入：/usr/local/go
   ```

4. **验证**
   ```bash
   grep GOLANG_EXTERNAL_BOOTSTRAP_ROOT .config
   # 应显示：CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT="/usr/local/go"
   ```

完成。重新编译即可。
