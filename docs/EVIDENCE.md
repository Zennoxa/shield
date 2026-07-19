# Zennoxa Shield — Tested Against Real Targets

We don't just claim accuracy — here is **exactly what we ran Shield against and what it found.**
Public datasets, default competitor configs, reproducible commands. Numbers you can check yourself.

_Last measured 2026-07-18. Competitors run at default configuration. Figures attributed to OWASP are reproduced from OWASP's own published scorecards. Trademarks belong to their owners; this is a factual comparison, not an endorsement._

---

## 1. What we tested against

| Target (public) | What it is | Layers exercised | Headline result |
|---|---|---|---|
| **OWASP Benchmark v1.2** | 2,740 labelled Java test cases | SAST | **#1 Benchmark Score (+0.450), 92.8% precision** |
| **OWASP Juice Shop** | Deliberately-insecure JS/Node app | SAST · Secrets · SCA | issues detected across all three layers; audit precision below |
| **DVNA** | Damn Vulnerable NodeJS App | SAST · SCA · Secrets | ~88% precision (verified audit) |
| **WebGoat** | OWASP Java training app | SAST · Secrets | ~86% precision (verified audit) |
| **Kubernetes Goat** | Vulnerable K8s cluster | Container · IaC · Secrets | ~93% precision (verified audit) |
| **terragoat** | Vulnerable Terraform (IaC) | IaC | **0 → 18** misconfigurations detected |
| **zennoxa-web / honey-web** | Real Node.js projects (pinned commits) | SCA | **9/9 and 7/7** true advisories |

Everything above is a **public** target except the two real Node projects (used for the dependency benchmark).

---

## 2. Results by scan layer — what we scan, in which files, how well

### 🔍 SAST (static code analysis) — 14 languages
Scans `.py .js .ts .java .go .php .rb .cs .cpp .c .kt .rs .swift .dart` (+ IaC/config formats).

**OWASP Benchmark v1.2** (the industry-standard SAST test suite, 2,740 Java cases; score = TPR − FPR):

| Tool | Precision | Benchmark Score | Source |
|---|---:|---:|---|
| 🏆 **Shield** | **92.8%** | **+0.450** | our measurement |
| FindSecBugs | 66.1% | +0.438 | OWASP scorecard |
| SonarQube (Java) | 81.1% | +0.323 | OWASP scorecard |
| Semgrep | 65.5% | +0.299 | our measurement |
| OWASP ZAP | 99.6% | +0.172 | OWASP scorecard |

→ **Highest Benchmark Score of the tools measured, at 92.8% precision.** Reproduce: `make bench-owasp`.

### 🔑 Secrets — 26 credential patterns
Scans **every file** for cloud keys, tokens, private keys, database URLs, provider API keys.
Verified on Juice Shop / WebGoat / DVNA / Kubernetes Goat — SCA + secret findings verified ~95–100% real in our adversarial audit (see §3).

### 📦 SCA (dependencies) — via OSV.dev + CycloneDX SBOM
Scans `package.json`, `package-lock.json`, `pom.xml`, `requirements.txt`, `go.mod`, `Gemfile.lock`, `composer.lock`, …

**Head-to-head on a real Node project** (`zennoxa-web`, pinned commit, all tools at default config). Ground truth = **9** known-vulnerable advisories (undici, dompurify, form-data), each verifiable in the public GitHub Advisory / OSV databases:

| Tool | Advisories detected (of 9) |
|---|---:|
| **Shield** | **9** |
| OSV | 9 |
| npm audit | 3 |
| Trivy | 2 |
| Snyk | 2 |

Reproduce: `make bench-accuracy`.

### 🐳 Container
Scans `Dockerfile` + image config for misconfigurations and end-of-life base images. Verified on Kubernetes Goat.

### 🏗️ IaC (infrastructure-as-code)
Scans **Terraform / Kubernetes / CloudFormation**. On **terragoat** (the standard vulnerable-Terraform benchmark): **18 misconfigurations** detected where the layer previously scanned nothing (0 → 18).

### ⚙️ CI/CD
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

SCA and taint-based findings verified **~95–100% real**; secrets were the weakest class (since hardened).
_Methodology: internal adversarial verification (each finding independently judged), not a third-party scorecard — reported here for transparency, distinct from the reproducible OWASP result above._

---

## 4. Where Shield is honest about its limits (precision-first, not everything)

We publish our weak spots too — credibility is the whole point:

- **Precision-first by design.** We optimise for low false positives, so on some datasets recall is not the highest (e.g. OWASP v1.2: 92.8% precision at ~46% recall). Fewer, higher-confidence findings is our default.
- **No image-layer OS-CVE scanning yet.** On the vulhub CVE-image corpus Shield is blind to OS-package CVEs baked into images (that's Trivy/Grype territory) — use those alongside Shield for image CVEs.
- **Coverage is uneven across corpora** — strong on OWASP-Java (0.450) and dependency detection; weaker recall on some niche SAST corpora (e.g. Juliet-C). We show the numbers rather than hide them.

---

## 5. Reproduce any of it

- **OWASP Benchmark:** clone the public [OWASP-Benchmark/BenchmarkJava](https://github.com/OWASP-Benchmark/BenchmarkJava), run the Shield CLI, score with OWASP's own tool. Competitor rows are checkable against OWASP's [published scorecards](https://owasp.org/www-project-benchmark/).
- **Dependency example:** the 9 advisories are public GitHub Advisory / OSV entries — verify each, then re-run any tool at default config on the same project + commit.
- **Vulnerable apps:** Juice Shop, DVNA, WebGoat, Kubernetes Goat, terragoat are all public — run `shield scan` on any of them.
