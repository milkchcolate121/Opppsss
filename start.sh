#!/bin/bash
set -e

echo "🚀 Starting X-UI + nginx reverse proxy..."

export NGINX_PORT=3000

cd /usr/local/x-ui

echo "🔧 Applying panel settings via x-ui CLI & SQLite..."
./x-ui setting -port 2053 -webBasePath /managepanel/ || true

# تنظیم پورت و مسیر ساب‌اسکریپشن در دیتابیس
if [ -f /etc/x-ui/x-ui.db ]; then
    sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '2096' WHERE key = 'subPort';" || true
    sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = '/sub/' WHERE key = 'subPath';" || true
    sqlite3 /etc/x-ui/x-ui.db "UPDATE settings SET value = 'true' WHERE key = 'subEnable';" || true
fi

echo "🔧 Building nginx.conf for fixed port: $NGINX_PORT"
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "▶️  Starting x-ui in background..."
./x-ui &

sleep 2

echo "▶️  Starting nginx in foreground on port $NGINX_PORT..."
nginx -t
exec nginx -g "daemon off;"
