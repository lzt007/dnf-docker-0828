#!/bin/bash
# ============================================================
# 预下载 CentOS7-DNF 所需组件包到 build/packages/
# 在网络良好的环境下执行一次即可
# ============================================================
set -e

BASE="https://raw.githubusercontent.com/1995chen/dnf_util/refs/heads/main"
PKG_DIR="$(dirname "$0")/packages"

mkdir -p "$PKG_DIR"
cd "$PKG_DIR"

echo "下载 10 个依赖包..."
for f in \
    socat-1.7.4.3.tar.gz \
    Python-2.7.13.tgz \
    setuptools-18.0.1.tgz \
    pip-7.1.0.tar.gz \
    MySQL-shared-compat-5.0.95-1.rhel5.x86_64.rpm \
    MySQL-devel-community-5.0.95-1.rhel5.x86_64.rpm \
    MySQL-client-community-5.0.95-1.rhel5.x86_64.rpm \
    MySQL-server-community-5.0.95-1.rhel5.x86_64.rpm \
    GeoIP-1.4.8.tgz \
    lib.tgz; do
    echo "  -> $f"
    curl -fsSL "$BASE/common_pkgs/$f" -o "$f"
done

echo ""
echo "=========================================="
echo " 下载完成! 文件列表:"
ls -lh "$PKG_DIR"
echo "=========================================="
