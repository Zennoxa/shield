# OWASP Benchmark v1.2 — Zennoxa Shield result

[`benchmark.json`](benchmark.json) is the canonical, first-party result Shield
publishes for the [OWASP Benchmark v1.2](https://owasp.org/www-project-benchmark/)
suite (2,740 labelled Java test cases). It is **Shield-only** — it contains no
competitor data.

**Headline (v0.2.0):** Benchmark Score **+0.547** at **92.4% precision** / **60% recall**.
Score = True Positive Rate − False Positive Rate (Youden's J); higher is better.

## Reproduce it yourself
1. Install the Shield CLI **v0.2.0** and verify the download against `SHA256SUMS` on the release.
2. `git clone https://github.com/OWASP-Benchmark/BenchmarkJava`
3. `shield scan BenchmarkJava/src/main/java/org/owasp/benchmark/testcode --format sarif --output shield.sarif`
4. Score `shield.sarif` against `expectedresults-1.2.csv` with OWASP's own scoring tooling.

The number is produced by the **downloadable binary** on a **public** suite, so
anyone can reproduce it. To compare other scanners, use OWASP's own published
scorecards (run every tool at its default configuration).

> "OWASP" and "OWASP Benchmark" are trademarks of the OWASP Foundation, used for
> identification only; this project is not affiliated with or endorsed by the
> OWASP Foundation.
