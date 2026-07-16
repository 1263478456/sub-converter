# sc-commit: init
# subweb-commit: init
# ============================================================
#  All-in-One: subconverter + sub-web + Nginx
#  从上游源码构建，自动跟踪最新代码
# ============================================================

# ---- Stage 1: 从源码编译 subconverter ----
FROM alpine:3.20 AS builder

RUN apk add --no-cache \
    git cmake make g++ \
    curl-dev yaml-cpp-dev \
    zlib-dev libevent-dev \
    pcre2-dev brotli-dev

RUN git clone --depth=1 https://github.com/tindy2013/subconverter.git /src

WORKDIR /src
RUN cmake -DCMAKE_BUILD_TYPE=Release . && \
    make -j$(nproc) && \
    strip subconverter

# ---- Stage 2: 获取 sub-web 前端编译产物 ----
FROM careywong/subweb:latest AS frontend

# ---- Stage 3: 最终镜像 ----
FROM nginx:alpine

LABEL maintainer="lyb69177116"
LABEL description="subconverter + sub-web All-in-One"
LABEL org.opencontainers.image.source="https://github.com/1263478456/sub-converter"

RUN apk add --no-cache \
    curl \
    wget \
    supervisor \
    libc6-compat \
    libstdc++ \
    yaml-cpp \
    libevent \
    pcre2 \
    brotli

# ---- 从 builder 拷贝编译产物 ----
COPY --from=builder /src/subconverter /opt/subconverter/subconverter
COPY --from=builder /src/base/ /opt/subconverter/base/
RUN chmod +x /opt/subconverter/subconverter

# ---- 拷贝前端静态文件 ----
COPY --from=frontend /usr/share/nginx/html/ /usr/share/nginx/html/

# ---- 拷贝自定义配置（覆盖默认） ----
COPY subconverter/pref.ini /opt/subconverter/base/pref.ini
COPY subconverter/config/ /opt/subconverter/base/config/

# ---- Nginx 配置 ----
COPY nginx.conf /etc/nginx/nginx.conf

# ---- Supervisor 配置 ----
COPY supervisord.conf /etc/supervisord.conf

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -sf http://localhost:80/version || exit 1

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
