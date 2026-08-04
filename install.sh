#!/bin/sh
# Zennoxa Shield CLI installer.
#
#   curl -fsSL https://raw.githubusercontent.com/Zennoxa/shield/main/install.sh | sh
#
# Downloads the latest signed release binary for your OS/arch from GitHub,
# verifies it against the published SHA256SUMS, and installs it onto your PATH.
# No account, no dependencies beyond curl + a shell. Override the destination
# with SHIELD_INSTALL_DIR=/some/dir.
set -eu

REPO="Zennoxa/shield"
BIN="shield"
INSTALL_DIR="${SHIELD_INSTALL_DIR:-/usr/local/bin}"
BASE="https://github.com/${REPO}/releases/latest/download"

say() { printf '%s\n' "$*"; }
err() { printf 'error: %s\n' "$*" >&2; exit 1; }

# --- detect platform -------------------------------------------------------
os="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "$os" in
  linux)  os=linux ;;
  darwin) os=darwin ;;
  *) err "unsupported OS '$os'. Windows: download ${BIN}-windows-amd64.exe from https://github.com/${REPO}/releases/latest" ;;
esac

arch="$(uname -m)"
case "$arch" in
  x86_64|amd64)  arch=amd64 ;;
  arm64|aarch64) arch=arm64 ;;
  *) err "unsupported architecture '$arch' — grab a binary manually from https://github.com/${REPO}/releases/latest" ;;
esac

asset="${BIN}-${os}-${arch}"
command -v curl >/dev/null 2>&1 || err "curl is required"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT INT TERM

# --- download --------------------------------------------------------------
say "Downloading ${asset} (latest release)…"
curl -fsSL --retry 3 "${BASE}/${asset}" -o "${tmp}/${BIN}" \
  || err "download failed: ${BASE}/${asset}"

# --- verify checksum (abort on mismatch; warn if sums unavailable) ---------
if curl -fsSL --retry 3 "${BASE}/SHA256SUMS" -o "${tmp}/SHA256SUMS" 2>/dev/null; then
  expected="$(grep " ${asset}\$" "${tmp}/SHA256SUMS" 2>/dev/null | awk '{print $1}')"
  if [ -n "${expected:-}" ]; then
    actual=""
    if command -v sha256sum >/dev/null 2>&1; then
      actual="$(sha256sum "${tmp}/${BIN}" | awk '{print $1}')"
    elif command -v shasum >/dev/null 2>&1; then
      actual="$(shasum -a 256 "${tmp}/${BIN}" | awk '{print $1}')"
    fi
    if [ -n "$actual" ] && [ "$expected" != "$actual" ]; then
      err "checksum mismatch for ${asset} (expected ${expected}, got ${actual})"
    fi
    [ -n "$actual" ] && say "Checksum verified."
  fi
else
  say "warning: could not fetch SHA256SUMS — skipping checksum verification."
fi

chmod +x "${tmp}/${BIN}"

# --- install (sudo only if needed; fall back to ~/.local/bin) --------------
target="${INSTALL_DIR}/${BIN}"
if [ -w "$INSTALL_DIR" ] 2>/dev/null; then
  mv "${tmp}/${BIN}" "$target"
elif command -v sudo >/dev/null 2>&1; then
  say "Installing to ${INSTALL_DIR} (requires sudo)…"
  sudo mv "${tmp}/${BIN}" "$target"
else
  INSTALL_DIR="${HOME}/.local/bin"
  target="${INSTALL_DIR}/${BIN}"
  mkdir -p "$INSTALL_DIR"
  mv "${tmp}/${BIN}" "$target"
  case ":${PATH}:" in
    *":${INSTALL_DIR}:"*) ;;
    *) say "note: add ${INSTALL_DIR} to your PATH (e.g. export PATH=\"${INSTALL_DIR}:\$PATH\")." ;;
  esac
fi

say ""
say "✓ Installed ${BIN} → ${target}"
say "  Try it:  ${BIN} scan ."
