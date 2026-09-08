#!/usr/bin/env node
// Runs after fix-content-images.js, once the static export's <img> tags are
// in their final form. For every raster <img> (jpg/jpeg/png) it generates
// AVIF and WebP siblings on disk for each file referenced in src/srcset,
// then wraps the tag in <picture> with <source type="image/avif">,
// <source type="image/webp">, and the original <img> as the fallback —
// so a browser without AVIF/WebP support (or without <picture> support at
// all) just gets the original image, unchanged.
//
// No live Ghost server involved: unlike img_url(format="webp"), this bakes
// the alternate-format files directly into the static export, so there's
// nothing for gssg to have missed.

const fs = require("fs");
const path = require("path");
const sharp = require("sharp");

const STATIC_DIR = path.join(__dirname, "..", "static");
const RASTER_EXT = /\.(jpe?g|png)$/i;

const IMG_TAG_RE = /<img\b[^>]*>/gi;
const SRC_RE = /\ssrc="([^"]*)"/i;
const SRCSET_RE = /\ssrcset="([^"]*)"/i;
const SIZES_RE = /\ssizes="([^"]*)"/i;
const PRELOAD_LINK_RE = /<link\s+rel="preload"\s+as="image"[^>]*>/gi;
const HREF_RE = /\shref="([^"]*)"/i;

function listHtmlFiles(dir) {
  return fs.readdirSync(dir, { recursive: true }).filter((f) => f.endsWith(".html"));
}

// Maps a static/-relative or absolute-on-this-domain URL to its file on disk.
// Returns null for anything not servable from this export (external URLs,
// query strings we can't resolve, etc).
function resolveLocalPath(url) {
  const noHost = url.replace(/^https?:\/\/[^/]+/, "");
  if (!noHost.startsWith("/")) return null;
  if (!RASTER_EXT.test(noHost)) return null;
  const filePath = path.join(STATIC_DIR, decodeURIComponent(noHost));
  return filePath.startsWith(STATIC_DIR) ? filePath : null;
}

const conversionCache = new Map(); // src file path -> { avif: bool, webp: bool }

async function ensureModernVariants(filePath) {
  if (conversionCache.has(filePath)) return conversionCache.get(filePath);
  const result = { avif: false, webp: false };

  if (fs.existsSync(filePath)) {
    const avifPath = filePath.replace(RASTER_EXT, ".avif");
    const webpPath = filePath.replace(RASTER_EXT, ".webp");
    try {
      if (!fs.existsSync(avifPath)) {
        // effort defaults to 4; AVIF's encoder is slow enough that this step
        // alone added ~3.5 minutes to every deploy at the default. effort:2
        // cuts encode time by ~85% for only ~15% larger files — this build
        // runs on every push, so build time matters more than squeezing out
        // the last few KB.
        await sharp(filePath).avif({ quality: 55, effort: 2 }).toFile(avifPath);
      }
      result.avif = true;
    } catch (err) {
      console.warn(`  avif failed for ${filePath}: ${err.message}`);
    }
    try {
      if (!fs.existsSync(webpPath)) {
        await sharp(filePath).webp({ quality: 80 }).toFile(webpPath);
      }
      result.webp = true;
    } catch (err) {
      console.warn(`  webp failed for ${filePath}: ${err.message}`);
    }
  }

  conversionCache.set(filePath, result);
  return result;
}

function swapExt(url, ext) {
  return url.replace(RASTER_EXT, ext);
}

// Rebuilds a srcset string with each URL's extension swapped, only including
// entries whose modern-format file was actually generated.
async function buildModernSrcset(srcset, ext, checkKey) {
  const entries = srcset.split(",").map((e) => e.trim());
  const kept = [];
  for (const entry of entries) {
    const [url, descriptor] = entry.split(/\s+/, 2);
    const filePath = resolveLocalPath(url);
    if (!filePath) continue;
    const variants = await ensureModernVariants(filePath);
    if (!variants[checkKey]) continue;
    kept.push(`${swapExt(url, ext)}${descriptor ? " " + descriptor : ""}`);
  }
  return kept.join(", ");
}

