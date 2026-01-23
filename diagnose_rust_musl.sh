#!/bin/bash
# Rust musl libc.a 诊断脚本
# 生成诊断日志到 logs 目录

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/rust_musl_diagnosis_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_separator() {
    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "$*" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

log "开始 Rust musl 诊断..."
log "日志文件: $LOG_FILE"

# 1. 检查工具链状态
log_separator "1. 检查工具链安装状态"

log "检查 musl 安装标记..."
if find staging_dir/toolchain-*/stamp/.musl_installed 2>/dev/null | head -1 | grep -q .; then
    MUSL_STAMP=$(find staging_dir/toolchain-*/stamp/.musl_installed 2>/dev/null | head -1)
    log "✓ musl 安装标记存在: $MUSL_STAMP"
    ls -lh "$MUSL_STAMP" | tee -a "$LOG_FILE"
else
    log "✗ musl 安装标记不存在"
fi

log ""
log "检查 libc.a 文件..."
if find staging_dir/toolchain-*/lib -name "libc.a" 2>/dev/null | head -1 | grep -q .; then
    LIBC_A=$(find staging_dir/toolchain-*/lib -name "libc.a" 2>/dev/null | head -1)
    log "✓ libc.a 存在: $LIBC_A"
    ls -lh "$LIBC_A" | tee -a "$LOG_FILE"
    TOOLCHAIN_DIR=$(dirname "$(dirname "$LIBC_A")")
    log "工具链目录: $TOOLCHAIN_DIR"
else
    log "✗ libc.a 不存在"
    TOOLCHAIN_DIR=$(find staging_dir -name "toolchain-*" -type d | head -1)
    log "工具链目录: $TOOLCHAIN_DIR"
fi

# 2. 检查环境变量
log_separator "2. 检查构建环境变量"

log "TOOLCHAIN_DIR: ${TOOLCHAIN_DIR:-未设置}"
log "STAGING_DIR: ${STAGING_DIR:-未设置}"
log "STAGING_DIR_HOST: ${STAGING_DIR_HOST:-未设置}"
log "TARGET_LDFLAGS: ${TARGET_LDFLAGS:-未设置}"
log "TARGET_CPPFLAGS: ${TARGET_CPPFLAGS:-未设置}"
log "PATH: $PATH" | tee -a "$LOG_FILE"

# 3. 检查 Rust 构建目录
log_separator "3. 检查 Rust 构建目录"

RUST_BUILD_DIR=$(find build_dir -path "*/host/rustc-*" -type d 2>/dev/null | head -1)
if [ -n "$RUST_BUILD_DIR" ]; then
    log "✓ Rust 构建目录: $RUST_BUILD_DIR"
    cd "$RUST_BUILD_DIR" || exit 1
    
    log ""
    log "检查 config.toml..."
    if [ -f config.toml ]; then
        log "✓ config.toml 存在"
        log "config.toml 内容（相关部分）:"
        grep -i "musl\|libdir\|target.*aarch64" config.toml | tee -a "$LOG_FILE" || echo "未找到相关配置" | tee -a "$LOG_FILE"
    else
        log "✗ config.toml 不存在"
    fi
    
    log ""
    log "检查 bootstrap.toml..."
    if [ -f src/bootstrap/bootstrap.toml ]; then
        log "✓ bootstrap.toml 存在"
        log "bootstrap.toml 内容（相关部分）:"
        grep -i "change-id\|musl" src/bootstrap/bootstrap.toml | head -10 | tee -a "$LOG_FILE" || echo "未找到相关配置" | tee -a "$LOG_FILE"
    else
        log "✗ bootstrap.toml 不存在"
    fi
    
    log ""
    log "检查构建日志中的错误..."
    if [ -f .built ]; then
        log "构建标记存在，检查最近的错误..."
    else
        log "构建未完成，查找错误日志..."
        find . -name "*.log" -o -name "*error*" 2>/dev/null | head -5 | while read -r logfile; do
            if [ -f "$logfile" ]; then
                log "发现日志文件: $logfile"
                tail -50 "$logfile" | grep -i "libc\|musl\|error" | head -10 | tee -a "$LOG_FILE"
            fi
        done
    fi
    
    cd "$SCRIPT_DIR" || exit 1
else
    log "✗ Rust 构建目录不存在"
    log "查找可能的 Rust 相关目录:"
    find build_dir -name "*rust*" -type d 2>/dev/null | head -5 | tee -a "$LOG_FILE"
fi

# 4. 检查 Rust 包配置
log_separator "4. 检查 Rust 包配置"

log "查找 Rust 包 Makefile..."
RUST_MAKEFILE=$(find feeds -name "rust" -type d 2>/dev/null | head -1)
if [ -n "$RUST_MAKEFILE" ]; then
    RUST_MAKEFILE="${RUST_MAKEFILE}/Makefile"
    if [ -f "$RUST_MAKEFILE" ]; then
        log "✓ Rust Makefile: $RUST_MAKEFILE"
        log "Makefile 内容（相关部分）:"
        grep -i "musl\|TOOLCHAIN\|STAGING\|libdir" "$RUST_MAKEFILE" | head -20 | tee -a "$LOG_FILE" || echo "未找到相关配置" | tee -a "$LOG_FILE"
    fi
else
    log "✗ Rust 包目录不存在"
    log "查找所有 feeds 中的 rust 相关:"
    find feeds -name "*rust*" -type d 2>/dev/null | tee -a "$LOG_FILE"
fi

# 5. 检查 .config 中的 Rust 配置
log_separator "5. 检查 .config 中的 Rust 配置"

if [ -f .config ]; then
    log "检查 Rust 相关配置:"
    grep -i "rust\|RUST" .config | tee -a "$LOG_FILE" || echo "未找到 Rust 配置" | tee -a "$LOG_FILE"
else
    log "✗ .config 文件不存在"
fi

# 6. 检查工具链库文件
log_separator "6. 检查工具链库文件"

if [ -n "$TOOLCHAIN_DIR" ] && [ -d "$TOOLCHAIN_DIR/lib" ]; then
    log "工具链 lib 目录: $TOOLCHAIN_DIR/lib"
    log "lib 目录内容:"
    ls -lh "$TOOLCHAIN_DIR/lib" | grep -E "libc|libgcc|libunwind" | tee -a "$LOG_FILE"
    
    log ""
    log "检查关键库文件:"
    for lib in libc.a libgcc.a libunwind.a; do
        if [ -f "$TOOLCHAIN_DIR/lib/$lib" ]; then
            log "✓ $lib 存在: $(ls -lh "$TOOLCHAIN_DIR/lib/$lib" | awk '{print $9, $5}')"
        else
            log "✗ $lib 不存在"
        fi
    done
else
    log "✗ 无法确定工具链 lib 目录"
fi

# 7. 检查 Rust bootstrap 可能查找的路径
log_separator "7. 检查 Rust bootstrap 查找路径"

log "Rust bootstrap 错误信息显示在 'lib' 目录查找..."
log "检查可能的 lib 目录:"

# 检查 Rust 构建目录下的 lib
if [ -n "$RUST_BUILD_DIR" ] && [ -d "$RUST_BUILD_DIR" ]; then
    cd "$RUST_BUILD_DIR" || exit 1
    log "Rust 构建目录下的 lib:"
    find . -type d -name "lib" 2>/dev/null | head -5 | while read -r libdir; do
        log "  $libdir"
        ls -la "$libdir" 2>/dev/null | head -5 | tee -a "$LOG_FILE"
    done
    cd "$SCRIPT_DIR" || exit 1
fi

# 8. 检查系统信息
log_separator "8. 系统信息"

log "架构: $(uname -m)"
log "操作系统: $(uname -s)"
log "内核版本: $(uname -r)"
log "当前用户: $(whoami)"
log "当前目录: $(pwd)"

# 9. 生成修复建议
log_separator "9. 修复建议"

log "基于诊断结果，建议的修复步骤:"
log ""
log "1. 如果 libc.a 存在但 Rust 找不到:"
log "   - 检查 Rust Makefile 中的环境变量设置"
log "   - 确保 TOOLCHAIN_DIR 正确传递给 Rust 构建"
log "   - 可能需要设置 MUSL_ROOT 或类似的环境变量"
log ""
log "2. 如果不需要 Rust:"
log "   - 在 menuconfig 中禁用 Rust 相关选项"
log "   - 或编辑 .config，设置 CONFIG_PACKAGE_rust is not set"
log ""
log "3. 如果需要 Rust:"
log "   - 检查 feeds/packages/lang/rust/Makefile"
log "   - 确保 Host/Configure 或 Host/Compile 中设置了正确的路径"
log "   - 可能需要添加环境变量: export MUSL_ROOT=\$TOOLCHAIN_DIR"

log ""
log "诊断完成！"
log "完整日志已保存到: $LOG_FILE"
