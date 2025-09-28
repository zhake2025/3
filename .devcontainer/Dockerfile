# 基于 Ubuntu 的 Flutter 开发环境 Dockerfile
FROM ubuntu:24.04

# 安装基本依赖
RUN apt-get update && apt-get install -y \
    git curl unzip xz-utils zip libglu1-mesa openjdk-17-jdk wget clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev && \
    rm -rf /var/lib/apt/lists/*

# 设置环境变量
ENV USER_NAME=codespace
ENV HOME=/home/$USER_NAME
ENV FLUTTER_HOME=$HOME/flutter
ENV PATH=$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH

# 克隆 Flutter SDK（stable channel）
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME

# 预下载 Flutter 依赖
RUN $FLUTTER_HOME/bin/flutter --version && $FLUTTER_HOME/bin/flutter precache

# 创建默认工作目录
WORKDIR /workspaces/3

# 切换到非 root 用户（Codespaces 默认用户）
RUN useradd -ms /bin/bash $USER_NAME && chown -R $USER_NAME:$USER_NAME $HOME && chown -R $USER_NAME:$USER_NAME /workspaces/3
USER $USER_NAME

# 终端默认进入工作区
CMD ["bash"]
