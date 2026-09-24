# Language matrix

GENERATED FILE, mirrored from the engine repository where a Go test derives it
from the scanner's own tables (file-to-language map, taint specs, rule language
tags, reachability extension lists, secret rule ids, dependency manifest table)
and fails CI when the committed copy drifts. Do not edit by hand. Read with
[BLIND_SPOTS.md](BLIND_SPOTS.md), which explains what each column does not mean.

## Totals

- Language tags the SAST layer can assign to a file: 36
- Programming languages (general-purpose plus smart-contract): 24
- Tags with at least one rule: 34
- Languages with cross-line taint tracking (intra-file): 8 (C, C++, Go, Java, JavaScript, PHP, Python, TypeScript)
- Languages the hosted import-graph reachability parses: 4 (Go, JavaScript, Python, TypeScript)
- Languages the hosted package-tier reachability reads imports from: 6 (Go, Java, JavaScript, Python, Ruby, TypeScript)
- SAST rules: 341 in the free tier (the public CLI), 341 across all tiers (hosted)
- Rules with no language tag, run on every file regardless of language: 3
- Secret detectors: 27
- Dependency ecosystems: 10, across 18 manifest and lockfile formats

## Languages

| Language | Tag | Class | Files | Rules | Taint sources / sinks / sanitizers | Same-file summaries | Import graph (hosted) | Package tier (hosted) |
|---|---|---|---|---:|---|---|---|---|
| JavaScript | `javascript` | general-purpose | `.cjs` `.js` `.jsx` `.mjs` `.svelte` `.vue` | 36 | 7 / 8 / 11 | no | yes | yes |
| TypeScript | `typescript` | general-purpose | `.ts` `.tsx` | 36 | 7 / 8 / 11 | no | yes | yes |
| Python | `python` | general-purpose | `.py` | 26 | 5 / 9 / 7 | no | yes | yes |
| Ruby | `ruby` | general-purpose | `.rb` | 26 | none | no | no | yes |
| Java | `java` | general-purpose | `.java` | 23 | 16 / 9 / 11 | yes | no | yes |
| PHP | `php` | general-purpose | `.php` | 22 | 2 / 4 / 9 | no | no | no |
| C | `c` | general-purpose | `.c` `.h` | 21 | 4 / 4 / 4 | no | no | no |
| C# | `csharp` | general-purpose | `.cs` | 21 | none | no | no | no |
| C++ | `cpp` | general-purpose | `.cc` `.cpp` `.cxx` `.hpp` | 21 | 4 / 4 / 4 | no | no | no |
| Kotlin | `kotlin` | general-purpose | `.kt` `.kts` | 18 | none | no | no | no |
| Rust | `rust` | general-purpose | `.rs` | 17 | none | no | no | no |
| Swift | `swift` | general-purpose | `.swift` | 17 | none | no | no | no |
| Dart | `dart` | general-purpose | `.dart` | 14 | none | no | no | no |
| Go | `go` | general-purpose | `.go` | 12 | 8 / 4 / 3 | no | yes | yes |
| Groovy | `groovy` | general-purpose | `.gradle` `.groovy` `Jenkinsfile` | 6 | none | no | no | no |
| Objective-C | `objc` | general-purpose | `.m` `.mm` | 6 | none | no | no | no |
| PowerShell | `powershell` | general-purpose | `.ps1` `.psd1` `.psm1` | 6 | none | no | no | no |
| Shell | `shell` | general-purpose | `.bash` `.ksh` `.sh` `.zsh` | 6 | none | no | no | no |
| VB.NET | `vbnet` | general-purpose | `.vb` | 6 | none | no | no | no |
| Perl | `perl` | general-purpose | `.pl` `.pm` | 4 | none | no | no | no |
| Scala | `scala` | general-purpose | `.sc` `.scala` | 4 | none | no | no | no |
| Lua | `lua` | general-purpose | `.lua` `.nse` | 3 | none | no | no | no |
| Solidity | `solidity` | smart contract | `.sol` | 6 | none | no | no | no |
| Vyper | `vyper` | smart contract | `.vy` | 6 | none | no | no | no |
| SQL | `sql` | query | `.sql` | 6 | none | no | no | no |
| JSP | `jsp` | template | `.jsp` `.jspx` `.tag` | 3 | none | no | no | no |
| FreeMarker | `freemarker` | template | `.ftl` `.ftlh` | 2 | none | no | no | no |
| Jinja | `jinja` | template | `.j2` `.jinja` `.jinja2` | 2 | none | no | no | no |
| Twig | `twig` | template | `.twig` | 2 | none | no | no | no |
| ERB | `erb` | template | `.erb` | 1 | none | no | no | no |
| Razor | `razor` | template | `.cshtml` `.razor` | 1 | none | no | no | no |
| Helm | `helm` | config / infrastructure | `Chart.yaml` `values.yaml` | 8 | none | no | no | no |
| Dockerfile | `dockerfile` | config / infrastructure | `Containerfile` `Dockerfile` | 5 | none | no | no | no |
| YAML | `yaml` | config / infrastructure | `.yaml` `.yml` | 2 | none | no | no | no |
| JSON | `json` | config / infrastructure | `.json` | 0 | none | no | no | no |
| Terraform (HCL) | `terraform` | config / infrastructure | `.tf` | 0 | none | no | no | no |

Reading the columns:

- Rules: per-line RE2 rules tagged with this language, not counting the untagged generic rules that run on every file. A rule can match inside comments and string literals; there is no parser.
- Taint: the intra-file tracker's vocabulary. Taint state resets at every function boundary. "none" means the language gets per-line rules only.
- Same-file summaries: the tracker builds method summaries for calls inside the same file. Today they only remove taint (a callee that sanitises); they never add it.
- Import graph: the hosted pipeline's file-level reachability (which files an entry point imports). The CLI does not run it.
- Package tier: the hosted pipeline's check of whether a vulnerable dependency is imported anywhere. The CLI does not run it.
- Terraform, JSON and YAML files are also read by the IaC and container scanners, which are not counted in the Rules column.

## Dependency manifests

| Manifest | Ecosystem |
|---|---|
| `.csproj` | NuGet |
| `Cargo.lock` | crates.io |
| `Gemfile.lock` | RubyGems |
| `Pipfile.lock` | PyPI |
| `composer.lock` | Packagist |
| `go.mod` | Go |
| `gradle.lockfile` | Maven |
| `mix.lock` | Hex |
| `package-lock.json` | npm |
| `package.json` | npm |
| `packages.config` | NuGet |
| `packages.lock.json` | NuGet |
| `pnpm-lock.yaml` | npm |
| `poetry.lock` | PyPI |
| `pom.xml` | Maven |
| `pubspec.lock` | Pub |
| `requirements.txt` | PyPI |
| `yarn.lock` | npm |

Advisories come from OSV.dev; `--deps` is the only CLI layer that touches the network.

## Secret detectors

27 rule ids: SECRET-001, SECRET-002, SECRET-003, SECRET-004, SECRET-005, SECRET-006, SECRET-007, SECRET-008, SECRET-009, SECRET-010, SECRET-011, SECRET-012, SECRET-013, SECRET-014, SECRET-015, SECRET-016, SECRET-017, SECRET-018, SECRET-019, SECRET-020, SECRET-021, SECRET-022, SECRET-023, SECRET-024, SECRET-025, SECRET-026, SECRET-ENT. `SECRET-ENT` is the entropy rule; the rest are fixed patterns.
