#!/bin/bash
# LEDE 初次构建脚本
# 用途：从零开始编译 LEDE 固件

set -e  # 遇到错误立即退出

echo "=========================================="
echo "LEDE 初次构建脚本"
echo "=========================================="

# 1. 更新源码（如果是 git 仓库）
echo "[1/6] 更新源码..."
if [ -d .git ]; then
    git pull
else
    echo "  提示: 当前目录不是 git 仓库，跳过更新"
fi

# 2. 更新并安装 feeds（软件包源）
echo "[2/6] 更新 feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# 3. 配置编译选项
echo "[3/6] 配置编译选项..."
echo "  提示: 如果已有 .config 文件，会基于现有配置更新"
echo "  提示: 如果没有 .config，请先运行: make menuconfig"
if [ ! -f .config ]; then
    echo "  警告: .config 文件不存在！"
    echo "  请先运行: make menuconfig 选择你的设备"
    exit 1
fi

# 4. 更新配置以适配新源码（应用新的默认值）
echo "[4/5] 更新配置..."
make oldconfig

# 5. 下载依赖包
echo "[5/5] 下载依赖包..."
make download -j8

# 6. 开始编译
echo "=========================================="
echo "开始编译固件..."
echo "  提示: 第一次编译建议使用单线程: make V=s -j1"
echo "  提示: 后续编译可以使用多线程: make V=s -j\$(nproc)"
echo "=========================================="
make V=s -j1

echo "=========================================="
echo "编译完成！"
echo "固件位置: bin/targets/"
echo "=========================================="
