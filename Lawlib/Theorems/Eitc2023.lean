import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Mathlib.Topology.Instances.Rat
import Mathlib.Topology.Order.Lattice
import Lawlib.Verify.EicTable2023

/-!
# Structural theorems about the translated EITC (Phase 2)

∀-quantified statements over *earned income as a real quantity* — the
symbolic upgrade of the M6 grid scan. Everything is proved against the
**generated** definitions (`Lawlib.Gen...eitc`) on the canonical scan
household (`Verify.mkTaxUnit`), so a re-extraction that changes the
encoded law breaks these proofs — which is the point: failed proofs
localize semantic change.

Structure: every (filing group × child count) cell of the 2023 EITC
provably equals one **statutory trapezoid** `trap M P R S` (maximum,
phase-in rate, phase-out rate, phase-out start — constants from the
extracted parameters). The trapezoid's properties are proved once,
abstractly, and instantiated per cell:

* continuous in earned income — the machine-checked form of "the EITC
  credit function has no cliffs" (M6 found none on a grid; this holds
  at every rational income);
* monotone from $0 through the end of the plateau;
* identically zero at and beyond the exact statutory completed
  phase-out `S + M/R`;
* never negative.
-/

namespace Lawlib.Theorems

open Lawlib Lawlib.Verify Lawlib.Gen Lawlib.Gen.Gov.Irs.Credits.Eitc

/-! ## The statutory trapezoid, abstractly -/

/-- Phase-in at rate `P` to maximum `M`, plateau, then phase-out at rate
`R` starting at income `S`. -/
def trap (M P R S : Rat) (x : Rat) : Rat :=
  min (min M (max 0 x * P)) (max 0 (M - R * max 0 (max 0 x - S)))

theorem trap_nonneg {M P : Rat} (hM : 0 ≤ M) (hP : 0 ≤ P) (R S x : Rat) :
    0 ≤ trap M P R S x :=
  le_min (le_min hM (mul_nonneg (le_max_left 0 x) hP)) (le_max_left 0 _)

theorem trap_monotone_below {M P R S x y : Rat}
    (hx : 0 ≤ x) (hxy : x ≤ y) (hy : y ≤ S) (hP : 0 ≤ P) :
    trap M P R S x ≤ trap M P R S y := by
  unfold trap
  rw [max_eq_right hx, max_eq_right (hx.trans hxy),
      max_eq_left (by linarith : x - S ≤ 0),
      max_eq_left (by linarith : y - S ≤ 0)]
  exact min_le_min (min_le_min le_rfl (mul_le_mul_of_nonneg_right hxy hP)) le_rfl

theorem trap_zero_beyond {M P R S x : Rat}
    (hM : 0 ≤ M) (hP : 0 ≤ P) (hR : 0 < R) (hS : 0 ≤ S)
    (hx : S + M / R ≤ x) : trap M P R S x = 0 := by
  have hMR : 0 ≤ M / R := div_nonneg hM hR.le
  have h0 : (0 : Rat) ≤ x := by linarith
  have hRS : M ≤ R * (x - S) := by
    have := (div_le_iff₀ hR).mp (by linarith : M / R ≤ x - S)
    linarith
  unfold trap
  rw [max_eq_right h0, max_eq_right (by linarith : (0 : Rat) ≤ x - S),
      max_eq_left (by linarith : M - R * (x - S) ≤ 0)]
  exact min_eq_right (le_min hM (mul_nonneg h0 hP))

theorem trap_continuous (M P R S : Rat) : Continuous (trap M P R S) := by
  unfold trap
  fun_prop

/-! ## Each 2023 cell is a trapezoid

Closed-form lemmas: the generated 24-definition chain, unfolded through
the concrete parameter tables, equals `trap` at the cell's statutory
constants. -/

section ClosedForms

