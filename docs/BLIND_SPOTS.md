# Blind spots

This file is the published list of what Zennoxa Shield does not do: the finding classes it will miss, the false positives it will report, and the engine limits behind both. It is mirrored from the engine repository, where every entry also cites the file and line that imposes the limit; this copy keeps the consequence, the measurement and the status. The generated [LANGUAGE-MATRIX.md](LANGUAGE-MATRIX.md) is the per-language companion to this file.

Conventions. Each entry carries a **Kind** (known unsupported pattern, known parser limitation, known framework limitation, known false positive, known false negative, known reachability limitation), a **Measured** line that names the source of every number, and a **Status** of "by design", "planned (step N)" or "not planned". Step numbers refer to the engine team's 90-day sequence of 2026-09-24.

## Parsing and language model

### No AST or parser for any language

**Kind:** known parser limitation.

**What it means for you:** Every rule is a regular expression over one physical line and every flow fact is derived from regexes over comment-stripped logical lines; nothing in Shield knows what a token, a scope, a declaration or a call is. Any vulnerability whose recognition depends on syntax the regex vocabulary does not spell out (a sink reached through a wrapper, a method resolved through a type, an interface call) is invisible.

**Measured:** on the 84-case killer ladder every wrapper, sink-wrapper, cross-function, cross-file and callback rung is a miss in all four measured languages (internal engine gap analysis, 2026-09-24).

**Status:** not planned for the next 90 days; a parser go/no-go is written from measurements at step 12 (internal engine gap analysis, 2026-09-24).

### Per-line rules fire inside comments and string literals

**Kind:** known false positive.

**What it means for you:** A commented-out `eval(x)`, a block comment containing `exec(...)`, or the string `"eval(x)"` in a test fixture is reported with the rule's full severity, because the per-line rules see the raw physical line. Only the taint pass strips comments before matching.

**Measured:** `// eval(x)`, `/* exec(...) */` and `"eval(x)"` produced three critical findings from the v0.7.0 binary (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 9 of the engine sequence, token-aware per-line rules).

### Only 8 of 34 language tags get any flow analysis

**Kind:** known unsupported pattern.

**What it means for you:** Cross-line data flow (source in one line, sink in another) exists for JavaScript, TypeScript, Python, Java, PHP, Go, C and C++ only. Ruby, C#, Kotlin, Rust, Swift, Scala, Dart, Perl, Lua, Groovy, Objective-C, VB.NET, PowerShell, shell, SQL, Solidity, Vyper and the template languages get per-line regex rules and nothing else, so a two-line source-to-sink flow in those languages is never reported.

**Measured:** 8 of 34 tags with flow analysis, 1 (Java) with call summaries (internal engine gap analysis, 2026-09-24).

**Status:** by design for the template and configuration languages; Ruby, C# and Kotlin taint specs are deferred until the killer ladder exists in the repo (internal engine gap analysis, 2026-09-24).

### Sources, sinks and sanitizers are hardcoded Go lists, one framework per language

**Kind:** known framework limitation.

**What it means for you:** Shield recognises a request source only under the receiver names it was written for: `request.` for Flask and Django, `request.getParameter` for servlets and Spring annotations for Java, `r.FormValue` and `r.URL.Query` for Go net/http. A handler that reads input through Gin's `c.Query`, Fastify's `request.query` under another name, or a custom request wrapper has no source and produces no taint finding. Sinks are equally fixed: a Java query through `JdbcTemplate.query` or `.update` is not a sink because only `.execute(` is listed for that receiver.

**Measured:** 87 vulnerable OWASP SQL injection cases build the tainted query correctly and then call a JdbcTemplate method that is not in the sink list (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 6 of the engine sequence, sink and source vocabulary).

## Data flow and taint

### Taint is intra-file and resets at every function boundary

**Kind:** known false negative.

**What it means for you:** A variable tainted in one function is forgotten the moment the next function signature is seen, and callee parameters are never seeded from call-site arguments. The controller-to-service-to-repository shape of most real applications is therefore never traced: a handler that passes `req.query.id` into `findUser(id)` defined ten lines below produces no taint finding, in the same file or any other. Function boundaries are themselves regexes, so an arrow callback passed as an argument is not a scope (taint bleeds into the next handler) while a nested Python `def` wipes the enclosing closure.

