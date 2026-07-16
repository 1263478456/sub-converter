# sc-commit: init
# subweb-commit: init
# ============================================================
#  All-in-One: subconverter + sub-web + Nginx
#  基于官方 subconverter 镜像，添加 Nginx + 前端 + 前端补丁
# ============================================================

# ---- Stage 1: 获取 sub-web 前端编译产物 ----
FROM careywong/subweb:latest AS frontend

# ---- Stage 2: 基于官方 subconverter 镜像构建 ----
FROM tindy2013/subconverter:latest

LABEL maintainer="lyb69177116"
LABEL description="subconverter + sub-web All-in-One"
LABEL org.opencontainers.image.source="https://github.com/1263478456/sub-converter"

# ---- 安装 Nginx + Supervisor ----
RUN apk add --no-cache nginx supervisor

# ---- 拷贝前端静态文件 ----
COPY --from=frontend /usr/share/nginx/html/ /usr/share/nginx/html/

# ---- 把配置文件放到二进制旁边 ----
# subconverter 启动时 chdir 到自己所在目录（/usr/bin/），在那里找配置文件
RUN cp /base/pref.example.yml /usr/bin/pref.yml
RUN cp -r /base/base /usr/bin/base

# ---- 注入前端补丁 ----
COPY patch.js /usr/share/nginx/html/patch.js
RUN sed -i 's|</head>|<script src="/patch.js"></script></head>|' \
    /usr/share/nginx/html/index.html

# ---- Nginx 配置 ----
COPY nginx.conf /etc/nginx/nginx.conf

# ---- Supervisor 配置 ----
COPY supervisord.conf /etc/supervisord.conf

ENTRYPOINT []

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -sf http://localhost:80/version || exit 1

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