/-- Unfold the full translated chain and the parameter tables. -/
macro "eitc_normalize" : tactic =>
  `(tactic| (
    simp only [pe, mkTaxUnit, eitc, eitc_eligible,
      eitc_investment_income_eligible, eitc_demographic_eligible,
      filer_meets_eitc_identification_requirements,
      meets_eitc_identification_requirements, eitc_relevant_investment_income,
      eitc_child_count, eitc_maximum, eitc_phase_in_rate, eitc_phase_out_rate,
      eitc_phase_out_start, eitc_phased_in, eitc_reduction, eitc_earned_income,
      is_qualifying_child_dependent, is_tax_unit_dependent,
      is_tax_unit_head_or_spouse, is_full_time_student, is_in_k12_school,
      tax_unit_is_joint, net_capital_gains, long_term_capital_gains,
      self_employment_tax_ald_person, sumBy, anyBy, boolToRat, trap]
    simp +decide [DatedParam.atDate, DatedParam.atDate.go, Scale.atDate,
      ExtRat.leCap,
      Params.gov.irs.dependent.ineligible_age.student,
      Params.gov.irs.dependent.ineligible_age.non_student,
      Params.gov.irs.credits.eitc.max,
      Params.gov.irs.credits.eitc.phase_in_rate,
      Params.gov.irs.credits.eitc.phase_out.rate,
      Params.gov.irs.credits.eitc.phase_out.start,
      Params.gov.irs.credits.eitc.phase_out.joint_bonus,
      Params.gov.irs.credits.eitc.phase_out.max_investment_income,
      Params.gov.irs.credits.eitc.eligibility.age.min,
      Params.gov.irs.credits.eitc.eligibility.age.min_student,
      Params.gov.irs.credits.eitc.eligibility.age.max,
      d2023]
    norm_num [Rat.mkRat_eq_div]))

theorem single0_closed : pe .single 0 = trap 600 (153/2000) (153/2000) 9800 := by
  funext x; eitc_normalize

theorem single1_closed : pe .single 1 = trap 3995 (17/50) (799/5000) 21560 := by
  funext x; eitc_normalize

theorem single2_closed : pe .single 2 = trap 6604 (2/5) (1053/5000) 21560 := by
  funext x; eitc_normalize

theorem single3_closed : pe .single 3 = trap 7430 (9/20) (1053/5000) 21560 := by
  funext x; eitc_normalize

theorem joint0_closed : pe .joint 0 = trap 600 (153/2000) (153/2000) 16370 := by
  funext x; eitc_normalize

theorem joint1_closed : pe .joint 1 = trap 3995 (17/50) (799/5000) 28120 := by
  funext x; eitc_normalize

theorem joint2_closed : pe .joint 2 = trap 6604 (2/5) (1053/5000) 28120 := by
  funext x; eitc_normalize

theorem joint3_closed : pe .joint 3 = trap 7430 (9/20) (1053/5000) 28120 := by
  funext x; eitc_normalize

end ClosedForms

/-! ## The theorems, instantiated for every 2023 cell -/

/-- **EITC is a continuous function of earned income** in every cell:
the credit function itself has no cliffs — M6's empirical grid result,
now at every rational income. -/
theorem eitc_continuous :
    ∀ g n, n ≤ 3 → Continuous (pe g n) := by
  rintro (_ | _) (_ | _ | _ | _ | n) h
  · exact single0_closed ▸ trap_continuous ..
  · exact single1_closed ▸ trap_continuous ..
  · exact single2_closed ▸ trap_continuous ..
  · exact single3_closed ▸ trap_continuous ..
  · omega
  · exact joint0_closed ▸ trap_continuous ..
  · exact joint1_closed ▸ trap_continuous ..
  · exact joint2_closed ▸ trap_continuous ..
  · exact joint3_closed ▸ trap_continuous ..
  · omega

/-- EITC is never negative, in every cell. -/
theorem eitc_nonneg :
    ∀ g n, n ≤ 3 → ∀ x : Rat, 0 ≤ pe g n x := by
  rintro (_ | _) (_ | _ | _ | _ | n) h x
  · exact single0_closed ▸ trap_nonneg (by norm_num) (by norm_num) ..
  · exact single1_closed ▸ trap_nonneg (by norm_num) (by norm_num) ..
  · exact single2_closed ▸ trap_nonneg (by norm_num) (by norm_num) ..
  · exact single3_closed ▸ trap_nonneg (by norm_num) (by norm_num) ..
  · omega
  · exact joint0_closed ▸ trap_nonneg (by norm_num) (by norm_num) ..
  · exact joint1_closed ▸ trap_nonneg (by norm_num) (by norm_num) ..
  · exact joint2_closed ▸ trap_nonneg (by norm_num) (by norm_num) ..
  · exact joint3_closed ▸ trap_nonneg (by norm_num) (by norm_num) ..
  · omega

/-- Monotone from $0 through the end of the plateau (phase-out starts:
single $9,800 childless / $21,560 with children; MFJ $16,370 / $28,120). -/
theorem single0_monotone {x y : Rat} (hx : 0 ≤ x) (hxy : x ≤ y) (hy : y ≤ 9800) :
    pe .single 0 x ≤ pe .single 0 y :=
  single0_closed ▸ trap_monotone_below hx hxy hy (by norm_num)

theorem single1_monotone {x y : Rat} (hx : 0 ≤ x) (hxy : x ≤ y) (hy : y ≤ 21560) :
    pe .single 1 x ≤ pe .single 1 y :=
  single1_closed ▸ trap_monotone_below hx hxy hy (by norm_num)

theorem single2_monotone {x y : Rat} (hx : 0 ≤ x) (hxy : x ≤ y) (hy : y ≤ 21560) :
    pe .single 2 x ≤ pe .single 2 y :=
  single2_closed ▸ trap_monotone_below hx hxy hy (by norm_num)

theorem single3_monotone {x y : Rat} (hx : 0 ≤ x) (hxy : x ≤ y) (hy : y ≤ 21560) :
    pe .single 3 x ≤ pe .single 3 y :=
  single3_closed ▸ trap_monotone_below hx hxy hy (by norm_num)

theorem joint0_monotone {x y : Rat} (hx : 0 ≤ x) (hxy : x ≤ y) (hy : y ≤ 16370) :
    pe .joint 0 x ≤ pe .joint 0 y :=
  joint0_closed ▸ trap_monotone_below hx hxy hy (by norm_num)

theorem joint1_monotone {x y : Rat} (hx : 0 ≤ x) (hxy : x ≤ y) (hy : y ≤ 28120) :
    pe .joint 1 x ≤ pe .joint 1 y :=
  joint1_closed ▸ trap_monotone_below hx hxy hy (by norm_num)

theorem joint2_monotone {x y : Rat} (hx : 0 ≤ x) (hxy : x ≤ y) (hy : y ≤ 28120) :
    pe .joint 2 x ≤ pe .joint 2 y :=
  joint2_closed ▸ trap_monotone_below hx hxy hy (by norm_num)

theorem joint3_monotone {x y : Rat} (hx : 0 ≤ x) (hxy : x ≤ y) (hy : y ≤ 28120) :
    pe .joint 3 x ≤ pe .joint 3 y :=
  joint3_closed ▸ trap_monotone_below hx hxy hy (by norm_num)

/-- Zero at and beyond the exact statutory completed phase-out
`S + M/R`. The hypotheses are the statutory expressions; e.g. single
childless: $9,800 + $600/0.0765 = $17,643 7/51. Note these are the exact
rationals — the IRS's published (rounded) figures differ by up to a few
dollars, and its internal table generator uses unrounded values
(findings §8). -/
theorem single0_zero_beyond {x : Rat} (hx : 9800 + 600 / (153/2000) ≤ x) :
    pe .single 0 x = 0 :=
  single0_closed ▸
    trap_zero_beyond (by norm_num) (by norm_num) (by norm_num) (by norm_num) hx

theorem single1_zero_beyond {x : Rat} (hx : 21560 + 3995 / (799/5000) ≤ x) :
    pe .single 1 x = 0 :=
  single1_closed ▸
    trap_zero_beyond (by norm_num) (by norm_num) (by norm_num) (by norm_num) hx

theorem single2_zero_beyond {x : Rat} (hx : 21560 + 6604 / (1053/5000) ≤ x) :
    pe .single 2 x = 0 :=
  single2_closed ▸
    trap_zero_beyond (by norm_num) (by norm_num) (by norm_num) (by norm_num) hx

theorem single3_zero_beyond {x : Rat} (hx : 21560 + 7430 / (1053/5000) ≤ x) :
    pe .single 3 x = 0 :=
  single3_closed ▸
    trap_zero_beyond (by norm_num) (by norm_num) (by norm_num) (by norm_num) hx

theorem joint0_zero_beyond {x : Rat} (hx : 16370 + 600 / (153/2000) ≤ x) :
    pe .joint 0 x = 0 :=
  joint0_closed ▸
    trap_zero_beyond (by norm_num) (by norm_num) (by norm_num) (by norm_num) hx

theorem joint1_zero_beyond {x : Rat} (hx : 28120 + 3995 / (799/5000) ≤ x) :
    pe .joint 1 x = 0 :=
  joint1_closed ▸
    trap_zero_beyond (by norm_num) (by norm_num) (by norm_num) (by norm_num) hx

theorem joint2_zero_beyond {x : Rat} (hx : 28120 + 6604 / (1053/5000) ≤ x) :
    pe .joint 2 x = 0 :=
  joint2_closed ▸
    trap_zero_beyond (by norm_num) (by norm_num) (by norm_num) (by norm_num) hx

theorem joint3_zero_beyond {x : Rat} (hx : 28120 + 7430 / (1053/5000) ≤ x) :
    pe .joint 3 x = 0 :=
  joint3_closed ▸
    trap_zero_beyond (by norm_num) (by norm_num) (by norm_num) (by norm_num) hx

end Lawlib.Theorems
