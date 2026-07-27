# One Tax Code, Two Credits, and a Proof Assistant

*What we learned building Lawlib, a machine-checked twin of the Earned
Income Tax Credit and Child Tax Credit — July 2026*

Here are three statements about United States tax law. Each one has been
checked by a computer program that will not accept an unjustified step:

1. **The Earned Income Tax Credit has no cliffs.** For every family
   size (0–3 children) and both filing structures the credit
   distinguishes, the 2023 EITC is a continuous function of earned
   income: earning one more cent never costs you a jump in credit.
   This is a theorem, proven for *every* income, not a claim tested on
   samples.
2. **The Child Tax Credit has exactly forty cliffs** (for a single
   parent with one child): the credit drops by exactly $50 at exactly
   $200,000, $201,000, …, $239,000 of income, and is flat at every
   other dollar. Also a theorem — a complete atlas of every
   discontinuity, with a proof there are no others.
3. **The tax code disagrees with itself by fifty cents.** The EITC
   formula written in the statute (26 U.S.C. §32) produces a maximum
   credit of $7,429.50 for a family with three children in 2023. The
   IRS's published maximum, the lookup tables filers actually use, and
   the major microsimulation models all say $7,430. Both numbers come
   from official sources. They cannot both be the formula's answer.

None of these facts is individually shocking. What's new is their
*epistemic status*: they are now machine-checked, down to definitions
extracted mechanically from running tax software and cross-checked
against the IRS's own published tables — and anyone can re-run the
checks from public sources.

