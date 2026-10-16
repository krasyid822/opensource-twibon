# Twibon — Pembuat Twibbon Gratis

Aplikasi web **statis satu berkas** (`index.html`): tempel fotomu ke template twibbon
(gambar PNG dengan bagian tengah transparan), atur posisinya, lalu unduh hasilnya.

Semua proses berjalan **di dalam browser** (Canvas API) — **tanpa server, tanpa database,
tanpa login, tanpa iklan, tanpa watermark**. Fotomu tidak pernah dikirim ke mana pun.

Ini adalah alternatif bebas (open source) untuk fitur-fitur twibbon yang biasanya berbayar.

## Fitur

| Fitur | Keterangan |
| --- | --- |
| Isi lubang otomatis | Mendeteksi area transparan template lalu menaruh foto tepat di dalamnya |
| Atur manual | Geser (mouse/sentuh), cubit/gulir untuk zoom, cubit dua jari untuk memutar, cermin, putar 90° |
| Isi penuh | Mode alternatif: foto menutupi seluruh kanvas, template menyaringnya |
| Filter foto | Kecerahan, kontras, saturasi, hitam-putih — semuanya gratis |
| Teks | Nama/acara/angkatan, ukuran bebas (tanpa dipangkas otomatis), warna, garis tepi, 9 posisi, **kerapatan huruf & kata**, ikut menyesuaikan ukuran template |
| Latar belakang | Transparan (PNG) atau warna pilihan (JPG) |
| Unduh | PNG transparan atau JPG, pada resolusi penuh template (1×) atau 0,5× / 2× |
| Tanpa watermark | Tidak pernah ada watermark, tanpa batas jumlah unduhan |
| Contoh bawaan | Tombol "Pakai contoh" untuk mencoba tanpa berkas apa pun |
| Cara memasukkan gambar | Tombol pilih berkas, **kamera di dalam aplikasi**, seret & lepas, atau tempel (Ctrl+V) |
| Pratinjau melayang | Saat kanvas tergulir keluar layar, pratinjau kecil muncul di pojok agar hasil tetap terlihat saat menyetel filter (klik untuk kembali) |
| Teks melingkar | Teks mengikuti tepi lubang dengan **rotasi sudut 0–360°** + pengatur jari-jari |
| PWA / luring penuh | Bisa dipasang ke layar utama; seluruh fitur tetap jalan tanpa internet |
| `run.sh` | Skrip menjalankan proyek secara lokal (server statis + membuka peramban) |
| `push.sh` | Skrip push ke GitHub + naikkan versi cache otomatis + aktifkan Pages + deploy (sekali perintah) |

## Cara pakai

1. Buka situsnya (atau `index.html` langsung di browser).
2. **1. Template twibbon** → pilih gambar PNG transparan (bagian tengah kosong).
   Template biasanya disediakan penyelenggara acara. Atau klik **Pakai contoh**.
3. **2. Fotomu** → pilih foto (bisa dari kamera ponsel).
4. Foto otomatis diposisikan. Geser / cubit untuk merapikan. Gunakan **Lanjutan** bila
   ingin menambah filter, teks, atau warna latar.
5. Klik **Unduh PNG** (latar transparan) atau **Unduh JPG** (latar berwarna).

Pintasan papan tombol: `←↑→↓` geser, `+` / `-` zoom, `Shift` + panah untuk langkah besar, `R` reset.

## Menjalankan di komputer sendiri

Cara tercepat — pakai skrip yang disediakan:

```bash
./run.sh                 # buka http://127.0.0.1:8080
PORT=3000 ./run.sh       # ganti port
HOST=0.0.0.0 ./run.sh    # bisa dibuka dari ponsel di jaringan yang sama
NO_OPEN=1 ./run.sh       # jangan buka peramban otomatis
```

`run.sh` hanya menjalankan server statis (default: `python3 -m http.server`) lalu membuka
peramban. Server statis apa pun bisa dipakai, misalnya:

```bash
python3 -m http.server 8080
npx --yes serve -l 8080 .
php -S 127.0.0.1:8080
```

Tanpa server pun bisa: cukup buka `index.html` langsung di peramban. Bedanya, pada
`file://` service worker (mode luring/PWA) tidak berjalan — lihat bagian berikut.

## Mode luring (PWA)

Aplikasi ini adalah PWA: bisa dipasang ke layar utama dan **bekerja penuh tanpa internet**
(memuat template dari galeri, mengatur foto, dan mengunduh hasil semuanya lokal — tidak ada
permintaan jaringan sama sekali).

Berkasnya:

