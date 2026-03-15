#!/bin/bash
set -e

# Deteksi platform (termux/ubuntu/linux)
PLATFORM="linux"
if [ -n "${TERMUX_VERSION:-}" ] || [ -d "/data/data/com.termux/files/usr" ]; then
    PLATFORM="termux"
elif [ -f /etc/os-release ] && grep -qiE 'ubuntu|debian' /etc/os-release; then
    PLATFORM="ubuntu"
fi

ARCH="$(uname -m)"
echo "Arsitektur terdeteksi: $ARCH"
case "${PLATFORM}:${ARCH}" in
    termux:aarch64|termux:arm64) ;;
    ubuntu:x86_64|ubuntu:amd64|linux:x86_64|linux:amd64) ;;
    *)
        echo "Arsitektur tidak didukung untuk platform ini."
        exit 1
        ;;
esac

if [ "$PLATFORM" = "termux" ]; then
    BASHRC_FILE="/data/data/com.termux/files/usr/etc/bash.bashrc"
else
    BASHRC_FILE="$HOME/.bashrc"
fi

ensure_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            SUDO="sudo"
        else
            echo "Perintah ini membutuhkan akses root. Jalankan sebagai root atau install sudo."
            exit 1
        fi
    fi
}

setup_systemd_service() {
    if [ "$PLATFORM" = "termux" ]; then
        return
    fi
    if ! command -v systemctl >/dev/null 2>&1 || [ ! -d /run/systemd/system ]; then
        echo "Systemd tidak terdeteksi. Lewati setup service."
        return
    fi
    ensure_sudo
    RUN_USER="${SUDO_USER:-$(id -un)}"
    RUN_HOME="$(getent passwd "$RUN_USER" | cut -d: -f6)"
    [ -n "$RUN_HOME" ] || RUN_HOME="$HOME"
    SERVICE_PATH="/etc/systemd/system/ccminer.service"

    $SUDO tee "$SERVICE_PATH" >/dev/null <<EOL
[Unit]
Description=ccminer miner
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${RUN_USER}
WorkingDirectory=${RUN_HOME}/ccminer
Environment=TERM=xterm
ExecStart=/bin/bash -lc 'cd ${RUN_HOME}/ccminer && ./start.sh'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

    $SUDO systemctl daemon-reload
    $SUDO systemctl enable --now ccminer
    echo "Service systemd ccminer aktif. Cek status: systemctl status ccminer"
}

install_packages() {
    if [ "$PLATFORM" = "termux" ]; then
        yes | pkg update && pkg upgrade
        yes | pkg install libjansson wget nano
    else
        if ! command -v apt-get >/dev/null 2>&1; then
            echo "apt-get tidak ditemukan. Script ini fokus untuk Ubuntu/Debian."
            exit 1
        fi
        ensure_sudo
        apt_cmd() {
            if [ -n "$SUDO" ]; then
                $SUDO env DEBIAN_FRONTEND=noninteractive apt-get "$@"
            else
                env DEBIAN_FRONTEND=noninteractive apt-get "$@"
            fi
        }
        apt_cmd update
        apt_cmd upgrade -y
        apt_cmd install -y libjansson4 wget nano
    fi
}

clear
echo "Settingup..."
echo "Platform terdeteksi: $PLATFORM"

# Update, upgrade, dan install paket
install_packages

# Change to home directory
cd $HOME
clear

# Clone repository
git clone https://github.com/alpian9890/ccminer.git && cd $HOME/ccminer

# Set permissions
chmod +x "$HOME/ccminer" "$HOME/ccminer/ccminer" "$HOME/ccminer/start.sh" 2>/dev/null || true
chmod +x "$HOME/ccminer/setupverus" "$HOME/ccminer/setup-verus-mining.sh" 2>/dev/null || true
if [ -d "$HOME/ccminer/bin" ]; then
    find "$HOME/ccminer/bin" -type f -name ccminer -exec chmod +x {} + 2>/dev/null || true
fi
clear
echo "cloning ccminer done!"
echo " "
echo " "
ls
echo " "
echo " "
echo " "
# Ask for autorun configuration
echo -n "Apakah kamu ingin autorun start mining verush dijalankan pada saat aplikasi pertama kali dibuka? (Y/n): "
read autorun_choice
autorun_choice=${autorun_choice//$'\r'/}
autorun_choice=${autorun_choice:-Y}  # Default to Y if Enter is pressed

if [ "${autorun_choice^^}" = "Y" ]; then
    autorun_cmd="cd $HOME/ccminer && ./start.sh"
    if ! grep -Fq "$autorun_cmd" "$BASHRC_FILE" 2>/dev/null; then
        echo "$autorun_cmd" >> "$BASHRC_FILE"
    fi
    autorun_status="yes"
else
    autorun_status="no"
fi

# Get mining configuration from user
echo -n "Masukkan alamat server/url (default: ap.luckpool.net): "
read server_url
server_url=${server_url//$'\r'/}
server_url=${server_url:-ap.luckpool.net}

echo -n "Masukkan port (default: 3956): "
read port
port=${port//$'\r'/}
port=${port:-3956}

echo -n "Masukkan alamat wallet Veruscoin: (contoh: RGJS61iPSNMhrkfqT9SWX6cjLqzCPLQSW1): "
read wallet_address
wallet_address=${wallet_address//$'\r'/}
wallet_address=${wallet_address:-RGJS61iPSNMhrkfqT9SWX6cjLqzCPLQSW1}

echo -n "Masukkan nama worker: (default: worker1): "
read worker_name
worker_name=${worker_name//$'\r'/}
worker_name=${worker_name:-worker1}
# Get CPU threads
total_cores=$(nproc)
echo -n "Masukkan jumlah CPU threads yang akan digunakan (max: $total_cores): "
read cpu_threads
cpu_threads=${cpu_threads//$'\r'/}
cpu_threads=${cpu_threads:-$total_cores}

# Create config.json
cat > config.json << EOL
{
    "pools": [
        {
            "name": "${server_url}",
            "url": "stratum+tcp://${server_url}:${port}",
            "timeout": 180,
            "disabled": 1
        }
    ],
    "user": "${wallet_address}.${worker_name}",
    "pass": "",
    "algo": "verus",
    "threads": ${cpu_threads},
    "cpu-priority": 1,
    "cpu-affinity": -1,
    "retry-pause": 10,
    "api-allow": "192.168.0.0/16",
    "api-bind": "0.0.0.0:4068"
}
EOL

# Final message
echo "Setup selesai!"
echo "Autorun mining: $autorun_status"

if [ "$autorun_status" = "no" ]; then
    echo "Karena kamu memilih no, mining tidak akan autorun saat startup."
    echo "Untuk memulai mining manual, jalankan: cd $HOME/ccminer && ./start.sh"
fi

if [ "$PLATFORM" != "termux" ] && [ "$ARCH" = "x86_64" ]; then
    setup_systemd_service
fi
