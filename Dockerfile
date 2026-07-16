# sc-commit: init
# subweb-commit: init
# ============================================================
#  All-in-One: subconverter + sub-web + Nginx
#  从官方镜像提取二进制，从前端镜像提取静态文件
# ============================================================

# ---- Stage 1: 从官方镜像获取 subconverter 二进制 ----
FROM tindy2013/subconverter:latest AS subconverter

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
    pcre2 \
    libcurl \
    yaml-cpp

# ---- 从 subconverter 官方镜像拷贝 ----
COPY --from=subconverter /usr/bin/subconverter /opt/subconverter/subconverter
COPY --from=subconverter /base/ /opt/subconverter/base/
RUN chmod +x /opt/subconverter/subconverter

# ---- 拷贝前端静态文件 ----
COPY --from=frontend /usr/share/nginx/html/ /usr/share/nginx/html/

# ---- 修正前端默认后端地址 ----
# sub-web 默认指向 api.wcc.best（作者公共后端）
# 替换为空，使后端地址变为 /sub?（相对路径，走 Nginx 代理到本地后端）
RUN find /usr/share/nginx/html -name '*.js' -exec \
    sed -i 's|https://api\.wcc\.best||g' {} \;

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
