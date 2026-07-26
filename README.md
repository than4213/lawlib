# Lawlib

**A formal library of law in Lean 4** — starting with the US federal Earned
Income Tax Credit (26 U.S.C. §32).

Lawlib is a *verified twin* of [PolicyEngine US](https://github.com/PolicyEngine/policyengine-us),
the largest living formalization of US tax-benefit law. PolicyEngine's
Python formulas are mechanically translated into Lean 4 definitions by the
[pe2lean](https://github.com/than4213/pe2lean) extractor, then validated by
differential testing: 100,000 randomized households per night, evaluated in
both engines, must agree exactly (up to PolicyEngine's own float32 noise —
which we log as findings, because Lawlib computes in exact rationals).

```lean
/-- `policyengine_us/variables/gov/irs/credits/earned_income/eitc.py`
    policyengine-us 1.783.0, entity tax_unit, value_type float. -/
def eitc (t : TaxUnit) (d : Date) : Rat :=
  (if (eitc_eligible t d) then (((min (eitc_phased_in t d)
    (max 0 ((eitc_maximum t d) - (eitc_reduction t d)))) * ...
```

Money is exact `Rat`, never `Float` — the law's semantics is exact decimal
arithmetic with statutory rounding; IEEE 754 is an implementation accident.
Every generated definition carries its upstream source path and statutory
citations. Parameters (rates, thresholds, maximums) are date-keyed data:
one checkout computes any covered tax year.

## Build

```
lake build          # zero dependencies beyond Lean core
lake build lawlib   # the JSONL evaluator binary
```

```
echo '{"date":"2023-01-01","tax_unit":{...}}' | ./.lake/build/bin/lawlib
```

## Layout

| Path | What |
|---|---|
| `Lawlib/Core/` | hand-written semantic domain: `USD`/`Rate` (exact rationals), `Date`, `DatedParam`, `Scale`, `ExtRat`, aggregation helpers |
| `Lawlib/Gen/` | **generated — never hand-edited** (CI-enforced): parameters, enums, entities, variable defs |
| `EXTRACTION_MANIFEST.json` | pins (policyengine-us, pe2lean), source hashes, the classified input boundary, law-date coverage |
| `rejection_report.md` | what the extractor refused to translate, and why — a deliverable, not a failure |
| `docs/` | design, handoff, findings |

## Why

Deep embeddings of law (Catala, s(CASP)) can be *reasoned about* but cover
little; shallow embeddings (PolicyEngine) cover much but can only be *run*.
Lawlib bridges them: recover inspectable, provable structure from the
largest maintained encoding of US law. A wrong translation is worse than no
translation — the extractor rejects what it cannot faithfully express, and
the differential suite is the trust anchor. Phase 2 adds theorems
(phase-out monotonicity, continuity except at enumerated cliffs); failed
proofs will localize real benefit cliffs.

See [docs/design.md](docs/design.md) and
[docs/lawlib-handoff.md](docs/lawlib-handoff.md).