| Berkas | Fungsi |
| --- | --- |
| `manifest.webmanifest` | Nama, ikon, warna tema, mode `standalone` |
| `sw.js` | Service worker + strategi cache |
| `icons/`, `apple-touch-icon.png` | Ikon (dibuat oleh `tools/make-icons.mjs`, tanpa dependensi) |
| `tools/make-icons.mjs` | Pembuat ikon: `node tools/make-icons.mjs` |
| `tools/set-version.sh` | Menulis nomor versi ke `sw.js` + `index.html` (dipakai otomatis oleh `push.sh`) |

### Kenapa cache-nya tidak akan menghambat pembaruan kode

Ini kekhawatiran yang wajar pada PWA, dan diselesaikan secara sengaja:

1. **Seluruh aplikasi ada di satu berkas** (`index.html`), termasuk CSS dan JavaScript.
   Tidak ada berkas JS/CSS terpisah yang bisa tertinggal versi lama di cache.
2. **Permintaan navigasi (HTML) selalu *network-first*.** Selama ada internet, pengguna
   selalu menerima kode terbaru; cache hanya dipakai sebagai cadangan saat luring. Jadi
   `git push` langsung terasa, tanpa perlu mengubah apa pun.
3. **Aset (ikon/manifest) memakai *stale-while-revalidate*** — cepat, tetap diperbarui.
4. **Nama cache memuat nomor versi** (`twibon-<versi>`). Saat versi dinaikkan, semua cache
   lama dihapus pada tahap `activate`, jadi tidak menumpuk.
5. **`skipWaiting()` + `clients.claim()`** membuat service worker baru langsung aktif;
   halaman menampilkan tombol **"Muat ulang"** (tidak memuat ulang paksa, supaya foto yang
   sedang diatur tidak hilang).

Jika daftar berkas di `SHELL` (`sw.js`) berubah, naikkan versi agar cache lama dibuang.

### Versi & pembaruan otomatis

Nomor versi disimpan di **satu sumber** dan dipakai dua tempat:

- `sw.js` → `const VERSION = 'v1.0.0';` (menentukan nama cache)
- `index.html` → `<meta name="app-version" content="v1.0.0">` (ditampilkan di footer dan
  notifikasi pembaruan)

`push.sh` **menaikkan versi secara otomatis** setiap kali ada perubahan yang akan di-commit
(memakai `tools/set-version.sh`, format waktu `v2026.10.16.0920`). Jadi setiap push
menghasilkan nama cache baru → cache lama dibuang sendiri, dan pengguna lama menerima
notifikasi. Bila tidak ada perubahan, versi dibiarkan agar tidak membuat commit kosong.

Menulis versi manual bila perlu:

```bash
tools/set-version.sh            # otomatis dari waktu sekarang
tools/set-version.sh v1.2.3     # versi tertentu
```

**Notifikasi pembaruan** menampilkan versi lama dan versi baru, misalnya
`Versi baru tersedia: v1.0.0 → v1.0.1`, beserta tombol **Muat ulang**. Versi baru diperoleh
dengan menanyai service worker baru lewat `MessageChannel` (pesan `{type:'VERSION'}`).

### Menguji mode luring

1. Jalankan `./run.sh` (wajib `http://`, bukan `file://`).
2. Buka sekali agar service worker tersimpan.
3. Putuskan internet (atau centang "Offline" di DevTools → Network), lalu muat ulang —
   aplikasi tetap terbuka dan berfungsi penuh.

## Deploy ke GitHub Pages

Workflow tersedia di [`.github/workflows/pages.yml`](.github/workflows/pages.yml) dan
berjalan otomatis **setiap kali `git push`** ke `main`/`master`.

### Cara tercepat: satu perintah

```bash
./push.sh                  # git init + commit + gh repo create + push + aktifkan Pages + deploy
REPO_NAME=twibon ./push.sh # tentukan nama repo
VISIBILITY=private ./push.sh
DRY_RUN=1 ./push.sh        # lihat rencananya dulu, tanpa efek samping
```

`push.sh` melakukan semuanya secara berurutan: `git init` (bila perlu) → **naikkan versi
cache otomatis** (bila ada perubahan) → commit → `gh repo create` (bila perlu, dengan
deskripsi repo) → `git push` → aktifkan Pages (`build_type=workflow`) → jalankan workflow
deploy → cetak URL situs. Aman dijalankan berulang kali (idempoten). Perlu `git` + `gh` dan
sudah `gh auth login`.

### Cara manual

#### Langkah 1 — buat repo dan push

```bash
git init
git add .
git commit -m "Twibon: pembuat twibbon statis, gratis tanpa watermark"
git branch -M main
git remote add origin git@github.com:<pengguna>/<repo>.git
git push -u origin main
```

#### Langkah 2 — aktifkan Pages (sekali saja)

**Cara CLI (disarankan).** Dari dalam direktori repo, `{owner}` dan `{repo}` otomatis
mengacu ke repo yang sedang aktif:

