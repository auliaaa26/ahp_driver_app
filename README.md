# ahp_driver_app

Flutter app untuk driver dengan setup Supabase Auth yang siap dipakai.

## Setup Supabase

1. Buat project di Supabase dan ambil `Project URL` serta `publishable key` dari dashboard project.
2. Jalankan dependency install:

```bash
flutter pub get
```

3. Buat file konfigurasi lokal dari template:

```bash
cp env/supabase.example.json env/supabase.local.json
```

4. Isi `env/supabase.local.json` dengan kredensial Supabase milik project.
5. Pastikan tabel inti di Supabase sudah ada sesuai schema backend kamu: `profiles`, `pengiriman`, `paket`, `bukti_pengiriman`, `detail_pengiriman`, dan `tracking_pengiriman`.
6. Jalankan isi file `supabase/schema.sql` untuk menyiapkan bucket Storage `delivery-proofs`.
7. Buat user driver lewat Supabase Auth, lalu pastikan email user itu ada juga di tabel `profiles`.
8. Pastikan `profiles.nama` sama dengan nilai `pengiriman.driver`, karena app memetakan tugas driver lewat dua kolom itu.
9. Jika butuh data contoh, gunakan `supabase/seed_example.sql`.
10. Jalankan app dengan `--dart-define-from-file`:

```bash
flutter run --dart-define-from-file=env/supabase.local.json
```

## Yang Sudah Terpasang

- Inisialisasi Supabase di `main.dart`
- Konfigurasi aman via `String.fromEnvironment`
- Login memakai `Supabase Auth` dengan email dan password
- Session check saat splash screen, jadi user yang masih login akan langsung masuk app
- Logout Supabase dari halaman profil
- Halaman `Tugas` membaca `pengiriman` aktif berdasarkan `pengiriman.driver`
- Halaman `Riwayat` membaca `pengiriman` dengan status `Sampai`
- Halaman `Profil` membaca tabel `profiles` berdasarkan email user yang login
- Detail barang diambil dari tabel `paket`
- Bukti pengiriman disimpan ke Storage dan direkam ke tabel `bukti_pengiriman`
- Timeline status driver ditulis ke tabel `tracking_pengiriman`
- Timestamp pengiriman selesai dan receipt URL diperbarui ke `detail_pengiriman`
- Upload bukti pengiriman ke Supabase Storage bucket `delivery-proofs`
- Tombol Maps membuka Google Maps berdasarkan koordinat atau alamat tugas
- Foto profil di halaman profil masih bersifat lokal di device, karena schema `profiles` yang kamu kirim belum punya kolom avatar

## Struktur Data

Tabel utama yang dipakai app:

- `profiles`
  Kunci mapping akun driver di app: `email`, `nama`, `no_hp`, `role`
- `pengiriman`
  Sumber data tugas dan riwayat: `driver`, `no_resi`, `nama_penerima`, `alamat_tujuan`, `status`, `asal_lat`, `asal_lng`, `tujuan_lat`, `tujuan_lng`
- `paket`
  Detail barang: `nama_barang`, `berat`, `jenis`
- `bukti_pengiriman`
  Menyimpan URL/path foto bukti dan waktu upload
- `detail_pengiriman`
  Menyimpan `delivered_at` dan `goods_receipt_url`
- `tracking_pengiriman`
  Menyimpan log perubahan status driver

File [supabase/schema.sql](/home/lonecatz/KULIAH/KP_sebelah/app/ahp_driver_app/supabase/schema.sql:1) sekarang hanya menyiapkan Storage yang dipakai app, bukan membuat ulang tabel inti.

## Catatan

- Jika `SUPABASE_URL` atau `SUPABASE_PUBLISHABLE_KEY` belum diisi, app tetap bisa dibuka tetapi login Supabase akan dinonaktifkan.
- File `env/supabase.local.json` sudah di-ignore dari git.
- Jika halaman profil kosong/error, biasanya email di `auth.users` belum cocok dengan `profiles.email`.
- Jika tugas tidak muncul, biasanya `profiles.nama` belum sama dengan `pengiriman.driver`.
- Jika upload gagal, cek bucket/policy `delivery-proofs` dan izin insert ke tabel `bukti_pengiriman`.
