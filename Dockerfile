# extended-digest: init
# ============================================================
#  SubConverter-Extended + 自定义前端 + Nginx
#  nginx 用 musl 跑，subconverter 用 glibc 跑
# ============================================================

# ---- Stage 1: 从干净 Alpine 提取 nginx + musl 运行时 ----
FROM alpine:3.20 AS nginx-src
RUN apk add --no-cache nginx pcre

# ---- Stage 2: 构建 curl 工具（独立安装目录，便于整体拷贝） ----
FROM alpine:3.20 AS curl-src
RUN apk add --no-cache curl ca-certificates \
    && mkdir -p /out/usr/bin /out/usr/lib /out/etc/ssl/certs /out/etc \
    && cp -a /usr/bin/curl /out/usr/bin/ \
    && cp -a /usr/lib/libcurl*.so* /out/usr/lib/ \
    && cp -a /usr/lib/libnghttp2*.so* /out/usr/lib/ 2>/dev/null || true \
    && cp -a /usr/lib/libbrotlidec*.so* /out/usr/lib/ 2>/dev/null || true \
    && cp -a /usr/lib/libbrotlicommon*.so* /out/usr/lib/ 2>/dev/null || true \
    && cp -a /usr/lib/libpsl*.so* /out/usr/lib/ 2>/dev/null || true \
    && cp -a /lib/libz.so* /out/usr/lib/ \
    && cp -a /lib/libssl.so* /out/usr/lib/ \
    && cp -a /lib/libcrypto.so* /out/usr/lib/ \
    && cp -a /lib/ld-musl-x86_64.so.1 /out/lib/ \
    && cp -a /etc/ssl/certs/ca-certificates.crt /out/etc/ssl/certs/ \
    && cp -a /etc/ca-certificates /out/etc/ 2>/dev/null || true

# ---- Stage 3: 基于 Extended 镜像 ----
FROM aethersailor/subconverter-extended:latest

LABEL maintainer="lyb69177116"
LABEL description="SubConverter-Extended + lightweight frontend"
LABEL org.opencontainers.image.source="https://github.com/1263478456/sub-converter"

# ---- 从 Stage 1 拷贝 nginx + musl 运行时 ----
COPY --from=nginx-src /usr/sbin/nginx /opt/nginx/usr/sbin/nginx
COPY --from=nginx-src /etc/nginx /opt/nginx/etc/nginx
COPY --from=nginx-src /usr/lib/nginx /opt/nginx/usr/lib/nginx
COPY --from=nginx-src /usr/share/nginx /opt/nginx/usr/share/nginx
COPY --from=nginx-src /lib/ld-musl-x86_64.so.1 /opt/nginx/lib/ld-musl-x86_64.so.1
COPY --from=nginx-src /usr/lib/libpcre.so.1 /opt/nginx/usr/lib/libpcre.so.1
COPY --from=nginx-src /lib/libz.so.1 /opt/nginx/lib/libz.so.1
COPY --from=nginx-src /lib/libcrypto.so.3 /opt/nginx/lib/libcrypto.so.3
COPY --from=nginx-src /lib/libssl.so.3 /opt/nginx/lib/libssl.so.3

# ---- 从 Stage 2 拷贝 curl 工具链（整体目录，含所有依赖） ----
COPY --from=curl-src /out/ /opt/curl/

# ---- 创建目录 ----
RUN mkdir -p /var/log/nginx /run/nginx /tmp/nginx /var/lib/nginx/tmp /var/lib/nginx/logs

# ---- curl 包装脚本 ----
RUN printf '#!/bin/sh\n\
export SSL_CERT_FILE=/opt/curl/etc/ssl/certs/ca-certificates.crt\n\
export SSL_CERT_DIR=/opt/curl/etc/ssl/certs\n\
exec /opt/curl/lib/ld-musl-x86_64.so.1 --library-path /opt/curl/lib /opt/curl/usr/bin/curl "$@"\n\
' > /usr/local/bin/curl && chmod +x /usr/local/bin/curl

# ---- nginx 包装脚本 ----
RUN printf '#!/bin/sh\n\
exec /opt/nginx/lib/ld-musl-x86_64.so.1 --library-path /opt/nginx/lib:/opt/nginx/usr/lib /opt/nginx/usr/sbin/nginx -c /opt/nginx/etc/nginx/nginx.conf "$@"\n\
' > /usr/local/bin/nginx && chmod +x /usr/local/bin/nginx

# ---- 自定义前端 ----
COPY index.html /opt/nginx/usr/share/nginx/html/index.html

# ---- Nginx 配置 ----
COPY nginx.conf /opt/nginx/etc/nginx/nginx.conf

# ---- 启动脚本 ----
COPY start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT []

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -sf http://localhost:80/version || exit 1

EXPOSE 80

CMD ["/start.sh"]
