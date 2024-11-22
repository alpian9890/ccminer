#!/bin/bash

clear
echo "Settingup..."

# Update and upgrade packages
yes | pkg update && pkg upgrade && apt update && apt upgrade

# Install required packages
yes | pkg install libjansson wget nano

# Change to home directory
cd $HOME
clear

# Clone repository
git clone https://github.com/alpian9890/ccminer.git && cd $HOME/ccminer

# Set permissions
chmod +x $HOME/ccminer $HOME/ccminer/*
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
autorun_choice=${autorun_choice:-Y}  # Default to Y if Enter is pressed

if [ "${autorun_choice^^}" = "Y" ]; then
    echo "cd $HOME/ccminer/&&./start.sh" >> /data/data/com.termux/files/usr/etc/bash.bashrc
    autorun_status="yes"
else
    autorun_status="no"
fi

# Get mining configuration from user
echo -n "Masukkan alamat server/url (default: ap.luckpool.net): "
read server_url
server_url=${server_url:-ap.luckpool.net}

echo -n "Masukkan port (default: 3956): "
read port
port=${port:-3956}

echo -n "Masukkan alamat wallet Veruscoin: (contoh: RGJS61iPSNMhrkfqT9SWX6cjLqzCPLQSW1): "
read wallet_address
wallet_address=${wallet_address:-RGJS61iPSNMhrkfqT9SWX6cjLqzCPLQSW1}

echo -n "Masukkan nama worker: (default: worker1): "
read worker_name
worker_name=${worker_name:-worker1}
# Get CPU threads
total_cores=$(nproc)
echo -n "Masukkan jumlah CPU threads yang akan digunakan (max: $total_cores): "
read cpu_threads
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
