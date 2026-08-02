# Zulip draft 2: lawlib announcement
*(post after the bug thread has landed and Nathanael has reviewed this
text; suggested stream: #general or #lean4, topic "Lawlib: US tax and
benefit law as a Lean library")*

---

Hi everyone! I'd like to introduce **lawlib**
(https://github.com/than4213/lawlib): US tax-and-transfer law as a
Lean 4 library — and get your advice on making it a good citizen of
this ecosystem.

**What's in it.** The computable core of the US tax-benefit system:
**10,362 date-indexed parameters** (every rate, threshold, and bracket
table in [PolicyEngine US](https://github.com/PolicyEngine/policyengine-us),
as exact rationals from the YAML source text — floats never touch the
data) and **~3,200 formulas** mechanically translated from PolicyEngine's
Python into plain Lean defs. Five programs — EITC, CTC, SNAP, SSI, and
the ACA premium tax credit — are *differentially validated* nightly: thousands of randomized
households (a deep soak of the root programs plus a full-tier sweep),
evaluated by both engines, must agree to within PolicyEngine's own
float32 noise. Translation is
rejection-based: anything the typed IR can't faithfully express becomes
a documented boundary input, never a guess (`rejection_report.md`).

**Some theorems.** The 2023 IRS EIC table — 10,120 cells parsed from
the Form 1040 instructions PDF — is reproduced cell-for-cell by a
five-line reverse-engineered generator (`native_decide`); PolicyEngine's
smooth formula is within $11.50 of the printed table everywhere, and
that bound is sharp. On the kernel side: the EITC is *continuous* in
income (no benefit cliffs), with closed trapezoid forms per filing
cell; the CTC's $50 cliffs are completely enumerated. And an
independent statute-first Catala encoding of 26 U.S.C. §32 proves the
statute's literal arithmetic differs from administered practice by
exactly 24¢/50¢ — the Rev.-Proc. rounding the statute never mentions.

**Trust story, honestly.** Table/grid results use `native_decide`
(compiler in the TCB); the symbolic theorems are ordinary proofs.
Statements about *reality* (the printed table, executed PolicyEngine)
are never-asserted claim `Prop`s with graded evidence tiers, so
`#print axioms` is clean for the whole library and every
reality-facing conclusion carries its hypotheses explicitly. The
library contains *law only*: inflation-projected values in the source
data are classified out (a projection is a forecast of a future
administrative act, not law), and the evaluator fails fast past the
enacted horizon.

**Toolchain war story.** Scaling to 3,200 generated defs found the
`FromJson` codegen bug I posted about in [link bug thread] (structures
≥ 156 fields corrupt the heap in compiled code — bisected to the exact
boundary) and taught us to emit a fused, memoized evaluator instead of
naive per-definition recursion.

**What I'd love from you.** Naming/idiom review (the generated-code
conventions especially), opinions on the claims-as-Props pattern for
empirical uncertainty, and pointers if any of this duplicates existing
work. The transpiler (pe2lean, Apache-2.0) generalizes to any
OpenFisca-style system; lawlib itself is AGPL-3.0 (upstream is).

*Longer writeup: docs/writeup-phase1.md in the repo; findings index
(17 so far): docs/FINDINGS.md.*
