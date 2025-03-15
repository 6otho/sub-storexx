FROM alpine

# 设置工作目录
WORKDIR /opt/app

# 安装 nodejs、curl、tzdata 和 unzip（解压工具）
RUN apk add --no-cache nodejs curl tzdata unzip

# 设置时区为 Asia/Shanghai
ENV TIME_ZONE=Asia/Shanghai 
RUN cp /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone
# 如有需要可以删除 tzdata，注释掉下面命令
# RUN apk del tzdata

# 下载 Sub-Store 后端文件
ADD https://github.com/sub-store-org/Sub-Store/releases/latest/download/sub-store.bundle.js /opt/app/sub-store.bundle.js

# 下载前端压缩包
ADD https://github.com/sub-store-org/Sub-Store-Front-End/releases/latest/download/dist.zip /opt/app/dist.zip

# 解压前端压缩包，并将目录重命名为 frontend，然后删除压缩包
RUN unzip dist.zip; mv dist frontend; rm dist.zip

# 【关键步骤】将前端入口文件复制到容器根目录，确保 genezio 能找到 /index.html 与 /index.js
RUN cp /opt/app/frontend/index.html / && cp /opt/app/frontend/index.js /

# 下载 http-meta 相关文件
ADD https://github.com/xream/http-meta/releases/latest/download/http-meta.bundle.js /opt/app/http-meta.bundle.js
ADD https://github.com/xream/http-meta/releases/latest/download/tpl.yaml /opt/app/http-meta/tpl.yaml

# 下载并解压 mihomo 工具
RUN version=$(curl -s -L --connect-timeout 5 --max-time 10 --retry 2 --retry-delay 0 --retry-max-time 20 'https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt') && \
    arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64-compatible/) && \
    url="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/mihomo-linux-$arch-$version.gz" && \
    curl -s -L --connect-timeout 5 --max-time 10 --retry 2 --retry-delay 0 --retry-max-time 20 "$url" -o /opt/app/http-meta/http-meta.gz && \
    gunzip /opt/app/http-meta/http-meta.gz && \
    rm -rf /opt/app/http-meta/http-meta.gz

# 修改文件权限
RUN chmod 777 -R /opt/app

# 容器启动时运行的命令
CMD mkdir -p /opt/app/data; cd /opt/app/data; \
  META_FOLDER=/opt/app/http-meta HOST=:: node /opt/app/http-meta.bundle.js > /opt/app/data/http-meta.log 2>&1 & echo "HTTP-META is running..."; \
  SUB_STORE_BACKEND_API_HOST=:: SUB_STORE_FRONTEND_HOST=:: SUB_STORE_FRONTEND_PORT=3001 SUB_STORE_FRONTEND_PATH=/opt/app/frontend SUB_STORE_DATA_BASE_PATH=/opt/app/data node /opt/app/sub-store.bundle.js
