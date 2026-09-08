#!/bin/bash

set -e

echo "======================================"
echo "       Chicken Sync Installer"
echo "======================================"
echo

if [ "$EUID" -ne 0 ]; then
    echo "请使用 root 运行"
    exit 1
fi

REPO_RAW="https://raw.githubusercontent.com/你的用户名/chicken-sync/main"

INSTALL_DIR="/opt/chicken-sync"
CONFIG_FILE="/etc/chicken-sync.conf"

echo "[1/6] 创建目录..."

mkdir -p "$INSTALL_DIR"

echo "[2/6] 下载程序..."

curl -fsSL \
    "$REPO_RAW/upload.py" \
    -o "$INSTALL_DIR/upload.py"

chmod 755 "$INSTALL_DIR/upload.py"

echo
echo "[3/6] 配置 Cloudflare Worker"
echo

read -rp "Worker URL: " WORKER_URL
read -rsp "服务器 Token: " TOKEN
echo

if [ -z "$WORKER_URL" ]; then
    echo "Worker URL 不能为空"
    exit 1
fi

if [ -z "$TOKEN" ]; then
    echo "Token 不能为空"
    exit 1
fi

echo
echo "[4/6] 写入配置..."

cat > "$CONFIG_FILE" <<EOF
WORKER_URL=$WORKER_URL
TOKEN=$TOKEN
EOF

chmod 600 "$CONFIG_FILE"

echo "[5/6] 创建 systemd..."

cat > /etc/systemd/system/chicken-sync.service <<EOF
[Unit]
Description=Chicken Accounts Sync
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 /opt/chicken-sync/upload.py
EOF


cat > /etc/systemd/system/chicken-sync.timer <<EOF
[Unit]
Description=Chicken Accounts Sync Timer

[Timer]
OnBootSec=30
OnUnitActiveSec=300
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload

systemctl enable chicken-sync.timer

systemctl start chicken-sync.timer

echo
echo "[6/6] 第一次上传..."
echo

if systemctl start chicken-sync.service; then
    echo
    echo "======================================"
    echo "          安装完成"
    echo "======================================"
    echo
    echo "自动同步：每 5 分钟"
    echo
    echo "查看状态："
    echo "systemctl status chicken-sync.timer"
    echo
    echo "手动上传："
    echo "systemctl start chicken-sync.service"
    echo
else
    echo
    echo "第一次上传失败，请检查："
    echo "systemctl status chicken-sync.service"
    echo "journalctl -u chicken-sync.service -n 50"
    exit 1
fi
