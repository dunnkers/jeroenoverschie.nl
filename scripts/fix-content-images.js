#!/usr/bin/env node
// Rewrites <img> tags in the exported static HTML that reference full-resolution
// originals under /content/images/ to use Ghost's already-generated responsive
// variants under /content/images/size/wNNN/ instead (via src + srcset + sizes).
// Only touches images that have no srcset yet and for which resized variants
// actually exist on disk.

const fs = require("fs");
const path = require("path");

const STATIC_DIR = path.join(__dirname, "..", "static");
const IMAGES_ROOT = path.join(__dirname, "..", "content", "images");
const RASTER_EXT = /\.(jpe?g|png|gif|webp)$/i;
const WIDTHS = [400, 600, 750, 960, 1000, 1140, 1200, 1600, 2000, 2400];
const FALLBACK_MAX_WIDTH = 1000;
const SIZES_ATTR = "(min-width: 720px) 720px, 100vw";

const IMG_TAG_RE = /<img\b[^>]*>/gi;
const SRC_RE = /\ssrc="([^"]*)"/i;
const IMG_PATH_RE =
  /^(https?:\/\/[^/]+)?(\/content\/images\/(\d{4})\/(\d{2})\/([^"?#]+))$/;

function listHtmlFiles(dir) {
  return fs.readdirSync(dir, { recursive: true }).filter((f) => f.endsWith(".html"));
}

function availableVariants(year, month, filename) {
  return WIDTHS.filter((w) =>
    fs.existsSync(path.join(IMAGES_ROOT, "size", `w${w}`, year, month, filename))
  );
}

function buildReplacement(tag, src, match) {
  const [, prefix = "", , year, month, filename] = match;
  const variants = availableVariants(year, month, filename);
  if (variants.length === 0) return null;

  const urlFor = (w) => `${prefix}/content/images/size/w${w}/${year}/${month}/${filename}`;
  const srcset = variants.map((w) => `${urlFor(w)} ${w}w`).join(", ");
  const fallbackWidth =
    variants.find((w) => w >= FALLBACK_MAX_WIDTH) || variants[variants.length - 1];

  // If the tag already declares a display width smaller than the content
  // column, use that as the sizes hint instead of assuming full-width.
  const widthAttr = tag.match(/\swidth="(\d+)"/i);
  const explicitWidth = widthAttr ? parseInt(widthAttr[1], 10) : null;
  const sizesAttr =
    explicitWidth && explicitWidth < 720 ? `${explicitWidth}px` : SIZES_ATTR;

  let newTag = tag.replace(SRC_RE, ` src="${urlFor(fallbackWidth)}"`);
  newTag = newTag.replace(/\ssrcset="[^"]*"/i, "");
  newTag = newTag.replace(/<img\b/i, `<img srcset="${srcset}" sizes="${sizesAttr}"`);
  if (!/\sloading="/i.test(newTag)) {
    newTag = newTag.replace(/<img\b/i, '<img loading="lazy"');
  }
  return newTag;
}

function processFile(filePath) {
  const html = fs.readFileSync(filePath, "utf8");
  let changed = 0;

  const updated = html.replace(IMG_TAG_RE, (tag) => {
    if (/\ssrcset="/i.test(tag)) return tag; // already responsive
    const srcMatch = tag.match(SRC_RE);
    if (!srcMatch) return tag;
    const src = srcMatch[1];
    if (!RASTER_EXT.test(src)) return tag;
    if (/\/content\/images\/size\//.test(src)) return tag; // already sized

    const pathMatch = src.match(IMG_PATH_RE);
    if (!pathMatch) return tag;

    const replacement = buildReplacement(tag, src, pathMatch);
    if (!replacement) return tag; // no resized variants on disk, leave as-is
    changed += 1;
    return replacement;
  });

  if (changed > 0) {
    fs.writeFileSync(filePath, updated);
  }
  return changed;
}

function main() {
  if (!fs.existsSync(STATIC_DIR)) {
    console.error(`No static/ export found at ${STATIC_DIR} — run gssg first.`);
    process.exit(1);
  }

  const files = listHtmlFiles(STATIC_DIR);
  let totalChanged = 0;
  let filesChanged = 0;

  for (const relFile of files) {
    const filePath = path.join(STATIC_DIR, relFile);
    const changed = processFile(filePath);
    if (changed > 0) {
      filesChanged += 1;
      totalChanged += changed;
      console.log(`  ${relFile}: ${changed} image(s) rewritten`);
    }
  }

  console.log(
    `fix-content-images: rewrote ${totalChanged} image(s) across ${filesChanged} file(s)`
  );
}

main();
