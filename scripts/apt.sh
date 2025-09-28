#!/bin/bash

apt update && apt install ffmpeg



case "$PROFILE" in
  cu124)
    echo "apt: cu124"
    apt install -y python3.12 python3-venv python3-dev python3-pip
    python3.12 -m ensurepip
    python3.12 -m pip install --upgrade pip
    pip3 config set global.index-url http://mirrors.cloud.tencent.com/pypi/simple
    pip3 config set global.trusted-host mirrors.cloud.tencent.com
    pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
    ;;
  cpu)
    echo "apt: cpu"
    pip3 config set global.index-url http://mirrors.cloud.tencent.com/pypi/simple
    pip3 config set global.trusted-host mirrors.cloud.tencent.com
    pip install torch torchvision torchaudio
    ;;
  l4t)
    echo "apt: l4t"
    ;;
  *)
    ;;
esac

pip3 install -r requirements.txt