#!/usr/bin/env bash
# Install a current Neovim and Tree-sitter CLI for Ubuntu 24.04+.
# Installs to ~/.local, leaving apt-managed Neovim and existing configs alone.
set -Eeuo pipefail

SYNC_PLUGINS=false
for arg in "$@"; do
  case "$arg" in
    --sync-plugins) SYNC_PLUGINS=true ;;
    -h|--help)
      cat <<'HELP'
Usage: bash bootstrap-nvim.sh [--sync-plugins]

Installs the latest stable Neovim and Tree-sitter CLI to ~/.local,
installs missing Ubuntu build tools, and adds ~/.local/bin to PATH.
Does not overwrite ~/.config/nvim or edit plugins.lua.

--sync-plugins   Run a headless lazy.nvim sync if ~/.config/nvim/init.lua exists.
HELP
      exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == Linux ]] || die 'This script requires Linux.'
case "$(uname -m)" in
  x86_64) NVIM_ARCH=x86_64; TS_ARCH=x64 ;;
  aarch64|arm64) NVIM_ARCH=arm64; TS_ARCH=arm64 ;;
  *) die "Unsupported CPU architecture: $(uname -m)" ;;
esac

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == ubuntu ]] || die "Expected Ubuntu; found ${ID:-unknown}."
fi

# Install missing prerequisites only; no npm, Rust, or distro Neovim needed.
packages=()
command -v curl >/dev/null 2>&1 || packages+=(curl)
command -v unzip >/dev/null 2>&1 || packages+=(unzip)
command -v tar >/dev/null 2>&1 || packages+=(tar)
command -v git >/dev/null 2>&1 || packages+=(git)
command -v cc >/dev/null 2>&1 || packages+=(build-essential)
if ((${#packages[@]})); then
  command -v apt-get >/dev/null 2>&1 || die 'apt-get not found.'
  if [[ "$(id -u)" == 0 ]]; then SUDO=(); else
    command -v sudo >/dev/null 2>&1 || die "Missing prerequisites: ${packages[*]}; install them as root."
    SUDO=(sudo)
  fi
  log "Installing missing apt packages: ${packages[*]}"
  "${SUDO[@]}" apt-get update
  "${SUDO[@]}" apt-get install -y "${packages[@]}"
fi

BIN="$HOME/.local/bin"
PREFIX="$HOME/.local/opt"
mkdir -p "$BIN" "$PREFIX"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

log 'Downloading latest stable Neovim'
NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"
curl --fail --location --retry 3 --silent --show-error "$NVIM_URL" -o "$TMP/nvim.tar.gz"
tar -xzf "$TMP/nvim.tar.gz" -C "$TMP"
EXTRACTED="$TMP/nvim-linux-${NVIM_ARCH}"
[[ -x "$EXTRACTED/bin/nvim" ]] || die 'Neovim archive does not contain the expected binary.'
"$EXTRACTED/bin/nvim" --version | head -n 1
# Stage then replace. Existing installation is preserved as .previous.
rm -rf "$PREFIX/nvim.new"
mv "$EXTRACTED" "$PREFIX/nvim.new"
rm -rf "$PREFIX/nvim.previous"
if [[ -e "$PREFIX/nvim" ]]; then mv "$PREFIX/nvim" "$PREFIX/nvim.previous"; fi
mv "$PREFIX/nvim.new" "$PREFIX/nvim"
ln -sfn "$PREFIX/nvim/bin/nvim" "$BIN/nvim"

log 'Downloading latest stable Tree-sitter CLI'
TS_URL="https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-cli-linux-${TS_ARCH}.zip"
curl --fail --location --retry 3 --silent --show-error "$TS_URL" -o "$TMP/tree-sitter.zip"
# -p extracts the named file to stdout, without writing unexpected paths.
unzip -p "$TMP/tree-sitter.zip" tree-sitter > "$TMP/tree-sitter"
chmod 755 "$TMP/tree-sitter"
"$TMP/tree-sitter" --version
install -m 755 "$TMP/tree-sitter" "$BIN/tree-sitter"

# Idempotently make ~/.local/bin preferred over apt's /usr/bin and old /opt nvim.
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
for rc in "$HOME/.bashrc" "$HOME/.profile"; do
  touch "$rc"
  if ! grep -Fqx "$PATH_LINE" "$rc"; then
    { printf '\n# User-installed Neovim and Tree-sitter CLI\n%s\n' "$PATH_LINE"; } >> "$rc"
  fi
done
export PATH="$BIN:$PATH"

log 'Installed binaries'
"$BIN/nvim" --version | head -n 1
"$BIN/tree-sitter" --version
printf 'Neovim path: %s\nTree-sitter path: %s\n' "$BIN/nvim" "$BIN/tree-sitter"

if [[ "$SYNC_PLUGINS" == true ]]; then
  if [[ -f "$HOME/.config/nvim/init.lua" ]]; then
    log 'Running lazy.nvim sync (this uses your existing Neovim config)'
    "$BIN/nvim" --headless '+Lazy! sync' '+qa' || die 'Plugin sync failed. Try opening nvim and running :Lazy sync.'
  else
    log 'No ~/.config/nvim/init.lua found; skipping plugin sync.'
  fi
fi

cat <<'DONE'

Finished. Open a NEW shell (or run: source ~/.bashrc), then check:
    command -v nvim
    nvim --version
    tree-sitter --version

If your Neovim config is already present, open Neovim and run:
    :Lazy sync
    :TSUpdate
    :checkhealth nvim-treesitter

This installer intentionally did NOT replace or create ~/.config/nvim.
For new nodes, copy your working config separately (rsync/scp/git).
DONE
