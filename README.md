# BeagleBone OverlayGen

🧩 Generate `.dtbo` overlays for UART, I2C, SPI, GPIO etc. with an interactive terminal script.

## Install dependencies

```bash
sudo apt-get update
sudo apt-get install -y jq device-tree-compiler git
```

For TUI:

```bash
sudo apt-get install -y python3 python3-venv
python3 -m venv .venv
source .venv/bin/activate
pip install npyscreen pyyaml
```

## ⚙️ Usage

Clone the repo:

```bash
git clone https://github.com/veliertunc/beaglebone-overlaygen.git
```

Bash script:

```bash
chmod +x overlaygen.sh
./overlaygen.sh
```

TUI:

```bash
chmod +x overlaygen-tui.py
python3 overlaygen-tui.py
```
