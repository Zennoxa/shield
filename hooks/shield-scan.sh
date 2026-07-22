#!/usr/bin/env bash
# pre-commit hook: run Zennoxa Shield over the repository and block on findings.
# Requires the `shield` CLI on PATH (brew install zennoxa/tap/shield, or a release binary).
set -uo pipefail

if ! command -v shield >/dev/null 2>&1; then
  echo "shield: command not found on PATH." >&2
  echo "Install it first: brew install zennoxa/tap/shield" >&2
  echo "(or grab a binary from https://github.com/Zennoxa/shield/releases/latest)" >&2
  exit 1
fi

report=$(shield scan . --format json 2>/dev/null)

# A clean scan reports "Findings": null. Anything else means Shield found something.
if printf '%s' "$report" | grep -q '"Findings": null'; then
  exit 0
fi

printf '%s\n' "$report"
echo "" >&2
echo "Shield found security issues — commit blocked (bypass with: git commit --no-verify)" >&2
exit 1
