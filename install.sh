#!/data/data/com.termux/files/usr/bin/bash

echo "[+] Setting up irh_vconvert..."

# Folder aplikasi
mkdir -p /sdcard/irh_vconvert/input
mkdir -p /sdcard/irh_vconvert/output

# Pasang command ke PATH
cp irh_vconvert.sh $PREFIX/bin/irh_vconvert
chmod +x $PREFIX/bin/irh-vconvert

echo "[✓] Install selesai"
echo "▶ Jalankan: irh-vconvert"
