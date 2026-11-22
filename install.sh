#!/usr/bin/env bash
# MovieBox-Linux installer (patched moviebox-tui with Stremio + torrent support)
set -euo pipefail

APP_NAME="MovieBox-Linux"
BIN_NAME="moviebox-tui-torrent"
REPO="MrGodFavourite/MovieBox-Linux"
RELEASE_TAG="latest"
# >>> Must match the asset name attached to your GitHub release <<<
ASSET="moviebox-tui-torrent"
DEFAULT_INSTALL_DIR="$HOME/.local/bin"

CUSTOM_DIR=""
DRY_RUN=0
NO_MODIFY_PATH=0
UNINSTALL=0

while [ $# -gt 0 ]; do
    case "$1" in
        --dir=*) CUSTOM_DIR="${1#*=}"; shift ;;
        --dir)
            [ $# -ge 2 ] && [ -n "${2:-}" ] || { printf "error: --dir requires a path.\n" >&2; exit 1; }
            CUSTOM_DIR="$2"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --no-modify-path) NO_MODIFY_PATH=1; shift ;;
        --uninstall) UNINSTALL=1; shift ;;
        --help|-h)
            cat << 'EOF'
MovieBox-Linux Installer

USAGE:
    curl -fsSL https://raw.githubusercontent.com/MrGodFavourite/MovieBox-Linux/main/install.sh | bash -s -- [OPTIONS]

OPTIONS:
    --dir <path>       Install binary to a custom directory
    --dry-run          Run preflight checks without writing files
    --no-modify-path   Do not edit shell profile
    --uninstall        Remove MovieBox-Linux
    -h, --help         Show this help
EOF
            exit 0 ;;
        *) printf "warning: ignoring unknown argument: %s\n" "$1" >&2; shift ;;
    esac
done

while [ -n "$CUSTOM_DIR" ] && [ "${CUSTOM_DIR%/}" != "$CUSTOM_DIR" ]; do
    CUSTOM_DIR="${CUSTOM_DIR%/}"
done

IS_TTY=0; [ -t 1 ] && IS_TTY=1
IS_COLOR=0
if [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ] && [ "$IS_TTY" -eq 1 ]; then IS_COLOR=1; fi

if [ "$IS_COLOR" -eq 1 ]; then
    C_RESET="\033[0m"; C_BOLD="\033[1m"
    if [ "${COLORTERM:-}" = "truecolor" ] || [ "${COLORTERM:-}" = "24bit" ]; then
        C_MAUVE="\033[38;2;203;166;247m"; C_BLUE="\033[38;2;137;180;250m"
        C_SAPPHIRE="\033[38;2;116;199;236m"; C_GREEN="\033[38;2;166;227;161m"
        C_YELLOW="\033[38;2;249;226;175m"; C_RED="\033[38;2;243;139;168m"
        C_TEXT="\033[38;2;205;214;244m"; C_MUTED="\033[38;2;108;112;134m"
    else
        C_MAUVE="\033[35m"; C_BLUE="\033[34m"; C_SAPPHIRE="\033[36m"
        C_GREEN="\033[32m"; C_YELLOW="\033[33m"; C_RED="\033[31m"
        C_TEXT="\033[37m"; C_MUTED="\033[90m"
    fi
    CURSOR_HIDE="\033[?25l"; CURSOR_SHOW="\033[?25h"
else
    C_RESET=""; C_BOLD=""; C_MAUVE=""; C_BLUE=""; C_SAPPHIRE=""; C_GREEN=""
    C_YELLOW=""; C_RED=""; C_TEXT=""; C_MUTED=""; CURSOR_HIDE=""; CURSOR_SHOW=""
fi

