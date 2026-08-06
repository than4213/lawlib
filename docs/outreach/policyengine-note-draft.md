# Draft: note to PolicyEngine
*(Nathanael reviews and sends. Suggested channel: a GitHub Discussion
on PolicyEngine/policyengine-us, or email if you'd rather start
privately. The repository is already public, so this is "here is what
I found and where it is written down," not a heads-up before
publishing.)*

Subject: Independent Lean formalization of policyengine-us — some
findings, and a thank-you

Hi PolicyEngine team,

I've built **lawlib** (github.com/than4213/lawlib), a library of US
law in the Lean 4 proof assistant. It is populated by mechanically
translating policyengine-us (pinned at 1.783.0) into Lean definitions,
with a nightly cross-check that computes thousands of randomized
households in both engines and requires them to agree — in effect, an
independent machine-checked audit of your model. It's AGPL-3.0, same
as upstream, and the repository is public.

First and most importantly: thank you. policyengine-us is an
extraordinary piece of work, and none of this would exist without it.
Lawlib's claim to cover real law rests on your model being good, and
the cross-check says it is: **801 translated formulas, 259 variables
compared, agreeing on every household generated**, to within float
rounding.

That last qualifier is where the interesting things live. A few
findings you may want — all correctness-and-precision engineering,
nothing urgent:

1. **32-bit float residue.** Money pipelines in float32 accumulate up
   to ~1.6¢ of error against exact rational evaluation, and the EITC
   chain applies no rounding at all, so it can produce fractional-cent
   credits.

2. **The smooth EITC formula vs. the printed table.** The legally
   operative credit is the step function in the 1040 instructions. The
   smooth formula deviates from it by up to $11.50, and that bound is
   tight (worst case: $50 of earned income with three children —
   formula $22.50, table $34). I also recovered the table's generator
   exactly: it anchors the phase-out at *unrounded* internal
   completed-phaseout amounts, which means the published Rev. Proc.
   integers do not regenerate the published table.

3. **`marginal_rate` scales.** A scale parameter tagged
   `metadata.type: marginal_rate` is a rate schedule — each bracket's
   rate applies to its own slice — not a lookup. I initially read it
   as a lookup and produced a "26% tax" where the law wanted 26% of
   the first slice plus 28% of the rest. Entirely my bug, but the tag
   is load-bearing in a way that isn't obvious from the YAML, and may
   deserve a line of documentation.

4. **Input-API path dependence.** Setting the same conceptual input by
   different routes yields different values (raw vs. `calculate_divide`
   ÷12 vs. the uprating fallback). Separately, `Simulation.__init__`
   moves income inputs onto their `*_before_lsr` counterparts, which
   silently overwrites caller-set values.

5. **Marital-unit inference is context-dependent.** The identical
   household gets different marital units — and therefore different
   SSI, through `ssi_claim_is_joint` and the couple resource test —
   depending on whether it is simulated alone or inside a vectorized
   batch. Declaring marital units explicitly removes the ambiguity.

6. **Semantic details I had to reverse-engineer**, in case they're
   worth documenting: `GroupPopulation.__call__` on a person variable
   implicitly sums over members; `adds` lists may mix variable names
   with parameter paths; some state-indexed breakdown parameters omit
   territory enum members (a latent KeyError that your data
   distribution happens to avoid).

7. **Enacted values vs. uprated projections.** Parameter files
   interleave enacted law with projections through 2035. Lawlib
   classifies and strips the projections to support a "law only"
   claim; if that classification is useful to you, I'd happily
   contribute it upstream.

The running list with details is `docs/FINDINGS.md` in the repo. If
any of it is wrong I would genuinely like the correction — a mistake
in my translation is more likely than a mistake in your model, and
several entries here started out as exactly that.

If an independent exact-arithmetic check of policyengine-us is
interesting to you longer term, I'd like to talk about it. And if
you'd rather have any of this as ordinary issues on your tracker
instead of one long note, say so and I'll split it up.

Best,
Nathanael (than4213)
