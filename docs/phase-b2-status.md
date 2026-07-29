# Phase B2 status: full-tree formula sweep (3,224 defs) — parked on this branch

*2026-07-28. Branch `phase-b2`; main remains at the v0.7.1 state (1,771
defs, all theorems green).*

## What B2 is

Feeding the parser the **entire 10,362-parameter tree** (instead of the
curated subtrees) unlocks ~1,450 additional formulas: 3,224 translated
defs, 1,576 boundary inputs. Extractor work is merged on pe2lean main
(commit "Phase B2 extractor"); this branch carries the generated Lean.

## Why it is not on main

Evaluating the 3,224-def closure crashes the Lean 4.32.1 runtime.
Reproducible, scale-triggered (identical machinery is green at v0.7.1's
1,771 defs):

- interpreter (`#eval`, `native_decide`): segfaults — null-deref in
  `lean::utf8_char_pos` (single-module combos of the EIC table
  constants + any generated-variable call), plus wandering crash sites
  in generated native code under `--load-dynlib`;
- fully compiled evaluator (`lake exe lawlib`): segfault inside
  mimalloc (`mi_segment_alloc`, ~92 MB RSS — not OOM) on any household,
  including an all-zero one, ~23 s into the un-memoized federal chain.

Also independent of the crash: un-memoized evaluation cost is
exponential in member-nesting depth. `is_qualifying_relative_dependent`
is PRUNEd on this branch for that reason; the general fix is below.

## The path to landing (post-vacation)

1. **Memoized evaluator emission**: emit a fused per-entity evaluator
   (topologically ordered `let` chain; person-level vars as per-member
   arrays) so each variable is computed once per household. This fixes
   the exponential cost, makes `native_decide` over the full closure
   feasible again, and — because it collapses the call graph into a few
   large defs — most likely sidesteps the toolchain crash entirely.
2. Minimal reproducer for the Lean crash → upstream issue.
3. Re-run the differential harness (the B2 twin has NOT yet passed a
   diff run end-to-end — the evaluator crashes first), then re-enable
   the quarantined theorem modules (`Verify/PendingLeanBug2023.lean`,
   `Theorems/Eitc2023.lean`, `Theorems/Ctc2023.lean`,
   `Verify/Catala2023.lean`) and ship as v0.8.0.
