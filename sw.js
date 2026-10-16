/* sw.js — service worker Twibon.
 *
 * Algoritma cache (sengaja "matang", bukan sekadar cache-first):
 *
 *  1. Aplikasi ini SATU berkas (index.html) dan seluruh CSS/JS-nya menempel
 *     di dalamnya, tanpa aset eksternal. Karena itu tidak ada berkas terpisah
 *     yang bisa "terjebak" versi lama.
 *  2. Permintaan NAVIGASI (HTML) selalu network-first. Selama ada jaringan,
 *     pengguna SELALU menerima kode terbaru; cache hanya dipakai sebagai
 *     cadangan saat luring. Inilah inti jaminan "cache tidak menghambat
 *     pembaruan kode di masa depan".
 *  3. Aset statis (ikon/manifest) memakai stale-while-revalidate: cepat,
 *     tetapi tetap diperbarui di latar belakang.
 *  4. Nama cache memuat VERSI. Saat versi dinaikkan, seluruh cache lama
 *     dihapus pada tahap activate sehingga tidak menumpuk.
 *  5. skipWaiting() + clients.claim() membuat service worker baru langsung
 *     aktif, dan halaman menawarkan tombol "Muat ulang" (tidak memuat ulang
 *     paksa, supaya pekerjaan pengguna yang sedang berjalan tidak hilang).
 *
 * Naikkan VERSION bila daftar aset di SHELL berubah.
 */
const VERSION = 'v1';
const CACHE = `twibon-${VERSION}`;
const SHELL = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/icon-maskable-512.png',
  './apple-touch-icon.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    // Disimpan satu per satu: satu berkas gagal tidak membatalkan seluruh instalasi.
    await Promise.all(SHELL.map(async (url) => {
      try { await cache.add(new Request(url, { cache: 'reload' })); } catch { /* abaikan */ }
    }));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
    if (self.registration.navigationPreload) {
      try { await self.registration.navigationPreload.disable(); } catch { /* opsional */ }
    }
    await self.clients.claim();
  })());
});

self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') self.skipWaiting();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;      // tidak ada aset lintas asal

  if (req.mode === 'navigate') {
    event.respondWith((async () => {
      try {
        const fresh = await fetch(req);
        if (fresh && fresh.ok) {
          const cache = await caches.open(CACHE);
          cache.put('./index.html', fresh.clone());
        }
        return fresh;
      } catch {
        return (await caches.match(req))
          || (await caches.match('./index.html'))
          || new Response('Aplikasi belum tersimpan untuk mode luring.', {
            status: 503, headers: { 'Content-Type': 'text/plain; charset=utf-8' }
          });
      }
    })());
    return;
  }

  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const cached = await cache.match(req);
    const network = fetch(req).then((res) => {
      if (res && res.ok && res.type === 'basic') cache.put(req, res.clone());
      return res;
    }).catch(() => null);
    return cached || (await network) || new Response('', { status: 504 });
  })());
});
