import Lawlib.Claims

/-!
# Quarantined axiom shadow (registry probe target — import nothing from here)

One `axiom` per live claim Prop. **No module in the library imports
this file** (CI-enforced); the library proper stays axiom-free and
every downstream theorem takes claims as explicit hypotheses. This leaf
exists solely as the consistency-probe target for a claims registry
(Claimlib): with the claims *asserted*, the kernel's ambient gate can
*discover* joint inconsistency — any proof in the asserted environment
that derives `False` is a machine-found contradiction among the claims
(cf. finding 9, where "the table matches the statute formula" and "the
table matches the transcription" differ by 50¢ and cannot both hold).

Mechanically derivable from `Lawlib/Claims.lean`: one line per claim.
Keep it a *minimal generating set* — never assert a derivable value
(chisel-claims lesson; docs/FINDINGS.md, internal lessons).
-/

namespace Lawlib.Claims.Asserted

axiom claim_table_transcription_asserted : claim_table_transcription

axiom claim_pe_twin_eitc_asserted : claim_pe_twin_eitc

end Lawlib.Claims.Asserted
