# printer-driver-hprt-cpcl

CUPS printer driver for HPRT HM-A300 series mobile Bluetooth label printers.

## Supported Models

| Model | Paper Width | Protocol |
|-------|-------------|----------|
| HM-A300 | 80mm | CPCL |
| HM-A300E | 80mm | CPCL |
| HM-A300S | 80mm | CPCL |
| HM-T300 | 80mm | CPCL |

> Other HPRT mobile printers using CPCL may also work.

## Requirements

- Linux with CUPS
- Python 3
- `poppler-utils` (`pdftoppm`, `pdfinfo`)
- `bluez` (`bluetoothctl`)

```bash
sudo apt install cups python3 poppler-utils bluez
```

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/printer-driver-hprt-cpcl.git
cd printer-driver-hprt-cpcl
sudo bash install.sh
```

## Adding a Printer

### Option 1: GUI (GNOME Settings / system-config-printer)

1. Pair your HM-A300 via Bluetooth first
2. Open **Settings → Printers → Add Printer**
3. The printer should appear automatically
4. Select driver: **HPRT → HM-A300/A300E/T300 CPCL Bluetooth**

### Option 2: Command Line

```bash
# Format: btcpcl://XX-XX-XX-XX-XX-XX/CHANNEL  (use dashes, not colons)
sudo lpadmin -p HM-A300 \
  -E \
  -v 'btcpcl://04-7F-0E-0F-5A-62/1' \
  -P /usr/share/ppd/hprt/HPRT-HM-A300-Series.ppd \
  -D 'HPRT HM-A300'
```

Replace `04-7F-0E-0F-5A-62` with your printer's Bluetooth MAC address (use `-` not `:`).

To find your printer's MAC address:
```bash
bluetoothctl devices
```

## Printing

Before printing, disconnect any active Bluetooth connection (the driver will reconnect automatically):

```bash
bluetoothctl disconnect 04:7F:0E:0F:5A:62
lp -d HM-A300 yourfile.pdf
```

## How It Works

This driver consists of three components:

- **`filter/pdftocpcl`** — CUPS filter that converts PDF to CPCL (Comtec Printer Control Language). Uses `pdftoppm` to render the PDF at the correct DPI and scales it to fill the print width, then generates `EG` (EXPANDED-GRAPHICS) commands.
- **`backend/btcpcl`** — CUPS backend that sends CPCL data to the printer over Bluetooth RFCOMM. Supports automatic discovery of paired HPRT printers.
- **`ppd/HPRT-HM-A300-Series.ppd`** — PPD file describing the printer capabilities (200 DPI, 80mm paper, common label sizes).

## Protocol

The HPRT HM-A300 uses **CPCL** (Comtec Printer Control Language), not ESC/POS. A print job looks like:

```
! 0 200 200 {height} 1\r\n
EG {byte_width} {height} 0 0 {hex_image_data}\r\n
FORM\r\n
PRINT\r\n
```

## Uninstall

```bash
sudo bash uninstall.sh
```

## License

MIT