**Measured:** ladder rungs 04 (source wrapper), 04b (sink wrapper), 05, 06 (cross-function, same file) and 07 (cross-file) are misses in JavaScript, Python, Go and Java; rung 18 (cross-handler bleed via arrow callback) is a false positive in JavaScript and Go; rung 08b (closure) is a miss in Python (internal engine gap analysis, 2026-09-24). Per language the ladder gives JS 7/23, Python 9/22, Go 8/18, Java 4/8 vulnerable cases caught.

**Status:** planned (step 8 of the engine sequence, same-file callee summaries that add taint; step 7 for scope-correct boundaries). Cross-file flow is not planned.

### Same-file method summaries exist only for Java and can only remove taint

**Kind:** known false negative.

**What it means for you:** The one interprocedural mechanism, a same-file method-summary pass, exists to discard OWASP-style decoys where a helper returns a constant. It is built only for languages whose spec opts in, which only Java does, and at a call site it is consulted only to delete taint. A helper that reads a request source and returns it, or a helper that receives a tainted argument and passes it to a sink, is invisible in every language including Java.

**Measured:** Java ladder T02 (source wrapper), T05 (sink wrapper) and T06 (cross-function) are misses while T03 (constant decoy) is correctly silent; 195 vulnerable OWASP SQL injection cases involve a same-file helper whose summary can only subtract taint (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 8 of the engine sequence).

### Sanitizers are sink-agnostic name lists: the wrong encoder is accepted

**Kind:** known false negative.

**What it means for you:** A variable is considered clean the moment any listed sanitizer name appears on its assignment, regardless of which sink it later reaches. `encodeURIComponent(req.query.host)` followed by `exec("ping " + host)` is silent, as are `html.escape` before `os.system`, `template.HTMLEscapeString` before `exec.Command("sh", "-c", ...)` and `Encode.forHtml` before `Runtime.exec`. A sanitizer on any argument of a sink line also suppresses the whole line, so `db.query(sql + id, parseInt(limit))` is silent even though `id` is tainted.

**Measured:** ladder rung 10 (ineffective encoder) is a miss in JavaScript, Go and Java (T07); rung 10b (`sanitizeHtml` before `execSync`) is a miss; rung 16 (sanitizer on another argument of the sink line) is a miss in JavaScript, Python and Go (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 6 of the engine sequence, sanitizer-to-sink-class mapping).

### The sink argument region is the rest of the line outside Python

**Kind:** known false positive.

**What it means for you:** For JavaScript, Go, Java, PHP and C the taint pass checks every identifier after the sink's opening parenthesis, so a correctly parameterized query whose bound parameter is tainted (`db.query("SELECT ... WHERE id = ?", [id])`) is reported as SQL injection, and Go's argv-form `exec.Command("ls", dir)` is reported as command injection. Only Python scopes the check to the first argument, and only for the SQL and SSRF sinks.

**Measured:** `const id = req.query.id; db.query("... ?", [id])` produced SHIELD-TAINT-SQL at severity high; ladder rung 13 (parameterized query with tainted bound parameter) is a false positive in JavaScript and Go and a true negative in Python (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 6 of the engine sequence, per-argument sink regions).

### Cross-file flows are never traced

**Kind:** known false negative.

**What it means for you:** A source read in one file and consumed by a sink in another file is never connected, in any language, by any pass. This is the ceiling of a same-file engine and no amount of regex tuning moves it; only a parser plus an export/import symbol table would.

**Measured:** 194 of the 902 vulnerable OWASP Benchmark flow cases (21.5 percent) route through a separate class (SeparateClassRequest, ThingInterface) and are unreachable to the engine by construction, worth at most about 7 recall points; ladder rung 07 is a miss in all four languages (internal engine gap analysis, 2026-09-24).

**Status:** not planned for the next 90 days (internal engine gap analysis, 2026-09-24).

### Alias tracking stops at bare identifiers

**Kind:** known false negative.

**What it means for you:** Taint propagates when any identifier token on the right-hand side of an assignment is tainted, which is why `a = src; b = a; c = b; sink(c)` works. Destructuring (`const {id} = req.query`), chained assignment (`a = b = c = src`), member-path targets (`state.id = src`) and Go tuple assignment are not modelled, so flows through them are missed.

**Measured:** ladder rungs 03b (chained assignment) miss in JavaScript and Python, 15 (destructuring) miss in JavaScript and Go, 17 (member property) miss in JavaScript and Python (internal engine gap analysis, 2026-09-24).

**Status:** planned in part (step 7 of the engine sequence adds declarations and bindings to the block stack); member paths and tuple assignment are not planned.

### Branch-join semantics exist only for Python

