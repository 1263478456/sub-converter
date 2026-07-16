#!/bin/sh
set -e

# ---- 设置架构相关的库路径 ----
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

# ---- 启动 subconverter（后台） ----
echo "Starting subconverter..."
/usr/bin/subconverter -f "$CONF" &
SC_PID=$!

# ---- 等待 subconverter 就绪 ----
echo "Waiting for subconverter to be ready..."
for i in $(seq 1 30); do
  if curl -sf http://127.0.0.1:25500/version > /dev/null 2>&1; then
    echo "subconverter is ready!"
    break
  fi
  sleep 1
done

# ---- 启动 nginx（前台） ----
echo "Starting nginx..."
nginx -g "daemon off;" &
NGINX_PID=$!

# ---- 信号处理：退出时停止所有进程 ----
trap "kill $SC_PID $NGINX_PID 2>/dev/null; exit 0" SIGTERM SIGINT

# ---- 等待任意子进程退出 ----
wait -n $SC_PID $NGINX_PID 2>/dev/null || true

# 如果有进程退出，清理并退出
kill $SC_PID $NGINX_PID 2>/dev/null || true
exit 1
