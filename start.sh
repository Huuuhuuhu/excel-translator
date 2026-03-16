#!/bin/bash

# zyt's translator 启动脚本
# 用法: ./start.sh [start|stop|restart|status]

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_FILE="app.py"
PORTS=(8501 8502 8503)
PID_DIR="$APP_DIR/.pids"

cd "$APP_DIR"

# 激活虚拟环境（如果存在）
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
fi

mkdir -p "$PID_DIR"

start() {
    echo "Starting Streamlit instances..."
    for port in "${PORTS[@]}"; do
        if [ -f "$PID_DIR/$port.pid" ] && kill -0 "$(cat "$PID_DIR/$port.pid")" 2>/dev/null; then
            echo "  Port $port: already running (PID $(cat "$PID_DIR/$port.pid"))"
        else
            nohup streamlit run "$APP_FILE" \
                --server.port "$port" \
                --server.headless true \
                --server.address 127.0.0.1 \
                --server.maxUploadSize 50 \
                --browser.gatherUsageStats false \
                > "$PID_DIR/$port.log" 2>&1 &
            echo $! > "$PID_DIR/$port.pid"
            echo "  Port $port: started (PID $!)"
        fi
    done
    echo ""
    echo "All instances started. Use nginx to proxy requests."
    echo "Check logs: $PID_DIR/<port>.log"
}

stop() {
    echo "Stopping Streamlit instances..."
    for port in "${PORTS[@]}"; do
        if [ -f "$PID_DIR/$port.pid" ]; then
            pid=$(cat "$PID_DIR/$port.pid")
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid"
                echo "  Port $port: stopped (PID $pid)"
            else
                echo "  Port $port: not running"
            fi
            rm -f "$PID_DIR/$port.pid"
        else
            echo "  Port $port: no pid file"
        fi
    done
}

status() {
    echo "Streamlit instances status:"
    for port in "${PORTS[@]}"; do
        if [ -f "$PID_DIR/$port.pid" ] && kill -0 "$(cat "$PID_DIR/$port.pid")" 2>/dev/null; then
            echo "  Port $port: running (PID $(cat "$PID_DIR/$port.pid"))"
        else
            echo "  Port $port: stopped"
        fi
    done
}

case "${1:-start}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 2
        start
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
