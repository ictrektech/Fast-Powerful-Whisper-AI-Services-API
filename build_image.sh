#!/usr/bin/env bash
set -euo pipefail

# build_image.sh
IMG_NAME="fwhisper_server"

ARCH=$(uname -m)
ARCH_TAG="unknown"
BASE_IMAGE=""
PROFILE="${PROFILE:-cpu}"
NO_CACHE="false"

# ---------- 架构探测 ----------
case "$ARCH" in
  aarch64)
    if [[ -f "/etc/nv_tegra_release" ]] || grep -qi "nvidia" /proc/device-tree/model 2>/dev/null; then
      ARCH_TAG="jet"
      BASE_IMAGE="dustynv/l4t-pytorch:r36.4.0"
    else
      ARCH_TAG="arm"
    fi
    ;;
  x86_64) ARCH_TAG="amd" ;;
  *)      ARCH_TAG="unknown" ;;
esac

# ---------- 参数解析 ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:-}"; [[ -z "$PROFILE" ]] && { echo "ERROR: --profile 需要一个值"; exit 1; }
      shift 2
      ;;
    --no-cache)
      NO_CACHE="true"; shift ;;
    *)
      echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ---------- 根据 PROFILE 选择 ----------
case "$PROFILE" in
  cu124)
    PROFILE_TAG="${ARCH_TAG}_cu124"
    BASE_IMAGE="${BASE_IMAGE:-nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04}"
    ;;
  cpu)
    PROFILE_TAG="${ARCH_TAG}"
    BASE_IMAGE="${BASE_IMAGE:-python:3.12.11}"
    ;;
  l4t)
    PROFILE_TAG="${ARCH_TAG}_l4t"
    BASE_IMAGE="dustynv/l4t-pytorch:r36.4.0"
    ;;
  *)
    echo "WARN: 未知 PROFILE='${PROFILE}', 使用 cpu 默认"
    PROFILE="cpu"
    PROFILE_TAG="${ARCH_TAG}"
    BASE_IMAGE="${BASE_IMAGE:-python:3.12.11}"
    ;;
esac

DATE=$(date +%Y%m%d)

# ---------- 获取版本并彻底去掉换行/空白 ----------
# 1) 拿到重定向 Location 里的 tag
# 2) 去掉 CR
# 3) 只保留数字和点
VERSION=$(curl -s https://api.github.com/repos/Evil0ctal/Fast-Powerful-Whisper-AI-Services-API/releases/latest \
  | jq -r .tag_name \
  | sed 's/^v//' \
  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
: "${VERSION:=0.0.0}"

# 再做一次保险：删掉所有空白字符（包括残留的 \n \t）
VERSION=$(printf '%s' "$VERSION" | tr -d '[:space:]')

TAG="${PROFILE_TAG}_${VERSION}_${DATE}"
# 同样保证 TAG 不含空白
TAG=$(printf '%s' "$TAG" | tr -d '[:space:]')

IMAGE="swr.cn-southwest-2.myhuaweicloud.com/ictrek/${IMG_NAME}:${TAG}"

echo "ARCH_TAG=${ARCH_TAG}"
echo "PROFILE=${PROFILE}"
echo "BASE_IMAGE=${BASE_IMAGE}"
echo "VERSION=${VERSION}"
echo "TAG=${TAG}"
echo "NO_CACHE=${NO_CACHE}"
echo

# ---------- 构建 ----------
BUILD_CMD=(docker build)
[[ "${NO_CACHE}" == "true" ]] && BUILD_CMD+=("--no-cache")
BUILD_CMD+=(
  "--build-arg" "BASE_IMAGE=${BASE_IMAGE}"
  "--build-arg" "ARCH_TAG=${ARCH_TAG}"
  "--build-arg" "TAG=${TAG}"
  "--build-arg" "PROFILE=${PROFILE}"
  "-t" "${IMAGE}"
  "."
)

echo "+ ${BUILD_CMD[*]}"
"${BUILD_CMD[@]}"

echo "+ docker push ${IMAGE}"
docker push "${IMAGE}"