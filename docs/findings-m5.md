# Findings from Phase 1 extraction (M1–M6)

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

## 7. M6 cliff scan: the encoded EITC has no unexplained cliffs — and no statutory table either

The scanner (`pe2lean-scan`) swept earned income $0–$60,000 through the
exact-ℚ engine for all 100 (filing status × children 0–3 × year
2021–2025) cells, detecting every point where the exact slope changes.
Result ([m6-scan-report.md](m6-scan-report.md)): **437 breakpoints, every
one classified to a statutory phase boundary (phase-in end, phase-out
start, phase-out end) within $2; zero unexplained kinks; zero
discontinuities.** As encoded, EITC is exactly the statutory trapezoid in
every cell — the empirical form of the continuity/piecewise-linearity
theorems Phase 2 will prove symbolically, now grid-verified.

The absence of one structure is itself the finding: **26 U.S.C. §32(f)
requires the credit to be "determined under tables" — the IRS EITC
tables bucket earned income into $50 brackets, so the *legal* credit is
a step function.** PolicyEngine implements the smooth §32(a)–(b) formula:
the scan shows no $50-periodic staircase anywhere, and (finding 1) the
chain applies no rounding at all. Consequence: for nearly every filer
inside a phase region, PolicyEngine's EITC differs from the
table-determined credit an actual return would claim — by up to roughly
half a bracket times the phase rate (≈ $11 at the 45% phase-in;
≈ $5 on phase-out), plus reporting fractional cents no tax form
contains. Verification against the published Rev. Proc. tables and a
mirror of the table semantics in Lawlib (with the smooth-vs-table delta
as a provable bound) is queued for Phase 2. This is Lawlib's first
finding candidate: not a bug in an implementation, but a measurable gap
between the shipped model and §32(f)'s procedural text.
