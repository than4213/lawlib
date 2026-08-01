# Phase B2: LANDED (v0.8.0)

*Updated 2026-08-01. Originally parked on this branch behind what turned
out to be a Lean codegen bug; fully landed after root-causing it.*

## Final state

- **3,224 translated formulas** from the full 10,362-parameter tree
  (15x → 27x the original curated closure).
- **Root cause of the crashes** (findings 16): Lean ≤ 4.32.2 compiled
  code corrupts the heap decoding structures with ≥ 156 fields via
  derived `FromJson` — exact boundary bisected, 20-line standalone
  repro in docs/lean-fromjson-crash-repro.md. Worked around by capping
  all generated structures at 128 fields (`_pN` part-splitting).
- **Fused memoized evaluator** (`Lawlib/Gen/Memo.lean`): the validated
  closure as one topologically-ordered let-chain, each variable
  computed once (person-level vars as index-aligned arrays). Fixes the
  exponential recomputation cost (finding 17); `native_decide` runs
  243k full-household evaluations in ~90 s.
- **Validated tier: 278 variables diff-clean** (was 65) at 300
  households across multiple seeds; ~40 child-care-subsidy chain
  variables are translated but demoted to `DIFF_PENDING`
  (pe2lean extract.py) until their input conventions are hardened.
- **All theorem modules restored**: EIC table generator, PE-vs-table
  bounds (restated over `peM`, the memoized evaluator), trapezoid
  closed forms + continuity (unfold list extended for the deeper
  federal chain), CTC cliff atlas, Catala §32 comparison.

## Remaining follow-ups

1. Harden the child-care chains and drain DIFF_PENDING.
2. File the Lean bug upstream (report draft: docs/zulip-draft-bug.md).
3. Enacted-vs-projection split (laws only — see FINDINGS 4).
