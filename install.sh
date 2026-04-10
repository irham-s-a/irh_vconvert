#!/data/data/com.termux/files/usr/bin/bash

pkg install -y ffmpeg bc whiptail

cp irh_vconvert.sh $PREFIX/bin/irh_vconvert
chmod +x $PREFIX/bin/irh_vconvert

echo "======================="
echo "✅ Install selesai"
echo "▶ Jalankan: irh_vconvert"
echo "======================="
