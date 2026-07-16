<div align="center">

# 🛡️ Zennoxa Shield

**Find, prioritize & fix code security risks — one scan, every layer.**

[Website](https://zennoxa.com) · [Report an issue](https://github.com/Zennoxa/shield/issues)

[![Latest release](https://img.shields.io/github/v/release/Zennoxa/shield?label=CLI&color=4f46e5)](https://github.com/Zennoxa/shield/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
![Platforms](https://img.shields.io/badge/platforms-macOS%20%C2%B7%20Linux%20%C2%B7%20Windows-informational)
![Status](https://img.shields.io/badge/beta-free%20to%20use-16a34a)

</div>

---

Zennoxa Shield is a DevSecOps platform that scans your source code, dependencies, secrets, containers, and infrastructure-as-code for security vulnerabilities — then ranks what to fix first by real-world risk, so you spend time on the issues that actually matter.

> **This repository** hosts the **Shield CLI releases, documentation, and community issue tracker.** The scanning engine and dashboard are a hosted product at **[zennoxa.com](https://zennoxa.com)** — free during beta.

## What it checks

| Layer | What Shield finds |
| --- | --- |
| **Code (SAST)** | Insecure patterns across **21 languages** — injection, XSS, weak crypto, unsafe deserialization, and more |
| **Secrets** | **26 credential patterns** — cloud keys, tokens, private keys, database URLs, provider API keys |
| **Dependencies (SCA)** | Known CVEs via **[OSV.dev](https://osv.dev)** + a **CycloneDX 1.4 SBOM** |
| **Containers** | Dockerfile misconfigurations and image scanning |
| **Infrastructure-as-Code** | Terraform & Kubernetes misconfigurations *(hosted)* |
| **License compliance** | Dependency license risks *(hosted)* |
| **Prioritization** | A **0–100 risk score** per finding — severity + code reachability — so the noise sinks and the exploitable issues rise |

## Supported languages (SAST)

C · C++ · C# · Dart · Go · Java · JavaScript · Kotlin · Lua · Perl · PHP · Python · Ruby · Rust · Scala · Shell · Swift · TypeScript — plus **JSON · YAML · Terraform** for config/IaC.

## Install the CLI

Grab the latest binary for your platform from **[Releases](https://github.com/Zennoxa/shield/releases/latest)**.

**macOS / Linux**
```bash
# pick your platform: shield-linux-amd64 · shield-linux-arm64 · shield-darwin-amd64 · shield-darwin-arm64
curl -L https://github.com/Zennoxa/shield/releases/latest/download/shield-darwin-arm64 -o shield
chmod +x shield && sudo mv shield /usr/local/bin/shield
shield version
```

**Windows** — download `shield-windows-amd64.exe` from Releases and add it to your `PATH`.

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

## Use it in CI

Fail a pull request when Shield finds high-severity issues:

```yaml
# .github/workflows/security.yml
name: Shield security scan
on: [pull_request]
jobs:
  shield:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Shield CLI
        run: |
          curl -L https://github.com/Zennoxa/shield/releases/latest/download/shield-linux-amd64 -o shield
          chmod +x shield && sudo mv shield /usr/local/bin/shield
      - name: Scan
        run: shield scan . --deps
```

## How prioritization works

Most scanners drown you in findings. Shield scores every finding **0–100** by combining its **vulnerability severity** with **code reachability** (is the risky code actually reachable?), so the list is sorted by what's genuinely exploitable — not just what's noisy. You fix the top of the list and move on.

## FAQ

**Is it free?** Yes — free during beta, no credit card required. The CLI and documentation in this repo are MIT-licensed.

**Does my code leave my machine?** `shield scan .` runs locally. Results are only uploaded when you pass `--submit` to send them to your dashboard.

**Which languages are supported?** 21 for SAST (see the list above). Secrets, dependency, and container scanning are language-agnostic.

**Can I run it in CI?** Yes — see the GitHub Actions example above. Any CI that can run a binary works.

## Community & support

- 🐛 **Bugs / feature requests** → [open an issue](https://github.com/Zennoxa/shield/issues)
- 🔒 **Found a security vulnerability?** → please report it privately via [GitHub Security Advisories](https://github.com/Zennoxa/shield/security/advisories/new). See [SECURITY.md](./SECURITY.md).
- 🤝 **Contributing** → [CONTRIBUTING.md](./CONTRIBUTING.md)
- 🌐 **Product & sign-up** → [zennoxa.com](https://zennoxa.com)

## License

The CLI and documentation in this repository are released under the [MIT License](./LICENSE). The hosted scanning engine and dashboard are a separate, proprietary product.

---

<div align="center">© Zennoxa · <a href="https://zennoxa.com">zennoxa.com</a></div>