```bash
# aktifkan: coba buat dulu; kalau sudah ada (409) baru perbarui
gh api -X POST repos/{owner}/{repo}/pages -f build_type=workflow \
  || gh api -X PUT  repos/{owner}/{repo}/pages -f build_type=workflow

# verifikasi
gh api repos/{owner}/{repo}/pages --jq '{build_type, html_url, status}'

# picu deploy tanpa perlu commit baru
gh workflow run pages.yml && gh run watch
```

Syaratnya: kamu punya akses **admin** ke repo, dan token `gh` memuat scope `repo`
(cek dengan `gh auth status`). Untuk PAT fine-grained, beri izin **Pages: write**.

**Cara UI (alternatif).** Repo → **Settings** → **Pages** → **Build and deployment** →
**Source: GitHub Actions**.

Setelah aktif, setiap `git push` ke `main`/`master` otomatis menerbitkan situs di
`https://<pengguna>.github.io/<repo>/`. Status ada di tab **Actions**.

> **Catatan scope push:** karena kamu memakai SSH untuk operasi git, mendorong berkas
> `.github/workflows/pages.yml` aman-aman saja. Bila suatu saat push lewat HTTPS dengan
> token OAuth `gh`, tambahkan scope `workflow` dulu (`gh auth refresh -s workflow`),
> jika tidak GitHub akan menolak berkas workflow.

#### Opsi: aktifkan Pages sepenuhnya otomatis dari workflow

`actions/configure-pages` bisa mengaktifkan Pages sendiri, **tetapi wajib memakai token
selain `GITHUB_TOKEN`** (menurut dokumentasi resminya). Buat PAT dengan scope `repo`
(atau fine-grained **Pages: write**), simpan sebagai secret repo bernama `GH_PAGES_TOKEN`,
lalu buka komentar pada langkah **Konfigurasi Pages** di
[`.github/workflows/pages.yml`](.github/workflows/pages.yml):

```yaml
        with:
          token: ${{ secrets.GH_PAGES_TOKEN }}
          enablement: true
```

Kalau tidak mau menambah secret, cukup pakai Langkah 2 di atas sekali saja.

## Status fitur berbayar: sekarang gratis

Twibbonize mengenakan biaya untuk beberapa hal; yang bisa dikerjakan sepenuhnya di browser
sudah dibuka di sini.

| Fitur berbayar di Twibbonize | Harganya | Status di Twibon |
| --- | --- | --- |
| Hapus watermark | Premium Supporter $2,99/bln, Premium Creator $11,99/bln | **Gratis & permanen** — memang tidak pernah dipasang |
| Tanpa iklan | Premium | **Gratis** — tidak ada iklan sama sekali |
| Filter foto (Add Filter) | Premium Supporter | **Gratis** |
| Tambah teks (Add Text) | Premium Supporter | **Gratis** |
| Unduh resolusi penuh (HD) | Premium | **Gratis**, hingga 2× ukuran template |
| Template/frame sendiri | Premium Creator | **Gratis**, unggah PNG apa pun |
| Beberapa frame dalam satu tautan | Premium Creator | Sebagian — ganti-ganti berkas template secara manual |
| Analytics, tautan privat/unlisted, halaman kampanye, kustomisasi halaman | Premium Creator | **Belum bisa** — memerlukan server/database, sedangkan proyek ini sengaja hanya statis |

Bagian "belum bisa" sengaja tidak dipaksakan agar tetap tanpa server, tanpa database, dan
bisa di-hosting gratis di GitHub Pages.

## Teknis

- Satu berkas `index.html`: HTML + CSS + JavaScript (vanilla), tanpa dependensi, tanpa build.
- Render memakai `<canvas>`; ekspor memakai `canvas.toBlob()` dan tautan unduhan.
- Deteksi lubang: membaca kanal alfa template (diturunkan skalanya), lalu *flood fill*
  dari titik tengah untuk menemukan area transparan yang terhubung, dan mengambil kotak
  pembatasnya. Bila tidak ada lubang yang masuk akal, dipakai mode "isi penuh".
- Transformasi foto disimpan dalam koordinat template (px desain), sehingga pratinjau dan
  hasil unduhan selalu konsisten pada skala apa pun.
- Foto dibatasi maksimum 5000 px sisi terpanjang agar tetap ringan di ponsel.
- Tema terang/gelap mengikuti pengaturan sistem; tata letak mengutamakan layar ponsel.
- PWA: `sw.js` (network-first untuk HTML, stale-while-revalidate untuk aset, cache ber-versi)
  + `manifest.webmanifest` + ikon yang dibuat `tools/make-icons.mjs` secara mandiri
  (encoder PNG sendiri memakai `zlib` bawaan Node — tanpa dependensi).

## Lisensi

GNU General Public License v3.0 atau lebih baru — lihat [`LICENSE`](LICENSE).
Proyek ini bebas dipakai, dipelajari, dan disebarkan; setiap turunannya tetap bebas.

---
