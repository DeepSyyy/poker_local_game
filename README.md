# 🃏 Texas Hold'em Poker Chip Simulator

Aplikasi **Virtual Chip Manager & Table Simulator** untuk permainan Texas Hold'em Poker menggunakan **Flutter**. Dirancang khusus untuk sesi bermain santai (*casual home games*) bersama teman menggunakan kartu fisik asli di dunia nyata—tanpa perlu repot membawa kepingan chip fisik dan tanpa unsur judi uang sungguhan.

---

## 📱 Skenario Penggunaan (*Shared Table Mode*)
Letakkan smartphone atau tablet Anda secara mendatar di tengah meja kopi/meja makan. Layar aplikasi berfungsi sebagai **meja felt dan baki chip digital**, di mana setiap pemain dapat melihat pot, ronde aktif, serta menekan tombol taruhannya masing-masing saat gilirannya tiba.

---

## ✨ Fitur Utama

### 1. ⚙️ Setup Fleksibel (2–8 Pemain)
- **Kapasitas**: Mendukung 2 hingga 8 pemain dengan penataan kursi melingkar otomatis.
- **Kustomisasi**: Nama pemain dapat disesuaikan dengan nama teman asli.
- **Modal Awal**: Pilihan cepat saldo chip awal (500, 1.000, 2.000, 5.000 chip).
- **Struktur Blinds**: Opsi mengaktifkan Small Blind (SB) dan Big Blind (BB) otomatis, atau bermain santai tanpa blinds.

### 2. 🎮 Logika Taruhan Resmi Texas Hold'em
- **Rotasi Dealer Button (`D`)**: Posisi Dealer, SB, dan BB otomatis bergeser searah jarum jam setiap hand baru.
- **Aksi Pemain Lengkap**:
  - **CHECK**: Hanya tersedia jika tidak ada kenaikan taruhan meja.
  - **CALL [X]**: Menyamakan nominal taruhan tertinggi saat ini.
  - **RAISE...**: Modal slider 2-kolom landscape dengan shortcut cepat (`Min`, `2x`, `3x`, `½ Pot`, `Full Pot`, `All-in`).
  - **FOLD**: Menyerah (jika tersisa 1 pemain aktif, pot otomatis diserahkan ke pemain tersebut).
  - **ALL-IN**: Mempertaruhkan seluruh sisa chip.
- **Transisi Ronde (Streets)**:
  - **Pre-Flop** $\rightarrow$ **Flop** (3 kartu meja) $\rightarrow$ **Turn** (kartu ke-4) $\rightarrow$ **River** (kartu ke-5) $\rightarrow$ **Showdown**.
- **Kalkulasi Pot & Side Pot**: Menghitung *Main Pot* dan *Side Pot* secara otomatis jika ada pemain yang All-in dengan chip lebih sedikit.

### 3. 🏆 Showdown & Pembagian Chip
- Pemilihan pemenang kartu terbaik yang intuitif di akhir ronde.
- Mendukung **Split Pot** jika terdapat lebih dari satu pemain dengan kombinasi kartu bernilai seri.
- Tombol **"Next Hand"** untuk langsung memutar posisi tombol Dealer dan memotong blinds untuk ronde selanjutnya.

### 4. 💎 Desain Visual & Kenyamanan (UX)
- **Fullscreen Immersive (`SystemUiMode.immersiveSticky`)**: Status bar dan bilah navigasi disembunyikan agar layar 100% penuh untuk meja poker.
- **Floating HUD (Tanpa Navbar Memotong Meja)**:
  - Meja felt hijau zamrud mengisi 100% layar landscape.
  - Kapsul info blinds dan tombol menu mengambang transparan di sudut atas.
  - Action bar mengambang ramping (*floating dock*) di bagian bawah layar.
- **Optimasi Posisi 2 Pemain (Heads-Up)**: Kedua pemain ditempatkan di sisi Kiri dan Kanan yang saling berhadapan, bebas dari tumpukan vertikal.
- **Rebuy / Top-up Chip**: Menambah chip pemain yang kehabisan saldo tanpa harus mereset game.
- **Log Riwayat Aksi**: Catatan lengkap setiap aksi taruhan di meja.

---

## 🛠️ Struktur Proyek

```
lib/
├── app.dart                                # Root MaterialApp & routing
├── main.dart                               # Entry point, Fullscreen & Landscape config
├── controllers/
│   └── poker_game_controller.dart          # Engine logika Texas Hold'em & State Manager
├── core/
│   ├── constants/
│   │   └── app_colors.dart                 # Palet warna poker (felt, chip, actions)
│   └── theme/
│       └── app_theme.dart                  # Konfigurasi ThemeData Material 3
├── models/
│   ├── poker_player.dart                   # Model data pemain & status
│   └── poker_game_state.dart               # Enum BettingStreet, Pot, ActionLog
└── screens/
    └── poker/
        ├── setup_screen.dart               # Layar konfigurasi awal game
        ├── table_screen.dart               # Layar meja poker landscape utama
        └── widgets/
            ├── player_seat_widget.dart     # Kartu kursi pemain & badge
            ├── table_center_widget.dart    # Tampilan pot, street, CTA showdown
            ├── poker_action_bar.dart       # Floating action dock pemain
            ├── raise_dialog.dart           # Modal raise 2-kolom landscape
            ├── showdown_dialog.dart        # Dialog penyerahan pot ke pemenang
            ├── rebuy_dialog.dart           # Dialog top-up saldo chip
            └── action_history_sheet.dart   # Lembar riwayat aksi taruhan meja
```

---

## 🚀 Cara Menjalankan Aplikasi

### Persyaratan
- [Flutter SDK](https://flutter.dev) (v3.13 ke atas)
- Android / iOS Device atau Emulator

### Menjalankan dalam Mode Debug
```bash
flutter pub get
flutter run
```

### Menjalankan dalam Mode Release (Bebas Lepas Kabel USB)
Untuk performa maksimal dan penggunaan permanen di HP tanpa terhubung ke komputer:
```bash
flutter run --release
```

### Build File APK (Android)
```bash
flutter build apk --split-per-abi
```
File APK siap dipasang akan berada di: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.

### Deploy ke GitHub Pages (Web)
Proyek ini sudah dilengkapi file workflow otomatis di `.github/workflows/deploy.yml`:
1. Di repository GitHub Anda, buka **Settings** $\rightarrow$ **Pages**.
2. Pada opsi **Build and deployment** > **Source**, pilih **GitHub Actions**.
3. Setiap kali Anda melakukan `git push` ke branch `main`, aplikasi web akan otomatis di-build dan di-deploy ke alamat:
   `https://adyasena.github.io/belajar_flutter/`

---

## 🧪 Pengujian (Tests)

Proyek ini dilengkapi dengan unit test logika engine poker dan widget smoke test:
```bash
flutter test
```
Verifikasi kepatuhan linter:
```bash
flutter analyze
```

---

## 📄 Lisensi
Proyek ini dibuat untuk tujuan edukasi dan hiburan santai tanpa unsur perjudian uang asli. Bebas dimodifikasi untuk penggunaan pribadi.
