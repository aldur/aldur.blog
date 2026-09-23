#!/usr/bin/env node
// OpenGraph image renderer (SVG -> WebP), called by the Jekyll `og_image`
// plugin. Runs entirely from npm packages:
//   - @resvg/resvg-wasm   rasterises the SVG to RGBA pixels (WebAssembly)
//   - @jsquash/webp       decodes the embedded background + encodes WebP (WASM)
//   - dejavu-fonts-ttf    the sans-serif faces (incl. the Greek mu glyph)
//
// resvg-wasm can't decode an embedded WebP, so the background (embedded as a
// WebP data-URI) is transcoded to PNG before rasterising.
//
// Usage:  node bin/og-render.mjs <manifest.json>
// where manifest.json is [{ "svg": "<in.svg path>", "out": "<out.webp path>" }, ...]
//
// SVGs are read from disk (rather than passed inline) so the large, identical
// background data-URI isn't duplicated once per job in the manifest.

import { readFile, writeFile } from "node:fs/promises";
import { deflateSync } from "node:zlib";
import { createRequire } from "node:module";
import { availableParallelism } from "node:os";
import { Worker, isMainThread, workerData } from "node:worker_threads";
import { initWasm, Resvg } from "@resvg/resvg-wasm";
import encodeWebp, { init as initWebpEncode } from "@jsquash/webp/encode.js";
import decodeWebp, { init as initWebpDecode } from "@jsquash/webp/decode.js";

const require = createRequire(import.meta.url);
const WEBP_QUALITY = 90;

// Minimal RGBA -> PNG encoder, so we don't pull in a PNG codec. PNG is just a
// signature + IHDR + a zlib-compressed IDAT (unfiltered scanlines) + IEND.
const CRC_TABLE = Uint32Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function pngChunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, "ascii"), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}
function encodePng({ data, width, height }) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // 8-bit channels
  ihdr[9] = 6; // RGBA
  const stride = width * 4;
  const raw = Buffer.alloc((stride + 1) * height);
  const src = Buffer.from(data.buffer, data.byteOffset, data.byteLength);
  for (let y = 0; y < height; y++) {
    raw[y * (stride + 1)] = 0; // filter: none
    src.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }
  return Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    pngChunk("IHDR", ihdr),
    pngChunk("IDAT", deflateSync(raw)),
    pngChunk("IEND", Buffer.alloc(0)),
  ]);
}

// Rewrite embedded `data:image/webp` backgrounds to PNG. Cached, since every
// card shares the same background.
const WEBP_URI = /data:image\/webp;base64,([A-Za-z0-9+/=]+)/g;
async function transcodeBackgrounds(svg, cache) {
  for (const [, b64] of svg.matchAll(WEBP_URI)) {
    if (cache.has(b64)) continue;
    const webp = Buffer.from(b64, "base64");
    const image = await decodeWebp(
      webp.buffer.slice(webp.byteOffset, webp.byteOffset + webp.byteLength),
    );
    cache.set(b64, encodePng(image).toString("base64"));
  }
  return svg.replace(WEBP_URI, (_, b64) => `data:image/png;base64,${cache.get(b64)}`);
}

async function renderJobs(jobs) {
  // Initialise the WASM modules once, passing the precompiled modules
  // explicitly: Node can't fetch them by URL the way a browser would.
  await initWasm(readFile(require.resolve("@resvg/resvg-wasm/index_bg.wasm")));
  const compile = async (pkg) =>
    WebAssembly.compile(await readFile(require.resolve(pkg)));
  await initWebpEncode(await compile("@jsquash/webp/codec/enc/webp_enc_simd.wasm"));
  await initWebpDecode(await compile("@jsquash/webp/codec/dec/webp_dec.wasm"));

  // DejaVu Sans regular + bold: covers the title (bold), labels (regular) and
  // the Greek mu badge. Loaded explicitly so no system fonts are needed.
  const ttf = (name) =>
    readFile(require.resolve(`dejavu-fonts-ttf/ttf/${name}`));
  const fontBuffers = await Promise.all([
    ttf("DejaVuSans.ttf"),
    ttf("DejaVuSans-Bold.ttf"),
  ]);

  const bgCache = new Map();
  for (const { svg, out } of jobs) {
    const svgData = await transcodeBackgrounds(await readFile(svg, "utf8"), bgCache);
    const resvg = new Resvg(svgData, {
      font: {
        fontBuffers,
        loadSystemFonts: false,
        defaultFontFamily: "DejaVu Sans",
        sansSerifFamily: "DejaVu Sans",
      },
    });
    const rendered = resvg.render();
    const webp = await encodeWebp(
      {
        data: new Uint8ClampedArray(rendered.pixels),
        width: rendered.width,
        height: rendered.height,
      },
      { quality: WEBP_QUALITY },
    );
    await writeFile(out, Buffer.from(webp));
    rendered.free();
    resvg.free();
  }
}

async function main() {
  const manifestPath = process.argv[2];
  if (!manifestPath) {
    console.error("usage: og-render.mjs <manifest.json>");
    process.exit(2);
  }

  const jobs = JSON.parse(await readFile(manifestPath, "utf8"));
  if (jobs.length === 0) return;

  // Rendering and encoding are CPU-bound. Each worker initialises WASM and
  // fonts once for its batch. Bound concurrency to limit WASM memory usage.
  const requestedWorkers = Number(process.env.OG_RENDER_JOBS ?? 4);
  if (!Number.isSafeInteger(requestedWorkers) || requestedWorkers < 1) {
    throw new Error("OG_RENDER_JOBS must be a positive integer");
  }
  const count = Math.min(requestedWorkers, availableParallelism(), jobs.length);
  if (count === 1) return renderJobs(jobs);

  const batches = Array.from({ length: count }, () => []);
  jobs.forEach((job, i) => batches[i % count].push(job));
  const workers = [];
  try {
    await Promise.all(batches.map((batch) => new Promise((resolve, reject) => {
      const worker = new Worker(new URL(import.meta.url), { workerData: batch });
      workers.push(worker);
      worker.once("error", reject);
      worker.once("exit", (code) => {
        if (code === 0) resolve();
        else reject(new Error(`OG renderer worker exited with code ${code}`));
      });
    })));
  } finally {
    await Promise.all(workers.map((worker) => worker.terminate()));
  }
}

(isMainThread ? main() : renderJobs(workerData)).catch((err) => {
  console.error(err);
  process.exit(1);
});
