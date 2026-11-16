# OWASP Benchmark v1.2 — Zennoxa Shield result

[`benchmark.json`](benchmark.json) is the canonical, first-party result Shield
publishes for the [OWASP Benchmark v1.2](https://owasp.org/www-project-benchmark/)
suite (2,740 labelled Java test cases). It is **Shield-only** — it contains no
competitor data.

**Headline (measured on the v0.8.0 release binary, 2026-11-16):** Benchmark Score **+1.000** when the whole benchmark project is scanned: all 1,415 vulnerable cases reported, none of the 1,325 safe ones. Scanning only the `testcode` folder gives **+0.912** (recall 91.2%, no false positive), because 124 cases depend on helper classes and a properties file outside that folder. v0.7.0 scored +0.582 (92.5% precision, 63.7% recall) either way.
Score = True Positive Rate − False Positive Rate (Youden's J); higher is better.

## Reproduce it yourself
1. Install the Shield CLI **v0.8.0** and verify the download against `SHA256SUMS` on the release.
2. `git clone https://github.com/OWASP-Benchmark/BenchmarkJava`
3. `shield scan BenchmarkJava --format sarif --output shield.sarif` (for the second figure, scan `BenchmarkJava/src/main/java/org/owasp/benchmark/testcode`)
4. Score `shield.sarif` against `expectedresults-1.2.csv`: a finding counts for a test case when it is reported in that case's file and its CWE matches the case's category. The script we use for this mapping is not published here yet.

A perfect score means the engine models the code shapes this suite is built from. It is not a claim about other code: on NIST Juliet for Java, which was not used during development, the data-flow findings of v0.8.0 catch 51.9% of the vulnerable cases and flag none of the fixed variants.

The scan is produced by the **downloadable binary** on a **public** suite. Until the
scoring script is published, treat the score as our measurement. To compare other
scanners, use OWASP's own published scorecards (run every tool at its default configuration).

> "OWASP" and "OWASP Benchmark" are trademarks of the OWASP Foundation, used for
> identification only; this project is not affiliated with or endorsed by the
> OWASP Foundation.
