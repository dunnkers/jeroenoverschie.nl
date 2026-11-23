#!/usr/bin/env node
// Appends the git commit and repo to the footer year's "Website last built"
// tooltip in the exported static HTML. The theme can't know them: Ghost
// renders the page, and nothing in its handlebars context carries the commit
// being built. The theme already writes the build time into the title, so the
// page reads fine without this step (e.g. on the local Ghost instance).
//
// In CI, GITHUB_SHA / GITHUB_REPOSITORY name the commit being deployed.
// Locally it falls back to git, marking a dirty tree. Runs near the end of
// `npm run build`; it only edits the title inside <p class="gh-copyright">.

const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const STATIC_DIR = path.join(__dirname, "..", "static");

function git(...args) {
  return execFileSync("git", args, { encoding: "utf8" }).trim();
}

function buildInfo() {
  let sha = process.env.GITHUB_SHA;
  let repo = process.env.GITHUB_REPOSITORY;
  let dirty = false;
  if (!sha) {
    sha = git("rev-parse", "HEAD");
    // Ghost keeps writing to the tracked content DB, so it can't count.
    dirty = git("status", "--porcelain", "--", ".", ":!content/data/ghost-local.db") !== "";
  }
  if (!repo) {
    repo = git("remote", "get-url", "origin").replace(/^.*github\.com[:/]/, "").replace(/\.git$/, "");
  }
  return `${repo}@${sha.slice(0, 7)}${dirty ? "-dirty" : ""}`;
}

// Group 1 is everything up to the end of the theme's build time, so a second
// run replaces an earlier stamp instead of appending another.
const TITLE_RE = /(<p class="gh-copyright">[^]*?<time\b[^>]*\stitle="Website last built [^"·]*?)(?: · [^"]*)?"/;

const info = buildInfo();
let stamped = 0;
for (const file of fs.readdirSync(STATIC_DIR, { recursive: true })) {
  if (!file.endsWith(".html")) continue;
  const p = path.join(STATIC_DIR, file);
  const html = fs.readFileSync(p, "utf8");
  if (!TITLE_RE.test(html)) continue;
  stamped++;
  const out = html.replace(TITLE_RE, `$1 · ${info}"`);
  if (out !== html) fs.writeFileSync(p, out);
}
console.log(`stamp-build-info: ${info} written to ${stamped} pages`);
if (stamped === 0) {
  console.error("stamp-build-info: found no footer tooltip to stamp");
  process.exit(1);
}
