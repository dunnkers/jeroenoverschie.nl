# jeroenoverschie.nl

My personal website, built with Ghost.

## Install

First, clone the theme:

```
cd content
git clone https://github.com/dunnkers/ghost-dunnkers-theme-edition.git dunnkers-theme-edition
```

Then:

```
cd .devcontainer
docker compose up
```

OR, better:

[![Open in Remote - Containers](https://img.shields.io/static/v1?label=Remote%20-%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/dunnkers/jeroenoverschie.nl)

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
  --restart always \
  ghost:5.126.1
```