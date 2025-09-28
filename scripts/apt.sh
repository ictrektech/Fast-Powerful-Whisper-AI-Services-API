#!/bin/bash

apt update && apt install ffmpeg

pip3 config set global.index-url http://mirrors.cloud.tencent.com/pypi/simple
pip3 config set global.trusted-host mirrors.cloud.tencent.com

case "$PROFILE" in
  cu124)
    echo "apt: cu124"
    pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
    ;;
  cpu)
    echo "apt: cpu"
    pip install torch torchvision torchaudio
    ;;
  l4t)
    echo "apt: l4t"
  *)
    ;;
esac

pip3 install -r requirements.txt