**Kind:** known false negative.

**What it means for you:** In JavaScript, Go, Java, PHP and C a clean rebind of a variable inside an `if` block clears its taint for the rest of the function, even though the other branch leaves it tainted. Python has a block stack with dead-branch folding and join semantics; the brace languages have none, and a Java `switch` in particular is never folded or joined.

**Measured:** ladder rung 11b (clean rebind in a non-constant branch) is a miss in JavaScript and Go and a hit in Python; 107 vulnerable OWASP cases route through a Java `switch` the engine cannot join or fold (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 7 of the engine sequence, brace-language block stack).

## Reachability and priority

### Import-graph reachability is file-level, Go/JS/TS/Python only, and server-side only

**Kind:** known reachability limitation.

**What it means for you:** On hosted scans, "reachable" for a SAST finding means "this file is on an import path from a heuristic entry point", not that the vulnerable line can be reached; every finding in a reachable file is marked, and every Go file in the same directory as a reachable Go file is marked with it. Java, PHP, C and C++ files, which the taint pass does cover, never get a file-level verdict. The CLI does not run this pass at all.

**Measured:** the analyzer computes a reason and an entry point per verdict, but the hosted pipeline reads only the boolean, so the reason is never stored or shown (internal engine gap analysis, 2026-09-24).

**Status:** by design for the language list; a persisted reachability provenance field is planned (step 5 of the engine sequence).

### Package-tier reachability for dependency CVEs covers Go/JS/TS/Python/Java/Ruby only and only promotes

**Kind:** known reachability limitation.

**What it means for you:** A dependency CVE is promoted to "reachable" when first-party source imports the package (tier 2) or references a curated vulnerable symbol (tier 3). Import collection reads only Go, JavaScript, TypeScript, Python, Java and Ruby files, so PHP, C#, Rust and every other ecosystem's CVEs stay at the baseline forever, and tier 3 exists only for the handful of CVEs in a hand-written symbol table. The CLI never runs this pass, so offline DEP-CVE findings are always `Reachable: false`.

**Measured:** the curated symbol table holds ten CVE entries (internal engine gap analysis, 2026-09-24).

**Status:** by design; a dependency path or transitive flag is not planned for the next 90 days.

### "Reachable" has three meanings and the server drops the CLI taint verdict at INSERT

**Kind:** known reachability limitation.

**What it means for you:** The same boolean and the same dashboard badge mean three different things: in the CLI, "the intra-file taint pass traced a source to this sink in the same function"; on a hosted scan, "this file is on an import path" (the taint verdict computed by the same engine is discarded when the finding is inserted); on a `--submit` upload, whatever the CLI said. All three earn the same +15 priority points. A dead file that is never imported still gets `Reachable: true` from the CLI because the flag is set at the sink, not by any call graph.

**Measured:** a never-imported `dead.js` produced SHIELD-TAINT-SQL with `Reachable: true` and priority 41.4, identical to the live `app.js` (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 5 of the engine sequence, a ReachSource provenance field persisted end to end).

### EPSS and KEV apply only to findings that carry a CVE

**Kind:** known reachability limitation.

**What it means for you:** The priority formula is CVSS 0.30 + EPSS 0.30 + KEV 0.25 + reachability 0.15. Only dependency findings have a CVE identifier, so every SAST, secret, container and IaC finding scores 0 on the EPSS and KEV terms by construction. Container and IaC findings also carry no CVSS, so their offline priority is 0 and a privileged-container finding sorts below a low-severity SRI finding.

**Measured:** the formula disagrees with the human-labelled 50-finding truth set on 35 of 50 (internal engine gap analysis, 2026-09-24).

**Status:** by design (EPSS and KEV are CVE-keyed catalogues); a per-factor breakdown in output is not planned for the next 90 days.

## Layers (secrets, dependencies, containers, IaC)

### Secret values are emitted verbatim in CLI JSON and HTML output

**Kind:** known unsupported pattern.

**What it means for you:** A secret finding's snippet is the full source line, including the key, token or private-key body it detected; the redaction step only truncates lines longer than 200 characters. Of the five layers this is the one whose output can itself become a leak: a scan report committed to a ticket or pasted into CI logs republishes the secret. Only the MCP server path masks values; SARIF happens to be clean because its message is the rule title. The hosted database stores the snippet raw. Test files are skipped as whole files and git history is never read, so a secret that was committed and later removed is not found.

