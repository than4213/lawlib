# Two categories, one membrane

*(Draft — for review before any community-facing use.)*

Lawlib holds one doctrine about knowledge strictly: **constructed
systems and empirical reality are different epistemic types, and they
never mix silently.**

## The two columns

| | Constructed (math, CS, law) | Empirical (the sciences) |
|---|---|---|
| What it is | Constituted by its texts — the artifact *is* the object | Answerable to observation |
| Truth | Definitional; provable | Inferred; evidenced |
| Native tool | Kernel-checked proof, exact arithmetic | Statistics, provenance, replication |
| Can formalization be complete? | Yes | No — always model + evidence |
| Lives in | lawlib (Lean + Mathlib) | the claims layer |

The mechanical fragment of law belongs in the first column. No
experiment can falsify 26 U.S.C. §32(b); the statute just *is* the
rule. That is why lawlib can be exact (`Rat`, never `float`) and
proved (kernel theorems, not test suites), with no epistemic hedging
anywhere: `eitc_continuous` is a theorem in the same sense
`Nat.add_comm` is.

Statistics is the inference engine of the second column. It is the
foundation for claims about reality — and it is *not needed* for the
first column at all. Keeping it out of the pure layer is not a
limitation; it is the design.

## Three edges where the boundary needs drawing

1. **Law leaks empiricism through interpretation, not statistics.**
   The statute's literal arithmetic says $599.76; the IRS's
   administered tables say $600 (findings #8–9). "Which is the law?"
   is a fact about institutional practice. The resolution: formalize
   *readings* — "under reading R, the value is X" stays pure; which
   reading governs is recorded outside the kernel. Likewise enacted
   rules vs pre-materialized inflation projections
   (docs/enacted-vs-projections.md): the rule is law, the forecast is
   not.

2. **CS splits the same way one level down.** Programs are pure;
   *executions* are physical. Finding #16 is the specimen: correct
   Lean source, heap-corrupting compiled binary. Accordingly, "the
   differential harness passed on N households" is evidence about
   program runs — it lives in CI artifacts and the claims ledger,
   never inside the library.

3. **Statistics itself straddles the line — cleanly.** Probability
   theory is math (Mathlib, pure column). Statistical inference
   applied to data is science (claims layer). Same word, two
   categories, no conflict.

## The membrane rule

The boundary is **typed, not walled**. There is exactly one
sanctioned crossing: the certified conditional
(`Lawlib/Claims/Data.lean`):

> IF this dataset is the artifact with hash H, and the external
> computation reported total T, THEN lawlib's total is within ε of T.

The kernel certifies the arrow. It never certifies the antecedent.
Data enters only as opaque symbols carrying tiered, provenance-tagged
claims; trust is auditable at this membrane and nowhere else.

Consequences held throughout the codebase:

- lawlib contains **zero data and zero floats**; a survey revision can
  never invalidate a lawlib proof;
- fidelity evidence (differential CI) is **about** the library, not
  **in** it;
- population aggregates, poverty studies, optimization results are
  claims-layer objects — formal notation over them must carry
  evidence tiers, never a kernel stamp.
