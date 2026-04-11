#!/data/data/com.termux/files/usr/bin/bash

# Matikan history expansion (biar tanda ! tidak error)
set +H

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
check_dep mediainfo mediainfo

# =========================
# 2.5. CEK FFMPEG LINKING ERROR
# =========================
check_ffmpeg_works() {
  ffmpeg -version >/dev/null 2>&1
  return $?
}

if ! check_ffmpeg_works; then
  whiptail --msgbox "⚠️ FFmpeg error: library missing\nMencoba perbaikan..." 10 50
  pkg reinstall libbluray ffmpeg -y
  if ! check_ffmpeg_works; then
    whiptail --msgbox "❌ Gagal. Jalankan manual:\npkg reinstall libbluray ffmpeg" 12 50
    exit 1
  fi
fi

# =========================
# 3. DEVICE SPECS DETECTION
# =========================
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_MB=$((RAM_KB / 1024))

CPU_CORE=$(nproc)
CPU_NAME=$(grep -m1 "model name\|Hardware\|Processor" /proc/cpuinfo | cut -d: -f2)

# CLASSIFICATION
if [ "$RAM_MB" -le 2048 ] || [ "$CPU_CORE" -le 4 ]; then
  LEVEL="LOW"
elif [ "$RAM_MB" -le 4096 ] || [ "$CPU_CORE" -le 6 ]; then
  LEVEL="MEDIUM"
else
  LEVEL="HIGH"
fi

# =========================
# 4. SPEK UI
# =========================
whiptail --msgbox "
📱 DEVICE SPEC INFO
========================

RAM        : ${RAM_MB} MB
CPU CORE   : ${CPU_CORE}
CPU        : ${CPU_NAME:-UNKNOWN}

STATUS     : $LEVEL

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
# 7.5 CACHE DIRECTORY (Hidden in Termux)
# =========================
CACHE_DIR="$PREFIX/var/lib/irh_vconvert"
mkdir -p "$CACHE_DIR"

# =========================
# FIX VARIABLES
# =========================
CRF_DEFAULT=23

# =========================
# AUTO CLEANUP CACHE
# =========================
cleanup_old_cache() {
  if [ -d "$CACHE_DIR" ]; then
    find "$CACHE_DIR" -type f -mtime +7 -delete 2>/dev/null
  fi
}

# Jalankan cleanup saat startup
cleanup_old_cache

