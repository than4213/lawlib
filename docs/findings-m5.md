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
contains. **Verified against the actual IRS table — see finding 8.**

## 8. VERIFIED: the 2023 IRS EIC table, fully reverse-engineered — and the exact PE-vs-law gap

We parsed all 1,265 $50-bracket rows (10,120 cells) of the 2023 EIC
table from the Form 1040 instructions PDF and compared them against the
exact-rational engine (`pe2lean-tablecheck`). Results:

* **Finding 7 confirmed.** The table equals the phase formula evaluated
  at the *bracket midpoint*, rounded half-up: 6,684 of 7,467 nonzero
  cells match exactly under PolicyEngine's semantics; all 2,653
  no-credit cells agree.
* **The IRS anchors phase-out at the END, not the start.** The 780
  cells that differ (by exactly $1, 778 of them in phase-out) are all
  explained by one convention: the table computes phase-out credit as
  `rate × (E − midpoint)` where `E` is the completed-phaseout amount —
  not `max − rate × (midpoint − start)` as PolicyEngine does. Fitting E
  per column against every phase-out cell pins it to ±$0.05 and shows
  the generator uses the IRS-internal *unrounded* value (e.g. single/3
  children: implied E ∈ [$56,837.77, $56,837.82); the Rev. Proc.
  publishes $56,838). With that one number per column, **the
  end-anchored midpoint model explains all 10,120 cells**, given two
  boundary conventions:
* **Kink-straddling brackets get the full plateau maximum**
  (taxpayer-favorable): e.g. single/1 child at $21,550–21,600 (contains
  the $21,560 phase-out start) pays the full $3,995 where the formula
  gives $3,992.60.
* **End-straddling brackets are split** into special partial rows with
  eligibility cut exactly at E — a real $50-scale cliff the smooth
  formula does not have.

**Update — now machine-checked:** `Lawlib/Verify/EicTable2023.lean`
states the generator model in Lean (rates/thresholds referenced from the
extracted parameters) and proves by `native_decide` that it reproduces
every parsed table cell, that the PE-vs-table gap is ≤ $11.50 everywhere
(sharp at $50 earned income, three children), and ≤ $5.297 at bracket
midpoints. The finding is no longer an empirical comparison; it is a
theorem about committed data.

## 9. First cross-encoding divergence: the statutory formula vs the administered maximum

An independent Catala encoding of §32(a)–(b)
([catala/section_32.catala_en](../catala/section_32.catala_en)), written
from the statute text without consulting PolicyEngine, diverges from
the PolicyEngine encoding on plateau credits. §32(a)(2)(A) caps the
credit at "the credit percentage of the earned income amount" — for
2023: 7.65% × $7,840 = **$599.76** (childless) and 45% × $16,510 =
**$7,429.50** (three children). PolicyEngine's `max` parameter — and
Rev. Proc. 2022-38's own "Maximum Amount of Credit" line, and the
§32(f) tables — all use the *rounded* $600 / $7,430. So the literal
statutory formula and administered practice disagree by up to $0.50 on
every plateau dollar of the affected cells (0 and 3+ children; the 1-
and 2-child products happen to be whole dollars). Since §32(f) makes
the tables operative for most filers, the administered figure
presumably governs — but two published government artifacts (statute
formula, Rev. Proc. maximum) are arithmetically inconsistent, and any
encoder must silently choose. PolicyEngine chose the Rev. Proc.;
Catala-from-the-text chooses the formula; the machine caught the
difference at the first plateau test point. (Confirmed also at the
childless zero point: both encodings agree the credit hits $0 at
exactly $17,640 = 9,800 + 599.76/0.0765, because the childless credit
and phaseout percentages coincide.)

**Now machine-checked** (`Lawlib/Verify/Catala2023.lean`): the Catala
encoding, transpiled to Lean via its OCaml backend output
(`pe2lean-catala`, cent-exact `multMonRat` semantics from the Catala
runtime), is proven by `native_decide` to (a) reproduce the Catala
interpreter's outputs, (b) agree with the PolicyEngine encoding within
**1 cent** at every whole-dollar income $0–$60,000 in the 1- and
2-child cells — pure cent-rounding residue — and within 25¢/51¢ in the
0/3-child cells, and (c) diverge by **exactly 24¢ / 50¢** on those
plateaus. Equivalence-modulo-documented-divergence, as a theorem.

Consequences for PolicyEngine fidelity, now exact rather than
estimated: PE differs from the legal credit by up to ~$11.25 in
phase-in and ~$5.27 in phase-out from midpoint quantization, plus a
systematic ~$0–1 shift throughout phase-out from start-anchoring vs the
IRS's end-anchoring, plus the boundary-bracket conventions. Phase 2 can
now mirror the *exact* table semantics in Lean (the generator is fully
specified above) and prove the PE-vs-table delta bound as a theorem.
Verification scope: tax year 2023, Single and MFJ column groups (the
single-group column also covers HoH/QSS by the table's own header);
2 of 1,267 rows are footnoted split rows the parser skips.
