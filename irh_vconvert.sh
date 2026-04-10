#!/data/data/com.termux/files/usr/bin/bash

# =========================
# 1. WHIPTAIL SAFE CHECK (NO UI YET)
# =========================
if ! command -v whiptail >/dev/null 2>&1; then
  pkg update -y
  pkg install -y whiptail
fi

command -v whiptail >/dev/null 2>&1 || {
  echo "❌ whiptail tidak tersedia"
  exit 1
}

# =========================
# 2. DEPENDENCY CHECK (STRICT + Y/N INSTALL)
# =========================
check_dep() {
  if command -v "$1" >/dev/null 2>&1; then
    return
  fi

  whiptail --yesno "❌ $1 belum ada\nInstall sekarang?" 12 50
  if [ $? -eq 0 ]; then
    pkg install -y "$2"
  else
    whiptail --msgbox "❌ $1 wajib untuk menjalankan aplikasi" 12 50
    exit 1
  fi
}

check_dep ffmpeg ffmpeg
check_dep ffprobe ffmpeg
check_dep bc bc

# FINAL VERIFY
command -v ffmpeg >/dev/null 2>&1 || exit
command -v bc >/dev/null 2>&1 || exit

# =========================
# 3. AUTO FOLDER
# =========================
BASE_DIR="/sdcard/irh_vconvert"
INPUT_DIR="$BASE_DIR/input"
OUTPUT_DIR="$BASE_DIR/output"

mkdir -p "$INPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# =========================
# 4. MAIN LOOP
# =========================
while true; do

MENU=$(whiptail --title "irh_vconvert" \
--menu "READY SYSTEM\n\nInput: $INPUT_DIR\nOutput: $OUTPUT_DIR" \
15 60 3 \
"1" "Mulai Convert" \
"2" "Panduan" \
"0" "Keluar" \
3>&1 1>&2 2>&3)

[ $? -ne 0 ] && continue

case $MENU in

  0)
    break
  ;;

  2)
    whiptail --msgbox \
"📘 PANDUAN

1. Taruh video ke:
$INPUT_DIR

2. Pilih Convert

3. Pilih urutan:
- Mode (Size / CRF)
- Codec (H264 / H265)
- FPS
- Resolusi

4. Hasil:
$OUTPUT_DIR
" 18 60
    continue
  ;;

esac

# =========================
# 5. MODE (SIZE / CRF)
# =========================
MODE=$(whiptail --menu "Metode Convert" 15 60 2 \
"1" "Custom Size (MB target)" \
"2" "CRF Quality" \
3>&1 1>&2 2>&3)

[ $? -ne 0 ] && continue

# =========================
# 6. CODEC (BENAR DI SINI)
# =========================
CODEC=$(whiptail --menu "Pilih Codec" 15 60 2 \
"264" "H264 (compatibility)" \
"265" "H265 (smaller file)" \
3>&1 1>&2 2>&3)

[ $? -ne 0 ] && continue

# =========================
# 7. FPS
# =========================
FPS_OPT=$(whiptail --menu "FPS" 15 60 4 \
"24" "Cinematic" \
"30" "Normal" \
"60" "Smooth" \
"ori" "Original" \
3>&1 1>&2 2>&3)

[ $? -ne 0 ] && continue

# =========================
# 8. RESOLUSI
# =========================
RES_OPT=$(whiptail --menu "Resolusi" 15 60 5 \
"360" "360p" \
"480" "480p" \
"720" "720p" \
"1080" "1080p" \
"ori" "Original" \
3>&1 1>&2 2>&3)

[ $? -ne 0 ] && continue

[ "$RES_OPT" != "ori" ] && SCALE="-vf scale=-2:$RES_OPT" || SCALE=""

# =========================
# 9. INPUT PARAMETER
# =========================
if [ "$MODE" = "2" ]; then
  CRF=$(whiptail --inputbox "CRF (18-28)" 10 50 23 \
  3>&1 1>&2 2>&3)
  CRF=${CRF:-23}
fi

if [ "$MODE" = "1" ]; then
  SIZE_MB=$(whiptail --inputbox "Target Size (MB)" 10 50 \
  3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && continue
fi

# =========================
# 10. PROCESS FILES
# =========================
for file in "$INPUT_DIR"/*.mp4 "$INPUT_DIR"/*.mkv "$INPUT_DIR"/*.mov; do
  [ -e "$file" ] || continue

  name=$(basename "$file")
  out="$OUTPUT_DIR/converted_$name"

  # FPS
  if [ "$FPS_OPT" = "ori" ]; then
    FPS_VAL=$(ffprobe -v error -select_streams v:0 \
      -show_entries stream=r_frame_rate \
      -of default=noprint_wrappers=1:nokey=1 "$file")
    FPS_VAL=$(echo "$FPS_VAL" | awk -F'/' '{print $1/$2}')
  else
    FPS_VAL=$FPS_OPT
  fi

  (
    echo "10"
    echo "# Processing $name"

    if [ "$MODE" = "1" ]; then
      duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$file")
      vbit=$(echo "($SIZE_MB * 8192) / $duration - 128" | bc)

      ffmpeg -y -i "$file" -r $FPS_VAL $SCALE \
        -c:v libx264 -b:v ${vbit}k -pass 1 -an -f mp4 /dev/null

      echo "60"

      ffmpeg -i "$file" -r $FPS_VAL $SCALE \
        -c:v libx264 -b:v ${vbit}k -pass 2 \
        -c:a aac -b:a 128k "$out"

    else
      if [ "$CODEC" = "265" ]; then
        ffmpeg -i "$file" -r $FPS_VAL $SCALE \
          -c:v libx265 -crf $CRF -preset medium \
          -c:a aac -b:a 128k "$out"
      else
        ffmpeg -i "$file" -r $FPS_VAL $SCALE \
          -c:v libx264 -crf $CRF -preset medium \
          -c:a aac -b:a 128k "$out"
      fi
    fi

    echo "100"
  ) | whiptail --gauge "Processing..." 10 60 0

done

whiptail --msgbox "✅ Semua video selesai!" 10 40

done
