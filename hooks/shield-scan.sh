#!/usr/bin/env bash
# pre-commit hook: run Zennoxa Shield over the repository and block on findings.
# Requires the `shield` CLI on PATH (see "Install the CLI" in the README).
set -uo pipefail

if ! command -v shield >/dev/null 2>&1; then
  echo "shield: command not found on PATH." >&2
  echo "Install it first: https://github.com/Zennoxa/shield#install-the-cli" >&2
  exit 1
fi

report="$(mktemp)"
errlog="$(mktemp)"
trap 'rm -f "$report" "$errlog"' EXIT

shield scan . --format json --output "$report" >/dev/null 2>"$errlog"
code=$?

# Exit 0 is a completed scan (2 would be a tripped gate; none is requested
# here). Anything else means the scan did not finish: say so instead of
# reporting it as "issues found".
if [ "$code" -ne 0 ] && [ "$code" -ne 2 ]; then
  echo "Shield could not complete the scan (exit ${code}); commit blocked." >&2
  sed 's/^/  /' "$errlog" >&2
  echo "Bypass with: git commit --no-verify" >&2
  exit 1
fi

# The report lists one "RuleID" per finding. None means a clean scan, whether
# the CLI wrote the empty list as null or as [].
if ! grep -q '"RuleID"' "$report"; then
  exit 0
fi

# Show the findings the way a person reads them.
shield scan . 2>/dev/null || true
echo "" >&2
echo "Shield found security issues; commit blocked (bypass with: git commit --no-verify)" >&2
exit 1
