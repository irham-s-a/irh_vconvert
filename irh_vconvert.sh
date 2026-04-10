#!/data/data/com.termux/files/usr/bin/bash

# =========================
# 1. WHIPTAIL CHECK
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
# 2. DEPENDENCY CHECK
# =========================
check_dep() {
  command -v "$1" >/dev/null 2>&1 && return

  whiptail --yesno "❌ $1 belum ada\nInstall?" 12 50
  if [ $? -eq 0 ]; then
    pkg install -y "$2"
  else
    exit 1
  fi
}

check_dep ffmpeg ffmpeg
check_dep ffprobe ffmpeg
check_dep bc bc

# =========================
# 3. DEVICE SPECS DETECTION
# =========================
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_MB=$((RAM_KB / 1024))

CPU_CORE=$(nproc)
CPU_NAME=$(grep -m1 "model name\|Hardware\|Processor" /proc/cpuinfo | cut -d: -f2)

# CLASSIFICATION (FIXED RULE)
if [ "$RAM_MB" -le 2048 ] || [ "$CPU_CORE" -le 4 ]; then
  LEVEL="LOW"
elif [ "$RAM_MB" -le 4096 ] || [ "$CPU_CORE" -le 6 ]; then
  LEVEL="MEDIUM"
else
  LEVEL="HIGH"
fi

# =========================
# 4. SPEK UI (FULL DETAIL)
# =========================
whiptail --msgbox "
📱 DEVICE SPEC INFO
========================

RAM        : ${RAM_MB} MB
CPU CORE   : ${CPU_CORE}
CPU        : ${CPU_NAME:-UNKNOWN}

STATUS     : $LEVEL

========================
RULE SYSTEM
========================
LOW    → BLOCK (tidak bisa lanjut)
MEDIUM → WARNING (boleh lanjut)
HIGH   → NORMAL
========================
" 22 60

# =========================
# 5. LOW DEVICE BLOCK
# =========================
if [ "$LEVEL" = "LOW" ]; then
  whiptail --msgbox "
❌ DEVICE BLOCKED

HP terlalu lemah untuk proses ini.

Saran:
- upgrade device
- atau gunakan resolusi 360p saja
" 15 55
  exit 1
fi

# =========================
# 6. MEDIUM WARNING
# =========================
if [ "$LEVEL" = "MEDIUM" ]; then
  whiptail --msgbox "
⚠ WARNING DEVICE MEDIUM

Performa terbatas.

Rekomendasi:
- max 1080p stabil
- 2K bisa lag
- 4K tidak disarankan
- gunakan FPS 30
" 16 60
fi

# =========================
# 7. FOLDER
# =========================
BASE="/sdcard/irh_vconvert"
IN="$BASE/input"
OUT="$BASE/output"

mkdir -p "$IN" "$OUT"

# =========================
# FIX VARIABLES
# =========================
SIZE_MB=100
CRF=23

# =========================
# 8. MAIN MENU
# =========================
while true; do

MENU=$(whiptail --menu "
IRH VCONVERT

RAM  : $RAM_MB MB
CPU  : $CPU_CORE CORE
TYPE : $LEVEL

INPUT : $IN
OUTPUT: $OUT
" 18 60 3 \
"1" "Convert Video" \
"2" "Panduan" \
"0" "Keluar" \
3>&1 1>&2 2>&3)

[ -z "$MENU" ] && continue

case $MENU in
0)
  exit
;;

2)
whiptail --msgbox "
📘 PANDUAN

1. Taruh video di:
$IN

2. Pilih convert

3. Setting:
- Mode
- Codec
- FPS
- Resolusi

4. Hasil:
$OUT
" 18 60
continue
;;
esac

# =========================
# 9. MODE
# =========================
MODE=$(whiptail --menu "MODE" 12 50 2 \
"1" "CRF Quality" \
"2" "Size Target" \
3>&1 1>&2 2>&3)

[ -z "$MODE" ] && continue