TMP_DIR=""
cleanup() {
    printf "%b" "$CURSOR_SHOW" 2>/dev/null || true
    [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    return 0
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

log_step()    { printf "  %b→%b %b%s%b\n" "$C_BLUE" "$C_RESET" "$C_TEXT" "$1" "$C_RESET"; }
log_success() { printf "  %b✔%b %b%s%b\n" "$C_GREEN" "$C_RESET" "$C_TEXT" "$1" "$C_RESET"; }
log_warn()    { printf "  %b⚠%b %b%s%b\n" "$C_YELLOW" "$C_RESET" "$C_TEXT" "$1" "$C_RESET"; }
log_error()   { printf "  %b✖%b %b%s%b\n" "$C_RED" "$C_RESET" "$C_TEXT" "$1" "$C_RESET" >&2; }

print_header() {
    if [ "$IS_TTY" -eq 1 ] && [ "${TERM:-}" != "dumb" ]; then clear 2>/dev/null || true; fi
    local cols="${COLUMNS:-}"
    if [ -z "$cols" ] && [ "$IS_TTY" -eq 1 ]; then cols=$(tput cols 2>/dev/null || echo 80); fi
    cols="${cols:-80}"

    local lines=()
    local width
    if [ "$cols" -ge 76 ]; then
        width=72
        lines=(
            "███╗   ███╗  ██████╗  ██╗   ██╗ ██╗ ███████╗ ██████╗   ██████╗  ██╗  ██╗"
            "████╗ ████║ ██╔═══██╗ ██║   ██║ ██║ ██╔════╝ ██╔══██╗ ██╔═══██╗ ╚██╗██╔╝"
            "██╔████╔██║ ██║   ██║ ██║   ██║ ██║ █████╗   ██████╔╝ ██║   ██║  ╚███╔╝ "
            "██║╚██╔╝██║ ██║   ██║ ╚██╗ ██╔╝ ██║ ██╔══╝   ██╔══██╗ ██║   ██║  ██╔██╗ "
            "██║ ╚═╝ ██║ ╚██████╔╝  ╚████╔╝  ██║ ███████╗ ██████╔╝ ╚██████╔╝ ██╔╝ ██╗"
            "╚═╝     ╚═╝  ╚═════╝    ╚═══╝   ╚═╝ ╚══════╝ ╚═════╝   ╚═════╝  ╚═╝  ╚═╝"
        )
    elif [ "$cols" -ge 36 ]; then
        width=31
        lines=("█▀▄▀█ █▀█ █ █ █ █▀▀ █▀▄ █▀█ ▀▄▀" "█ ▀ █ █▄█ ▀▄▀ █ ██▄ █▄▀ █▄█ █ █")
    else
        width=14
        lines=("MovieBox-Linux")
    fi

    local pad=0 sub="Torrent Edition  •  Stremio + Torrent Engine" sub_pad=0
    [ "$cols" -gt "$width" ] && pad=$(( (cols - width) / 2 ))
    [ "$cols" -gt "${#sub}" ] && sub_pad=$(( (cols - ${#sub}) / 2 ))

    printf "%b" "$CURSOR_HIDE"
    printf "\n%b%b" "$C_BOLD" "$C_MAUVE"
    for line in "${lines[@]}"; do
        printf "%*s%s\n" "$pad" "" "$line"
        [ "$IS_COLOR" -eq 1 ] && sleep 0.02
    done
    printf "%*s%b%b%s%b\n\n%b" "$sub_pad" "" "$C_RESET" "$C_SAPPHIRE" "$sub" "$C_RESET" "$CURSOR_SHOW"
}

run_spinner() {
    local message="$1"; shift
    if [ "$IS_COLOR" -ne 1 ]; then
        log_step "$message..."
        "$@" || { log_error "$message failed."; return 1; }
        return 0
    fi
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏") i=0
    local out; out=$(mktemp)
    printf "%b" "$CURSOR_HIDE"
    "$@" > "$out" 2>&1 &
    local pid=$!
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r\033[K  %b%s%b %b%s...%b" "$C_SAPPHIRE" "${frames[$i]}" "$C_RESET" "$C_TEXT" "$message" "$C_RESET"
        i=$(( (i + 1) % ${#frames[@]} )); sleep 0.08
    done
    local code=0
    wait "$pid" || code=$?
    printf "%b\r\033[K" "$CURSOR_SHOW"
    if [ "$code" -ne 0 ]; then
        log_error "$message failed:"; cat "$out" >&2; rm -f "$out"; return "$code"
    fi
    rm -f "$out"
}

do_uninstall() {
    print_header
    log_step "Uninstalling $APP_NAME..."
    local found=0 path
    local paths=("$HOME/.local/bin/$BIN_NAME" "/usr/local/bin/$BIN_NAME")
    [ -n "$CUSTOM_DIR" ] && paths+=("$CUSTOM_DIR/$BIN_NAME")
    command -v "$BIN_NAME" >/dev/null 2>&1 && paths+=("$(command -v "$BIN_NAME")")
    for path in "${paths[@]}"; do
        if [ -f "$path" ]; then
            if [ -w "$path" ] || [ -w "$(dirname "$path")" ]; then
                rm -f "$path"; log_success "Removed $path"; found=1
            elif command -v sudo >/dev/null 2>&1; then
                sudo rm -f "$path"; log_success "Removed $path (sudo)"; found=1
            fi
        fi
    done
    if [ "$found" -eq 1 ]; then log_success "$APP_NAME uninstalled."; else log_warn "No installed $BIN_NAME found."; fi
    exit 0
}

[ "$UNINSTALL" -eq 1 ] && do_uninstall

print_header

# ---- [1/4] environment ------------------------------------------------------
command -v curl >/dev/null 2>&1 || { log_error "curl is required. Please install curl."; exit 1; }

OS="$(uname -s)"; ARCH="$(uname -m)"
if [ "$OS" != "Linux" ]; then
    log_error "This build is for Linux only (detected: $OS)."; exit 1
fi
if [ "$ARCH" != "x86_64" ]; then
    log_error "Unsupported architecture ($ARCH). This build is Linux x86_64 only."; exit 1
fi
PLATFORM_NAME="Linux (x86_64)"

if [ -n "$CUSTOM_DIR" ]; then INSTALL_DIR="$CUSTOM_DIR"; else INSTALL_DIR="$DEFAULT_INSTALL_DIR"; fi
APP_PATH="$INSTALL_DIR/$BIN_NAME"
URL="https://github.com/$REPO/releases/download/$RELEASE_TAG/$ASSET"
SUMS_URL="https://github.com/$REPO/releases/download/$RELEASE_TAG/SHA256SUMS"

log_success "[1/4] Environment ready ($PLATFORM_NAME)"

if [ -x "$APP_PATH" ]; then
    log_step "Existing install found at $APP_PATH, updating to the latest build."
fi

if [ "$DRY_RUN" -eq 1 ]; then
    log_success "[Dry Run] Download URL: $URL"
    log_success "[Dry Run] Install path: $APP_PATH"
    log_success "[Dry Run] All preflight checks passed."
    exit 0
fi

TMP_DIR=$(mktemp -d)

# ---- [2/4] download ---------------------------------------------------------
download_files() {
    curl -fsSL "$URL" -o "$TMP_DIR/$ASSET" || return 1
    # checksum file is optional; ignore if the release doesn't have one
    curl -fsSL "$SUMS_URL" -o "$TMP_DIR/SHA256SUMS" 2>/dev/null || rm -f "$TMP_DIR/SHA256SUMS"
    return 0
}
run_spinner "[2/4] Downloading $ASSET" download_files || {
    log_error "Could not download $URL"
    log_error "Check that the release asset name matches ASSET in install.sh."
    exit 1
}
log_success "[2/4] Downloaded $ASSET"

# ---- [3/4] verify -----------------------------------------------------------
verify_checksum() {
    [ -f "$TMP_DIR/SHA256SUMS" ] || return 0
    local expected actual
    expected=$(awk -v f="$ASSET" '{gsub(/^\*/, "", $2); if ($2 == f) print $1}' "$TMP_DIR/SHA256SUMS")
    [ -n "$expected" ] || return 0
    if command -v sha256sum >/dev/null 2>&1; then
        actual=$(sha256sum "$TMP_DIR/$ASSET" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        actual=$(shasum -a 256 "$TMP_DIR/$ASSET" | awk '{print $1}')
    else
        return 0
    fi
    [ "$actual" = "$expected" ]
}
run_spinner "[3/4] Verifying download" verify_checksum || exit 1
if [ -f "$TMP_DIR/SHA256SUMS" ]; then
    log_success "[3/4] SHA256 checksum verified"
else
    log_success "[3/4] Download verified (no checksum published)"
fi

# ---- [4/4] install ----------------------------------------------------------
mkdir -p "$INSTALL_DIR" 2>/dev/null || true
if [ ! -w "$INSTALL_DIR" ]; then
    log_warn "$INSTALL_DIR is not writable, using $DEFAULT_INSTALL_DIR"
    INSTALL_DIR="$DEFAULT_INSTALL_DIR"; APP_PATH="$INSTALL_DIR/$BIN_NAME"
    mkdir -p "$INSTALL_DIR"
fi

install_binary() {
    local src="$TMP_DIR/$ASSET"
    case "$ASSET" in
        *.tar.gz|*.tgz)
            command -v tar >/dev/null 2>&1 || return 1
            tar -xzf "$src" -C "$TMP_DIR"
            src="$TMP_DIR/$BIN_NAME"
            [ -f "$src" ] || return 1 ;;
    esac
    rm -f "$APP_PATH"
    cp "$src" "$APP_PATH"
    chmod 755 "$APP_PATH"
}
run_spinner "[4/4] Installing to $INSTALL_DIR" install_binary || exit 1
log_success "[4/4] Installed to $APP_PATH"

# smoke test: does the binary at least load?
set +e
smoke=$("$APP_PATH" --version 2>&1); smoke_rc=$?
set -e
if [ "$smoke_rc" -ne 0 ]; then
    log_error "Installed binary failed its smoke test (exit $smoke_rc):"
    [ -n "$smoke" ] && printf "  %s\n" "$smoke" >&2
    exit 1
fi

# ---- PATH -------------------------------------------------------------------
SHELL_MODIFIED=""
if [ "$NO_MODIFY_PATH" -eq 0 ] && ! printf '%s' "$PATH" | tr ':' '\n' | grep -Fqx "$INSTALL_DIR"; then
    RC_FILE=""
    case "$(basename "${SHELL:-bash}")" in
        zsh)  RC_FILE="$HOME/.zshrc" ;;
        bash) if [ -f "$HOME/.bashrc" ]; then RC_FILE="$HOME/.bashrc"
              elif [ -f "$HOME/.bash_profile" ]; then RC_FILE="$HOME/.bash_profile"
              else RC_FILE="$HOME/.bashrc"; fi ;;
        fish) RC_FILE="$HOME/.config/fish/config.fish" ;;
    esac
    if [ -n "$RC_FILE" ]; then
        mkdir -p "$(dirname "$RC_FILE")"
        if ! { [ -f "$RC_FILE" ] && grep -Fq -- "$INSTALL_DIR" "$RC_FILE"; }; then
            if [ "$(basename "${SHELL:-bash}")" = "fish" ]; then
                printf "\nfish_add_path %s\n" "$INSTALL_DIR" >> "$RC_FILE"
            else
                printf "\nexport PATH=\"%s:\$PATH\"\n" "$INSTALL_DIR" >> "$RC_FILE"
            fi
            SHELL_MODIFIED="$RC_FILE"
        fi
    fi
fi

# ---- player detection -------------------------------------------------------
PLAYER=""
if command -v mpv >/dev/null 2>&1 || [ -f /var/lib/flatpak/exports/bin/io.mpv.Mpv ]; then PLAYER="mpv"
elif command -v vlc >/dev/null 2>&1 || [ -f /var/lib/flatpak/exports/bin/org.videolan.VLC ]; then PLAYER="VLC"
fi

# ---- summary ----------------------------------------------------------------
printf "\n  %b✔ %s successfully installed!%b\n\n" "$C_GREEN" "$APP_NAME" "$C_RESET"
printf "  %b•%b %bBinary:%b  %b%s%b\n" "$C_MUTED" "$C_RESET" "$C_MUTED" "$C_RESET" "$C_TEXT" "$APP_PATH" "$C_RESET"
if [ -n "$PLAYER" ]; then
    printf "  %b•%b %bPlayer:%b  %b%s (ready)%b\n" "$C_MUTED" "$C_RESET" "$C_MUTED" "$C_RESET" "$C_GREEN" "$PLAYER" "$C_RESET"
else
    printf "  %b•%b %bPlayer:%b  %bNone detected (mpv or VLC recommended)%b\n" "$C_MUTED" "$C_RESET" "$C_MUTED" "$C_RESET" "$C_SAPPHIRE" "$C_RESET"
fi
[ -n "$SHELL_MODIFIED" ] && printf "  %b•%b %bShell:%b   %bPATH added to %s%b\n" "$C_MUTED" "$C_RESET" "$C_MUTED" "$C_RESET" "$C_MAUVE" "$SHELL_MODIFIED" "$C_RESET"

printf "\n  %bTo start streaming:%b\n    %b$ %s%b\n\n" "$C_TEXT" "$C_RESET" "$C_GREEN" "$BIN_NAME" "$C_RESET"
printf "  %bRe-run the install command any time to update.%b\n\n" "$C_MUTED" "$C_RESET"
[ -n "$SHELL_MODIFIED" ] && printf "  %bℹ%b Run %b'source %s'%b or restart your terminal to reload PATH.\n\n" "$C_SAPPHIRE" "$C_RESET" "$C_BOLD" "$SHELL_MODIFIED" "$C_RESET"
exit 0
