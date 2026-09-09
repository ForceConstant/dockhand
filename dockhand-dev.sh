#!/usr/bin/env bash
# Dockhand dev helper — start/stop/restart/status/logs
set -euo pipefail

export PATH="/home/node/.local/bin:$PATH"
cd /home/node/.openclaw/workspace/dockhand

PIDFILE=".dev-server.pid"
LOGFILE=".dev-server.log"

case "${1:-start}" in
  start)
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
      echo "Dev server already running (PID $(cat "$PIDFILE"))"
      exit 0
    fi
    echo "Starting Dockhand dev server on :5173..."
    env -u GITHUB_TOKEN -u DOCKHAND_GITHUB_TOKEN -u GITHUB_PERSONAL_ACCESS_TOKEN \
      nohup npx vite dev > "$LOGFILE" 2>&1 &
    echo $! > "$PIDFILE"
    echo "Started (PID $!). Waiting for ready..."
    for i in $(seq 1 30); do
      if curl -sf http://localhost:5173/api/health >/dev/null 2>&1; then
        echo "Ready → http://localhost:5173"
        exit 0
      fi
      sleep 1
    done
    echo "Timeout waiting for server. Check $LOGFILE"
    ;;
  stop)
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
      kill "$(cat "$PIDFILE")" && rm -f "$PIDFILE"
      echo "Dev server stopped."
    else
      echo "Not running."
      rm -f "$PIDFILE"
    fi
    ;;
  restart)
    $0 stop; sleep 1; $0 start
    ;;
  status)
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
      echo "Running (PID $(cat "$PIDFILE")) → http://localhost:5173"
    else
      echo "Not running."
    fi
    ;;
  logs)
    tail -f "$LOGFILE"
    ;;
  test)
    env -u GITHUB_TOKEN -u DOCKHAND_GITHUB_TOKEN -u GITHUB_PERSONAL_ACCESS_TOKEN \
      bun test "${2:-tests/}"
    ;;
  build)
    env -u GITHUB_TOKEN -u DOCKHAND_GITHUB_TOKEN -u GITHUB_PERSONAL_ACCESS_TOKEN \
      npx vite build
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status|logs|test|build}"
    exit 1
    ;;
esac