# =========================
# 10. CODEC
# =========================
CODEC=$(whiptail --menu "CODEC" 12 50 2 \
"264" "H264" \
"265" "H265" \
3>&1 1>&2 2>&3)

[ -z "$CODEC" ] && continue

# =========================
# 11. FPS
# =========================
FPS=$(whiptail --menu "FPS" 14 50 4 \
"24" "Cinematic" \
"30" "Normal" \
"60" "Smooth" \
"ori" "Original" \
3>&1 1>&2 2>&3)

[ -z "$FPS" ] && continue

# =========================
# 12. RESOLUSI
# =========================
RES=$(whiptail --menu "RESOLUSI" 16 50 7 \
"360" "360p" \
"480" "480p" \
"720" "720p" \
"1080" "1080p" \
"1440" "2K" \
"2160" "4K" \
"ori" "Original" \
3>&1 1>&2 2>&3)

[ -z "$RES" ] && continue

[ "$RES" != "ori" ] && SCALE="-vf scale=-2:$RES" || SCALE=""

# =========================
# 13. LOW SAFETY BLOCK
# =========================
if [ "$LEVEL" = "LOW" ] && { [ "$RES" = "1440" ] || [ "$RES" = "2160" ]; }; then
  whiptail --msgbox "❌ BLOCK: DEVICE LOW tidak bisa 2K/4K" 12 60
  continue
fi

if [ "$LEVEL" = "MEDIUM" ] && { [ "$RES" = "1440" ] || [ "$RES" = "2160" ]; }; then
  whiptail --yesno "
⚠ WARNING EXTREME LOAD

Device MEDIUM + resolusi berat
Lanjut?" 15 60 || continue
fi

# =========================
# 14. PROCESS FILES
# =========================
for file in "$IN"/*; do
  [ -e "$file" ] || continue

  name=$(basename "$file")
  out="$OUT/conv_$name"

  FPS_VAL=$([ "$FPS" = "ori" ] && echo 30 || echo $FPS)

  # =========================
  # MODE 1 - SIZE LOCK FIXED
  # =========================
  if [ "$MODE" = "1" ]; then

    duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$file")

    # ===== PATCH FIX 1 =====
    if [ -z "$duration" ] || [ "$duration" = "N/A" ]; then
      whiptail --msgbox "❌ ERROR: durasi tidak terbaca" 10 50
      continue
    fi

    target_bytes=$(echo "$SIZE_MB * 1024 * 1024" | bc)

    audio_kbps=128
    audio_bytes=$(echo "$audio_kbps * 1000 * $duration / 8" | bc)

    safety=0.95

    video_bytes=$(echo "$target_bytes - $audio_bytes" | bc)
    video_bytes=$(echo "$video_bytes * $safety" | bc)

    vbit=$(echo "($video_bytes * 8) / $duration / 1000" | bc)

    # ===== PATCH FIX 2 =====
    if [ -z "$vbit" ]; then
      vbit=300
    fi

    if [ "$vbit" -lt 120 ] 2>/dev/null; then
      vbit=120
    fi

    ffmpeg -y -loglevel error -i "$file" -r $FPS_VAL $SCALE \
      -c:v libx264 -b:v ${vbit}k -pass 1 -an -f null /dev/null

    ffmpeg -y -i "$file" -r $FPS_VAL $SCALE \
      -c:v libx264 -b:v ${vbit}k -pass 2 \
      -c:a aac -b:a ${audio_kbps}k "$out"

  else

    if [ "$CODEC" = "265" ]; then
      ffmpeg -y -i "$file" -r $FPS_VAL $SCALE \
        -c:v libx265 -crf $CRF \
        -c:a aac -b:a 128k "$out"
    else
      ffmpeg -y -i "$file" -r $FPS_VAL $SCALE \
        -c:v libx264 -crf $CRF \
        -c:a aac -b:a 128k "$out"
    fi

  fi

done

whiptail --msgbox "✅ DONE" 10 40

done
