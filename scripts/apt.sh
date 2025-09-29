#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# 基础：ffmpeg
apt-get update
apt-get install -y ffmpeg
rm -rf /var/lib/apt/lists/*

case "${PROFILE:-cpu}" in
  cu124)
    echo "apt: cu124"

    # 直接尝试获取 python3.12（Ubuntu 成功；非 Ubuntu 也不会卡死）
    apt-get update
    apt-get install -y software-properties-common ca-certificates gnupg || true
    add-apt-repository -y ppa:deadsnakes/ppa || true
    apt-get update || true

    # 尝试安装 3.12；失败就退回系统 python3

    apt-get install -y python3 python3-venv python3-dev python3-pip build-essential \
      gcc g++ make
    PY=python3
    rm -rf /var/lib/apt/lists/*

    # 保证 pip 可用并升级
    $PY -m ensurepip --upgrade || true
    $PY -m pip install --upgrade pip

    # 镜像源 & 安装 CUDA 12.4 的 torch
    $PY -m pip config set global.index-url http://mirrors.cloud.tencent.com/pypi/simple
    $PY -m pip config set global.trusted-host mirrors.cloud.tencent.com
    $PY -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
    $PY -m pip install onnxruntime-gpu
    ;;
  cpu)
    echo "apt: cpu"
    # CPU 情况下直接用已有 python
    if command -v python3 >/dev/null 2>&1; then PY=python3; else PY=python; fi
    $PY -m pip install --upgrade pip
    $PY -m pip config set global.index-url http://mirrors.cloud.tencent.com/pypi/simple
    $PY -m pip config set global.trusted-host mirrors.cloud.tencent.com
    $PY -m pip install torch torchvision torchaudio onnxruntime
    ;;
  l4t)
    echo "apt: l4t"
    # Jetson/L4T 通常已带 PyTorch，按需补充
    $PY -m pip config set global.index-url http://mirrors.cloud.tencent.com/pypi/simple
    $PY -m pip config set global.trusted-host mirrors.cloud.tencent.com
    $PY -m pip install https://github.com/ultralytics/assets/releases/download/v0.0.0/onnxruntime_gpu-1.20.0-cp310-cp310-linux_aarch64.whl
    if command -v python3 >/dev/null 2>&1; then PY=python3; else PY=python; fi
    ;;
  *)
    echo "apt: default (${PROFILE:-})"
    if command -v python3 >/dev/null 2>&1; then PY=python3; else PY=python; fi
    $PY -m pip install --upgrade pip
    $PY -m pip config set global.index-url http://mirrors.cloud.tencent.com/pypi/simple
    $PY -m pip config set global.trusted-host mirrors.cloud.tencent.com
    $PY -m pip install torch torchvision torchaudio onnxruntime
    ;;
esac

# 项目依赖
$PY -m pip install -r requirements.txt