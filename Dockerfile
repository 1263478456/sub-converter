# sc-commit: init
# ============================================================
#  All-in-One: subconverter + 自定义前端 + Nginx
#  前端为纯 HTML/JS，无任何框架依赖
# ============================================================

# ---- Stage 1: 基于官方 subconverter 镜像 ----
FROM tindy2013/subconverter:latest

LABEL maintainer="lyb69177116"
LABEL description="subconverter + lightweight frontend"
LABEL org.opencontainers.image.source="https://github.com/1263478456/sub-converter"

RUN apk add --no-cache nginx supervisor

# ---- 自定义前端 ----
COPY index.html /usr/share/nginx/html/index.html

# ---- 配置文件放到二进制旁边 ----
RUN cp /base/pref.example.yml /usr/bin/pref.yml && \
    cp -r /base/base /usr/bin/base && \
    cp -r /base/snippets /usr/bin/snippets && \
    cp -r /base/config /usr/bin/config && \
    cp -r /base/profiles /usr/bin/profiles && \
    cp -r /base/rules /usr/bin/rules

# ---- Nginx 配置 ----
COPY nginx.conf /etc/nginx/nginx.conf

# ---- Supervisor 配置 ----
COPY supervisord.conf /etc/supervisord.conf

ENTRYPOINT []

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -sf http://localhost:80/version || exit 1

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