# =========================
# IMPROVED GET_DURATION FUNCTION
# =========================
get_duration() {
  local file="$1"
  local file_hash=$(echo -n "$file" | md5sum | cut -d' ' -f1)
  local cache_file="$CACHE_DIR/$file_hash.cache"
  
  # Check cache first
  if [ -f "$cache_file" ]; then
    local cached_dur=$(cat "$cache_file" 2>/dev/null)
    local cache_time=$(stat -c %Y "$cache_file" 2>/dev/null)
    local current_time=$(date +%s)
    local cache_age=$((current_time - cache_time))
    
    # Cache valid untuk 24 jam
    if [ $cache_age -lt 86400 ]; then
      echo "$cached_dur"
      return 0
    fi
  fi
  
  local dur
  
  # Metode 1: ffprobe (standard)
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$file" 2>/dev/null)
  if [[ -n "$dur" && "$dur" != "N/A" && "$dur" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    echo "$dur" > "$cache_file"
    echo "$dur"
    return 0
  fi
  
  # Metode 2: ffprobe (stream format)
  dur=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
  if [[ -n "$dur" && "$dur" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    echo "$dur" > "$cache_file"
    echo "$dur"
    return 0
  fi
  
  # Metode 3: mediainfo
  if command -v mediainfo >/dev/null 2>&1; then
    dur_ms=$(mediainfo --Inform="General;%Duration%" "$file" 2>/dev/null)
    if [[ -n "$dur_ms" && "$dur_ms" =~ ^[0-9]+$ ]]; then
      dur=$(echo "scale=3; $dur_ms / 1000" | bc -l 2>/dev/null)
      if [[ -n "$dur" && "$dur" != "0" ]]; then
        echo "$dur" > "$cache_file"
        echo "$dur"
        return 0
      fi
    fi
  fi
  
  # Metode 4: Frame counting (LEBIH CEPAT)
  echo "" >&2
  echo "==============================================" >&2
  echo "⏳ MEMBACA DURASI (FRAME COUNTING)" >&2
  echo "   File: $(basename "$file")" >&2
  echo "   Metode: Frame counting (lebih cepat)" >&2
  echo "==============================================" >&2
  
  local tmp_log=$(mktemp)
  ffmpeg -i "$file" -f null - < /dev/null 2> "$tmp_log"
  local frames=$(grep -oP 'frame=\s*\K[0-9]+' "$tmp_log" | tail -n1)
  rm -f "$tmp_log"
  
  if [[ -n "$frames" && "$frames" =~ ^[0-9]+$ ]]; then
    local fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    if [[ -n "$fps" ]]; then
      fps=$(echo "scale=2; $fps" | bc -l 2>/dev/null || echo "30")
    else
      fps="30"
    fi
    
    dur=$(echo "scale=3; $frames / $fps" | bc -l 2>/dev/null)
    if [[ -n "$dur" ]]; then
      echo "   ✓ Durasi: ${dur} detik (dari $frames frame)" >&2
      echo "==============================================" >&2
      echo "$dur" > "$cache_file"
      echo "$dur"
      return 0
    fi
  fi
  
  # Metode 5: Full decode (FALLBACK TERAKHIR)
  echo "   Fallback: Full decode (lambat)..." >&2
  tmp_log=$(mktemp)
  ffmpeg -i "$file" -f null - < /dev/null 2> "$tmp_log"
  dur=$(grep -oP 'time=\K[0-9:.]+' "$tmp_log" | tail -n1)
  rm -f "$tmp_log"
  
  if [[ -n "$dur" ]]; then
    IFS=: read -r h m s <<< "$dur"
    s=${s%.*}
    dur=$((10#$h * 3600 + 10#$m * 60 + 10#$s))
    echo "   ✓ Durasi: $dur detik" >&2
    echo "==============================================" >&2
    echo "$dur" > "$cache_file"
    echo "$dur"
    return 0
  fi
  
  echo "   ✗ Gagal membaca durasi" >&2
  echo "==============================================" >&2
  return 1
}

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
  exit 0
;;

2)
whiptail --msgbox "
📘 PANDUAN
1. Taruh video di: $IN
2. Pilih convert
3. Setting:
- Mode
- Codec
- FPS
- Resolusi
4. Hasil: $OUT
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
# 14. INPUT CRF atau SIZE
# =========================
CRF=$CRF_DEFAULT
SIZE_MB=100

if [ "$MODE" = "1" ]; then
  CRF_INPUT=$(whiptail --inputbox "Masukkan nilai CRF (Constant Rate Factor)\n\nSemakin kecil = kualitas lebih baik (18-28)\nDefault 23 (direkomendasikan)" 12 60 "$CRF_DEFAULT" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ] && [ -n "$CRF_INPUT" ]; then
    if [[ "$CRF_INPUT" =~ ^[0-9]+$ ]] && [ "$CRF_INPUT" -ge 0 ] && [ "$CRF_INPUT" -le 51 ]; then
      CRF=$CRF_INPUT
    else
      whiptail --msgbox "❌ Nilai CRF harus angka antara 0-51. Gunakan default 23." 10 50
    fi
  fi
else
  SIZE_MB_INPUT=$(whiptail --inputbox "Masukkan ukuran target (MB)\nDefault 100 MB" 10 50 "100" 3>&1 1>&2 2>&3)
  if [ $? -ne 0 ] || [ -z "$SIZE_MB_INPUT" ]; then
    SIZE_MB=100
    whiptail --msgbox "Menggunakan ukuran default: 100 MB" 10 50
  else
    if [[ "$SIZE_MB_INPUT" =~ ^[0-9]+$ ]] && [ "$SIZE_MB_INPUT" -ge 1 ]; then
      SIZE_MB=$SIZE_MB_INPUT
    else
      whiptail --msgbox "❌ Input tidak valid. Gunakan default 100 MB." 10 50
      SIZE_MB=100
    fi
  fi
fi

# =========================
# 15. CEK FILE INPUT
# =========================
shopt -s nullglob
files=("$IN"/*)
if [ ${#files[@]} -eq 0 ]; then
  whiptail --msgbox "❌ Tidak ada file di folder input!\nLetakkan video di:\n$IN" 12 55
  continue
fi

# =========================
# 16. PROSES KONVERSI
# =========================
for file in "$IN"/*; do
  [ -e "$file" ] || continue

  name=$(basename "$file")
  out="$OUT/conv_$name"
  FPS_VAL=$([ "$FPS" = "ori" ] && echo 30 || echo $FPS)

  if [ "$MODE" = "2" ]; then
    echo ""
    echo "==============================================" >&2
    echo "📹 SEDANG MEMERIKSA INFORMASI VIDEO" >&2
    echo "   File: $name" >&2
    echo "   Mengambil durasi untuk perhitungan ukuran target..." >&2
    echo "   Harap tunggu..." >&2
    echo "==============================================" >&2
    
    duration=$(get_duration "$file")
    if [[ -z "$duration" || "$duration" = "0" ]]; then
      whiptail --msgbox "❌ ERROR: durasi tidak terbaca untuk file $name" 12 55
      continue
    fi

    target_bytes=$(echo "$SIZE_MB * 1024 * 1024" | bc -l)
    audio_kbps=128
    audio_bytes=$(echo "$audio_kbps * 1000 * $duration / 8" | bc -l)
    safety=1.05

    max_iter=5
    iter=1
    tolerance=0.5
    converged=false
    actual_size_mb=0
    current_vbit=0

    while [ $iter -le $max_iter ] && [ "$converged" = false ]; do
      video_bytes=$(echo "($target_bytes - $audio_bytes) * $safety" | bc -l)
      vbit=$(echo "scale=0; ($video_bytes * 8) / ($duration * 1000) + 0.5" | bc -l 2>/dev/null)
      
      if [[ -z "$vbit" ]] || (( $(echo "$vbit <= 0" | bc -l) )); then
        vbit=300
      fi
      if (( $(echo "$vbit < 120" | bc -l) )); then
        vbit=120
      elif (( $(echo "$vbit > 5000" | bc -l) )); then
        vbit=5000
      fi
      
      current_vbit=$vbit
      
      echo "" >&2
      echo "--------------------------------------------------" >&2
      echo "🔄 ITERASI KE-$iter" >&2
      echo "   Target size: $SIZE_MB MB" >&2
      echo "   Toleransi lebih: max $tolerance MB" >&2
      echo "   Menggunakan bitrate video: ${vbit} kbps" >&2
      echo "   Safety factor: $safety" >&2
      echo "   Memulai two-pass encoding..." >&2
      echo "   Mohon tunggu...." >&2
      echo "--------------------------------------------------" >&2
      
      ffmpeg -y -loglevel error -i "$file" -r "$FPS_VAL" $SCALE \
        -c:v libx264 -b:v ${vbit}k -pass 1 -an -f null /dev/null < /dev/null
      
      ffmpeg -y -i "$file" -r "$FPS_VAL" $SCALE \
        -c:v libx264 -b:v ${vbit}k -pass 2 \
        -c:a aac -b:a ${audio_kbps}k "$out" < /dev/null
      
      rm -f ffmpeg2pass-0.log ffmpeg2pass-0.log.mbtree
      
      if [ ! -f "$out" ]; then
        whiptail --msgbox "❌ GAGAL mengkonversi $name pada iterasi ke-$iter" 12 55
        break 2
      fi
      
      actual_bytes=$(stat -c %s "$out" 2>/dev/null || du -b "$out" | cut -f1)
      if [ -z "$actual_bytes" ]; then
        whiptail --msgbox "❌ Tidak bisa membaca ukuran file hasil untuk $name" 12 55
        break 2
      fi
      actual_size_mb=$(echo "scale=2; $actual_bytes / 1024 / 1024" | bc -l)
      
      diff=$(echo "$actual_size_mb - $SIZE_MB" | bc -l)
      
      echo "   Ukuran aktual: ${actual_size_mb} MB" >&2
      echo "   Target : ${SIZE_MB} MB" >&2
      echo "   Selisih: ${diff} MB (positif = lebih)" >&2
      
      if (( $(echo "$diff >= 0" | bc -l) )) && (( $(echo "$diff <= $tolerance" | bc -l) )); then
        echo "   ✅ Ukuran memenuhi kriteria (tidak kurang dan kelebihan ≤ 0.5 MB)." >&2
        converged=true
        break
      fi
      
      if [ $iter -lt $max_iter ]; then
        ratio=$(echo "$SIZE_MB / $actual_size_mb" | bc -l)
        new_safety=$(echo "$safety * $ratio" | bc -l)
        if (( $(echo "$new_safety < 0.7" | bc -l) )); then
          new_safety=0.7
        elif (( $(echo "$new_safety > 1.8" | bc -l) )); then
          new_safety=1.8
        fi
        safety=$new_safety
        echo "   📊 Menyesuaikan safety factor menjadi: $safety" >&2
      fi
      
      ((iter++))
    done
    
    if [ "$converged" = false ]; then
      echo "   ⚠ Mencapai batas iterasi ($max_iter). Ukuran akhir: ${actual_size_mb} MB (target ${SIZE_MB} MB)" >&2
      whiptail --msgbox "⚠ Konversi selesai dengan ukuran ${actual_size_mb} MB (target ${SIZE_MB} MB)\nSelisih lebih: $(echo "$actual_size_mb - $SIZE_MB" | bc -l) MB" 12 55
    fi

  else
    # MODE CRF Quality
    if [ "$CODEC" = "265" ]; then
      ffmpeg -y -i "$file" -r "$FPS_VAL" $SCALE \
        -c:v libx265 -crf $CRF \
        -c:a aac -b:a 128k "$out" < /dev/null
    else
      ffmpeg -y -i "$file" -r "$FPS_VAL" $SCALE \
        -c:v libx264 -crf $CRF \
        -c:a aac -b:a 128k "$out" < /dev/null
    fi

    if [ ! -f "$out" ]; then
      whiptail --msgbox "❌ GAGAL mengkonversi $name\nCek apakah file video rusak atau codec tidak didukung." 12 55
      continue
    fi
  fi

done

whiptail --msgbox "✅ DONE" 10 40

done
