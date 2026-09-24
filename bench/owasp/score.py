#!/usr/bin/env python3
"""Score a Shield scan of the OWASP Benchmark against its ground truth.

The OWASP Benchmark (https://owasp.org/www-project-benchmark/) is 2,740 labelled
Java test cases with a known-answer CSV. The headline metric is the Benchmark
Score = TPR - FPR (Youden's J), computed with strict OWASP CWE-per-category
matching. Exits non-zero if the score is below --threshold, so it can gate CI.

Usage:
  score.py <shield-findings.json> <expectedresults.csv> [--threshold 0.44] [--json]
"""
import argparse
import collections
import json
import re
import sys

# OWASP category -> the CWE numbers that count as "detected this category".
CAT_CWE = {
    "pathtraver": {22},
    "cmdi": {78},
    "xss": {79},
    "sqli": {89},
    "ldapi": {90},
    "crypto": {327, 326, 310},   # weak cipher family
    "hash": {328},
    "weakrand": {330},
    "securecookie": {614},
    "trustbound": {501},
    "xpathi": {643},
}


def load_ground_truth(path):
    gt = {}
    with open(path) as f:
        for row in f:
            row = row.strip()
            if not row or row.startswith("#") or row.lower().startswith("test name"):
                continue
            p = row.split(",")
            if len(p) < 4:
                continue
            gt[p[0]] = (p[1], p[2].strip().lower() == "true")
    return gt


def load_flags(path):
    data = json.load(open(path))
    flagged = collections.defaultdict(set)
    for fnd in data.get("Findings", []):
        m = re.search(r"(BenchmarkTest\d+)", fnd.get("File", ""))
        if not m:
            continue
        cwe = fnd.get("CWE", "") or ""
        mm = re.search(r"(\d+)", cwe)
        if mm:
            flagged[m.group(1)].add(int(mm.group(1)))
    return flagged


def score(gt, flagged):
    per = collections.defaultdict(lambda: dict(tp=0, fp=0, fn=0, tn=0))
    tot = dict(tp=0, fp=0, fn=0, tn=0)
    for test, (cat, real) in gt.items():
        accepted = CAT_CWE.get(cat, set())
        hit = bool(flagged.get(test, set()) & accepted)
        k = "tp" if hit and real else "fp" if hit else "fn" if real else "tn"
        per[cat][k] += 1
        tot[k] += 1
    return per, tot


def bench_score(d):
    tp, fp, fn, tn = d["tp"], d["fp"], d["fn"], d["tn"]
    tpr = tp / (tp + fn) if (tp + fn) else 0.0
    fpr = fp / (fp + tn) if (fp + tn) else 0.0
    prec = tp / (tp + fp) if (tp + fp) else 0.0
    return tpr, fpr, prec, tpr - fpr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("findings")
    ap.add_argument("ground_truth")
    ap.add_argument("--threshold", type=float, default=0.44,
                    help="fail if the overall Benchmark Score is below this")
    ap.add_argument("--json", action="store_true", dest="as_json")
    args = ap.parse_args()

    gt = load_ground_truth(args.ground_truth)
    flagged = load_flags(args.findings)
    per, tot = score(gt, flagged)
    tpr, fpr, prec, bs = bench_score(tot)

    if args.as_json:
        out = {"overall": {"recall": tpr, "fpr": fpr, "precision": prec, "benchmark_score": bs},
               "categories": {c: dict(zip(("recall", "fpr", "precision", "benchmark_score"),
                                          bench_score(d))) for c, d in per.items()}}
        print(json.dumps(out, indent=2))
    else:
        print("  OWASP Benchmark v1.2 — Shield scorecard (strict CWE match)")
        print("=" * 78)
        for cat in sorted(per):
            t, f, p, b = bench_score(per[cat])
            print(f"  {cat:14s} recall={t:5.1%}  FPR={f:5.1%}  prec={p:5.1%}  Bench={b:+.3f}")
        print("-" * 78)
        print(f"  {'OVERALL':14s} recall={tpr:5.1%}  FPR={fpr:5.1%}  prec={prec:5.1%}  Bench={bs:+.3f}")
        print("=" * 78)
        print("  Other engines: OWASP publishes its own scorecards at https://owasp.org/www-project-benchmark/")

    if bs < args.threshold:
        print(f"\nFAIL: Benchmark Score {bs:+.3f} is below the gate {args.threshold:+.3f}",
              file=sys.stderr)
        return 1
    print(f"\nPASS: Benchmark Score {bs:+.3f} >= gate {args.threshold:+.3f}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
