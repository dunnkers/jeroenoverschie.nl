# jeroenoverschie.nl

My personal website, built with Ghost.

## Install

Clone the theme repo alongside this repo:

```
git clone https://github.com/dunnkers/ghost-dunnkers-theme-edition.git ../ghost-dunnkers-theme-edition
```

The Docker setup mounts it directly — no need to place it under `content/themes/`.

## Usage

Run:

```
npm run build
npm run deploy
```

Which will generate the website at `/static`, replace `localhost` with the website name, and upload it to GitHub pages 🙌🏻.

## Running Ghost locally

Ghost runs in a container. Pick **one** runtime; both bind port 2368 and share
the same `content` folder and sqlite DB, so don't run both at once.

### Option 1: Docker (recommended)

```
docker run -d \
  --user $(id -u):$(id -g) \
  -p 2368:2368 \
  -v /Users/dunnkers/git/dunnkers/jeroenoverschie.nl/content:/var/lib/ghost/content \
  -v /Users/dunnkers/git/dunnkers/ghost-dunnkers-theme-edition:/var/lib/ghost/content/themes/dunnkers-theme-edition \
  -e NODE_ENV=development \
  -e database__client=sqlite3 \
  -e database__connection__filename=/var/lib/ghost/content/data/ghost-local.db \
  -e security__staffDeviceVerification=false \
  --restart always \
  ghost:6.73.0
```

### Option 2: Apple container

Uses [apple/container](https://github.com/apple/container) (`brew install container`,
then `container system start` or `brew services start container`). It has no
`--restart` flag, so `scripts/ghost-container.sh` does that job: it starts the
`container` services, creates the `ghost` container if missing and starts it if
stopped. A LaunchAgent runs it at login and every 5 minutes:

```
cp scripts/nl.jeroenoverschie.ghost.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/nl.jeroenoverschie.ghost.plist
```

Logs go to `/tmp/nl.jeroenoverschie.ghost.log`. To create the container by hand instead:

```
container run -d --name ghost \
  --user $(id -u):$(id -g) \
  -p 2368:2368 \
  -v /Users/dunnkers/git/dunnkers/jeroenoverschie.nl/content:/var/lib/ghost/content \
  -v /Users/dunnkers/git/dunnkers/ghost-dunnkers-theme-edition:/var/lib/ghost/content/themes/dunnkers-theme-edition \
  -e NODE_ENV=development \
  -e database__client=sqlite3 \
  -e database__connection__filename=/var/lib/ghost/content/data/ghost-local.db \
  -e security__staffDeviceVerification=false \
  docker.io/library/ghost:6.73.0
```

Stop it with `container stop ghost` (unload the LaunchAgent first with
`launchctl bootout gui/$(id -u)/nl.jeroenoverschie.ghost`, or it restarts it within 5 minutes).
