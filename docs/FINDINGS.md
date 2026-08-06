# The findings list

A running index of what formalizing a large model of law turned up —
one line each, newest last. Details in
[findings-m5.md](findings-m5.md) (§ numbers), evidence tiers in
[CLAIMS.md](CLAIMS.md).

Several entries concern [policyengine-us](https://github.com/PolicyEngine/policyengine-us)
or the Lean compiler. None of them are criticisms of those projects:
they are the kind of thing that only shows up when you run two
independent implementations against each other in exact arithmetic,
which is exactly what this project exists to do. PolicyEngine's model
is the reason lawlib can exist at all, and every finding here was
reported upstream or is queued to be.

| # | Finding | Tier | Where |
|---|---|---|---|
| 1 | PolicyEngine computes money in float32; measured residue vs exact arithmetic up to ~1.6¢; EITC chain applies no rounding at all (fractional-cent credits) | T2 | §1, §6 |
| 2 | `defined_for` eligibility masks are invisible dependency edges — naive closure walks miss whole subtrees; caught paying credits to ineligible households | T2 | §2 |
| 3 | `adds` lists mean different things on group vs person variables (aggregate vs elementwise) | T2 | §3 |
| 4 | Parameter files mix enacted law with pre-materialized inflation projections through 2035 | T3 | §4 |
| 5 | The translatable fragment is real: EITC-proper translates completely; ~20 idioms cover two credits + SNAP | T3 | §5 |
| 6 | M5 acceptance: 100k households × 5 years, zero mismatches | T2 | §6 |
| 7 | The legal EITC is a step function (§32(f) tables), not the smooth formula everyone models | T1 | §7 |
| 8 | The 2023 EIC table reverse-engineered exactly: midpoint evaluation, half-up rounding, phase-out anchored at IRS-internal **unrounded** completed-phaseout endpoints (recovered to ±5¢); PE-vs-table gap ≤ $11.50, sharp | T1 | §8 |
| 9 | The statute's arithmetic disagrees with administered practice: §32(a)(2)(A) literal cap $599.76/$7,429.50 vs the rounded $600/$7,430 in Rev. Proc., tables, and PE — found by independent Catala encoding, divergence proven exactly 24¢/50¢ | T1 (gap) / T5 (legal reading) | §9 |
| 10 | Continuity contrast: EITC proven continuous (no cliffs, any income); CTC's 40+80 statutory $50 cliffs proven and completely enumerated | T0/T1 | §10 |
| 11 | PolicyEngine's period coercion of set inputs is path-dependent: `calculate_divide` (÷12), silent uprating fallback (stale values × SOI calibration ratios), auto-carry-over with source-commented period-sort hazards (H1/H2) | T4 (source-located) | §11 |
| 12 | `Simulation.__init__` silently moves income inputs onto `_before_lsr` counterparts, overwriting caller-set values and deleting sources | T4 (source-located) | §12 |
| 13 | NumPy erases the bool/number distinction and policyengine-us leans on it everywhere: bool variables defined by numeric sums, float variables returning `head \|\| spouse`, float-typed `defined_for` gates. A typing pass over the IR re-inserts every implicit coercion (`True+True=2`, `x != 0` truth tests); across 1,771 swept formulas **zero** puns were uncoercible — all are well-defined NumPy semantics, none are latent bugs | T2 | Phase B |
| 14 | `GroupPopulation.__call__` on a person variable implicitly **sums over members** — a one-line dispatch in policyengine-core that silently turns `spm_unit("x_person")` into an aggregate; undocumented, load-bearing in dozens of state-program formulas | T4 (source-located) | Phase B |
| 15 | `adds` lists may mix variable names with *parameter paths* (the path resolves to a list of addends at runtime); several variables' addend lists are themselves parameters | T3 | Phase B |
| 16 | Lean 4.32.1/4.32.2 compiled code miscompiles derived `FromJson` for structures with **≥ 156 fields**: heap corruption → wandering segfaults (allocator, JSON printer, unrelated later allocations). Boundary bisected exactly (155 ok, 156 crashes); interpreter unaffected; ~20-line standalone repro (docs/lean-fromjson-crash-repro.md). v0.7.1 survived by luck — its widest structure was exactly 155. Workaround: pe2lean caps generated structs at 128 fields | T1 (bisected repro) | Phase B2 |
| 17 | Un-memoized formula-as-function translation is exponentially expensive in member-nested aggregate depth: one 4-member household evaluation went from milliseconds (1,771-def closure) to ~30 s (3,224-def closure) once `is_qualifying_relative_dependent` and the full federal chain became computed. A vectorizing/memoizing evaluator (one `let` per variable) is the structural fix — the same shape PolicyEngine itself uses | T4 (measured) | Phase B2 (branch) |
| 18 | PolicyEngine's marital-unit auto-inference is **context-dependent**: the identical household gets different marital units (hence different SSI, via `ssi_claim_is_joint` → couple resource test) depending on whether it is simulated alone or inside a vectorized batch. Declaring marital units explicitly removes the ambiguity | T4 (reproduced) | diff hardening |
| 19 | (reverted experiment) PE's pre-effective-date parameter semantics differ between the simulation path and the parameter API (clamp); a zero-before-first-entry model exploded the diff — the real semantics are subtler; moot under federal scope, documented for the states revisit | internal | diff hardening |
| 20 | `floor`/`ceil` formulas sit on **exact-integer knife edges**: integer inputs whose /12 month-fractions cancel make e.g. `snap_net_income` exactly $3,305 in rational arithmetic, while PE's float32 lands at 3,304.9998 — `floor` amplifies the ε to a full dollar (×0.3 = a 30¢ SNAP contribution gap). Not cappable away (v0.8.4-style input ranges don't help); the harness now excuses sub-$1 deviations on the 8 quantized variables and counts them | T2 (reproduced, decomposed) | diff hardening |

## Internal lessons (about building verified twins, not about PE)

- Byte-exact CI determinism checks catch real bugs fast (our own
  `PYTHONHASHSEED`-dependent topological sort, on day one; the stale
  extractor pin on the CTC push).
- Never parse pretty-printed IR when a machine-generated backend
  exists (Catala lcalc vs OCaml output).
- Don't claim derivable values (chisel-claims lesson): keep the claim
  set a minimal generating set or risk manufacturing spurious
  inconsistencies.
