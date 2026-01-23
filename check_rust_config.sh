#!/bin/bash
# 检查 Rust 配置的详细脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/rust_config_check_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "检查 Rust 配置..."

# 1. 检查工具链类型
log ""
log "=== 工具链类型 ==="
if grep -q "^CONFIG_EXTERNAL_TOOLCHAIN=y" .config 2>/dev/null; then
    log "使用外部工具链"
    TOOLCHAIN_TYPE="external"
elif grep -q "^# CONFIG_EXTERNAL_TOOLCHAIN" .config 2>/dev/null || ! grep -q "CONFIG_EXTERNAL_TOOLCHAIN" .config 2>/dev/null; then
    log "使用内部工具链"
    TOOLCHAIN_TYPE="internal"
else
    log "无法确定工具链类型"
    TOOLCHAIN_TYPE="unknown"
fi

# 2. 检查 Rust Makefile
log ""
log "=== Rust Makefile 配置 ==="
RUST_MAKEFILE=$(find feeds -path "*/lang/rust/Makefile" 2>/dev/null | head -1)
if [ -n "$RUST_MAKEFILE" ]; then
    log "Rust Makefile: $RUST_MAKEFILE"
    log ""
    log "musl-root 相关配置:"
    grep -A2 -B2 "musl-root" "$RUST_MAKEFILE" | tee -a "$LOG_FILE" || log "未找到 musl-root 配置"
    
    log ""
    log "TOOLCHAIN 相关变量:"
    grep -E "TOOLCHAIN_(ROOT_)?DIR|TOOLCHAIN_ROOT" "$RUST_MAKEFILE" | tee -a "$LOG_FILE" || log "未找到 TOOLCHAIN 变量"
    
    log ""
    log "RUSTC_TARGET_ARCH 定义:"
    grep -E "RUSTC_TARGET_ARCH\s*:=" "$RUST_MAKEFILE" | tee -a "$LOG_FILE" || log "未找到 RUSTC_TARGET_ARCH"
else
    log "✗ 找不到 Rust Makefile"
fi

# 3. 检查实际工具链路径
log ""
log "=== 实际工具链路径 ==="
TOOLCHAIN_DIR=$(find staging_dir -name "toolchain-*" -type d | head -1)
if [ -n "$TOOLCHAIN_DIR" ]; then
    log "TOOLCHAIN_DIR: $TOOLCHAIN_DIR"
    log "libc.a 路径: $TOOLCHAIN_DIR/lib/libc.a"
    [ -f "$TOOLCHAIN_DIR/lib/libc.a" ] && log "✓ libc.a 存在" || log "✗ libc.a 不存在"
else
    log "✗ 找不到工具链目录"
fi

# 4. 检查 Rust 构建时的环境
log ""
log "=== Rust 构建环境 ==="
RUST_BUILD_DIR=$(find build_dir -path "*/host/rustc-*" -type d 2>/dev/null | head -1)
if [ -n "$RUST_BUILD_DIR" ]; then
    log "Rust 构建目录: $RUST_BUILD_DIR"
    log ""
    log "检查构建时的环境变量（从 Makefile 推断）:"
    # 这里可以检查实际的构建日志
    if [ -f "$RUST_BUILD_DIR/.built" ]; then
        log "构建已完成"
    else
        log "构建未完成，检查错误..."
        find "$RUST_BUILD_DIR" -name "*.log" -o -name "*error*" 2>/dev/null | head -3 | while read -r logfile; do
            if [ -f "$logfile" ]; then
                log "日志: $logfile"
                tail -20 "$logfile" | grep -i "libc\|musl" | head -5 | tee -a "$LOG_FILE"
            fi
        done
    fi
fi

log ""
log "检查完成，日志已保存到: $LOG_FILE"
