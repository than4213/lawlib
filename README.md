# Lawlib

**A formal library of law in Lean 4**: the computable core of the US
tax-and-transfer system — **10,362 exact-rational, date-indexed
parameters** (the entire PolicyEngine parameter tree) and **~3,200
mechanically translated formulas** spanning federal tax credits (EITC,
CTC), SNAP, SSI, the ACA premium tax credit, and a long tail of state
and local programs.

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
lake build          # Lean core + mathlib (for the ∀-theorems)
lake build lawlib   # the JSONL evaluator binary (fused memoized evaluator)
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

## Machine-checked results

[`Lawlib/Verify/EicTable2023.lean`](Lawlib/Verify/EicTable2023.lean)
proves (by `native_decide` over the table data extracted from the 2023
Form 1040 instructions):

- the 2023 IRS EIC table is exactly reproduced by a five-line generator:
  bracket-midpoint evaluation of the phase formula, **phase-out anchored
  at the IRS-internal *unrounded* completed-phaseout amounts**, rounded
  half up, with the plateau maximum for kink-straddling brackets;
- PolicyEngine's smooth formula never differs from the legal (table)
  credit by more than **$11.50** — and that bound is sharp;
- at bracket midpoints the gap is at most $5.297.

[`Lawlib/Theorems/`](Lawlib/Theorems/) adds symbolic results: the
EITC's closed trapezoid form per (filing status × children) cell,
continuity in income (no benefit cliffs — a kernel proof, no
computation), monotonicity on the phase-in, and the CTC's complete
$50-cliff atlas. [`Lawlib/Verify/Catala2023.lean`](Lawlib/Verify/Catala2023.lean)
compares an independent, statute-first [Catala](https://catala-lang.org)
encoding of §32 against the PolicyEngine twin and proves the statute's
literal arithmetic differs from administered practice by **exactly
24¢/50¢** (the Rev.-Proc. rounding the statute never mentions).

**TCB note**: table/grid results use `native_decide` (trusts the Lean
compiler); the symbolic theorems are ordinary kernel proofs. Statements
*about reality* (the printed table, executed PolicyEngine) are
never-asserted claim `Prop`s with evidence tiers
([`Lawlib/Claims.lean`](Lawlib/Claims.lean), [docs/CLAIMS.md](docs/CLAIMS.md));
`#print axioms` stays clean for the whole library.

See [docs/FINDINGS.md](docs/FINDINGS.md) — 17 findings so far, from
PolicyEngine's float32 residue to a Lean codegen bug with a 20-line
repro ([docs/lean-fromjson-crash-repro.md](docs/lean-fromjson-crash-repro.md)).

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

## License

Lawlib is **AGPL-3.0**: the generated content derives from
[policyengine-us](https://github.com/PolicyEngine/policyengine-us)
(AGPL-3.0). The [pe2lean](https://github.com/than4213/pe2lean)
transpiler is separately Apache-2.0.