async function buildReplacement(tag) {
  if (/<picture/i.test(tag)) return null; // defensive, shouldn't happen pre-wrap
  const srcMatch = tag.match(SRC_RE);
  if (!srcMatch) return null;
  const src = srcMatch[1];
  if (!RASTER_EXT.test(src)) return null; // svg/gif/etc — leave alone

  const srcsetMatch = tag.match(SRCSET_RE);
  const sizesMatch = tag.match(SIZES_RE);
  const srcset = srcsetMatch ? srcsetMatch[1] : null;
  const sizesAttr = sizesMatch ? ` sizes="${sizesMatch[1]}"` : "";

  const srcFilePath = resolveLocalPath(src);
  if (!srcFilePath) return null;
  const srcVariants = await ensureModernVariants(srcFilePath);
  if (!srcVariants.avif && !srcVariants.webp) return null; // nothing generated, skip

  const sources = [];

  if (srcVariants.avif) {
    const avifSrcset = srcset
      ? await buildModernSrcset(srcset, ".avif", "avif")
      : swapExt(src, ".avif");
    if (avifSrcset) {
      sources.push(`<source type="image/avif" srcset="${avifSrcset}"${sizesAttr}>`);
    }
  }

  if (srcVariants.webp) {
    const webpSrcset = srcset
      ? await buildModernSrcset(srcset, ".webp", "webp")
      : swapExt(src, ".webp");
    if (webpSrcset) {
      sources.push(`<source type="image/webp" srcset="${webpSrcset}"${sizesAttr}>`);
    }
  }

  if (sources.length === 0) return null;
  return `<picture>${sources.join("")}${tag}</picture>`;
}

// A bare <link rel="preload" as="image" href="original.jpg"> always fetches
// the original format, even when the <picture> element it's preloading for
// will actually pick an AVIF/WebP source. In principle a `type` attribute
// should let the browser skip a preload link for a format it can't render —
// but tested empirically this isn't reliably honored (observed all three
// typed links firing together, tripling the fetch instead of deduping it).
// So: preload exactly one format — the best one `<picture>` will pick in
// the near-universal case (AVIF, then WebP, then original) — rather than
// hedging with multiple links.
async function buildPreloadReplacement(tag) {
  const hrefMatch = tag.match(HREF_RE);
  if (!hrefMatch) return null;
  const href = hrefMatch[1];
  if (!RASTER_EXT.test(href)) return null;

  const filePath = resolveLocalPath(href);
  if (!filePath) return null;
  const variants = await ensureModernVariants(filePath);
  if (!variants.avif && !variants.webp) return null;

  const newHref = variants.avif
    ? swapExt(href, ".avif")
    : swapExt(href, ".webp");
  return tag.replace(HREF_RE, ` href="${newHref}"`);
}

async function processFile(filePath) {
  const html = fs.readFileSync(filePath, "utf8");
  const tags = html.match(IMG_TAG_RE) || [];
  const preloadTags = html.match(PRELOAD_LINK_RE) || [];
  if (tags.length === 0 && preloadTags.length === 0) return 0;

  let updated = html;
  let changed = 0;

  for (const tag of preloadTags) {
    const replacement = await buildPreloadReplacement(tag);
    if (!replacement) continue;
    updated = updated.replace(tag, replacement);
    changed += 1;
  }

  for (const tag of tags) {
    const replacement = await buildReplacement(tag);
    if (!replacement) continue;
    updated = updated.replace(tag, replacement);
    changed += 1;
  }

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
  let totalChanged = 0;
  let filesChanged = 0;

  for (const relFile of files) {
    const filePath = path.join(STATIC_DIR, relFile);
    const changed = await processFile(filePath);
    if (changed > 0) {
      filesChanged += 1;
      totalChanged += changed;
      console.log(`  ${relFile}: ${changed} image(s) wrapped in <picture>`);
    }
  }

  console.log(
    `generate-modern-images: wrapped ${totalChanged} image(s) across ${filesChanged} file(s), generated ${conversionCache.size} source file conversion(s)`
  );
}

main();
