<div align="center">

# 🛡️ Zennoxa Shield

**Find, prioritize & fix code security risks — one scan, every layer.**

[Website](https://shield.zennoxa.com) · [Docs](https://shield.zennoxa.com/docs) · [User Guide](https://shield.zennoxa.com/guide) · [Report an issue](https://github.com/Zennoxa/shield/issues)

</div>

---

Zennoxa Shield is a DevSecOps platform that scans your source code, dependencies, secrets, containers, and infrastructure-as-code for security vulnerabilities — then ranks what to fix first by real-world risk (CVSS + EPSS + CISA KEV + code reachability).

> This repository hosts the **Shield CLI releases, docs, and community issue tracker**. The scanning engine is a hosted product at **[shield.zennoxa.com](https://shield.zennoxa.com)** — free during beta.

## What it checks
- **SAST** — insecure code patterns across 14 languages
- **Secrets** — leaked API keys & credentials (28 patterns)
- **Dependencies** — known CVEs (OSV.dev) + a CycloneDX SBOM
- **Containers & IaC** — Dockerfiles, images, Terraform, Kubernetes
- **Prioritization** — a 0–100 risk score so you fix what matters first

## Install the CLI
Grab the latest binary for your platform from **[Releases](https://github.com/Zennoxa/shield/releases/latest)**.

**macOS / Linux**
```bash
# platforms: shield-linux-amd64 · shield-linux-arm64 · shield-darwin-amd64 · shield-darwin-arm64
curl -L https://github.com/Zennoxa/shield/releases/latest/download/shield-darwin-arm64 -o shield
chmod +x shield && sudo mv shield /usr/local/bin/shield
shield version
```

**Windows** — download `shield-windows-amd64.exe` from Releases.

## Quick start
```bash
shield login                              # authenticate (opens your browser)
shield scan . --submit \                  # scan and upload results to the dashboard
  --project YOUR-PROJECT-ID --org YOUR-ORG-ID
```
Browse findings at [shield.zennoxa.com](https://shield.zennoxa.com). Full CLI reference is in the [User Guide](https://shield.zennoxa.com/guide).

## Community & support
- 🐛 **Bugs / feature requests** → [open an issue](https://github.com/Zennoxa/shield/issues)
- 📖 **Docs & rules reference** → [shield.zennoxa.com/docs](https://shield.zennoxa.com/docs)
- Free during beta — no credit card required.

---
© Zennoxa Shield
