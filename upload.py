#!/usr/bin/env python3

import os
import sys
import urllib.request
import urllib.parse


# ==============================
# 配置文件
# ==============================

CONFIG_FILE = "/etc/chicken-sync.conf"

# TXT 文件
SOURCE_FILE = "/root/chicken_accounts.txt"


def load_config():
    config = {}

    if not os.path.exists(CONFIG_FILE):
        print(f"ERROR: {CONFIG_FILE} 不存在")
        sys.exit(1)

    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()

            if not line or line.startswith("#"):
                continue

            if "=" not in line:
                continue

            key, value = line.split("=", 1)

            config[key.strip()] = value.strip()

    return config


def get_public_ip():
    services = [
        "https://api.ipify.org",
        "https://ifconfig.me/ip",
    ]

    for service in services:
        try:
            req = urllib.request.Request(
                service,
                headers={
                    "User-Agent": "chicken-sync"
                }
            )

            with urllib.request.urlopen(
                req,
                timeout=10
            ) as response:

                ip = response.read().decode().strip()

                if ip:
                    return ip

        except Exception:
            pass

    raise RuntimeError("无法获取公网 IP")


def upload():

    config = load_config()

    worker_url = config.get("WORKER_URL")
    token = config.get("TOKEN")

    if not worker_url:
        raise RuntimeError("WORKER_URL 未配置")

    if not token:
        raise RuntimeError("TOKEN 未配置")

    if not os.path.exists(SOURCE_FILE):
        raise RuntimeError(
            f"{SOURCE_FILE} 不存在"
        )

    # 自动获取公网 IP
    server_ip = get_public_ip()

    # 读取 TXT
    with open(
        SOURCE_FILE,
        "rb"
    ) as f:
        data = f.read()

    if not data:
        raise RuntimeError(
            f"{SOURCE_FILE} 是空文件"
        )

    url = (
        worker_url.rstrip("/")
        + "/upload?server="
        + urllib.parse.quote(server_ip)
    )

    req = urllib.request.Request(
        url,
        data=data,
        method="POST",
        headers={
            "Authorization": "Bearer " + token,
            "Content-Type": "text/plain",
            "User-Agent": "chicken-sync/1.0"
        }
    )

    with urllib.request.urlopen(
        req,
        timeout=30
    ) as response:

        result = response.read().decode()

        if response.status == 200:
            print(
                f"[OK] {server_ip} 上传成功"
            )
            print(result)
        else:
            raise RuntimeError(
                f"HTTP {response.status}: {result}"
            )


if __name__ == "__main__":

    try:
        upload()

    except Exception as e:
        print(
            f"[ERROR] {e}",
            file=sys.stderr
        )

        sys.exit(1)
