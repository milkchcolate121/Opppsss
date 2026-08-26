#!/bin/bash
set -e

echo "🚀 Starting X-UI + nginx reverse proxy..."

export NGINX_PORT=3000

cd /usr/local/x-ui

echo "🔧 Applying initial CLI settings..."
./x-ui setting -port 2053 -webBasePath /managepanel/ || true

echo "▶️  Starting x-ui background process to initialize DB..."
./x-ui &
XUI_PID=$!

# ۳ ثانیه صبر می‌کنیم تا فایل دیتابیس ساخته شود
sleep 3

echo "🔧 Injecting Subscription settings into SQLite database..."
if [ -f /etc/x-ui/x-ui.db ]; then
    sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subPort', '2096');"
    sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subPath', '/sub/');"
    sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subEnable', 'true');"
fi

# ری‌استارت پنل برای اعمال تنظیمات جدید دیتابیس
kill $XUI_PID || true
sleep 1
./x-ui &

echo "🔧 Building nginx.conf..."
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "▶️  Starting nginx..."
nginx -t
exec nginx -g "daemon off;"
