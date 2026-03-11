#!/bin/bash
# HPRT HM-A300 驱动卸载脚本
set -e

[ "$EUID" -ne 0 ] && { echo "请以 root 权限运行"; exit 1; }

echo "卸载 HPRT HM-A300 驱动..."

rm -f /usr/lib/cups/filter/pdftocpcl
rm -f /usr/lib/cups/backend/btcpcl
rm -f /usr/share/ppd/hprt/HPRT-HM-A300-Series.ppd
rmdir --ignore-fail-on-non-empty /usr/share/ppd/hprt 2>/dev/null || true

systemctl restart cups
echo "✓ 卸载完成（已注册的打印机实例需手动删除）"
