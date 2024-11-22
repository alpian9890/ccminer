#!/bin/bash

clear
echo "Settingup..."

# Install required packages
echo "Installing required packages..."
pkg install -y curl git libjansson wget nano

# Update and upgrade packages
echo "Updating packages..."
yes | pkg update && pkg upgrade && apt update && apt upgrade

# Change to home directory
cd $HOME
clear

# Clone repository
echo "Cloning repository..."
git clone https://github.com/alpian9890/ccminer.git && cd $HOME/ccminer

# Set permissions
echo "Setting permissions..."
chmod +x $HOME/ccminer $HOME/ccminer/*

# Function to get user input
get_input() {
    local prompt="$1"
    local value=""
    while [ -z "$value" ]; do
        echo -n "$prompt: "
        read value
        if [ -z "$value" ]; then
            echo "Input tidak boleh kosong. Silakan coba lagi."
        fi
    done
    echo "$value"
}

# Function for yes/no questions
get_yes_no() {
    local prompt="$1"
    local answer=""
    while true; do
        echo -n "$prompt [y/n]: "
        read answer
        case ${answer,,} in
            "y"|"yes") return 0 ;;
            "n"|"no") return 1 ;;
            *) echo "Mohon jawab dengan 'y' atau 'n'" ;;
        esac
    done
}

# Ask for autorun configuration
echo "Konfigurasi Autorun"
echo "==================="
if get_yes_no "Apakah kamu ingin autorun start mining verush dijalankan pada saat aplikasi pertama kali dibuka?"; then
    echo "cd $HOME/ccminer/&&./start.sh" >> /data/data/com.termux/files/usr/etc/bash.bashrc
    autorun_status="yes"
else
    autorun_status="no"
fi

# Get mining configuration from user
echo ""
echo "Konfigurasi Mining"
echo "================="
server_url=$(get_input "Masukkan alamat server/url (contoh: ap.luckpool.net)")
port=$(get_input "Masukkan port (contoh: 3956)")
wallet_address=$(get_input "Masukkan alamat wallet Veruscoin")
worker_name=$(get_input "Masukkan nama worker")

# Get CPU threads
total_cores=$(nproc)
while true; do
    echo -n "Masukkan jumlah CPU threads yang akan digunakan (maksimum: $total_cores): "
    read cpu_threads
    if [ -z "$cpu_threads" ]; then
        echo "Input tidak boleh kosong."
        continue
    fi
    if ! [[ "$cpu_threads" =~ ^[0-9]+$ ]]; then
        echo "Mohon masukkan angka yang valid."
        continue
    fi
    if [ "$cpu_threads" -gt "$total_cores" ]; then
        echo "Jumlah threads tidak boleh melebihi jumlah CPU cores ($total_cores)"
        continue
    fi
    if [ "$cpu_threads" -lt 1 ]; then
        echo "Jumlah threads minimal 1"
        continue
    fi
    break
done

# Create config.json with user confirmation
echo ""
echo "Konfirmasi Konfigurasi:"
echo "======================"
echo "Server URL: $server_url"
echo "Port: $port"
echo "Wallet Address: $wallet_address"
echo "Worker Name: $worker_name"
echo "CPU Threads: $cpu_threads"
echo ""

if get_yes_no "Apakah konfigurasi di atas sudah benar?"; then
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

    echo ""
    echo "Setup selesai!"
    echo "Autorun mining: $autorun_status"

    if [ "$autorun_status" = "no" ]; then
        echo "Karena kamu memilih no, mining tidak akan autorun saat startup."
        echo "Untuk memulai mining manual, jalankan: cd $HOME/ccminer && ./start.sh"
    else
        echo "Mining akan otomatis berjalan saat startup."
    fi
else
    echo "Setup dibatalkan. Silakan jalankan script kembali untuk mengulang konfigurasi."
    exit 1
fi
