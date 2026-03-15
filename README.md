# ccminer
### Get Started Now
Script `setup-verus-mining.sh` dan `setupverus` sekarang mendeteksi platform (Termux/Ubuntu) dan menyesuaikan path serta dependency. Binary disimpan di `bin/` dan wrapper `ccminer` memilih arsitektur secara otomatis.
Download & setup

```bash
curl -s "https://alpian9890.github.io/get-ccminer/" | bash
```
Catatan: metode `curl` di atas masih khusus Termux. Untuk Ubuntu/Debian gunakan `setupverus` atau `setup-verus-mining.sh` di repo ini.
_add -i for interactive_:

curl -s "https://alpian9890.github.io/get-ccminer/" | bash -i

_or_
```bash
wget https://raw.githubusercontent.com/alpian9890/ccminer/refs/heads/main/setup-verus-mining.sh
chmod +x setup-verus-mining.sh
```
```bash
./setup-verus-mining.sh
```
