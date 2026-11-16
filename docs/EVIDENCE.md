# Zennoxa Shield — Tested Against Real Targets

We don't just claim accuracy — here is **exactly what we ran Shield against and what it found.**
Public datasets, reproducible commands, and the exact targets we ran against. Numbers you can check yourself.

_The OWASP Benchmark and Juliet figures were measured on the v0.8.0 release binary on 2026-11-16; the application audits in section 3 date from 2026-07-18 and an earlier release. Every figure is a **measured result** on the named public dataset, reproducible with the stated command — not a claim of general superiority. Competitor figures on the OWASP Benchmark are reproduced from **OWASP's own published scorecards**. Results depend on tool versions, rulesets, configuration, and workload and may differ elsewhere. See the Methodology Notice at the end._

---

## 1. What we tested against

| Target (public) | What it is | Layers exercised | Headline result |
|---|---|---|---|
| **OWASP Benchmark v1.2** | 2,740 labelled Java test cases | SAST | **Benchmark Score +1.000** scanning the whole project (+0.912 scanning only `testcode`), no false positive |
| **NIST Juliet for Java** | 5,772 cases of nine injection weaknesses, not used in development | SAST | data flow catches **51.9%** of the vulnerable cases, flags none of the fixed variants |
| **OWASP Juice Shop** | Deliberately-insecure JS/Node app | SAST · Secrets · SCA | issues detected across all three layers; audit precision below |
| **DVNA** | Damn Vulnerable NodeJS App | SAST · SCA · Secrets | ~88% precision (verified audit) |
| **WebGoat** | OWASP Java training app | SAST · Secrets | ~86% precision (verified audit) |
| **Kubernetes Goat** | Vulnerable K8s cluster | Container · IaC · Secrets | ~93% precision (verified audit) |
| **terragoat** | Vulnerable Terraform (IaC) | IaC | **0 → 18** misconfigurations detected |
| **zennoxa-web / honey-web** | Real Node.js projects (pinned commits) | SCA | **9/9 and 7/7** true advisories |

Everything above is a **public** target except the two real Node projects (used for the dependency benchmark).

---

## 2. Results by scan layer — what we scan, in which files, how well

### SAST (static code analysis) — 14 languages
Scans `.py .js .ts .java .go .php .rb .cs .cpp .c .kt .rs .swift .dart` (+ IaC/config formats).

**OWASP Benchmark v1.2** (the industry-standard SAST test suite, 2,740 Java cases; score = TPR − FPR):

With v0.8.0 Shield reports all 1,415 vulnerable cases and none of the 1,325 safe ones, a **Benchmark Score of +1.000**, when the whole benchmark project is scanned, and +0.912 when only its `testcode` folder is scanned (124 cases depend on helper classes and a properties file outside it). v0.7.0 scored +0.582. The scan is reproducible with the released CLI against the public suite (see [`bench/owasp/benchmark.json`](../bench/owasp/benchmark.json)). To see how other tools score, check OWASP's own [published scorecards](https://owasp.org/www-project-benchmark/).

### Secrets — 37 credential patterns
Scans **every file** for cloud keys, tokens, private keys, database URLs, provider API keys.
Verified on Juice Shop / WebGoat / DVNA / Kubernetes Goat — SCA + secret findings verified ~95–100% real in our adversarial audit (see §3).

### SCA (dependencies) — via OSV.dev + CycloneDX SBOM
Scans `package.json`, `package-lock.json`, `pom.xml`, `requirements.txt`, `go.mod`, `Gemfile.lock`, `composer.lock`, …

On a real Node project (`zennoxa-web`, pinned commit) there are **9** known-vulnerable advisories (undici, dompurify, form-data), each verifiable in the public GitHub Advisory / OSV databases. **Shield detected all 9.** Reproduce by running `shield scan --deps` on the pinned commit (each advisory is verifiable in the public GitHub Advisory / OSV databases), then run any SCA tool at default config on the same commit to compare for yourself.

### Container
Scans `Dockerfile` + image config for misconfigurations and end-of-life base images. Verified on Kubernetes Goat.

### IaC (infrastructure-as-code)
Scans **Terraform / Kubernetes / CloudFormation**. On **terragoat** (the standard vulnerable-Terraform benchmark): **18 misconfigurations** detected where the layer previously scanned nothing (0 → 18).

### CI/CD
Scans workflow YAML (`.github/workflows/*`, GitLab CI) for pipeline-injection and supply-chain risks.

---

## 3. Adversarial verification — 4 vulnerable apps, every finding checked

We ran Shield across **4 public deliberately-vulnerable applications** and then **adversarially verified every single finding** (find → refute → judge):

| App | Precision (verified) |
|---|---:|
| Kubernetes Goat | ~93% |
| DVNA | ~88% |
| WebGoat | ~86% |
| OWASP Juice Shop | ~73% |
| **Overall** | **301 true / 356 total = 84.6%** |

SCA and taint-based classes had the highest verified-true rate; secrets had the highest false-positive rate (since hardened).
_Methodology: internal adversarial verification (each finding independently judged), not a third-party scorecard — reported here for transparency, distinct from the reproducible OWASP result above._

---

## 4. Where Shield is honest about its limits (precision-first, not everything)

We publish our weak spots too — credibility is the whole point:

- **A perfect benchmark score is not a claim about your code.** v0.8.0 reports every vulnerable case of OWASP Benchmark v1.2 because it models the code shapes that suite is built from. On NIST Juliet for Java, which we did not develop against, its data-flow findings catch 51.9% of the vulnerable cases, and the simpler single-line rules still flag a fixed variant in 15.8% of cases. Expect real code to sit closer to Juliet than to the benchmark.
- **Precision-first by design.** We optimise for low false positives. Fewer, higher-confidence findings is our default.
- **No image-layer OS-CVE scanning yet.** On the vulhub CVE-image corpus Shield is blind to OS-package CVEs baked into images — pair it with a dedicated image-CVE scanner for that layer.
- **Coverage is uneven across corpora and languages** — strong on OWASP-Java and dependency detection; about half of Juliet-Java by data flow; weaker on some niche SAST corpora (e.g. Juliet-C). Data flow covers 14 languages; the other 11 have single-line rules only. We show the numbers rather than hide them.

---

## 5. Reproduce any of it

- **OWASP Benchmark:** clone the public [OWASP-Benchmark/BenchmarkJava](https://github.com/OWASP-Benchmark/BenchmarkJava), run the Shield CLI, score with OWASP's own tool. The full ranked leaderboard is published by OWASP at their [official scorecards](https://owasp.org/www-project-benchmark/).
- **Dependency example:** the 9 advisories are public GitHub Advisory / OSV entries — verify each, then re-run any tool at default config on the same project + commit.
- **Vulnerable apps:** Juice Shop, DVNA, WebGoat, Kubernetes Goat, terragoat are all public — run `shield scan` on any of them.
