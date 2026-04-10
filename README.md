# 🎬 irh_vconvert

Tool convert video berbasis Termux dengan UI Whiptail, dilengkapi deteksi perangkat keras dan koreksi ukuran file otomatis.

---

## ⚙️ Fitur Lengkap

- ✅ Auto install dependency (ffmpeg, ffprobe, bc, whiptail, mediainfo)
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

---

## 📁 Struktur Folder

```

/sdcard/irh_vconvert/
├── input   (letakkan video di sini)
└── output  (hasil konversi)

```

---

## 📲 Cara Install

1. **Clone repository**
   ```bash
   git clone https://github.com/irham-s-a/irh_vconvert.git
   cd irh_vconvert
```

1. Jalankan installer (akan otomatis menginstal dependensi dan membuat alias irh-vconvert)
   ```bash
   bash install.sh
   ```
2. Pastikan Termux memiliki akses penyimpanan
   ```bash
   termux-setup-storage
   ```

---

▶️ Cara Pakai

Setelah install, cukup ketik:

```bash
irh-vconvert
```

Atau jika ingin menjalankan langsung dari folder:

```bash
bash irh_vconvert.sh
```

---

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

---

📤 Hasil

File hasil konversi akan berada di:

```
/sdcard/irh_vconvert/output/
```

Nama file: conv_<nama asli>

---

⚠️ Catatan

· CRF kecil = kualitas tinggi (ukuran lebih besar)
· H265 lebih kecil tapi lebih berat saat encoding
· Mode Size Target tidak 100% presisi karena faktor kompleksitas video, tetapi iterasi koreksi akan mendekati target dengan toleransi 0.5 MB.
· Jika durasi tidak terbaca, script akan menggunakan metode decode yang lambat – harap bersabar.

---

👨‍💻 Requirements

· Termux
· ffmpeg
· bc
· whiptail
· mediainfo

---

📄 Lisensi

MIT License

---

Dibuat oleh irham-s-a
