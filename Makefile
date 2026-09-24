# Zennoxa Shield public repo — the CLI is distributed as a release binary; this
# Makefile only wraps what a stranger can run without the engine source.
.PHONY: help benchmark-owasp

help:
	@echo "make benchmark-owasp TAG=v0.7.0   reproduce the published OWASP Benchmark score"
	@echo "                                  (downloads the tagged binary, verifies SHA256SUMS,"
	@echo "                                   fetches the pinned dataset, scans, scores)"

TAG ?=
benchmark-owasp:
	bench/owasp/reproduce.sh $(TAG)
