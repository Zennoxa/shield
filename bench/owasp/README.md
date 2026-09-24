# OWASP Benchmark v1.2 — Zennoxa Shield result

[`benchmark.json`](benchmark.json) is the canonical, first-party result Shield
publishes for the [OWASP Benchmark v1.2](https://owasp.org/www-project-benchmark/)
suite (2,740 labelled Java test cases). It is **Shield-only**: it contains no
competitor data.

**Headline (v0.7.0):** Benchmark Score **+0.582** at **92.5% precision** / **63.7% recall**.
Score = True Positive Rate minus False Positive Rate (Youden's J) with strict
CWE-per-category matching; higher is better. The engine run is dated in the file
(`benchmark.measured_at`) and was re-scored with the released v0.7.0 binary on
2026-09-24 (`benchmark.reverified_at`): identical score.

## Reproduce it yourself

One script, no Go toolchain, no account. Needs bash, curl, git, python3 and
sha256sum (or shasum).

```sh
git clone https://github.com/Zennoxa/shield && cd shield
bench/owasp/reproduce.sh v0.7.0
```

It downloads the tagged binary for your OS, verifies it against the release's
`SHA256SUMS`, fetches `OWASP-Benchmark/BenchmarkJava` at the commit pinned in
`benchmark.json`, checks the ground-truth CSV checksum, runs `shield scan` over
the test cases, scores with [`score.py`](score.py) and compares with the
published number (tolerance 0.005). It ends with `REPRODUCED` or `NOT REPRODUCED`.

Variants:

```sh
SHIELD_BIN=/path/to/shield bench/owasp/reproduce.sh        # a binary you built yourself
OWASP_BENCH=/path/to/BenchmarkJava bench/owasp/reproduce.sh v0.7.0   # reuse a checkout
BENCH_STRICT=1 ...                                          # fail on any pin mismatch
```

`score.py` is stdlib-only Python: it reads the `--format json` scan output,
maps each finding's CWE to the OWASP category, and prints the per-category and
overall scorecard (`--json` for machine output, `--threshold` to gate).

## What the number does and does not say

- It measures Java SAST on a synthetic suite; it does not exercise Shield's
  secrets, dependency, container or IaC layers.
- Shield is precision-first. The weakest categories (SQL injection +0.303,
  trust boundary +0.237) are in the file, not hidden.
- To compare other scanners, use OWASP's own published scorecards and run every
  tool at its default configuration. We do not measure other tools here.

> "OWASP" and "OWASP Benchmark" are trademarks of the OWASP Foundation, used for
> identification only; this project is not affiliated with or endorsed by the
> OWASP Foundation.
