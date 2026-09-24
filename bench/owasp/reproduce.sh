#!/usr/bin/env bash
# Reproduce Zennoxa Shield's published OWASP Benchmark v1.2 score from the
# released binary. No Go toolchain, no account: bash, curl, git, python3 and
# sha256sum (or shasum) are all it needs.
#
#   bench/owasp/reproduce.sh [TAG]        # TAG defaults to benchmark.json tool.release
#
# Environment:
#   SHIELD_BIN=/path/to/shield   use an existing binary instead of downloading TAG
#   OWASP_BENCH=/path/to/BenchmarkJava
#                                use an existing checkout (its commit is checked
#                                against the pin in benchmark.json)
#   BENCH_OUT=dir                where findings.json / score.json / scan.log go
#                                (default: ./shield-owasp-out)
#   TOLERANCE=0.005              how far the score may drift from benchmark.json
#   BENCH_STRICT=1               fail (instead of warn) when the checkout commit
#                                or ground-truth checksum differs from the pin
#
# What it does: download the tagged asset for this OS/arch and verify it against
# the release's SHA256SUMS; fetch BenchmarkJava at the pinned commit; verify the
# ground-truth CSV checksum; scan the test-case tree with `shield scan`; score
# with score.py (strict OWASP CWE-per-category match, Benchmark Score = TPR - FPR);
# compare with the published overall score. Exit 0 when they agree within
# TOLERANCE, 1 otherwise.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
META="$HERE/benchmark.json"
[ -f "$META" ] || { echo "benchmark.json not found next to this script" >&2; exit 2; }

meta() { python3 -c 'import json,sys; d=json.load(open(sys.argv[1]))
for k in sys.argv[2].split("."): d=d[k]
print(d)' "$META" "$1"; }

TAG="${1:-$(meta tool.release)}"
EXPECT="$(meta benchmark.overall.benchmark_score)"
BENCH_COMMIT="$(meta dataset.commit)"
GT_SHA="$(meta dataset.ground_truth_sha256)"
GT_NAME="$(meta dataset.ground_truth)"
TOL="${TOLERANCE:-0.005}"
OUT="${BENCH_OUT:-$PWD/shield-owasp-out}"
mkdir -p "$OUT"

for tool in curl git python3; do
  command -v "$tool" >/dev/null 2>&1 || { echo "missing: $tool" >&2; exit 2; }
done
sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  else echo "missing: sha256sum or shasum" >&2; exit 2; fi
}
warn_or_fail() { echo "$1" >&2; [ "${BENCH_STRICT:-0}" = "1" ] && exit 1 || true; }

# 1. The binary: an explicit SHIELD_BIN, or the tagged release asset, checksum-verified.
if [ -n "${SHIELD_BIN:-}" ]; then
  BIN="$SHIELD_BIN"
  [ -x "$BIN" ] || { echo "SHIELD_BIN is not executable: $BIN" >&2; exit 2; }
  echo ">> using $BIN ($("$BIN" version 2>/dev/null || echo 'version unknown'))"
else
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"; arch="$(uname -m)"
  case "$arch" in x86_64|amd64) arch=amd64 ;; arm64|aarch64) arch=arm64 ;; *) echo "unsupported arch $arch" >&2; exit 2 ;; esac
  case "$os" in linux|darwin) ;; *) echo "unsupported OS $os (use SHIELD_BIN=)" >&2; exit 2 ;; esac
  asset="shield-${os}-${arch}"
  base="https://github.com/Zennoxa/shield/releases/download/${TAG}"
  echo ">> downloading ${asset} from release ${TAG} ..."
  curl -fsSL --retry 3 "${base}/${asset}" -o "$OUT/$asset"
  curl -fsSL --retry 3 "${base}/SHA256SUMS" -o "$OUT/SHA256SUMS"
  expected="$(grep " ${asset}\$" "$OUT/SHA256SUMS" | awk '{print $1}')"
  actual="$(sha256 "$OUT/$asset")"
  if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
    echo "SHA256 mismatch for ${asset}: expected ${expected:-<none>} got ${actual}" >&2; exit 1
  fi
  chmod +x "$OUT/$asset"; BIN="$OUT/$asset"
  echo ">> verified ${asset} sha256=${actual}"
fi

# 2. The dataset at the pinned commit.
if [ -n "${OWASP_BENCH:-}" ]; then
  BENCH="$OWASP_BENCH"
  have="$(git -C "$BENCH" rev-parse HEAD 2>/dev/null || echo unknown)"
  [ "$have" = "$BENCH_COMMIT" ] || warn_or_fail "warning: $BENCH is at $have, benchmark.json pins $BENCH_COMMIT"
else
  BENCH="$OUT/BenchmarkJava"
  if [ ! -d "$BENCH/.git" ]; then
    echo ">> fetching OWASP-Benchmark/BenchmarkJava @ ${BENCH_COMMIT} ..."
    git init -q "$BENCH"
    git -C "$BENCH" remote add origin https://github.com/OWASP-Benchmark/BenchmarkJava
    git -C "$BENCH" fetch -q --depth 1 origin "$BENCH_COMMIT"
    git -C "$BENCH" checkout -q FETCH_HEAD
  fi
fi
SRC="$BENCH/src/main/java/org/owasp/benchmark/testcode"
GT="$BENCH/$GT_NAME"
[ -d "$SRC" ] && [ -f "$GT" ] || { echo "BenchmarkJava layout not found under $BENCH" >&2; exit 2; }
gt_actual="$(sha256 "$GT")"
[ "$gt_actual" = "$GT_SHA" ] || warn_or_fail "warning: $GT_NAME sha256 $gt_actual differs from the pinned $GT_SHA"

# 3. Scan and score.
echo ">> scanning $(basename "$BENCH") ..."
"$BIN" scan "$SRC" --format json --output "$OUT/findings.json" >"$OUT/scan.log" 2>&1 || true
grep -E 'SAST:|Results:' "$OUT/scan.log" || true
python3 "$HERE/score.py" "$OUT/findings.json" "$GT" --threshold 0 || true
python3 "$HERE/score.py" "$OUT/findings.json" "$GT" --threshold 0 --json > "$OUT/score.json" 2>/dev/null

# 4. Compare with the published number.
python3 - "$OUT/score.json" "$EXPECT" "$TOL" "$TAG" <<'PY'
import json, sys
got = json.load(open(sys.argv[1]))["overall"]["benchmark_score"]
exp, tol, tag = float(sys.argv[2]), float(sys.argv[3]), sys.argv[4]
delta = got - exp
print(f"\nmeasured {got:+.4f}   published {exp:+.3f}   delta {delta:+.4f}   tolerance {tol}")
if abs(delta) <= tol:
    print(f"REPRODUCED: {tag} scores {got:+.3f} on OWASP Benchmark v1.2")
    sys.exit(0)
print(f"NOT REPRODUCED: differs from the published score by {delta:+.4f}")
sys.exit(1)
PY
