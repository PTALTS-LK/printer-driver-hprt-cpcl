#!/bin/bash
# HPRT HM-A300/HM-T300 CPCL 驱动安装脚本
# 安装完成后，通过系统打印机管理器添加打印机实例
set -e

DRIVER_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "══════════════════════════════════════════════"
echo "  HPRT HM-A300 CPCL 驱动安装"
echo "══════════════════════════════════════════════"

# ── 检查 root ──────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo "错误: 请以 root 权限运行"
    echo "  sudo bash install.sh"
    exit 1
fi

# ── 检查依赖 ───────────────────────────────────────────────
echo "[1/4] 检查依赖..."
MISSING=()
command -v python3    &>/dev/null || MISSING+=("python3")
command -v pdftoppm   &>/dev/null || MISSING+=("poppler-utils")
command -v pdfinfo    &>/dev/null || MISSING+=("poppler-utils")
command -v bluetoothctl &>/dev/null || MISSING+=("bluez")

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "  安装缺少的依赖: ${MISSING[*]}"
    apt-get install -y "${MISSING[@]}" 2>/dev/null || \
        { echo "  警告: 自动安装失败，请手动安装"; }
fi
echo "  ✓ 依赖检查完成"

# ── 安装 CUPS 过滤器 ───────────────────────────────────────
echo "[2/4] 安装 CUPS 过滤器..."
install -o root -g root -m 755 \
    "$DRIVER_DIR/filter/pdftocpcl" \
    /usr/lib/cups/filter/pdftocpcl
echo "  ✓ /usr/lib/cups/filter/pdftocpcl"

# ── 安装 CUPS 后端 ─────────────────────────────────────────
echo "[3/4] 安装 CUPS 蓝牙后端..."
install -o root -g root -m 700 \
    "$DRIVER_DIR/backend/btcpcl" \
    /usr/lib/cups/backend/btcpcl
# 权限必须是 700 (仅 root 可执行)，CUPS 才会信任该后端的网络 URI
echo "  ✓ /usr/lib/cups/backend/btcpcl (权限 700)"

# ── 安装 PPD 文件 ──────────────────────────────────────────
echo "[4/4] 安装 PPD 打印机描述文件..."
install -d -o root -g root -m 755 /usr/share/ppd/hprt
install -o root -g root -m 644 \
    "$DRIVER_DIR/ppd/HPRT-HM-A300-Series.ppd" \
    /usr/share/ppd/hprt/HPRT-HM-A300-Series.ppd
echo "  ✓ /usr/share/ppd/hprt/HPRT-HM-A300-Series.ppd"

# ── 重启 CUPS ──────────────────────────────────────────────
echo "  重启 CUPS..."
systemctl restart cups
sleep 1

# ── 验证安装 ───────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════"
echo "  驱动安装完成！"
echo ""
echo "  验证: lpinfo -m | grep -i hprt"
lpinfo -m 2>/dev/null | grep -i hprt || echo "  (可能需要几秒后再试)"
echo ""
echo "  ┌─ 如何添加打印机 ───────────────────────────"
echo "  │"
echo "  │  方式一: 系统打印机管理器 (推荐)"
echo "  │    1. 打开「系统设置」→「打印机」"
echo "  │    2. 点击「添加打印机」"
echo "  │    3. 选择已配对的 HM-A300 (自动发现)"
echo "  │       或手动输入 URI: btcpcl://XX:XX:XX:XX:XX:XX/1"
echo "  │    4. 选择驱动: HPRT → HM-A300 CPCL Bluetooth"
echo "  │"
echo "  │  方式二: 命令行"
echo "  │    sudo lpadmin -p HM-A300 -E \\"
echo "  │      -v 'btcpcl://04-7F-0E-0F-5A-62/1' \\"
echo "  │      -P /usr/share/ppd/hprt/HPRT-HM-A300-Series.ppd \\"
echo "  │      -D 'HPRT HM-A300'"
echo "  │"
echo "  └────────────────────────────────────────────"
echo ""
echo "  卸载: sudo bash uninstall.sh"
echo "══════════════════════════════════════════════"
