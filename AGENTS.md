# PROJECT KNOWLEDGE BASE

> **Generated:** 2026-05-22 | **Commit:** `4d4d531` | **Branch:** `main`

## OVERVIEW

Docker 容器化的 DNF（地下城与勇士/DFO）台服服务端项目。基于 CentOS 5/6/7 镜像，通过环境变量 + 初始化脚本实现一键部署。CI/CD 通过 CircleCI 自动构建并推送至 Docker Hub (`1995chen/dnf`)。

## STRUCTURE

```
./
├── build/                  # Docker 镜像构建上下文（Dockerfiles + 游戏服务端模板数据）
│   ├── Centos{5,6,7}-DNF/  #   各系统版本的 DNF 服务端 Dockerfile
│   ├── Centos5/            #   CentOS 5 基础镜像
│   ├── dnf_data/           #   模板数据：初始化脚本、二进制、Supervisor 配置
│   │   └── home/template/init/  # init.sh, df_game_r, libhook.so, 密钥对, 数据库初始化
│   ├── Standalone-DNF-DB/  #   独立数据库容器 Dockerfile
│   └── 0828-dnfdata/       #   原始服务端文件参考
├── deploy/dnf/
│   ├── docker-compose/     # Docker Compose 部署方案
│   │   ├── basic/          #   单机基础部署
│   │   ├── multi_channel/  #   多频道部署
│   │   ├── multi_server_group/  # 多大区部署（cain/diregie/siroco）
│   │   └── standalone_mysql/    # 独立数据库部署
│   └── k8s-deploy/         # Kubernetes 部署清单（StatefulSet + Service + Storage）
├── doc/                    # 架构图、K8s 部署指南、Linux 初始化文档
├── plugin/                 # 可选插件（dp2/70s2_dp/dnf-console/by-gate）
├── other/                  # 等级补丁、登录器
├── .circleci/config.yml    # CI/CD：staging（分支提交）→ production（tag 触发）
├── build.sh                # 本地构建脚本
└── LICENSE                 # MIT
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| 修改镜像构建逻辑 | `build/Centos{5,6,7}-DNF/Dockerfile` | 三个版本需同步更新 |
| 修改服务端初始化 | `build/dnf_data/home/template/init/init.sh` | 入口脚本，管理所有进程启动 |
| 新增环境变量 | `build/dnf_data/home/template/init/init.sh` + 各 `docker-compose.yaml` | 两处都要加 |
| 数据库初始化 SQL | `build/dnf_data/home/template/init/init_sql.tgz` | 首次启动自动解压执行 |
| 密钥/加密相关 | `build/dnf_data/home/template/init/publickey.pem` + `privatekey.pem` | 网关通信加密 |
| 内存优化 hook | `build/dnf_data/home/template/init/libhook.so` | CPU 占用优化 |
| 修改部署端口 | `deploy/dnf/` 下各 yaml 文件 | 端口映射遵循固定规则（见 CONVENTIONS） |
| CI/CD 流程 | `.circleci/config.yml` | staging 构建+推送，production 额外打 tag |
| 客户端配置 | `README.md` 客户端初始化章节 | 客户端不在本仓库 |

## CONVENTIONS

### 端口映射规则
- MySQL 外部端口: `3000`（非标准 3306）
- Supervisor Web: `2000` → 容器内 `180`
- 网关: `881` (TCP), 登录器: `7600` (TCP)
- 频道端口: `3xx11`(TCP) + `3xx11`(UDP)，其中 xx=频道号
  - 例：频道 11 → 30011(tcp) + 31011(udp)
  - 例：频道 52 → 30052(tcp) + 31052(udp)
- Relay: `7300`(TCP+UDP)
- STUN: `2311-2313`(UDP)

### 镜像版本命名
- 格式：`1995chen/dnf:centos{5,6,7}-{版本号}`
- CI 自动构建：commit SHA 前 7 位作为版本号
- Tag 触发时：tag 名作为版本号，同时更新 `-latest` 标签

### 大区编码
- `cain` = 卡恩, `diregie` = 狄瑞吉, `siroco` = 希洛克
- 多大区部署时通过 `SERVER_GROUP` 环境变量区分

### 环境变量命名
- 全大写蛇形命名：`PUBLIC_IP`, `GM_ACCOUNT`, `DNF_DB_ROOT_PASSWORD`
- 可选变量在 docker-compose 中被注释，需手动取消注释启用

### 初始化脚本执行顺序
1. `init.sh` → 检查环境变量 → 初始化 MySQL → 启动 Supervisor
2. Supervisor 按序启动: MySQL → df_master_r → df_guild_r → df_game_r → df_relay_r → df_bridge_r → df_channel_r → df_stun_r → df_monitor_r

### YAML 风格
- 使用 `version: "2.3"` 的 docker-compose 格式
- 缩进：2 空格
- List 项使用 `- ` 前缀

## ANTI-PATTERNS (THIS PROJECT)

- **不要只改一个 CentOS 版本的 Dockerfile** — CentOS 5/6/7 三版本需同步修改
- **不要硬编码端口** — 端口映射有固定偏移规则（频道号 → 端口号的转换公式）
- **不要删除 `--shm-size=8g`** — Docker 默认 64MB 共享内存不够，删除会导致服务启动失败
- **不要用于商业开服** — README 明确声明仅限学习使用
- **不要删除 `data/` 下的密钥和 PVF 文件** — 升级时只删除其他文件夹

## UNIQUE STYLES

- 项目文档、注释、README 全部使用中文
- 容器日志通过 Supervisor 管理，日志目录结构：`/home/neople/game/log/{服务器名}/`
- 使用 `:Z` 后缀挂载卷（SELinux 兼容）

## COMMANDS

```bash
# 本地构建（需在项目根目录执行）
docker build -f build/Centos5-DNF/Dockerfile -t 1995chen/dnf:centos5-latest .
docker build -f build/Centos6-DNF/Dockerfile -t 1995chen/dnf:centos6-latest .
docker build -f build/Centos7-DNF/Dockerfile -t 1995chen/dnf:centos7-latest .

# 或使用 build.sh
bash build.sh

# Docker Compose 部署（basic 为例）
cd deploy/dnf/docker-compose/basic
mkdir -p data mysql log
docker-compose up -d

# 查看服务端日志
tail -f log/siroco11/Log$(date +%Y%m%d).init

# 验证进程
docker exec dnf ps -ef | grep df_game_r

# 重启服务
docker restart dnf
```

## NOTES

- 服务端依赖 `/data` 卷存储 PVF、密钥、等级补丁等持久化数据
- `init.sh` 首次启动自动初始化 MySQL 数据（2.1.0+）
- 服务端进程占用内存较大（单频道 ~1.3GB），单机建议 ≥8GB 内存 + 充足 swap
- ARM 架构不支持
- 进程管理页面：`http://PUBLIC_IP:2000`（Supervisor Web）
- 频道出"五国"标志（GeoIP Allow Country Code 日志出现 CN/HK/KR/MO/TW）即启动成功，约需 1 分钟
- 升级 2.1.7+ 需删除 `/data/run/start_bridge.sh` 和 `start_channel.sh` 以启用 CLIENT_POOL_SIZE 配置
