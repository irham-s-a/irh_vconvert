
# 🎬 irh_vconvert

Tool convert video berbasis Termux menggunakan FFmpeg + Whiptail UI.

---

## ⚙️ Fitur

- ✔ Auto install dependency (ffmpeg, bc, whiptail)
- ✔ UI menu (whiptail)
- ✔ Convert video batch (banyak file sekaligus)
- ✔ Mode convert:
  - CRF (quality)
  - Custom Size (MB target)
- ✔ Pilihan FPS (24 / 30 / 60 / original)
- ✔ Pilihan resolusi (360p - 1080p)
- ✔ Support format: mp4, mkv, mov
- ✔ Output otomatis ke folder

---

## 📁 Struktur Folder

```
/sdcard/irh_vconvert/
├── input   (taruh video di sini)
└── output  (hasil convert)
```

---

## 📲 Cara Install

1. Clone repo:
```bash
git clone https://github.com/irham-s-a/irh_vconvert.git
cd irh_vconvert
```

2. Install script:
```bash
bash install.sh
```

---

## ▶️ Cara Pakai

```bash
irh_vconvert
```

---

## 📥 Cara penggunaan

1. Taruh video ke:
```
/sdcard/irh_vconvert/input
```

2. Jalankan script:
```
irh_vconvert
```

3. Pilih menu:
- Convert by Size
- Convert by CRF

4. Tunggu proses selesai

---

## 📤 Hasil

File hasil akan masuk ke:
```
/sdcard/irh_vconvert/output
```

---

## ⚠️ Catatan

- CRF kecil = kualitas tinggi
- H265 lebih kecil tapi lebih berat
- Mode size tidak 100% presisi (tergantung video)

---

## 👨‍💻 Requirements

- Termux
- ffmpeg
- bc
- whiptail
