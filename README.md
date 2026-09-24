<div align="center">

# Zennoxa Shield

**Find, prioritize & fix code security risks — one scan, every layer.**

[Website](https://zennoxa.com) · [Report an issue](https://github.com/Zennoxa/shield/issues)

[![Latest release](https://img.shields.io/github/v/release/Zennoxa/shield?label=CLI&color=4f46e5)](https://github.com/Zennoxa/shield/releases/latest)
[![Binary: MIT, source closed](https://img.shields.io/badge/binary-MIT%20%C2%B7%20source%20closed-blue.svg)](./LICENSE)
![Platforms](https://img.shields.io/badge/platforms-macOS%20%C2%B7%20Linux%20%C2%B7%20Windows-informational)
![Status](https://img.shields.io/badge/beta-free%20to%20use-16a34a)
[![OWASP Benchmark](https://img.shields.io/badge/OWASP%20Benchmark-%2B0.582-7c6cff)](./bench/owasp/benchmark.json)

</div>

<p align="center">
  <img src="docs/priority-demo.gif" alt="Zennoxa Shield's Priority Engine re-sorting findings by real-world exploitability so the reachable, exploitable bug rises to the top" width="820">
</p>

<p align="center"><em>Shield's <b>Priority Engine</b> re-orders findings by real-world exploitability — the reachable, exploitable bug rises to the top.<br><sub>Hosted dashboard shown. The <code>shield</code> CLI prints an offline priority for every finding that has a CVSS value, in text, JSON and SARIF: CVSS and reachability, plus EPSS and CISA KEV for dependency CVEs when you pass <code>--deps</code>.</sub></em></p>

<p align="center">
  <img src="docs/scan-demo.svg" alt="Example: shield scan finds a shell injection, hardcoded secrets and a weak hash" width="720">
</p>


---

**Zennoxa Shield is a static security scanner for source code, secrets, dependency manifests, Dockerfiles and infrastructure-as-code.** In one command it runs static analysis (SAST), secret scanning, dependency / software-composition analysis (SCA), container and infrastructure-as-code (IaC) checks over your codebase — then ranks every finding by real-world exploitability, so you fix what actually matters instead of a wall of "critical" alerts.

The `shield` CLI is a free binary released under the MIT license (its source is not public and is not in this repository). It runs offline from the command line, and outputs **SARIF** for GitHub code scanning and CI security gates across **25 programming languages**. What sets Shield apart from most scanners is its **Priority Engine**: instead of sorting by raw severity, it blends CVSS, EPSS, CISA KEV and code reachability into one **0–100 score**, so the genuinely exploitable findings rise to the top. Offline, the CLI scores with CVSS and reachability only (so at most 45 of 100) and adds EPSS and KEV for dependency CVEs when you pass `--deps`; the hosted dashboard keeps those two signals fresh for every finding that has a CVE.

> **This repository** hosts the Shield CLI releases, documentation and the community issue tracker. The scanning engine is compiled into the CLI binary and runs on your machine; its source is not public. The dashboard at **[zennoxa.com](https://zennoxa.com)** is a separate proprietary service that stores and re-ranks the findings you choose to submit — free during beta.

## Latest research

**The Severity Illusion — 9 in 10 "Critical" CVEs show no sign of being exploited.**
We joined three public datasets (NVD CVSS · FIRST EPSS · CISA KEV) across all
30,409 CVSS-9.0+ CVEs: **89.7%** sit below an EPSS exploitation probability of
0.10 *and* never appear in CISA's Known Exploited Vulnerabilities catalog — only
**1.6%** are in KEV. Every figure is reproducible from the three public snapshots.

→ **Read the study:** https://zennoxa.com/research/severity-illusion-critical-cves-2026

<p align="center">
  <a href="https://zennoxa.com/research/severity-illusion-critical-cves-2026">
    <img src="docs/severity-illusion-hero.png" width="820"
         alt="89.7% of CVSS-9.0+ Critical CVEs have EPSS below 0.10 and are absent from CISA KEV">
  </a>
</p>

_This is exactly what Shield's Priority Engine solves: it blends CVSS, EPSS, KEV
and reachability into one 0–100 score so the ~10% that actually matter rise first._

## What it checks

| Layer | What Shield finds |
| --- | --- |
| **Code (SAST)** | Insecure patterns across **25 languages** (14 with comprehensive coverage, a small number of rules each for the other 11) — injection, XSS, weak crypto, unsafe deserialization, and more |
| **Secrets** | **26 credential patterns** — cloud keys, tokens, private keys, database URLs, provider API keys |
| **Dependencies (SCA)** | Known CVEs via **[OSV.dev](https://osv.dev)** + a **CycloneDX 1.4 SBOM** |
| **Containers** | Dockerfile and Kubernetes manifest misconfigurations; `shield image-scan` inspects a registry image's config and build history without pulling layers (`--os-cve` adds OS-package CVEs) |
| **Infrastructure-as-Code** | Terraform & Kubernetes misconfigurations |
| **License compliance** | Dependency license risks *(hosted)* |
| **Priority Engine** | A **0–100 priority score** — CVSS + EPSS + CISA KEV + code reachability ([what the CLI computes offline](#how-prioritization-works--the-priority-engine)) — so the noise sinks and the exploitable issues rise |

## Supported languages (SAST)

**14 with comprehensive coverage:** C · C++ · C# · Dart · Go · Java · JavaScript · Kotlin · PHP · Python · Ruby · Rust · Swift · TypeScript

**Plus lighter coverage for 11 more:** Scala · Solidity · PowerShell · Groovy · Lua · Perl · Objective-C · VB.NET · Shell · SQL · Vyper

— and **YAML · Terraform · Kubernetes · CloudFormation (basic) · Dockerfile · Helm** for config / IaC.

## Measured results

> Per-target notes for everything we tested (OWASP Benchmark, Juice Shop, WebGoat, DVNA, Kubernetes Goat, terragoat) are in [docs/EVIDENCE.md](docs/EVIDENCE.md).

_Measured by us with the released CLI at its default configuration. Results vary with version, configuration and codebase. Last re-scored on the v0.7.0 release binary on 2026-09-21._

### OWASP Benchmark v1.2 (third-party test suite)

The [OWASP Benchmark](https://owasp.org/www-project-benchmark/) is a public suite of **2,740 labelled Java test cases** (score = True Positive Rate − False Positive Rate, higher is better). Shield scores a **Benchmark Score of +0.582 at 92.5% precision** (recall 63.7%, false-positive rate 5.5%) — see [`bench/owasp/benchmark.json`](bench/owasp/benchmark.json) for the per-category breakdown. The benchmark is Java only; it says nothing about the other languages or the secret, dependency, container and IaC layers.

What you can and cannot check today: the suite and its expected-results file are public, and the scan is one command (`shield scan <BenchmarkJava>/src/main/java/org/owasp/benchmark/testcode --format json --output findings.json`). The scorer that maps Shield's findings to the suite's categories is [`bench/owasp/score.py`](bench/owasp/score.py), and [`bench/owasp/reproduce.sh`](bench/owasp/reproduce.sh) runs the whole thing end to end (verified release download, pinned dataset, scan, score, compare) and ends with `REPRODUCED` or `NOT REPRODUCED`.

### Dependency (SCA) scanning — a run you can repeat

```bash
git clone https://github.com/appsecco/dvna && cd dvna && git checkout 9ba473a
shield scan . --deps
```

With v0.7.0 on 2026-09-21 this reports 35 dependency findings for DVNA's 19 declared packages, for example CVE-2017-5941 (node-serialize 0.0.4) and CVE-2022-29078 (ejs 2.5.7), next to 10 code findings and 2 container findings. Advisory data comes from [OSV.dev](https://osv.dev), so the count grows as new advisories are published, and the priority of dependency findings moves with EPSS.

Shield runs SAST, Secrets, SCA, Container, and CI/CD checks in a single local scan (dependency lookups with `--deps` need the network), with findings ranked by severity, reachability and, for dependency CVEs, EPSS/KEV.

### A note on precision

Shield is **precision-first**: it is tuned to keep false positives low so that the findings you see are the ones worth acting on. As a trade-off, on some datasets its recall is not the highest — on OWASP v1.2, for example, Shield reaches 92.5% precision at roughly 64% recall. We think fewer, higher-confidence findings are the right default, and the CLI is free to run on your own code so you can judge the trade-off there.

---

_"OWASP" and "OWASP Benchmark" are trademarks of the OWASP Foundation, used here for identification only; this project is not affiliated with, endorsed by, or sponsored by the OWASP Foundation. The OWASP Benchmark test suite is used under its open-source license._

## Install the CLI

### Homebrew (macOS / Linux)

```bash
brew install zennoxa/tap/shield
shield version
```

### Direct download

Grab the latest binary from **[Releases](https://github.com/Zennoxa/shield/releases/latest)** — optionally verifying it against the published `SHA256SUMS`.

```bash
# pick your platform: shield-linux-amd64 · shield-linux-arm64 · shield-darwin-amd64 · shield-darwin-arm64
curl -LO https://github.com/Zennoxa/shield/releases/latest/download/shield-darwin-arm64
curl -LO https://github.com/Zennoxa/shield/releases/latest/download/SHA256SUMS

# verify the download (prints "shield-darwin-arm64: OK")
# macOS: shasum -a 256 -c SHA256SUMS --ignore-missing
sha256sum --ignore-missing --check SHA256SUMS

# install onto your PATH
chmod +x shield-darwin-arm64 && sudo mv shield-darwin-arm64 /usr/local/bin/shield
shield version
```

**Windows** — download `shield-windows-amd64.exe` from Releases and add it to your `PATH`.

### What the install script does

`curl -sSL https://zennoxa.com/install | sh` detects your OS and CPU, downloads the matching binary and `SHA256SUMS` from the latest GitHub release, and aborts if the SHA-256 does not match. It installs to `/usr/local/bin` (using `sudo` only if that directory is not writable) or to `SHIELD_INSTALL_DIR` if you set it. Two things to know: the checksum detects a corrupted download, not a compromised release, and if `SHA256SUMS` cannot be fetched or no SHA-256 tool is present the script warns and installs without verification. If that matters to you, use the direct download above and verify by hand.

## Quick start

```bash
# Scan a project locally — SAST + secrets, no account needed
shield scan .

# Add dependency (SCA) analysis
shield scan . --deps

# Scan a container image
shield image-scan myorg/myapp:1.4

# Log in and submit results to your dashboard
shield login
shield scan . --submit --project YOUR-PROJECT-ID --org YOUR-ORG-ID
```

Browse and triage findings at **[zennoxa.com](https://zennoxa.com)**.

## Use Shield from your AI coding agent (MCP)

Since v0.7.0 the same binary runs as a [Model Context Protocol](https://modelcontextprotocol.io) server over stdio, so an MCP client such as Claude Code or Cursor can scan a repository, page through findings by priority, read the flagged line with fix guidance, look up a rule, apply a gate and list SBOM components.

```bash
# Claude Code
claude mcp add shield -- shield mcp
# or confine scans to the project directory:
claude mcp add shield -- shield mcp --root .
```

```json
// Other MCP clients (mcp.json)
{ "mcpServers": { "shield": { "command": "shield", "args": ["mcp"] } } }
```

| Tool | What it does |
| --- | --- |
| `shield_scan` | Scan a directory; returns a scan id, severity counts and the top 25 findings by priority |
| `shield_findings` | Page and filter a scan's findings (severity, rule, file, minimum priority, reachable only) |
| `shield_finding` | One finding: file and line, flagged snippet, the recommendation where the engine has one (secret and Terraform findings carry only title and CWE), rule guidance for catalogued SAST rules |
| `shield_rule` | Look up a catalogued SAST rule by id |
| `shield_gate` | Pass/fail on a severity, grade or score threshold |
| `shield_sbom` | CycloneDX or SPDX components, paged |

What touches the network:

| Mode | Leaves the machine |
| --- | --- |
| `shield_scan` (default) and every other tool | Nothing |
| `shield_scan` with `deps=true` | Package names and versions to OSV.dev, CVE ids to FIRST EPSS, CISA KEV feed download. No source code |
| Tool results | Returned to your agent (finding metadata and the flagged line), which forwards them to its model provider like any tool output |

Things to know: the tools only read from disk. Secret values in secret findings are masked before they are returned (pattern-based, best effort). Shield does not edit code; the agent does. Each finding carries a `fingerprint`, a hash of the rule, file path and flagged line text: it survives line-number shifts and changes when the file is renamed or that line is edited, so a rescan shows what was fixed. One scan runs at a time, with `--scan-timeout` (default 10m); `shield mcp --root DIR` rejects scan paths outside DIR (a path check: symlinks inside DIR are still followed), and `/`, `/proc`, `/sys`, `/dev`, `/run` and `/boot` are refused as scan roots. We have run the scan and finding tools end to end with Claude Code 2.1 and with the official MCP Go SDK client; other stdio clients should work but are not tested by us yet. More detail: [zennoxa.com/mcp](https://zennoxa.com/mcp).

## Pre-commit hook

Run Shield before every commit with [pre-commit](https://pre-commit.com). Install the `shield` CLI first (Homebrew or a release binary above), then add to your project's `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/Zennoxa/shield
    rev: v0.7.0
    hooks:
      - id: shield
```

```bash
pre-commit install
pre-commit run shield --all-files
```

The hook scans the whole repository and blocks the commit on any finding of any severity, and also if the scan itself fails (bypass with `git commit --no-verify`).

## Use it in CI

Add the **Zennoxa Shield GitHub Action** — one step, no manual install:

```yaml
# .github/workflows/security.yml
name: Security
on: [push, pull_request]
jobs:
  shield:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Zennoxa/shield@v0.7.0     # pin to a tag or commit SHA
        with:
          version: v0.7.0              # pins the scanner binary too (default: latest)
          args: --deps                 # also scan dependencies (SCA)
          fail-on-findings: false      # set true to block PRs on findings
```

Inputs: `path` (default `.`), `args`, `version` (default `latest`), `fail-on-findings`. More in [`examples/`](examples/).

## How prioritization works — the Priority Engine

Most scanners drown you in findings. Shield's **Priority Engine** scores findings **0–100** from four signals, not just severity:

```
Priority = CVSS·0.30 + EPSS·0.30 + KEV·0.25 + reachability·0.15
```

- **CVSS** — the vulnerability's base severity.
- **EPSS** — FIRST.org's probability it will be exploited in the wild in the next 30 days (where a CVE is known).
- **CISA KEV** — whether it appears in the Known Exploited Vulnerabilities catalog (proven exploited in the real world).
- **Reachability** — true when Shield's taint pass traces untrusted input to the flagged sink within the same file. It is not call-graph analysis; cross-file flows are missed.

So the list sorts by what's genuinely exploitable — not just what's noisy. You fix the top and move on.

**What the CLI computes offline.** A signal that is not available contributes zero. A plain `shield scan .` has CVSS and reachability, so its scores top out at 45. With `--deps`, dependency CVEs also get EPSS and CISA KEV. Findings without a CVE (code, secrets, configuration) have no EPSS or KEV anywhere, so 45 is their ceiling on the dashboard too; the hosted dashboard keeps EPSS and CISA KEV fresh for findings that do have a CVE. Findings whose rule has no CVSS value (container-config and Terraform rules today) are not scored. The CLI prints which basis it used: `PriorityBasis` in JSON, `properties.priorityBasis` in SARIF, and a legend line in text output.

## FAQ

**What is Zennoxa Shield?** Zennoxa Shield is a security scanner that finds vulnerabilities across your code (SAST), dependencies (SCA), secrets, containers and infrastructure-as-code in a single scan, then ranks every finding **0–100** by real-world exploitability. The `shield` CLI in this repo is free and MIT-licensed; a hosted dashboard at [zennoxa.com](https://zennoxa.com) adds team and organization features.

**Is the `shield` CLI free? How is it licensed?** The `shield` binary and the documentation in this repository are released under the [MIT license](./LICENSE): free to use, run in CI and redistribute, no account. The engine source is not public. The hosted dashboard at zennoxa.com is a separate, proprietary service.

**Is it free?** The CLI is free with no time limit. The hosted dashboard is free during beta for up to 5 repositories, no credit card; pricing after the beta has not been set.

**Does my code leave my machine?** `shield scan .` runs locally and makes no network requests. With `--deps`, package names and versions are sent to OSV.dev, CVE ids to FIRST EPSS, and the CISA KEV feed is downloaded; source code is not sent. Nothing is uploaded unless you pass `--submit`. Then, per finding, the CLI sends the rule id, severity, file path, line number, the flagged source line, the recommendation and the CVE id, plus the git branch and commit. For secret findings the flagged line is the line that contains the secret, so review what you submit.

**Which languages are supported?** 25 for SAST — 14 with comprehensive coverage plus a small number of rules each for 11 more (see the list above). Secret and container scanning are language-agnostic; dependency scanning covers 10 ecosystems (npm, PyPI, Go, Maven, NuGet, Packagist, Pub, RubyGems, crates.io, Hex).

**Does Shield output SARIF / work with GitHub code scanning?** Yes. `shield scan . --format sarif` emits [SARIF](https://sarifweb.azurewebsites.net/) you can upload to GitHub code scanning or feed to any SARIF-aware CI or security gate. See the GitHub Action example above.

**How is Shield different from Snyk, Semgrep, SonarQube or Trivy?** Most scanners hand you a long list sorted by raw severity. Shield's **Priority Engine** ranks findings by *exploitability* — blending CVSS, EPSS, CISA KEV and code reachability — so you act on the ~10% that actually matter, and it covers multiple layers in one scan: SAST, secrets, container and IaC checks run offline, and SCA with `--deps` queries OSV.dev. Rather than take our word for it, run it next to any other tool at its defaults on your own code and compare.

**Can I run it in CI?** Yes — see the GitHub Actions example above. Any CI that can run a binary works.

## Contributors welcome

New here? We've labelled a handful of **[good first issues](https://github.com/Zennoxa/shield/labels/good%20first%20issue)** — CI examples (GitLab, Bitbucket, Jenkins), a SARIF → GitHub code-scanning guide, and an example `.shieldignore`. They're self-contained and need no engine internals. The engine source is closed, so bug and false-positive reports are the most useful contribution. Open a PR or say hi in an issue — see [CONTRIBUTING.md](./CONTRIBUTING.md).

## Community & support

- **Bugs / feature requests** → [open an issue](https://github.com/Zennoxa/shield/issues)
- **Found a security vulnerability?** → please report it privately via [GitHub Security Advisories](https://github.com/Zennoxa/shield/security/advisories/new). See [SECURITY.md](./SECURITY.md).
- **Contributing** → [CONTRIBUTING.md](./CONTRIBUTING.md)
- **Product & sign-up** → [zennoxa.com](https://zennoxa.com)

## License

The CLI binary and the documentation in this repository are released under the [MIT License](./LICENSE). The engine source is not public. The hosted dashboard is a separate, proprietary service.

---

<div align="center">© Zennoxa · <a href="https://zennoxa.com">zennoxa.com</a></div>
