#!/bin/bash
# ============================================================
# DNF CentOS7 服务端镜像打包脚本
# 用法: bash build_centos7.sh [镜像标签]
# ============================================================
set -e

PROJECT_DIR="/home/dnf"
DOCKERFILE="$PROJECT_DIR/build/Centos7-DNF/Dockerfile"
IMAGE_NAME="1995chen/dnf"

# 标签：默认用时间戳，也可手动指定
TAG="${1:-centos7-$(date +%Y%m%d-%H%M%S)}"

echo "=========================================="
echo " DNF CentOS7 镜像构建"
echo " 项目目录: $PROJECT_DIR"
echo " 镜像标签: $IMAGE_NAME:$TAG"
echo "=========================================="

# 检查 Dockerfile 是否存在
if [ ! -f "$DOCKERFILE" ]; then
    echo "错误: Dockerfile 不存在: $DOCKERFILE"
    exit 1
fi

# 检查 docker 是否可用
if ! command -v docker &>/dev/null; then
    echo "错误: docker 未安装或不在 PATH 中"
    exit 1
fi

# ============================================================
# 检查 build/packages 下的依赖文件是否齐全
# ============================================================
REQUIRED_PACKAGES=(
    "socat-1.7.4.3.tar.gz"
    "Python-2.7.13.tgz"
    "setuptools-18.0.1.tgz"
    "pip-7.1.0.tar.gz"
    "MySQL-shared-compat-5.0.95-1.rhel5.x86_64.rpm"
    "MySQL-devel-community-5.0.95-1.rhel5.x86_64.rpm"
    "MySQL-client-community-5.0.95-1.rhel5.x86_64.rpm"
    "MySQL-server-community-5.0.95-1.rhel5.x86_64.rpm"
    "GeoIP-1.4.8.tgz"
    "lib.tgz"
)

PACKAGES_DIR="$PROJECT_DIR/build/packages"

echo ""
echo "[1/3] 检查依赖包..."

MISSING=()
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if [ ! -f "$PACKAGES_DIR/$pkg" ]; then
        MISSING+=("$pkg")
        echo "  [缺少] $pkg"
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo "=========================================="
    echo " 检测到 ${#MISSING[@]} 个依赖包缺失，"
    echo " 正在调用 download_packages.sh 下载..."
    echo "=========================================="
    echo ""
    echo "提示: 必须将 download_packages.sh 中要下载的文件"
    echo "      放入 $PACKAGES_DIR 目录下才能完成构建。"
    echo ""
    bash "$PROJECT_DIR/build/download_packages.sh"

    # 再次检查是否下载成功
    STILL_MISSING=()
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if [ ! -f "$PACKAGES_DIR/$pkg" ]; then
            STILL_MISSING+=("$pkg")
        fi
    done
    if [ ${#STILL_MISSING[@]} -gt 0 ]; then
        echo ""
        echo "=========================================="
        echo " 错误: 仍有 ${#STILL_MISSING[@]} 个依赖包缺失:"
        for pkg in "${STILL_MISSING[@]}"; do
            echo "   - $pkg"
        done
        echo ""
        echo " 请确保 download_packages.sh 中列出的文件"
        echo " 已放入 $PACKAGES_DIR 目录下，然后重新执行构建。"
        echo "=========================================="
        exit 1
    fi
    echo ""
    echo "所有依赖包下载完成。"
else
    echo "  所有依赖包已就绪。"
fi

# 开始构建
echo ""
echo "[2/3] 开始构建镜像..."
docker build --no-cache\
    -f "$DOCKERFILE" \
    -t "$IMAGE_NAME:$TAG" \
    "$PROJECT_DIR"

echo ""
echo "[3/3] 构建完成，镜像信息:"
docker images "$IMAGE_NAME:$TAG"

echo ""
echo "=========================================="
echo " 构建成功!"
echo " 镜像: $IMAGE_NAME:$TAG"
echo ""
echo " ！！！先给容器建立一个名为dnf-server，192.168.200.x的虚拟网段！！！"
echo " 启动示例:"
echo " docker run -d \\"
echo "   -e PUBLIC_IP=192.168.199.128 \\"
echo "   -e SERVER_GROUP_DB=cain \\"
echo "   -e SERVER_GROUP=3 \\"
echo "   -e WEB_USER=root \\"
echo "   -e WEB_PASS=123456 \\"
echo "   -e DNF_DB_ROOT_PASSWORD=123456 \\"
echo "   -e DNF_DB_GAME_PASSWORD='uu5!^%jg' \\"
echo "   -e GM_ACCOUNT=gmuser \\"
echo "   -e GM_PASSWORD=gmpass \\"
echo "   -v /home/server/mysql:/var/lib/mysql \\"
echo "   -v /home/server/neople:/home/neople \\"
echo "   -v /home/server/root:/root \\"
echo "   -v /home/server/data:/data \\"
echo "   -v /home/server/log:/home/neople/game/log \\"
echo "   -p 8088:8088 -p 18080:80 -p 2000:180 \\"
echo "   -p 3306:3306/tcp -p 7600:7600/tcp -p 881:881/tcp \\"
echo "   -p 7101:7101/tcp -p 7101:7101/udp \\"
echo "   -p 30011:30011 -p 31011:31011 \\"
echo "   -p 30052:30052 -p 31052:31052 \\"
echo "   -p 10011:30011/tcp -p 11011:31011/udp \\"
echo "   -p 10052:30052/tcp -p 11052:31052/udp \\"
echo "   -p 7300:7300/tcp -p 7300:7300/udp \\"
echo "   -p 2311-2313:2311-2313/udp \\"
echo "   --cap-add=NET_ADMIN --hostname=dnf \\"
echo "   --cpus=4 --memory=8g --memory-swap=-1 --shm-size=8g \\"
echo "   --name=dnf-0828 \\"
echo "   --network=dnf-network --ip 192.168.200.131 \\"
echo "   $IMAGE_NAME:$TAG"
echo "=========================================="
