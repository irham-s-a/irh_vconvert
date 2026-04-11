
# 🎬 irh_vconvert

## 🇮🇩 Bahasa Indonesia

Tool convert video berbasis Termux dengan UI Whiptail, dilengkapi deteksi perangkat keras dan koreksi ukuran file otomatis.

### ⚙️ Fitur Lengkap

- ✅ Auto install dependency (ffmpeg, ffprobe, bc, whiptail, mediainfo) — dilakukan oleh script utama saat pertama kali dijalankan
- ✅ Deteksi spesifikasi perangkat (RAM, CPU core) → klasifikasi LOW / MEDIUM / HIGH
  - **LOW** → Terbatas (tidak dapat konversi 2K dan 4K)
  - **MEDIUM** → Peringatan (rekomendasi max 1080p, FPS 30)
  - **HIGH** → Normal
- ✅ Penanganan error library `libbluray.so.3` (reinstall otomatis jika diperlukan)
- ✅ Mode konversi:
  - **CRF Quality** (input nilai CRF, default 23, rentang 0–51)
  - **Size Target** (input ukuran dalam MB, dengan iterasi koreksi otomatis)
- ✅ Iterasi Size Target:
  - Safety factor awal 1.05 (cenderung lebih dari target)
  - Maksimal 5 iterasi
  - Toleransi kelebihan ≤ 0.5 MB
  - Hasil akhir **tidak boleh kurang dari target**
- ✅ Pilihan FPS (24, 30, 60, original)
- ✅ Pilihan resolusi (360p, 480p, 720p, 1080p, 2K, 4K, original)
- ✅ Batch processing (semua file dalam folder input akan diproses)
- ✅ Output otomatis ke folder `/sdcard/irh_vconvert/output`
- ✅ Penanganan durasi video dengan 3 metode (ffprobe, mediainfo, decode penuh)

### 📁 Struktur Folder

```

/sdcard/irh_vconvert/
├── input   (letakkan video di sini)
└── output  (hasil konversi)

```

### 📲 Cara Install

1. **Clone repository**
   ```
   git clone https://github.com/irham-s-a/irh_vconvert.git
   cd irh_vconvert

1. Jalankan install.sh
   ```
   bash install.sh

2. Pastikan Termux memiliki akses penyimpanan

   ```
   termux-setup-storage
   ```

▶️ Cara Pakai

Setelah install, cukup ketik:

```
irh-vconvert
```

📥 Panduan Penggunaan

1. Siapkan video
      Salin file video (mp4, mkv, mov) ke:
   ```
   /sdcard/irh_vconvert/input
   ```
2. Jalankan script
      Pilih menu Convert Video.
3. Pilih mode
      · CRF Quality → masukkan nilai CRF (18–28 direkomendasikan, default 23).
      · Size Target → masukkan ukuran target dalam MB (contoh: 50). Script akan mencoba mencapai ukuran ≥ target dengan kelebihan maksimal 0.5 MB.
4. Pilih codec, FPS, resolusi sesuai kebutuhan.
5. Tunggu proses selesai

📤 Hasil

File hasil konversi akan berada di:

```
/sdcard/irh_vconvert/output/
```

Nama file: conv_(nama asli file)

⚠️ Catatan

· CRF kecil = kualitas tinggi (ukuran lebih besar)
· H265 lebih kecil tapi lebih berat saat encoding
· Mode Size Target tidak 100% presisi karena faktor kompleksitas video, tetapi iterasi koreksi akan mendekati target dengan toleransi 0.5 MB.
· Jika durasi tidak terbaca, script akan menggunakan metode decode yang lambat – harap bersabar.

👨‍💻 Requirements

· Termux
· ffmpeg
· bc
· whiptail
· mediainfo

---

🇬🇧 English

A Termux-based video conversion tool with Whiptail UI, equipped with hardware detection and automatic file size correction.

⚙️ Full Features

- ✅ Auto install dependencies (ffmpeg, ffprobe, bc, whiptail, mediainfo) — done by the main script on first run
- ✅ Device spec detection (RAM, CPU cores) → classification LOW / MEDIUM / HIGH
  - LOW → Limited (cannot convert 2K and 4K)
  - MEDIUM → Warning (recommended max 1080p, FPS 30)
  - HIGH → Normal
- ✅ Handle libbluray.so.3 library error (auto reinstall if needed)
- ✅ Conversion modes:
  - CRF Quality (input CRF value, default 23, range 0–51)
  - Size Target (input target size in MB, with auto correction iteration)
- ✅ Size Target iteration:
  - Initial safety factor 1.05 (tends to overshoot target)
  - Max 5 iterations
  - Overshoot tolerance ≤ 0.5 MB
  - Final result must not be below target
- ✅ FPS options (24, 30, 60, original)
- ✅ Resolution options (360p, 480p, 720p, 1080p, 2K, 4K, original)
- ✅ Batch processing (all files in input folder will be processed)
- ✅ Auto output to folder ```/sdcard/irh_vconvert/output```
- ✅ Video duration handling with 3 methods (ffprobe, mediainfo, full decode)

📁 Folder Structure

```
/sdcard/irh_vconvert/
├── input   (put your videos here)
└── output  (converted videos)
```

📲 Installation

1. Clone repository
   ```
   git clone https://github.com/irham-s-a/irh_vconvert.git
   cd irh_vconvert
   ```
2. Run install.sh
   ```
   bash install.sh
   ```
3. Make sure Termux has storage access
   ```
   termux-setup-storage
   ```

▶️ Usage

After installation, just type:

```
irh-vconvert
```

📥 How to Use

1. Prepare videos
      Copy video files (mp4, mkv, mov) to:
   ```
   /sdcard/irh_vconvert/input
   ```
2. Run script
      Select Convert Video menu.
3. Choose mode
      · CRF Quality → enter CRF value (18–28 recommended, default 23).
      · Size Target → enter target size in MB (e.g., 50). Script will try to reach size ≥ target with max overshoot 0.5 MB.
4. Select codec, FPS, resolution as needed.
5. Wait until finished

📤 Output

Converted files will be in:

```
/sdcard/irh_vconvert/output/
```

Filename: conv_(original file name)

⚠️ Notes

· Lower CRF = higher quality (larger file size)
· H265 is smaller but heavier during encoding
· Size Target mode is not 100% precise due to video complexity, but iteration correction will approach target with 0.5 MB tolerance.
· If duration cannot be read, script will use slow decode method – please be patient.

👨‍💻 Requirements

· Termux
· ffmpeg
· bc
· whiptail
· mediainfo

---

📄 Lisensi / License

MIT License

---

Dibuat oleh / Created by irham-s-a
