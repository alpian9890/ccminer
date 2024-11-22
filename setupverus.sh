clear
echo "Settingup..."
yes | pkg update && pkg upgrade && apt update && apt upgrade
yes | pkg install libjansson wget nano
mkdir $HOME/ccminer && cd $HOME/ccminer
#wget https://raw.githubusercontent.com/Darktron/pre-compiled/generic/ccminer
#wget https://raw.githubusercontent.com/Darktron/pre-compiled/generic/config.json
#wget https://raw.githubusercontent.com/Darktron/pre-compiled/generic/start.sh

git clone https://github.com/alpian9890/ccminer.git

chmod +x $HOME/ccminer $HOME/ccminer/*
#nano $HOME/ccminer/config.json

#Lanjut setting wallet dll
#Cara setting autorun :
# cd && cd && cd && nano ../usr/etc/bash.bashrc
#Copykan ini kebaris paling bawah,lalu ctrl X, simpan pilih Y enter
echo "cd $HOME/ccminer/&&./start.sh"  >> /data/data/com.termux/files/usr/etc/bash.bashrc
echo "\n \n"
cat /data/data/com.termux/files/usr/etc/bash.bashrc
