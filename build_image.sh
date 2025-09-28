#!/bin/bash

# build_image.sh
IMG_NAME="fwhisper_server"

ARCH=$(uname -m)

case "$ARCH" in
  aarch64)
    if [[ -f "/etc/nv_tegra_release" ]] || grep -qi "nvidia" /proc/device-tree/model 2>/dev/null; then
      ARCH_TAG="jet"
      BASE_IMAGE="dustynv/l4t-pytorch:r36.4.0"
    else
      ARCH_TAG="arm"
    fi
    ;;
  x86_64)
    ARCH_TAG="amd"
    ;;
  *)
    ARCH_TAG="unknown"
    ;;
esac


while [[ $# -gt 0 ]]; do
  case $1 in
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

case "$PROFILE" in
  cu124)
    PROFILE_TAG="${ARCH_TAG}_cu124"
    BASE_IMAGE="nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04"
    ;;
  cpu)
    PROFILE_TAG="${ARCH_TAG}"
    BASE_IMAGE="python:3.12.11"
    ;;
  l4t)
    PROFILE_TAG="${ARCH_TAG}_l4t"
    BASE_IMAGE="dustynv/l4t-pytorch:r36.4.0"
    ;;
  *)
    PROFILE_TAG="${ARCH_TAG}"
    BASE_IMAGE="python:3.12.11"
    ;;
esac

DATE=$(date +%Y%m%d)

# 检查 version.txt
VERSION=$(curl -sI https://github.com/Evil0ctal/Fast-Powerful-Whisper-AI-Services-API/releases/latest \
  | grep -i '^location:' | awk -F/ '{print $NF}' | tr -d '\r' | sed -E 's/^[Vv]//; s/[^0-9.].*$//')

TAG="${PROFILE_TAG}_${VERSION}_${DATE}"

echo $TAG

docker build \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg ARCH_TAG="${ARCH_TAG}" \
    --build-arg TAG="${TAG}" \
    --build-arg PROFILE="{$PROFILE}" \
    -t swr.cn-southwest-2.myhuaweicloud.com/ictrek/${IMG_NAME}:${TAG} .

docker push swr.cn-southwest-2.myhuaweicloud.com/ictrek/${IMG_NAME}:${TAG}

