# Draft: courtesy note to PolicyEngine (email or GitHub discussion)
*(send before any public post that names their internals; Nathanael
reviews and sends)*

Subject: Independent formal verification of policyengine-us — findings
you may want

Hi PolicyEngine team,

I've been building **lawlib** (github.com/than4213/lawlib), a Lean 4
formalization of US tax-benefit law created by mechanically translating
policyengine-us (pinned 1.783.0) into a proof assistant, with
differential testing between the two engines as the validation loop —
effectively an independent, machine-checked audit of your model. It's
AGPL-3.0, same as upstream.

First: thank you — policyengine-us is an extraordinary artifact, and
none of this exists without it.

In the process we found a few things you may want to know about before
we write about them publicly (nothing here is a vulnerability; it's
correctness/precision engineering):

1. **float32 residue**: money pipelines in float32 accumulate up to
   ~1.6¢ of error vs exact-rational evaluation, and the EITC chain
   applies no rounding at all (fractional-cent credits).
2. **The smooth EITC vs the IRS table**: the legal credit is the step
   function in the 1040-instructions tables; the smooth formula
   deviates by up to $11.50 (proven tight). We also reverse-engineered
   the table's generator exactly — including that it anchors phase-out
   at *unrounded* internal completed-phaseout amounts, so the published
   Rev. Proc. integers don't regenerate the published table.
3. **Input-API path-dependence**: setting the same conceptual input
   different ways yields different values (raw vs ÷12 vs
   uprating-fallback), and `Simulation.__init__` silently moves income
   inputs onto `*_before_lsr` twins, overwriting caller-set values.
4. **Small semantic traps we had to reverse-engineer** (may be worth
   documenting): `GroupPopulation.__call__` on a person variable
   implicitly sums; `adds` lists may mix variable names and parameter
   paths; some state-indexed breakdown parameters omit territory enum
   members (latent KeyError).
5. **Enacted vs projected**: parameter files interleave enacted values
   with uprated projections (through 2035); we classify and strip the
   projections for the "law only" claim, and would happily upstream the
   classification if useful.

Full running list: docs/FINDINGS.md in the repo. If any of this is
wrong, we'd love the correction before we publish; if it's useful, even
better. And if an independent exact-arithmetic verification layer for
policyengine-us is interesting to you longer-term, let's talk.

Best,
Nathanael (than4213)