This post explains what we built, for two audiences at once: formal
methods people who have never read a statute, and tax people who have
never seen a proof assistant. Code and data:
[lawlib](https://github.com/than4213/lawlib) (the Lean library) and
[pe2lean](https://github.com/than4213/pe2lean) (the extraction
toolchain).

## For the tax crowd: what is a proof assistant?

A proof assistant (we use [Lean 4](https://lean-lang.org/), home of the
[mathlib](https://leanprover-community.github.io/) mathematical
library) is a programming language whose compiler checks *mathematical
arguments*. You state a claim — "this function never decreases on this
interval" — and you must convince the compiler with a chain of
reasoning it can verify mechanically, step by step, down to logical
axioms. There is no "trust me." If the proof has a gap, it does not
compile.

Two properties make this interesting for law. First, Lean definitions
are *executable*: the same text that serves as a precise specification
of §32 also computes actual credit amounts, so the spec can be tested
against reality. Second, proofs quantify over *all* cases. Testing a
tax calculator on ten million households tells you about ten million
households; a theorem about "every rational income" closes the gap
where surprises hide.

## For the Lean crowd: what is the legal encoding problem?

Statutes are algorithms written in prose. §32 says, in effect: multiply
earned income by a rate, cap it, then reduce it as income rises past a
threshold. Encoding such rules formally has two traditions. *Deep*
encodings (the [Catala](https://catala-lang.org/) language, s(CASP),
Z3 models) produce inspectable logic you can reason about — but exist
for only a handful of code sections. *Shallow* encodings — above all
[PolicyEngine US](https://github.com/PolicyEngine/policyengine-us),
the largest living formalization of US tax-benefit law — cover most of
the federal income tax and major benefit programs, but each rule is an
opaque Python/NumPy formula: you can run it, not reason over it.

Lawlib bridges the two with a **verified twin**: a tool (`pe2lean`)
mechanically translates PolicyEngine's formulas into Lean definitions.
Nobody is asked to rewrite tax law in a new language — the twin tracks
the living codebase. Three disciplines keep the translation honest:

- **Rejection over guessing.** The translator accepts a small, typed
  fragment of Python (~20 constructs). Anything outside it — a loop, a
  dynamic dispatch, a clever cast — is *rejected loudly* with file,
  line, and reason, and the variable becomes a declared input instead.
  A wrong translation would poison every downstream theorem; a
  rejection is just a smaller domain.
- **Exact arithmetic.** PolicyEngine computes in floating point; the
  law's semantics is exact decimal arithmetic. The twin uses exact
  rationals everywhere — `0.34` is read from source text as 34/100,
  never as a binary float. (This mattered: see below.)
- **Differential testing.** Every night, 100,000 randomized households
  — with adversarial incomes placed exactly on phase boundaries — are
  evaluated by both PolicyEngine and the compiled Lean twin, and must
  agree. When they first disagreed, it caught a real translation gap
  within minutes (PolicyEngine variables carry an eligibility mask
  *outside* the formula body; the twin was paying credits to
  ineligible households until it learned the idiom).

The result for §32 and §24: 44 translated variables covering both
credit chains, each Lean definition carrying its source file and
statutory citations, built reproducibly (extraction is byte-for-byte
deterministic, enforced by CI). A generated definition looks like this:

```lean
/-- policyengine_us/variables/gov/irs/credits/earned_income/eitc.py
    policyengine-us 1.783.0, entity tax_unit. -/
def eitc (t : TaxUnit) (d : Date) : Rat :=
  if eitc_eligible t d then
    min (eitc_phased_in t d)
        (max 0 (eitc_maximum t d - eitc_reduction t d)) * ...
```

## What we found

### 1. The shape of two credits, proven

For the EITC we proved that every 2023 cell (filing status × number of
children) *equals* the statutory trapezoid — phase in at a rate, hit a
plateau, phase out at another rate — and therefore:

```lean
theorem eitc_continuous : ∀ g n, n ≤ 3 → Continuous (pe g n)
```

Read: the credit is a continuous function of earned income. No cliffs,
at any rational income, in any cell — plus monotonicity through the
plateau, nonnegativity, and exact zero beyond the statutory endpoint
($46,560.00 for a single parent of one, and that value is *exact*).

The CTC is the mirror image. §24(b)(2) phases the credit out "by $50
for each $1,000 **(or fraction thereof)**" over the threshold — a
ceiling function, hence a staircase. We proved the complete cliff
atlas: for a single parent with one child, exactly 40 drops of exactly
$50, at exactly $200,000 + $1,000·k, flat at every other whole-dollar
step from $0 to $250,000. One tax code, two credits, opposite
smoothness — by design, and now by theorem.

### 2. The IRS's EIC table, reverse-engineered

Here is a subtlety even many tax professionals miss: for most filers
the *legal* EITC is not the formula — §32(f) requires the credit to be
"determined under tables" published by the IRS, which bucket income
into $50 brackets. The formula is continuous; the law-as-administered
is a step function.

We parsed all 1,265 rows (10,120 values) of the 2023 table from the
Form 1040 instructions PDF and reverse-engineered its generator
exactly. The table is: *evaluate the formula at each bracket's
midpoint; round half-up; give kink-straddling brackets the full
plateau maximum; and — the surprise — anchor the phase-out not at the
statutory threshold but at the completed-phaseout endpoint, using the
IRS's internal **unrounded** value.* Those internal values don't appear
in any publication; fitting them from the table pins each to within
five cents (single, three children: between $56,837.77 and $56,837.82;
the Rev. Proc. publishes the rounded $56,838). All of this is now a
Lean theorem: the five-line generator model reproduces every one of
the 10,120 table cells.

Consequence, also proven: the smooth formula differs from the legal
(table) credit by up to **$11.50** — sharp, attained at $50 of earned
income with three children — and by at most $5.30 at bracket
midpoints. Anyone modeling the EITC with the formula (as essentially
all microsimulation does) carries that structural error relative to
what filers actually receive.

### 3. The fifty-cent self-disagreement

To test the twin against something *independent*, we wrote a second
encoding of §32 from scratch — in Catala, a language designed for
literate statute translation, following the statute text and
deliberately not looking at PolicyEngine — then compiled it into the
same Lean library and compared the two encodings at every whole-dollar
income from $0 to $60,000 in all eight cells.

Where the statute's arithmetic is unambiguous (one and two children),
the encodings agree to within one cent — that residue is Catala's
round-to-the-cent money semantics, and the agreement is a theorem over
480,008 points. Where they disagree, the disagreement is *itself*
exact and traceable to the source: §32(a)(2)(A) caps the credit at
"the credit percentage of the earned income amount" — 7.65% × $7,840 =
**$599.76** childless, 45% × $16,510 = **$7,429.50** with three kids —
while the Rev. Proc.'s "Maximum Amount of Credit" line, the IRS
tables, and PolicyEngine all use the rounded **$600 / $7,430**. Two
published government artifacts, arithmetically inconsistent; every
encoder silently picks one; the machine caught the fork at the first
plateau test point. (Which is "right" is a legal question, not a
computational one — §32(f) plausibly makes the administered figure
operative. The point is that the inconsistency is real, quantified,
and was found mechanically.)

### 4. Numerics as findings

Exact rationals turned floating point from an annoyance into an
instrument. Measured across 1.6 million values: PolicyEngine's float32
arithmetic deviates from exact arithmetic by up to about 1.6 cents,
and its EITC chain applies no rounding at all — it reports credits
with fractional cents. No tax form contains those. And the
translation work surfaced structural lessons for anyone doing static
analysis of OpenFisca-family codebases: eligibility masks
(`defined_for`) are invisible dependency edges; the `adds` idiom means
different things on group vs. person variables; parameter files mix
enacted law with pre-materialized inflation *projections* through 2035.

## Believing it

Every layer is independently checkable, from weakest to strongest
assumption:

| Layer | Checks | Trust base |
|---|---|---|
| Differential testing | Lean twin ≡ PolicyEngine on 100k households/night | both engines could be wrong together |
| Table verification | model ≡ all 10,120 IRS table cells | the published PDF |
| Cross-encoding | twin ≡ independent Catala encoding (±1¢) | two encoders reading the same text |
| Theorems | continuity, monotonicity, cliff atlas, exact bounds | Lean's kernel (+ compiler for finite checks) |

Reproducing it: `lake build` compiles the library and re-checks every
theorem; `pe2lean-diff` re-runs the differential suite;
`pe2lean-tablecheck` re-parses the IRS PDF and re-verifies the table
model. Pinned versions throughout (policyengine-us 1.783.0, Lean
4.32.1). The finite theorems use Lean's `native_decide`, which adds
the Lean compiler to the trust base; the ∀-theorems use the kernel
alone.

Honest scope notes: theorems quantify over income on a canonical
household (fixed ages, valid SSNs, AGI equal to earned income, other
income zero) — the *differential* suite covers the messy general
population; eligibility subtleties and other tax years are encoded and
tested but the theorem set is 2023-first; and none of this is tax
advice.

## What's next

The pattern — extract, diff-test, prove, compare encodings — is not
EITC-specific: the CTC joined in one evening, needing four new
translation idioms. Next: more credits, theorems across 2021–2025
(the American Rescue Plan's 2021 shapes are already extracted and
tested), a symbolic version of the CTC discontinuity result, and
Catala's published §121 encoding through the same pipeline. The
longer-term bet: a community-maintained formal library of law, where
"this amendment introduces an unintended cliff at $23,410" is a CI
comment, not a working paper.

If either half of this — the law or the Lean — is your world, we'd
love company. The rejection reports are a to-do list.

*Everything above is reproducible from
[lawlib](https://github.com/than4213/lawlib) and
[pe2lean](https://github.com/than4213/pe2lean); the detailed findings
log is [docs/findings-m5.md](findings-m5.md).*
