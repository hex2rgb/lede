#!/bin/bash
# Rust musl libc.a 修复脚本
# 修复 Rust Makefile 中的 TOOLCHAIN_ROOT_DIR 问题

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/rust_musl_fix_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "开始修复 Rust musl 配置问题..."
log "日志文件: $LOG_FILE"

# 查找 Rust Makefile
RUST_MAKEFILE=$(find feeds -path "*/lang/rust/Makefile" 2>/dev/null | head -1)

if [ -z "$RUST_MAKEFILE" ]; then
    log "错误: 找不到 Rust Makefile"
    log "请确保已运行: ./scripts/feeds update -a && ./scripts/feeds install -a"
    exit 1
fi

log "找到 Rust Makefile: $RUST_MAKEFILE"

# 备份原文件
BACKUP_FILE="${RUST_MAKEFILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$RUST_MAKEFILE" "$BACKUP_FILE"
log "已备份原文件到: $BACKUP_FILE"

# 检查当前配置
log ""
log "检查当前配置..."
if grep -q "TOOLCHAIN_ROOT_DIR" "$RUST_MAKEFILE"; then
    log "发现 TOOLCHAIN_ROOT_DIR 的使用:"
    grep -n "TOOLCHAIN_ROOT_DIR" "$RUST_MAKEFILE" | tee -a "$LOG_FILE"
    
    # 检查是否使用内部工具链
    if ! grep -q "CONFIG_EXTERNAL_TOOLCHAIN" .config 2>/dev/null || grep -q "^# CONFIG_EXTERNAL_TOOLCHAIN" .config 2>/dev/null; then
        log ""
        log "使用内部工具链，需要修复 TOOLCHAIN_ROOT_DIR -> TOOLCHAIN_DIR"
        
        # 修复：将 TOOLCHAIN_ROOT_DIR 替换为 TOOLCHAIN_DIR（仅针对 musl-root 配置）
        # 使用 sed 进行精确替换
        sed -i 's|--set=target\.$(RUSTC_TARGET_ARCH)\.musl-root=$(TOOLCHAIN_ROOT_DIR)|--set=target.$(RUSTC_TARGET_ARCH).musl-root=$(TOOLCHAIN_DIR)|g' "$RUST_MAKEFILE"
        
        log "已修复 musl-root 配置"
        log ""
        log "修复后的配置:"
        grep -n "musl-root" "$RUST_MAKEFILE" | tee -a "$LOG_FILE"
    else
        log "使用外部工具链，TOOLCHAIN_ROOT_DIR 应该已定义"
    fi
else
    log "未找到 TOOLCHAIN_ROOT_DIR，检查其他可能的配置..."
    grep -i "musl\|TOOLCHAIN" "$RUST_MAKEFILE" | head -10 | tee -a "$LOG_FILE"
fi

# 验证修复
log ""
log "验证修复结果..."
if grep -q "musl-root=\$(TOOLCHAIN_DIR)" "$RUST_MAKEFILE"; then
    log "✓ 修复成功：musl-root 现在使用 TOOLCHAIN_DIR"
elif grep -q "musl-root=\$(TOOLCHAIN_ROOT_DIR)" "$RUST_MAKEFILE"; then
    log "⚠ 仍在使用 TOOLCHAIN_ROOT_DIR，可能需要手动修复"
    log "请检查 .config 中的 CONFIG_EXTERNAL_TOOLCHAIN 设置"
else
    log "? 未找到 musl-root 配置，可能不需要修复或配置方式不同"
fi

log ""
log "修复完成！"
log "如果修复成功，可以尝试重新编译:"
log "  make package/feeds/packages/rust/clean"
log "  make package/feeds/packages/rust/compile V=s -j1"
log ""
log "如需恢复原文件:"
log "  cp $BACKUP_FILE $RUST_MAKEFILE"
