# Zulip draft 2: lawlib announcement
*(post after the bug thread has landed and Nathanael has reviewed this
text; suggested stream: #general or #lean4, topic "Lawlib: the formal
logic of law")*

---

Hi everyone! I'd like to introduce **lawlib**
(https://github.com/than4213/lawlib): a Lean 4 library whose subject
is **law** — and to ask your advice on making it a good citizen of
this ecosystem.

**The idea.** Law is a formal system. A statute's consequences follow
from its text the way a theorem follows from axioms: no experiment can
confirm or refute what 26 U.S.C. §32 says the Earned Income Credit is
— the text *settles* it. So law can live in a proof assistant the same
way mathematics does: definitions that are exact, and facts about the
law that are machine-checked theorems rather than opinions. Lawlib is
that library. Anything that is law belongs in it — statutes,
regulations, agency tables, court-made rules, any jurisdiction — as
long as each piece declares exactly what it depends on.

**What's in it today.** United States federal tax and benefit law:
roughly 1,000 parameters (every rate, threshold, and bracket table,
kept as exact fractions together with the date each value took effect
— floating point never touches the data) and about 700 formulas
covering the major programs: the income tax itself, the Earned Income
Tax Credit, the Child Tax Credit, food assistance (SNAP), Supplemental
Security Income, and the ACA premium credit. These were imported
mechanically from [PolicyEngine US](https://github.com/PolicyEngine/policyengine-us),
a large, actively maintained model of US tax-benefit law written in
Python, plus one independent hand-encoding of a statute in
[Catala](https://catala-lang.org). Those are the first sources, not
the definition of the project.

The import rule is strict: a formula is translated *exactly or not at
all*. Anything the translator cannot express faithfully becomes a
declared input instead, and the refusal is logged with its reason
(`rejection_report.md`). Nothing in the library is a guess.

**How we know the translation is right.** Every night, thousands of
randomized households are computed by both lawlib and PolicyEngine,
and about a hundred variables must agree on every one of them (up to
the rounding noise of PolicyEngine's own 32-bit floats — which lawlib,
computing in exact arithmetic, gets to measure).

**Some things we've proven.**
- The 2023 IRS EIC table — 10,120 numbers parsed from the Form 1040
  instructions — is reproduced *cell for cell* by a five-line rule
  (evaluate the formula at each $50 bracket's midpoint and round),
  recovered from the table and verified by computation.
- The EITC has **no benefit cliffs**: the credit is continuous in
  income, proved as an ordinary kernel theorem. The Child Tax Credit's
  $50 cliffs, by contrast, are real — and we enumerate every one.
- The statute's literal arithmetic and the IRS's administered practice
  **disagree by exactly 24 cents** (50¢ at the phase-out end): the
  statute never mentions the rounding the published figures use. Two
  sources of law, formalized separately, divergence proven — not a bug
  report, a theorem.

**What you have to trust.** The symbolic theorems are ordinary kernel
proofs; whole-table computations use `native_decide`, which
additionally trusts the Lean compiler. `#print axioms` is clean for
the whole library. And the library contains *law only*: pre-computed
inflation projections in the source data are classified out (a
forecast of a future administrative act is not law).

**A war story.** Scaling to hundreds of generated definitions
uncovered a Lean compiler bug — derived `FromJson` on structures with
156 or more fields corrupts the heap in compiled code (155 is fine;
the boundary is exact). Details and a 20-line reproduction in the bug
thread: [link].

**What I'd love from you.** Review of naming and idioms (especially
the generated-code conventions), and pointers if any of this
duplicates existing work. The translator
([pe2lean](https://github.com/than4213/pe2lean), Apache-2.0)
generalizes to any OpenFisca-style system; lawlib itself is AGPL-3.0
(the upstream data is).

*Findings index (20 so far): docs/FINDINGS.md; the "law is math"
design doctrine: docs/categories.md.*
