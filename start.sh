#!/bin/bash
set -e

echo "🚀 Starting X-UI + nginx reverse proxy..."

export NGINX_PORT=2053

cd /usr/local/x-ui

echo "🔧 Applying panel settings via x-ui CLI..."
./x-ui setting -port 2053 -webBasePath /managepanel/ || true

echo "▶️  Starting x-ui background process to initialize DB..."
./x-ui &
XUI_PID=$!

sleep 3

# روشن کردن اجباری پورت ۲۰۹۶ و فعال‌سازی ساب در دیتابیس
echo "🔧 Activating Sub Port 2096 in Database..."
if [ -f /etc/x-ui/x-ui.db ]; then
    sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subPort', '2096');"
    sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subPath', '/sub/');"
    sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subEnable', 'true');"
fi

# ری‌استارت x-ui تا پورت ۲۰۹۶ فعال بشه
kill $XUI_PID || true
sleep 1
./x-ui &

echo "🔧 Building nginx.conf..."
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "▶️  Starting nginx in foreground on port $NGINX_PORT..."
nginx -t
exec nginx -g "daemon off;"
