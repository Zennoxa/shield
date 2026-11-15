#!/bin/sh
# Zennoxa Shield CLI installer for macOS and Linux.
#
#   curl -fsSL https://raw.githubusercontent.com/Zennoxa/shield/main/install.sh | sh
#
# Downloads the release binary for this machine, checks it against the
# release's SHA256SUMS, installs it as `shield` and runs `shield version`.
# Nothing else is installed and nothing is sent anywhere.
#
# Options (environment variables):
#   SHIELD_VERSION      release tag to install, for example v0.7.0 (default: latest)
#   SHIELD_INSTALL_DIR  directory to install into (default: /usr/local/bin when it
#                       is writable or sudo can be used, otherwise ~/.local/bin)
#
#   curl -fsSL https://raw.githubusercontent.com/Zennoxa/shield/main/install.sh | SHIELD_VERSION=v0.7.0 sh
set -eu

REPO="Zennoxa/shield"
BIN="shield"

say() { printf '%s\n' "$*"; }
err() { printf 'error: %s\n' "$*" >&2; exit 1; }

# --- platform ----------------------------------------------------------------
case "$(uname -s)" in
  Linux)  os=linux ;;
  Darwin) os=darwin ;;
  *) err "no release binary for $(uname -s). On Windows use install.ps1: https://github.com/${REPO}#install-the-cli" ;;
esac
case "$(uname -m)" in
  x86_64|amd64)  arch=amd64 ;;
  arm64|aarch64) arch=arm64 ;;
  *) err "no release binary for $(uname -m). Releases: https://github.com/${REPO}/releases/latest" ;;
esac
# A shell running under Rosetta on Apple silicon reports x86_64; the native
# binary is the right one.
if [ "$os" = darwin ] && [ "$arch" = amd64 ] && [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = "1" ]; then
  arch=arm64
fi
asset="${BIN}-${os}-${arch}"

# --- release -----------------------------------------------------------------
version="${SHIELD_VERSION:-latest}"
case "$version" in
  latest) base="https://github.com/${REPO}/releases/latest/download" ;;
  v[0-9]*)
    case "$version" in *[!0-9A-Za-z.+-]*) err "SHIELD_VERSION must be a release tag such as v0.7.0" ;; esac
    base="https://github.com/${REPO}/releases/download/${version}" ;;
  *) err "SHIELD_VERSION must be a release tag such as v0.7.0, or latest" ;;
esac

if command -v curl >/dev/null 2>&1; then
  fetch() { curl -fsSL --retry 3 -o "$2" "$1"; }
elif command -v wget >/dev/null 2>&1; then
  fetch() { wget -q -O "$2" "$1"; }
else
  err "curl or wget is required"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
trap 'exit 1' INT TERM

say "Downloading ${asset} (${version})"
fetch "${base}/${asset}" "${tmp}/${BIN}" || err "download failed: ${base}/${asset}"
fetch "${base}/SHA256SUMS" "${tmp}/SHA256SUMS" || err "download failed: ${base}/SHA256SUMS"

# --- checksum (never skipped) --------------------------------------------------
want="$(awk -v a="$asset" '$2 == a || $2 == "*" a { print $1; exit }' "${tmp}/SHA256SUMS")"
[ -n "$want" ] || err "SHA256SUMS of this release does not list ${asset}"
if command -v sha256sum >/dev/null 2>&1; then
  got="$(sha256sum "${tmp}/${BIN}" | awk '{ print $1 }')"
elif command -v shasum >/dev/null 2>&1; then
  got="$(shasum -a 256 "${tmp}/${BIN}" | awk '{ print $1 }')"
elif command -v openssl >/dev/null 2>&1; then
  got="$(openssl dgst -sha256 "${tmp}/${BIN}" | awk '{ print $NF }')"
else
  err "no sha256 tool found (sha256sum, shasum or openssl); not installing an unverified binary"
fi
[ "$want" = "$got" ] || err "checksum mismatch for ${asset}: expected ${want}, got ${got}"
say "Checksum verified."
chmod 755 "${tmp}/${BIN}"

# --- where to install ----------------------------------------------------------
use_sudo=""
if [ -n "${SHIELD_INSTALL_DIR:-}" ]; then
  dir="$SHIELD_INSTALL_DIR"
  mkdir -p "$dir" 2>/dev/null || true
  [ -d "$dir" ] && [ -w "$dir" ] || err "cannot write to SHIELD_INSTALL_DIR (${dir})"
elif [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
  dir=/usr/local/bin
elif [ -d /usr/local/bin ] && command -v sudo >/dev/null 2>&1 && { sudo -n true 2>/dev/null || [ -t 1 ] || [ -t 2 ]; }; then
  dir=/usr/local/bin
  use_sudo=sudo
else
  dir="${HOME}/.local/bin"
  mkdir -p "$dir"
fi

target="${dir}/${BIN}"
if [ -n "$use_sudo" ]; then
  say "Installing to ${target} (sudo may ask for your password)"
  sudo mv "${tmp}/${BIN}" "$target"
  sudo chmod 755 "$target"
else
  mv "${tmp}/${BIN}" "$target"
fi

# A download made by a browser is quarantined by macOS; one made by curl is not.
# Clearing the flag is harmless either way.
if [ "$os" = darwin ] && command -v xattr >/dev/null 2>&1; then
  xattr -d com.apple.quarantine "$target" 2>/dev/null || true
fi

# --- prove it runs -------------------------------------------------------------
installed="$("$target" version 2>&1)" || err "${target} was installed but does not run: ${installed}"

say ""
say "Installed ${installed}"
say "  at ${target}"
resolved="$(command -v "$BIN" 2>/dev/null || true)"
if [ "$resolved" != "$target" ]; then
  if [ -n "$resolved" ]; then
    say "  note: another ${BIN} comes first on your PATH (${resolved})."
  else
    say "  note: ${dir} is not on your PATH. Add this line to your shell profile (~/.zshrc, ~/.bashrc):"
    say "        export PATH=\"${dir}:\$PATH\""
  fi
fi
say ""
say "Try it:  ${BIN} scan ."
