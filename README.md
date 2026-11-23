# jeroenoverschie.nl

My personal website, built with Ghost.

## Theme

The theme lives in [`content/themes/dunnkers-theme-edition`](content/themes/dunnkers-theme-edition),
a fork of Ghost's [Edition](https://github.com/TryGhost/Edition) theme. Ghost picks it up
through the `content` mount below, so there is nothing extra to clone or mount. To work on
its CSS/JS:

```
cd content/themes/dunnkers-theme-edition
npm ci
npm run dev
```

`npm run dev` rebuilds `assets/built/` (and `locales/`) on change; commit the rebuilt
files, since the deploy serves them as-is. The Theme Check workflow fails, and blocks the
deploy, when they are out of date or gscan reports a fatal error. Its history before it moved here lives in the old
[ghost-dunnkers-theme-edition](https://github.com/dunnkers/ghost-dunnkers-theme-edition) repo.

## Usage

Run:

```
npm run build
npm run deploy
```

Which will generate the website at `/static`, replace `localhost` with the website name, and upload it to GitHub pages 🙌🏻.

## Running Ghost locally

> **Moving from the separate theme repo?** A container created before the theme moved
> into this repo still mounts `../ghost-dunnkers-theme-edition` over
> `content/themes/dunnkers-theme-edition`. For Apple container, `scripts/ghost-container.sh`
> (and so the LaunchAgent) detects that and recreates the container on its next run. For
> Docker, remove it once (`docker rm -f <name>`) and recreate it with the command below.

Ghost runs in a container. Pick **one** runtime; both bind port 2368 and share
the same `content` folder and sqlite DB, so don't run both at once.

### Option 1: Docker (recommended)

```
docker run -d \
  --user $(id -u):$(id -g) \
  -p 2368:2368 \
  -v /Users/dunnkers/git/dunnkers/jeroenoverschie.nl/content:/var/lib/ghost/content \
  -e NODE_ENV=development \
  -e database__client=sqlite3 \
  -e database__connection__filename=/var/lib/ghost/content/data/ghost-local.db \
  -e security__staffDeviceVerification=false \
  --restart always \
  ghost:6.78.0
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
  -e NODE_ENV=development \
  -e database__client=sqlite3 \
  -e database__connection__filename=/var/lib/ghost/content/data/ghost-local.db \
  -e security__staffDeviceVerification=false \
  docker.io/library/ghost:6.78.0
```

Stop it with `container stop ghost` (unload the LaunchAgent first with
`launchctl bootout gui/$(id -u)/nl.jeroenoverschie.ghost`, or it restarts it within 5 minutes).
