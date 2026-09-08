#!/usr/bin/env node
// Adds explicit width/height to <img> tags in the exported static HTML that
// have neither. Ghost's theme-level img_url() helper (used for the post
// feature image and feed/related-post thumbnails, as opposed to in-body
// content images, which Ghost's own lexical renderer already sizes) gives no
// way to know a rendered image's intrinsic dimensions ahead of time, so the
// theme emits srcset/sizes but no width/height — the browser then has no
// aspect ratio to reserve layout space with, and swapping in the loaded
// image shifts everything below it (this is what Lighthouse's "Avoid large
// layout shifts" / "Media element lacking an explicit size" audits flagged
// across several posts and every related-posts section).
//
// Runs after fix-content-images.js (so it sees the final srcset) and before
// generate-modern-images.js (so its <picture>-wrapping regex still matches a
// plain <img> tag, not a wrapped one).

const fs = require("fs");
const os = require("os");
const path = require("path");
const sharp = require("sharp");

const STATIC_DIR = path.join(__dirname, "..", "static");
const CONCURRENCY = Math.max(1, os.cpus().length);
const RASTER_EXT = /\.(jpe?g|png|webp|gif)$/i;

const IMG_TAG_RE = /<img\b[^>]*>/gi;
const SRC_RE = /\ssrc="([^"]*)"/i;
const HAS_WIDTH_RE = /\swidth="/i;
const HAS_HEIGHT_RE = /\sheight="/i;

function listHtmlFiles(dir) {
  return fs.readdirSync(dir, { recursive: true }).filter((f) => f.endsWith(".html"));
}

// Maps a static/-relative or absolute-on-this-domain URL to its file on disk.
function resolveLocalPath(url) {
  const noHost = url.replace(/^https?:\/\/[^/]+/, "");
  if (!noHost.startsWith("/")) return null;
  if (!RASTER_EXT.test(noHost)) return null;
  const filePath = path.join(STATIC_DIR, decodeURIComponent(noHost));
  return filePath.startsWith(STATIC_DIR) ? filePath : null;
}

async function runPool(items, limit, worker) {
  let cursor = 0;
  async function runner() {
    while (cursor < items.length) {
      const item = items[cursor++];
      await worker(item);
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, runner));
}

const dimensionCache = new Map(); // file path -> { width, height } | null

async function readDimensions(filePath) {
  if (dimensionCache.has(filePath)) return dimensionCache.get(filePath);
  let result = null;
  if (fs.existsSync(filePath)) {
    try {
      const { width, height } = await sharp(filePath).metadata();
      if (width && height) result = { width, height };
    } catch (err) {
      console.warn(`  metadata failed for ${filePath}: ${err.message}`);
    }
  }
  dimensionCache.set(filePath, result);
  return result;
}

function collectUnsizedSrcs(html, referenced) {
  const tags = html.match(IMG_TAG_RE) || [];
  for (const tag of tags) {
    if (HAS_WIDTH_RE.test(tag) && HAS_HEIGHT_RE.test(tag)) continue;
    const srcMatch = tag.match(SRC_RE);
    if (!srcMatch || !srcMatch[1]) continue;
    const filePath = resolveLocalPath(srcMatch[1]);
    if (filePath) referenced.add(filePath);
  }
}

function processFile(filePath) {
  const html = fs.readFileSync(filePath, "utf8");
  let changed = 0;

  const updated = html.replace(IMG_TAG_RE, (tag) => {
    if (HAS_WIDTH_RE.test(tag) && HAS_HEIGHT_RE.test(tag)) return tag;
    const srcMatch = tag.match(SRC_RE);
    if (!srcMatch || !srcMatch[1]) return tag;
    const srcFilePath = resolveLocalPath(srcMatch[1]);
    if (!srcFilePath) return tag;
    const dims = dimensionCache.get(srcFilePath);
    if (!dims) return tag;

    let newTag = tag;
    if (!HAS_WIDTH_RE.test(newTag)) {
      newTag = newTag.replace(/<img\b/i, `<img width="${dims.width}"`);
    }
    if (!HAS_HEIGHT_RE.test(newTag)) {
      newTag = newTag.replace(/<img\b/i, `<img height="${dims.height}"`);
    }
    changed += 1;
    return newTag;
  });

  if (changed > 0) {
    fs.writeFileSync(filePath, updated);
  }
  return changed;
}

async function main() {
  if (!fs.existsSync(STATIC_DIR)) {
    console.error(`No static/ export found at ${STATIC_DIR} — run gssg first.`);
    process.exit(1);
  }

  const files = listHtmlFiles(STATIC_DIR);

  const referenced = new Set();
  for (const relFile of files) {
    const html = fs.readFileSync(path.join(STATIC_DIR, relFile), "utf8");
    collectUnsizedSrcs(html, referenced);
  }

  const toRead = Array.from(referenced);
  console.log(`add-image-dimensions: reading dimensions for ${toRead.length} unsized image(s)`);
  await runPool(toRead, CONCURRENCY, readDimensions);

  let totalChanged = 0;
  let filesChanged = 0;

  for (const relFile of files) {
    const filePath = path.join(STATIC_DIR, relFile);
    const changed = processFile(filePath);
    if (changed > 0) {
      filesChanged += 1;
      totalChanged += changed;
      console.log(`  ${relFile}: ${changed} image(s) sized`);
    }
  }

  console.log(
    `add-image-dimensions: sized ${totalChanged} image(s) across ${filesChanged} file(s)`
  );
}

main();
