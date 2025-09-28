ARG BASE_IMAGE="swr.cn-southwest-2.myhuaweicloud.com/ictrek/ubuntu:amd_22.04"
FROM ${BASE_IMAGE}

# 提升成环境变量的构建参数
ARG ARCH_TAG="amd"
ENV ARCH_TAG=${ARCH_TAG}

ARG PROFILE="cpu"
ENV PROFILE=${PROFILE}


RUN chmod 1777 /tmp && apt-get update && apt-get install -y \
    curl wget ca-certificates \
    tar \
    &&  update-ca-certificates && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/whisper
COPY . /root/whisper/

WORKDIR /root/whisper

RUN PROFILE=$PROFILE bash scripts/apt.sh

CMD ["python3", "start.py"]