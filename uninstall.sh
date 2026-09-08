#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
    echo "请使用 root"
    exit 1
fi

echo "停止服务..."

systemctl disable --now chicken-sync.timer 2>/dev/null || true

systemctl stop chicken-sync.service 2>/dev/null || true

rm -f /etc/systemd/system/chicken-sync.service
rm -f /etc/systemd/system/chicken-sync.timer

systemctl daemon-reload

rm -rf /opt/chicken-sync
rm -f /etc/chicken-sync.conf

echo
echo "Chicken Sync 已卸载"
