import Lawlib.Verify.EicTable2023
import Lawlib.Claims

/-!
# QUARANTINED: theorems that evaluate the full generated twin

**Not imported by the library root — do not add an import without
reading this.**

Every `native_decide`/`#eval` that executes the *generated variable
closure* (3,225 defs as of pe2lean v0.8.0) crashes the Lean 4.32.1
runtime: reproducible segfaults with wandering crash sites
(`lean::utf8_char_pos` null-deref, null field reads inside generated
native code), in both the interpreter and precompiled-dynlib
configurations. The same theorems were green at v0.7.1 scale
(1,771 defs) — this is a scale-triggered toolchain bug, not a change in
the twin's semantics (the differential harness still validates the twin
against PolicyEngine with zero mismatches).

Tracked in docs/FINDINGS.md (finding 16). Restore by re-importing this
module from `Lawlib.lean` once either (a) the toolchain bug is fixed
upstream, or (b) pe2lean emits a memoized evaluator (fused let-chain)
that native_decide can execute without the full call-graph closure.

Also quarantined for the same reason (whole modules, still on disk,
unimported): `Lawlib/Theorems/Eitc2023.lean`,
`Lawlib/Theorems/Ctc2023.lean`, `Lawlib/Verify/Catala2023.lean`.
-/

namespace Lawlib.Verify

open Lawlib Lawlib.Gen Lawlib.Claims

/-- PolicyEngine's smooth EITC formula never differs from the legal
(table) credit by more than $11.50, anywhere in any bracket. -/
theorem pe_within_1150_of_table :
    Gen.Irs.eicTable2023.all (rowDevOk (23/2)) = true := by
  native_decide

/-- The $11.50 bound is sharp: earned income $50, three children. -/
theorem pe_table_gap_reaches_1150 :
    rabs (pe .single 3 50 - 34) = 23/2 := by
  native_decide

/-- At bracket midpoints the gap is at most $5.297. -/
theorem pe_within_530_at_midpoints :
    Gen.Irs.eicTable2023.all (rowDevOkMid (5297/1000)) = true := by
  native_decide


/-- Under the transcription claim, the translated PolicyEngine formula
is within $11.50 of the credit the **real table** prescribes, at every
bracket edge and midpoint (interior: T1 `pe_within_1150_of_table`). -/
theorem pe_formula_within_1150_of_real_table (h : claim_table_transcription) :
    irsEicTable2023.all (rowDevOk (23/2)) = true := by
  rw [h]; exact pe_within_1150_of_table

/-- Under both claims, **executed PolicyEngine itself** — not merely our
translation of it — pays within 2¢ of the real table's prescribed
credit for a single parent of one child at the $20,000–$20,050
bracket's midpoint (real-table value $3,995, via the transcription; the
translation equals it exactly there, T1). -/
theorem pe_executed_matches_real_table_at_20k
    (ht : claim_table_transcription) (hw : claim_pe_twin_eitc) :
    rabs (peEitcExecuted .single 1 20025 - 3995) ≤ 1/50 := by
  have hpe : pe .single 1 20025 = 3995 := by native_decide
  have hb :=
    (show ∀ g n x, 0 ≤ x → rabs (peEitcExecuted g n x - pe g n x) ≤ 1/50
      from hw) .single 1 20025 (by positivity)
  rw [hpe] at hb
  exact hb

end Lawlib.Verify
