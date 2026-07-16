#!/bin/bash
# =============================================================
#  Sub-Converter 启动脚本
#  - nginx 通过 /usr/local/bin/nginx 包装脚本运行（自动使用 musl 链接器）
#  - subconverter 使用 Extended 镜像自带的二进制
# =============================================================

# ---- 设置架构相关的库路径（供 subconverter 使用） ----
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) LIB_ARCH="x86_64-linux-gnu" ;;
  aarch64|arm64) LIB_ARCH="aarch64-linux-gnu" ;;
  *) LIB_ARCH="" ;;
esac
if [ -n "$LIB_ARCH" ]; then
  export LD_LIBRARY_PATH="/lib/${LIB_ARCH}:/usr/lib/${LIB_ARCH}:/lib64:/usr/lib"
else
  export LD_LIBRARY_PATH="/lib:/usr/lib:/lib64:/usr/lib"
fi

# ---- 准备配置文件 ----
CONF="${PREF_PATH:-/base/pref.toml}"
if [ ! -f "$CONF" ] && [ -f /base/pref.example.toml ]; then
  cp /base/pref.example.toml "$CONF"
fi

# ---- 信号处理 ----
cleanup() {
    echo "[start.sh] Shutting down..."
    kill $SC_PID $NGINX_PID 2>/dev/null || true
    wait $SC_PID $NGINX_PID 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT

# ---- 启动 subconverter（后台） ----
echo "[start.sh] Starting subconverter..."
/usr/bin/subconverter -f "$CONF" &
SC_PID=$!

# ---- 等待 subconverter 就绪 ----
echo "[start.sh] Waiting for subconverter to be ready on :25500..."
for i in $(seq 1 30); do
  if curl -sf http://127.0.0.1:25500/version > /dev/null 2>&1; then
    echo "[start.sh] Subconverter is ready! (took ${i}s)"
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "[start.sh] WARNING: Subconverter did not become ready in 30s, continuing anyway..."
  fi
  sleep 1
done

# ---- 启动 nginx（daemon off = 前台运行，用 & 放入后台由 wait 管理） ----
echo "[start.sh] Starting nginx..."
/usr/local/bin/nginx -g "daemon off;" &
NGINX_PID=$!

echo "[start.sh] All services started. Nginx PID=$NGINX_PID, Subconverter PID=$SC_PID"

# ---- 等待任意子进程退出 ----
wait -n $SC_PID $NGINX_PID 2>/dev/null || true
echo "[start.sh] A child process exited, shutting down..."
cleanup
