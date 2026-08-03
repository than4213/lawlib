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

Statistics is the inference engine of the second column — the
foundation for claims about reality. It is *not needed* for the first
column at all. Keeping it out of the pure layer is not a limitation;
it is the design.

## Law's ambiguity is incompleteness, not empiricism

Law is often ambiguous — but not because it is about reality. It is
ambiguous because its texts are **incomplete**. Where a decision is
needed at an ambiguous point, whoever decides — an agency, a court —
is not discovering a fact; they are **making more law**. The
completion is a further text, from a further source.

Specimen (findings #8–9): the statute's literal EITC arithmetic yields
$599.76; the IRS's administered tables say $600. Neither is "the real
value" in an empirical sense. They are two formal texts from two
sources of authority, and the right move is exactly what this project
did: formalize both and **prove the divergence** — exactly 24¢/50¢ —
as a theorem about two constructed objects. No data was consulted,
because none is relevant.

Mathematics makes the same move constantly. `0^0 = 1` is a
stipulation completing an underdetermined definition; Mathlib's
`x / 0 = 0` is pure convention chosen for totality. Nobody claims
these agree with experiment. And math's human record is fallible the
same way law's is — Kempe's four-color "proof" stood accepted for
eleven years — which is why the kernel exists: it is mathematics' own
court of final appeal, and lawlib inherits it.

The one structure law adds that math does not need: math's
completions bind no one (rival conventions coexist), while law
requires uniformity, so it carries a **binding authority ordering**
over its texts — statute, regulation, administrative practice,
judicial completion, with precedence and effective dates. That
ordering is itself law, itself formal. So law = math **plus an
authority ordering over its texts** — a feature to model (the
manifest's per-source provenance and the authority taxonomy in
scope.md are its seed), never a leak to plug.

What remains genuinely about reality is only the archival question:
*is this text what the institution actually emitted?* That is
provenance — answered by hashes and citations, not statistics.

## CS splits the same way, one level down

Programs are pure; *executions* are physical. Finding #16 is the
specimen: correct Lean source, heap-corrupting compiled binary.
Accordingly, "the differential harness passed on N households" is
evidence about program runs — it lives in CI artifacts and the claims
ledger, never inside the library.

## The membrane rule

The boundary is **typed, not walled**. There is exactly one
sanctioned crossing: the certified conditional
(`Lawlib/Claims/Data.lean`):

> IF this dataset is the artifact with hash H, and the external
> computation reported total T, THEN lawlib's total is within ε of T.

The kernel certifies the arrow. It never certifies the antecedent.
Data enters only as opaque symbols carrying tiered, provenance-tagged
claims; trust is auditable at this membrane and nowhere else.

For the current, law-focused phase the membrane is nearly idle by
design: the only reality-touching artifacts are source-text
provenance (hashes in the manifest) and the differential-testing
evidence (QA about the translation, outside the formal object).
Neither involves statistics. Statistics becomes necessary exactly
when lawlib is asked to speak about the world — population
aggregates, poverty and optimization studies — and it will live in
the claims layer when that phase arrives.
