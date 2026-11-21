#!/usr/bin/env bash
set -euo pipefail

REPO="MrGodFavourite/MovieBox-Linux"   # change if your repo name differs
NAME="moviebox-tui-torrent"
DEST="$HOME/.local/bin"

mkdir -p "$DEST"
echo "Downloading $NAME..."
curl -fL --progress-bar -o "$DEST/$NAME" \
  "https://github.com/$REPO/releases/download/latest/$NAME"
chmod +x "$DEST/$NAME"

echo "Installed to $DEST/$NAME"
case ":$PATH:" in
  *":$DEST:"*) echo "Run: $NAME" ;;
  *) echo "Add $DEST to your PATH, or run: $DEST/$NAME" ;;
esac
