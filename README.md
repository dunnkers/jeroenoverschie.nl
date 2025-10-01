# jeroenoverschie.nl

My personal website, built with Ghost.

## Install

First, clone the theme:

```
cd content
git clone https://github.com/dunnkers/ghost-dunnkers-theme-edition.git dunnkers-theme-edition
```

## Usage

Run:

```
npm run build
npm run deploy
```

Which will generate the website at `/static`, replace `localhost` with the website name, and upload it to GitHub pages 🙌🏻.

## Detached mode (recommended)

```
docker run -d \
  -p 2368:2368 \
  -v /Users/dunnkers/git/jeroenoverschie.nl/content:/var/lib/ghost/content \
  -e NODE_ENV=development \
  -e database__client=sqlite3 \
  -e database__connection__filename=/var/lib/ghost/content/data/ghost-local.db \
  -e security__staffDeviceVerification=false \
  --restart always \
  ghost:5.130.5
```