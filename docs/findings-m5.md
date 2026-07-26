# Findings from Phase 1 extraction (M1–M5)

Things learned *about PolicyEngine US* (and about translating law) while
building the verified twin — recorded per design §1a: findings, not
infrastructure, are the product. policyengine-us 1.783.0.

## 1. Float32 arithmetic vs the law's exact semantics

PolicyEngine stores and computes money in float32. Lawlib computes the
same formulas in exact rationals. On randomized households the engines
agree to the dollar, but PE's float32 arithmetic carries per-value errors
up to about a cent on realistic amounts (observed max ≈ $0.01 on
`eitc_reduction` with large capital-gains sums flowing in; grows with
income magnitude). None exceed the differential tolerance; all deltas
> $1e-6 are counted by `pe2lean-diff` on every run. Consequence: any
future PE unit test asserting cent-level exactness is testing float
accidents, not law. (The statutory rounding question — where §32 rounds
vs where PE rounds — remains open for the Phase 2 findings pass; PE's
EITC chain applies no explicit rounding at all, so PE reports fractional
cents that no tax form would show.)

## 2. `defined_for` is an invisible dependency edge

A PolicyEngine variable can carry `defined_for = "<bool var>"` — a
class-level eligibility mask applied *outside* the formula body. Naive
formula-source analysis misses it entirely: our M1 closure walk
undercounted the EITC closure by 14 variables (the entire eligibility
subtree), and the M3 differential run caught Lean paying credits to
ineligible households (Lean $2,666 vs PE $0). Any static-analysis
approach to OpenFisca-family codebases must treat `defined_for` as a real
dependency edge. This was the first mistranslation the harness caught —
found within minutes of the first 200-household run.

## 3. Person-level `adds` lists are elementwise, not aggregating

`adds = [...]` on a *group* variable sums listed variables across
members; the same syntax on a *person* variable combines that person's
own values. Conflating them produced a 6× overcount of capital gains
(every member credited with the whole unit's total) — caught by a
20-household diff at M4. The idiom's meaning depends on the declaring
variable's entity, which nothing in the YAML/class syntax signals.

## 4. Parameter files contain projections, not just law

The EITC phase-out tables carry date-keyed values through 2035 —
IRS/CBO uprating projections pre-materialized into the same `values`
maps as enacted figures. The manifest's `law_date_coverage` (0000-01-01
→ 2035-01-01) therefore overstates *enacted* coverage; entries past the
latest revenue procedure are forecasts. A future manifest field should
separate enacted from projected effective dates.

## 5. The translatable fragment is real

Of the (corrected) 105-variable closure: 53 translate cleanly, 25 are
true inputs, and 27 reject — but after deliberate pruning of
out-of-scope subtrees (behavioral responses, AGI machinery), the
*EITC-proper* graph of 24 formulas translates completely, including the
full eligibility chain, with only 6 genuine fragment violations at the
boundary (dynamic `select`, `get_rank` positional logic, cross-subtree
parameters, simulation-object access). The handoff's bet — that
tax-credit code lives in a small, disciplined idiom set — held.

## 6. Acceptance run

M5 acceptance (2026-07-26, seed 0): **100,000 randomized + adversarial
households, tax years 2021–2025, 16 compared variables (1.6M values),
zero mismatches.** 89,816 values (≈5.6%) differed from PolicyEngine by
more than $1e-6 — pure float32 arithmetic noise, maximum $0.015875
(`eitc_reduction`) — every one within the dollar-level agreement bound.
The exact-rational twin and the float32 original disagree *only* where
IEEE 754 does; that residue is now measured, not anecdotal.