**Measured:** an RSA private-key body and a full AWS secret key were printed verbatim in CLI JSON from the v0.7.0 binary (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 10 of the engine sequence, emission-time masking).

### Image OS-CVE lookup queries OSV by binary package name, so recall on real images is near zero

**Kind:** known false negative.

**What it means for you:** `shield image --os-cve` reads the dpkg and apk databases and sends the binary package name (`libssl3`, `libc6`) to OSV, but Debian, Ubuntu and Alpine advisories are keyed by source package (`openssl`, `glibc`). Every split package returns zero advisories. The hosted image scan is configuration-only and does not attempt OS CVEs at all.

**Measured:** live OSV queries on 2026-09-24: Debian:12 `libssl3@3.0.9-1` returned 0 advisories and `openssl@3.0.9-1` returned 51; `libc6` 0 versus `glibc` 46; Alpine:v3.18 `libssl3` 0 versus `openssl` 12 (internal engine gap analysis, 2026-09-24).

**Status:** not planned for the next 90 days (internal engine gap analysis, 2026-09-24).

### The fix version shown by `shield scan` is the first OSV fixed event of any range

**Kind:** known false positive.

**What it means for you:** The "fix: bump X a -> b" line on a DEP-CVE finding takes the first `fixed` event across every affected entry of the advisory, ignoring which package and which version range the installed version is in. For multi-range advisories this recommends a downgrade or a version of a different package. `shield fix` has the correct resolver; `shield scan` does not use it.

**Measured:** `shield scan --deps` on DVNA recommended `sequelize 4.13.10 -> 3.35.1`; on a fixture with `minimist@1.2.0` it recommended `1.2.0 -> 0.2.1` although the advisory's second range is fixed at 1.2.3 (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 10 of the engine sequence).

### Container and IaC checks are literal string matching

**Kind:** known false positive.

**What it means for you:** The Dockerfile sensitive-port check tests whether the port string occurs anywhere in the line, so `EXPOSE 9229` and `EXPOSE 8022` are reported as exposing port 22. The pipe-to-shell check requires the word `curl`, so `wget ... | sh` is missed. The Terraform open-ingress check matches one exact spelling, so `cidr_blocks = ["0.0.0.0/0", "::/0"]`, a multi-line list, or the same value without spaces is missed, while a comment containing `logging` and `false` is reported. There is no HCL, YAML or JSON parser, no Azure or GCP rule set, and Helm templates are never rendered.

**Measured:** fixture runs from the v0.7.0 binary produced CONTAINER-004 "Exposing potentially sensitive port 22" on `EXPOSE 9229`, no IAC-TF-001 on three spelling variants of an open CIDR, and IAC-TF-005 on a comment line (internal engine gap analysis, 2026-09-24).

**Status:** not planned for the next 90 days (internal engine gap analysis, 2026-09-24).

### The same issue is reported by up to three layers and the CLI never deduplicates

**Kind:** known false positive.

**What it means for you:** Dockerfile checks exist both in the container scanner and in the SHIELD-DOCKER rule pack; Kubernetes checks exist in both the container scanner and the IaC scanner; a hardcoded credential in a Dockerfile is a secret, a Dockerfile rule and a container check. One line can produce three findings with three severities. The hosted deduplication step collapses exact duplicates and same-line CWE-798 overlaps, but it is called only by the hosted scan worker; the CLI drops only the IAC-K8S duplicates.

**Measured:** `Dockerfile:3` produced SECRET-012, SHIELD-DOCKER-004 (CWE-522) and CONTAINER-007 (CWE-798) in one run; `Dockerfile:4` produced SHIELD-DOCKER-003 at high and CONTAINER-005 at critical (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 3 of the engine sequence adds the CLI dedup call; step 10 shares one pipeline).

## Output and evidence

### SARIF has no column, no codeFlows and no per-finding message

**Kind:** known unsupported pattern.

**What it means for you:** Every SARIF region is a start line only, so code-scanning annotations cover whole lines; there is no `codeFlows`, `relatedLocations` or `fixes`, so a taint finding titled "cross-line data flow" shows only the sink line and no path; the result message is the rule title, so two findings of the same rule read identically. The tool version in the SARIF is a constant that does not match the binary.

**Measured:** region keys union over 131 results is `[startLine]`; 125 of 131 messages equal the rule's short description; the v0.7.0 binary emits driver version 0.1.0 (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 1 of the engine sequence for the version string; step 5 for column, codeFlows and messages).

### A finding carries no evidence beyond the sink line

**Kind:** known unsupported pattern.

