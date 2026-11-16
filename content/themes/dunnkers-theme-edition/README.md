# dunnkers-theme-edition

The Ghost theme for [jeroenoverschie.nl](https://jeroenoverschie.nl), a fork of
Ghost's [Edition](https://github.com/TryGhost/Edition) theme.

Ghost loads it from this folder through the site's `content/` mount (see the
[site README](../../../README.md)). `package.json` doubles as Ghost's theme
manifest (`config`, `card_assets`, custom settings).

## Development

CSS and JS are compiled with Gulp/PostCSS from `assets/css/` and `assets/js/`
into `assets/built/`:

```bash
npm ci          # install the locked dependencies
npm run dev     # build and watch for changes
npm run build   # one-off build
npm test        # validate with gscan
```

The build output (`assets/built/`, `locales/`) is committed and served as-is
by the deploy, so commit it together with source changes. CI
(`.github/workflows/theme_check.yaml`) fails when it is out of date or gscan
reports a fatal error, and the deploy only runs once that check passes.

## Upstream

Changes from upstream Edition are ported by hand. History before the theme
moved into the site repo lives in the old
[ghost-dunnkers-theme-edition](https://github.com/dunnkers/ghost-dunnkers-theme-edition)
repo.

## License

Based on Edition, copyright (c) 2013-2026 Ghost Foundation, released under the
[MIT license](LICENSE).
