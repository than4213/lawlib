# Two categories, one crossing

*(Draft — for review before any community-facing use.)*

Lawlib is built on one strict rule: **things we construct and things
we observe are different kinds of knowledge, and they never mix
silently.**

## The two columns

| | Constructed (math, CS, law) | Observed (the sciences) |
|---|---|---|
| What it is | Made of texts — the text *is* the thing | About the world |
| How truth is settled | By derivation: prove it from the texts | By evidence: observe and infer |
| Native tool | Machine-checked proof, exact arithmetic | Statistics, measurement, replication |
| Can a formalization be complete? | Yes | No — always a model plus evidence |
| Lives in | lawlib (the library) | the test/claims layer |

Law belongs in the first column. No experiment can confirm or refute
what 26 U.S.C. §32 says — the text settles it. That is why lawlib can
be exact (fractions, never floating point) and proved (theorems, not
test suites): "the EITC has no benefit cliffs" is true in the same way
"addition is commutative" is true.

Statistics is the engine of the second column — the foundation for
finding out what's true about the world. It is *not needed* in the
first column at all. Keeping it out of the library is not a
limitation; it is the design.

## Law's ambiguity is incompleteness, not observation

Law is often ambiguous — but not because it is about the world. It is
ambiguous because its texts are **incomplete**. When a decision is
needed at an ambiguous point, whoever decides — an agency, a court —
is not discovering a fact. They are **making more law**: a further
text, from a further source.

A concrete case (findings #8–9): the statute's literal EITC arithmetic
gives $599.76; the IRS's published tables say $600. Neither is "the
real value" in any experimental sense. They are two texts from two
sources of law, and the right move is what this project did:
formalize both and **prove exactly how far apart they are** — 24
cents. No data was consulted, because none is relevant.

Mathematics does the same thing constantly. `0^0 = 1` is a convention
completing an underdetermined definition; Lean's own `x / 0 = 0` is a
convention chosen so division is always defined. Nobody claims an
experiment justified either. Math's human record is fallible the same
way law's is — a famous "proof" of the four-color theorem stood
accepted for eleven years before the error was found — which is why
proof checkers exist: the checker is mathematics' court of final
appeal, and lawlib inherits it.

One structure law has that math doesn't need: in math, a convention
binds no one — rival conventions can coexist because nothing turns on
uniformity. Law requires uniformity, so it carries a **binding order
of authority** over its texts: statute, regulation, agency practice,
judicial decision, each with precedence and effective dates. That
ordering is itself law, itself a text, itself formalizable. Law is
math **plus a ranking of its texts** — a feature to model, not a leak
to plug.

What genuinely remains about the world is only the archival question:
*is this text really what the institution published?* That is
answered by document hashes and citations — bookkeeping, not
statistics.

## Programs have the same split, one level down

A program is a text; a *run* of it is a physical event. Finding #16
is the specimen: correct Lean source, but the compiled binary
corrupted memory. So "both engines agreed on 100,000 households" is
evidence about runs — it lives in the CI logs and the findings list,
never inside the library.

## The one crossing

The boundary between the columns is **typed, not walled**. Exactly one
kind of statement crosses it — the certified conditional:

> IF this dataset is the file with hash H, and the outside computation
> reported total T, THEN lawlib's total is within ε of T.

The proof checker certifies the arrow. It never certifies the "if".
The world enters only as named, unasserted hypotheses with their
evidence graded — and only in the test layer, never the library.

Held strictly, this shapes the whole repository:

- **`Lawlib/` is law only** — no data, no floats, no claims, no
  axioms. A new survey, a re-run, a re-measurement can never
  invalidate a lawlib proof.
- **Whatever the law itself generates is not stored as content.** The
  10,120-cell IRS table is *derivable* from a five-line rule, so the
  rule is in the library and the transcription is a test fixture.
- **`Tests/` holds everything that touches the world**: fixtures,
  claims about printed artifacts and executed programs, and their
  certified conditionals. It imports the library; the library never
  imports it.
- **Population studies never enter lawlib.** Poverty rates, program
  totals, optimization results — statements about people — are for a
  separate claims layer, with statistics, when that phase comes.
