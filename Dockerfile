# sc-commit: init
# ============================================================
#  SubConverter-Extended + 自定义前端 + Nginx
#  基于 Extended 镜像，用 shell 脚本管理进程（不依赖 supervisor/Python）
# ============================================================

# ---- Stage 1: 从干净 Alpine 提取 nginx ----
FROM alpine:3.20 AS nginx-src
RUN apk add --no-cache nginx && \
    mkdir -p /out && \
    cp -a /usr/sbin/nginx /out/ && \
    cp -a /etc/nginx /out/etc_nginx && \
    cp -a /usr/lib/nginx /out/lib_nginx && \
    cp -a /var/lib/nginx /out/var_lib_nginx && \
    cp -a /usr/share/nginx/html /out/html

# ---- Stage 2: 基于 Extended 镜像 ----
FROM aethersailor/subconverter-extended:latest

LABEL maintainer="lyb69177116"
LABEL description="SubConverter-Extended + lightweight frontend"
LABEL org.opencontainers.image.source="https://github.com/1263478456/sub-converter"

# 从 Stage 1 拷贝 nginx
COPY --from=nginx-src /out/nginx /usr/sbin/nginx
COPY --from=nginx-src /out/etc_nginx /etc/nginx
COPY --from=nginx-src /out/lib_nginx /usr/lib/nginx
COPY --from=nginx-src /out/var_lib_nginx /var/lib/nginx
COPY --from=nginx-src /out/html /usr/share/nginx/html

RUN mkdir -p /var/log/nginx /run/nginx /tmp/nginx

# ---- 自定义前端 ----
COPY index.html /usr/share/nginx/html/index.html

# ---- Nginx 配置 ----
COPY nginx.conf /etc/nginx/nginx.conf

# ---- 启动脚本 ----
COPY start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT []

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -sf http://localhost:80/version || exit 1

EXPOSE 80

CMD ["/start.sh"]