**What it means for you:** The finding struct has no source line, no propagation path, no sanitizer decision, no column and no confidence. The taint tracker keeps a set of tainted names, not where they came from, so even internally the source line is gone by the time the sink is reported. "Why was this flagged" is answered by the rule title and canned advice only.

**Measured:** 2 of the roadmap's 10 evidence questions (where, why) are answerable from a finding today (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 5 of the engine sequence, source-to-sink evidence on every taint finding).

### CLI output is not deduplicated and finding IDs are positional or empty

**Kind:** known unsupported pattern.

**What it means for you:** SAST and taint findings are numbered `finding-N` in emission order, so the same finding gets a different ID when an unrelated file is added; container, IaC and Kubernetes findings have no ID at all; secrets use a hash of path and rule. The SARIF fingerprint hashes rule, file and snippet without the line, so two identical lines in one file share a fingerprint and `--baseline` silently accepts the second occurrence. Same-line duplicates that the server would collapse are shipped by the CLI.

**Measured:** on samples/ the v0.7.0 binary emitted 131 findings of which 73 have an empty ID (55 CONTAINER-, 14 IAC-, 4 SHIELD-K8S-), 59 of 131 IDs are unique, 128 of 131 fingerprints are unique, and 8 same-line CWE-798 duplicates ship (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 3 of the engine sequence).

## Benchmarks and measurement

### Determinism is real today but unguarded by any test

**Kind:** known unsupported pattern.

**What it means for you:** Two runs on the same tree give the same findings in the same order because the walker is sequential and the final sort is stable, not because anything asserts it. Nothing stops a future map-ordered emission from making CI diffs flap. Two report fields (ScanID, CreatedAt) are wall-clock and the Target is an absolute path, so the JSON file itself is never byte-reproducible.

**Measured:** byte-identical re-runs except ScanID and CreatedAt, verified independently by four lanes and the researcher on DVNA and samples/ (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 3 of the engine sequence, a scan-twice test and `--reproducible`).

### The weakest OWASP Benchmark categories are SQL injection (+0.303) and trust boundary (+0.237)

**Kind:** known false negative.

**What it means for you:** The published overall score (+0.582, precision 92.5, recall 63.7) hides a spread: SQL injection recall is 39.0 percent and trust-boundary recall is 47.0 percent with a 23.3 percent false-positive rate, while weak randomness and secure cookie score 1.0. The Benchmark is Java-only and single-file; recall in JavaScript, Python and Go is measured only on the killer ladder and two golden repositories, and the ladder is not yet in the repository.

**Measured:** of the 449 flow-category false negatives, 87 call an unlisted JdbcTemplate method, 107 route through a Java `switch`, 83 read a collection source by index, 195 involve a same-file helper, and 194 are cross-file (internal engine gap analysis, 2026-09-24); no bench/killer directory exists in the checkout.

**Status:** planned (steps 6, 7 and 8 of the engine sequence for the same-file causes; step 4 commits the ladder); the cross-file share is not planned.

### The benchmark gate would pass a 22.7 percent regression and runs nowhere in CI

**Kind:** known unsupported pattern.

**What it means for you:** `make bench-owasp` fails only below +0.44 while the archived score is +0.582, so an engine change that loses a fifth of the score still passes the gate, and no workflow runs the gate, the accuracy golden or a determinism check on a pull request.

**Measured:** (0.582 - 0.44) / 0.582 = 22.7 percent (internal engine gap analysis, 2026-09-24).

**Status:** planned (step 1 of the engine sequence raises the gate to 0.57; step 11 adds a nightly benchmark on the self-hosted runner).

## How this file is kept honest

[LANGUAGE-MATRIX.md](LANGUAGE-MATRIX.md) is generated from the engine source by a test that fails when the committed copy drifts, and the website reads the same generated data, so the "8 of 34" figure above cannot drift from the code without a red build. In the engine repository every entry here names the file and line that imposes the limit; when that file changes, the entry is re-cited, rewritten, or deleted with the measurement that justifies the deletion. An entry is never removed because a claim became inconvenient.

Benchmark numbers follow the published benchmark policy: detection is never modified solely to raise a benchmark score, every engine change records its OWASP delta, and a known false positive is kept in the accuracy loop rather than suppressed to fit a fixture. The per-category OWASP numbers are in [../bench/owasp/benchmark.json](../bench/owasp/benchmark.json), reproducible with [../bench/owasp/reproduce.sh](../bench/owasp/reproduce.sh).
