import Lawlib.Theorems.EicTable2023
import Tests.Claims

/-!
# PE-formula vs table theorems (evaluated via the memoized evaluator)

Grid theorems are stated over `Theorems.peM` — the fused evaluator in
`Lawlib.Evaluator` — because per-variable evaluation recomputes shared
dependencies (finding 17). Formerly quarantined behind the Lean
≥156-field `FromJson` codegen bug (finding 16, now worked around by
capping generated structures at 128 fields).
-/

namespace Lawlib.Theorems

open Lawlib Lawlib.Claims Tests.EicTable

/-- PolicyEngine's smooth EITC formula never differs from the legal
(table) credit by more than $11.50, anywhere in any bracket. -/
theorem pe_within_1150_of_table :
    eicTable2023.all (rowDevOk (23/2)) = true := by
  native_decide

/-- The $11.50 bound is sharp: earned income $50, three children.
(Stated over `peM`, the memoized evaluator — see `Theorems.Scan`.) -/
theorem pe_table_gap_reaches_1150 :
    rabs (peM .single 3 50 - 34) = 23/2 := by
  native_decide

/-- At bracket midpoints the gap is at most $5.297. -/
theorem pe_within_530_at_midpoints :
    eicTable2023.all (rowDevOkMid (5297/1000)) = true := by
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
      from hw) .single 1 20025 (by decide)
  rw [hpe] at hb
  exact hb

end Lawlib.Theorems
