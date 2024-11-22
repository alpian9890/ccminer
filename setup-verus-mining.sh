#!/bin/bash

# Fungsi untuk memastikan dependensi terinstal
function install_dependencies() {
    echo "Memeriksa dan menginstal dependensi..."
    packages=("libjansson" "wget" "nano" "curl" "git")
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            echo "Menginstal $package..."
            yes | pkg install "$package" || { echo "Gagal menginstal $package, keluar."; exit 1; }
        fi
    done
}

# Fungsi untuk meminta input dengan validasi
function prompt_input() {
    local prompt="$1"
    local input
    while true; do
        echo -n "$prompt: "
        read input
        if [ -n "$input" ]; then
            echo "$input"
            break
        else
            echo "Input tidak boleh kosong, silakan coba lagi."
        fi
    done
}

# Fungsi untuk membuat konfigurasi file
function create_config_file() {
    local server="$1"
    local port="$2"
    local wallet="$3"
    local worker="$4"
    local threads="$5"
    local config_path="$HOME/ccminer/config.json"

    echo "Membuat file konfigurasi di $config_path..."
    cat <<EOF > "$config_path"
{
    "pools": [
        {
            "name": "$server",
            "url": "stratum+tcp://$server:$port",
            "timeout": 180,
            "disabled": 0
        }
    ],
    "user": "$wallet.$worker",
    "pass": "",
    "algo": "verus",
    "threads": $threads,
    "cpu-priority": 1,
    "cpu-affinity": -1,
    "retry-pause": 10,
    "api-allow": "192.168.0.0/16",
    "api-bind": "0.0.0.0:4068"
}
EOF
}

# Bersihkan layar
clear
echo "Setting up Verus Mining..."

# Memastikan dependensi terinstal
install_dependencies

# Update dan upgrade sistem
echo "Mengupdate sistem..."
yes | pkg update && pkg upgrade && apt update && apt upgrade || { echo "Gagal mengupdate sistem, keluar."; exit 1; }

# Masuk ke direktori $HOME
cd $HOME || { echo "Gagal masuk ke direktori $HOME, keluar."; exit 1; }

# Clone repository
echo "Mengunduh repository ccminer..."
if [ ! -d "$HOME/ccminer" ]; then
    git clone https://github.com/alpian9890/ccminer.git || { echo "Gagal mengclone repository, keluar."; exit 1; }
fi

# Masuk ke direktori ccminer
cd "$HOME/ccminer" || { echo "Gagal masuk ke direktori ccminer, keluar."; exit 1; }

# Memberi izin eksekusi
chmod +x "$HOME/ccminer" "$HOME/ccminer/"* || { echo "Gagal memberi izin eksekusi, keluar."; exit 1; }

# Dialog autorun
while true; do
    echo "Apakah kamu ingin autorun mining dijalankan pada saat aplikasi pertama kali dibuka? (yes/no)"
    echo -n "Jawaban (yes/no): "
    read autorun
    if [[ "$autorun" == "yes" || "$autorun" == "no" ]]; then
        break
    else
        echo "Input tidak valid, silakan jawab dengan 'yes' atau 'no'."
    fi
done

# Konfigurasi autorun
if [ "$autorun" == "yes" ]; then
    echo "cd $HOME/ccminer && ./start.sh" >> /data/data/com.termux/files/usr/etc/bash.bashrc
    echo "Autorun mining akan diaktifkan saat startup."
else
    echo "Autorun mining tidak diaktifkan."
fi

# Konfigurasi mining
server=$(prompt_input "Masukkan server mining (contoh: ap.luckpool.net)")
port=$(prompt_input "Masukkan port server mining (contoh: 3956)")
wallet=$(prompt_input "Masukkan alamat wallet Verus (contoh: RGJS61iPSNMhrkfqT9SWX6cjLqzCPLQSW1)")
worker=$(prompt_input "Masukkan nama worker (contoh: worker1)")

while true; do
    threads=$(prompt_input "Masukkan jumlah threads CPU yang akan digunakan (contoh: 8)")
    if [[ "$threads" =~ ^[0-9]+$ ]]; then
        break
    else
        echo "Jumlah threads harus berupa angka, silakan coba lagi."
    fi
done

# Membuat file konfigurasi
create_config_file "$server" "$port" "$wallet" "$worker" "$threads"

# Menampilkan hasil setup
clear
echo "Setup selesai."
if [ "$autorun" == "yes" ]; then
    echo "Autorun mining diaktifkan."
else
    echo "Autorun mining tidak diaktifkan karena kamu memilih 'no'."
fi

echo "Konfigurasi telah disimpan di $HOME/ccminer/config.json."
echo "Untuk memulai mining, jalankan perintah berikut:"
echo "cd $HOME/ccminer && ./start.sh"
