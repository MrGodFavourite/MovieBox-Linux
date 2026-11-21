# MovieBox-Linux

A patched Linux build of [moviebox-tui](https://github.com/mesamirh/MovieBox-Tui), the terminal movie and series browser written in Rust. This build adds support for playing Stremio addon streams and torrents, and installs under its own name so it never conflicts with the original app.

## Install / Update

```bash
curl -fsSL https://raw.githubusercontent.com/MrGodFavourite/MovieBox-Linux/main/install.sh | bash
```

Run the same command again any time to update to the latest build.

Then start it with:

```bash
moviebox-tui-torrent
```

The binary is installed to `~/.local/bin/moviebox-tui-torrent`. If the command is not found, log out and back in, or run it with the full path.

## Features

- Browse and search movies and series from the terminal
- Stremio addon support: streams that play in Stremio can play here
- Built-in torrent engine: play torrent and magnet streams directly
- Plays through your external player (mpv, VLC)
- Runs as `moviebox-tui-torrent`, separate from the original `moviebox-tui`

## Requirements

- Linux x86_64 (built for Linux Mint 21+ / Ubuntu 22.04+)
- A video player such as mpv or VLC
- A terminal; kitty is recommended for best display

## How it is built

Every push that changes `moviebox-linux-src.zip` or `moviebox.patch` triggers GitHub Actions. It unzips the source, applies the patch, builds a release binary with Cargo, and publishes it to the `latest` release.

| File | Purpose |
| --- | --- |
| `moviebox-linux-src.zip` | moviebox-tui source |
| `moviebox.patch` | Patches applied on top of the source |
| `install.sh` | One-line installer |
| `.github/workflows/build-linux.yml` | Build workflow |

To update the app, replace the zip and/or patch and commit. The new build appears under Releases in a few minutes.

## Credits

Based on [mesamirh/MovieBox-Tui](https://github.com/mesamirh/MovieBox-Tui). This repo only contains patches and build automation.
