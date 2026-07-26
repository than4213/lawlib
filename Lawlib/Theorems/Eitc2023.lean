import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Lawlib.Verify.EicTable2023

/-!
# Structural theorems about the translated EITC (Phase 2)

∀-quantified statements over *earned income as a real quantity* — the
symbolic upgrade of the M6 grid scan. Everything is proved against the
**generated** definitions (`Lawlib.Gen...eitc`) on the canonical scan
household (`Verify.mkTaxUnit`), so a re-extraction that changes the
encoded law breaks these proofs — which is the point: failed proofs
localize semantic change.

First cell: single filer, one qualifying child, tax year 2023.
Statutory constants (from the extracted parameters): phase-in rate 34%,
maximum $3,995, phase-out start $21,560, phase-out rate 15.98%, exact
completed phase-out $21,560 + $3,995/0.1598 = $46,560.
-/

namespace Lawlib.Theorems

open Lawlib Lawlib.Verify Lawlib.Gen Lawlib.Gen.Gov.Irs.Credits.Eitc

/-- Closed form of the generated EITC on the canonical (single, 1 child)
household: the statutory trapezoid. Proved by unfolding the whole
translated chain and the concrete parameter tables. -/
theorem pe_single1_closed (x : Rat) :
    pe .single 1 x =
      min (min 3995 (max 0 x * (17/50)))
        (max 0 (3995 - 799/5000 * max 0 (max 0 x - 21560))) := by
  simp only [pe, mkTaxUnit, eitc, eitc_eligible,
    eitc_investment_income_eligible, eitc_demographic_eligible,
    filer_meets_eitc_identification_requirements,
    meets_eitc_identification_requirements, eitc_relevant_investment_income,
    eitc_child_count, eitc_maximum, eitc_phase_in_rate, eitc_phase_out_rate,
    eitc_phase_out_start, eitc_phased_in, eitc_reduction, eitc_earned_income,
    is_qualifying_child_dependent, is_tax_unit_dependent,
    is_tax_unit_head_or_spouse, is_full_time_student, is_in_k12_school,
    tax_unit_is_joint, net_capital_gains, long_term_capital_gains,
    self_employment_tax_ald_person, sumBy, anyBy, boolToRat]
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
  norm_num [Rat.mkRat_eq_div]

/-- EITC is monotone in earned income from $0 through the end of the
plateau (phase-in and plateau regions). -/
theorem pe_single1_monotone_below_phaseout {x y : Rat}
    (hx : 0 ≤ x) (hxy : x ≤ y) (hy : y ≤ 21560) :
    pe .single 1 x ≤ pe .single 1 y := by
  rw [pe_single1_closed, pe_single1_closed,
      max_eq_right hx, max_eq_right (hx.trans hxy),
      max_eq_left (by linarith : x - 21560 ≤ 0),
      max_eq_left (by linarith : y - 21560 ≤ 0)]
  exact min_le_min (min_le_min le_rfl (by linarith)) le_rfl

/-- EITC is identically zero at and beyond the exact statutory completed
phase-out ($46,560 for single, one child, 2023). -/
theorem pe_single1_zero_beyond_phaseout {x : Rat} (hx : 46560 ≤ x) :
    pe .single 1 x = 0 := by
  have h0 : (0 : Rat) ≤ x := by linarith
  rw [pe_single1_closed, max_eq_right h0,
      max_eq_right (by linarith : (0 : Rat) ≤ x - 21560),
      max_eq_left (by linarith : 3995 - 799/5000 * (x - 21560) ≤ 0)]
  exact min_eq_right (le_min (by norm_num) (mul_nonneg h0 (by norm_num)))

/-- EITC is never negative. -/
theorem pe_single1_nonneg (x : Rat) : 0 ≤ pe .single 1 x := by
  rw [pe_single1_closed]
  exact le_min
    (le_min (by norm_num) (mul_nonneg (le_max_left 0 x) (by norm_num)))
    (le_max_left 0 _)

end Lawlib.Theorems
