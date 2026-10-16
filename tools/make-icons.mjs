// tools/make-icons.mjs — menghasilkan ikon PWA tanpa dependensi apa pun.
// Pakai: node tools/make-icons.mjs
//
// Encoder PNG ditulis sendiri memakai zlib bawaan Node, jadi tidak perlu
// ImageMagick/Pillow/kanvas. Jalankan ulang bila ingin mengubah desain ikon.
import { deflateSync } from 'node:zlib';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const OUT = join(ROOT, 'icons');

/* ── encoder PNG minimal (8-bit RGBA, filter 0) ── */
let TABLE = null;
function crc32(buf) {
  if (!TABLE) {
    TABLE = new Int32Array(256);
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      TABLE[n] = c;
    }
  }
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length, 0);
  const t = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([t, data])), 0);
  return Buffer.concat([len, t, data, crc]);
}
function encodePng(width, height, rgba) {
  const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0); ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  const stride = width * 4;
  const raw = Buffer.alloc((stride + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (stride + 1)] = 0;                                   // filter: none
    rgba.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }
  return Buffer.concat([sig, chunk('IHDR', ihdr), chunk('IDAT', deflateSync(raw, { level: 9 })), chunk('IEND', Buffer.alloc(0))]);
}

/* ── desain ikon ── */
const BG = [79, 70, 229];      // #4f46e5 (aksen aplikasi)
const FG = [255, 255, 255];    // cincin putih
const RING_R = 0.235;          // jari-jari cincin (relatif sisi)
const RING_W = 0.085;          // tebal cincin
const CORNER = 0.22;           // jari-jari sudut (ikon "any")

function insideRounded(u, v, r) {
  if (r <= 0) return true;
  const qx = Math.abs(u - 0.5) - (0.5 - r);
  const qy = Math.abs(v - 0.5) - (0.5 - r);
  return Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) <= r;
}

function render(size, { rounded }) {
  const ss = 4, out = Buffer.alloc(size * size * 4), n = ss * ss;
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      let pa = 0, pr = 0, pg = 0, pb = 0;
      for (let sy = 0; sy < ss; sy++) {
        for (let sx = 0; sx < ss; sx++) {
          const u = (x + (sx + 0.5) / ss) / size;
          const v = (y + (sy + 0.5) / ss) / size;
          const inBg = insideRounded(u, v, rounded ? CORNER : 0);
          const d = Math.hypot(u - 0.5, v - 0.5);
          const inRing = Math.abs(d - RING_R) <= RING_W / 2;
          const c = inRing ? FG : inBg ? BG : null;
          if (c) { pa++; pr += c[0]; pg += c[1]; pb += c[2]; }   // prata-rata pramultiplied (a=1)
        }
      }
      const a = Math.round((pa / n) * 255);
      const i = (y * size + x) * 4;
      out[i]     = pa ? Math.round(pr / pa) : 0;
      out[i + 1] = pa ? Math.round(pg / pa) : 0;
      out[i + 2] = pa ? Math.round(pb / pa) : 0;
      out[i + 3] = a;
    }
  }
  return encodePng(size, size, out);
}

mkdirSync(OUT, { recursive: true });
const jobs = [
  [join(OUT, 'icon-192.png'), 192, { rounded: true }],
  [join(OUT, 'icon-512.png'), 512, { rounded: true }],
  [join(OUT, 'icon-maskable-512.png'), 512, { rounded: false }],   // full-bleed, aman untuk zona mask
  [join(ROOT, 'apple-touch-icon.png'), 180, { rounded: false }],   // iOS membulatkan sendiri
];
for (const [file, size, opts] of jobs) {
  const png = render(size, opts);
  writeFileSync(file, png);
  console.log(`${file.replace(ROOT + '/', '')} — ${size}x${size}, ${png.length} byte`);
}
