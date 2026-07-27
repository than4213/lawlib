# pe2lean rejection report

policyengine-us 1.783.0, roots ['eitc', 'ctc', 'snap', 'ssi', 'aca_ptc'].
121 translated, 117 boundary inputs, 48 rejections.

## Rejections

- **tax_unit_is_required_to_file** (`policyengine_us/variables/gov/irs/tax_unit_is_required_to_file.py:4`): parameter 'gov.irs.income.exemption.suspended' outside emitted subtrees
- **aca_required_contribution_percentage** (`policyengine_us/variables/gov/aca/ptc/aca_required_contribution_percentage.py:6`): np.array
- **is_aca_ptc_eligible** (`policyengine_us/variables/gov/aca/eligibility/is_aca_ptc_eligible.py:8`): calc() on non-scale parameter 'gov.aca.ptc_income_eligibility'
- **filing_status** (`policyengine_us/variables/household/demographic/tax_unit/filing_status.py:7`): unrecognized call select
- **has_tin** (`policyengine_us/variables/household/demographic/person/has_tin.py:2`): attribute 'simulation' on value expression
- **dc_snap_temporary_local_benefit** (`policyengine_us/variables/gov/states/dc/tax/income/dc_snap_temporary_local_benefit.py:6`): parameter 'gov.states.dc.tax.income.snap.temporary_local_benefit.rate' outside emitted subtrees
- **snap_emergency_allotment** (`policyengine_us/variables/gov/usda/snap/snap_emergency_allotment.py:13`): person ref to non-person variable 'state_code'
- **medicaid_magi** (`policyengine_us/variables/gov/hhs/medicaid/income/medicaid_magi.py:4`): add() without literal variable list
- **slcsp_family_tier_amount** (`policyengine_us/variables/gov/aca/slspc/slcsp_family_tier_amount.py:3`): person ref to non-person variable 'slcsp_age_0'
- **is_tax_unit_head** (`policyengine_us/variables/household/demographic/tax_unit/is_tax_unit_head.py:5`): attribute 'tax_unit' on value expression
- **is_tax_unit_spouse** (`policyengine_us/variables/household/demographic/tax_unit/is_tax_unit_spouse.py:7`): attribute 'tax_unit' on value expression
- **snap_expected_contribution** (`policyengine_us/variables/gov/usda/snap/snap_expected_contribution.py:6`): np.floor
- **snap_max_allotment** (`policyengine_us/variables/gov/usda/snap/snap_max_allotment.py:4`): person ref to non-person variable 'snap_region_str'
- **snap_min_allotment** (`policyengine_us/variables/gov/usda/snap/snap_min_allotment.py:7`): person ref to non-person variable 'snap_region_str'
- **ssi_earned_income_deemed_from_ineligible_spouse** (`policyengine_us/variables/gov/ssa/ssi/eligibility/income/deemed/from_ineligible_spouse/ssi_earned_income_deemed_from_ineligible_spouse.py:6`): attribute 'marital_unit' on value expression
- **ssi_amount_if_eligible** (`policyengine_us/variables/gov/ssa/ssi/ssi_amount_if_eligible.py:38`): unbound name 'SSIFederalLivingArrangement'
- **ssi_countable_income** (`policyengine_us/variables/gov/ssa/ssi/eligibility/income/ssi_countable_income.py:23`): non-value handle used as value
- **pays_aca_premium** (`policyengine_us/variables/gov/aca/eligibility/pays_aca_premium.py:7`): add() without literal variable list
- **slcsp_age_0** (`policyengine_us/variables/gov/aca/slspc/slcsp_age_0.py:12`): unsupported parameter subscript on 'gov.aca.state_rating_area_cost'
- **slcsp_age_curve_multiplier** (`policyengine_us/variables/gov/aca/slspc/slcsp_age_curve_multiplier.py:6`): unrecognized call select
- **self_employment_tax** (`policyengine_us/variables/gov/irs/tax/self_employment/self_employment_tax.py:2`): parameter 'gov.contrib.ubi_center.flat_tax.abolish_self_emp_tax' outside emitted subtrees
- **meets_snap_categorical_eligibility** (`policyengine_us/variables/gov/usda/snap/eligibility/meets_snap_categorical_eligibility.py:3`): unsupported syntax ListComp
- **is_ssi_aged_blind_disabled** (`policyengine_us/variables/gov/ssa/ssi/eligibility/status/is_ssi_aged_blind_disabled.py:2`): attribute 'simulation' on value expression
- **slcsp_family_tier_applies** (`policyengine_us/variables/gov/aca/slspc/slcsp_family_tier_applies.py:3`): person ref to non-person variable 'state_code'
- **ctc_limiting_tax_liability** (`policyengine_us/variables/gov/irs/credits/ctc/refundable/ctc_limiting_tax_liability.py:2`): attribute 'simulation' on value expression
- **ca_snap_immigration_status_eligible** (`policyengine_us/variables/gov/states/ca/cdss/snap/eligibility/ca_snap_immigration_status_eligible.py:6`): isin against non-list param 'gov.states.ca.cdss.snap.eligibility.eligible_immigration_statuses'
- **meets_snap_parent_exception** (`policyengine_us/variables/gov/usda/snap/eligibility/student/meets_snap_parent_exception.py:7`): attribute 'spm_unit' on value expression
- **tanf_person** (`policyengine_us/variables/gov/hhs/tanf/cash/tanf_person.py:2`): attribute 'spm_unit' on value expression
- **capital_gains_behavioral_response** (`policyengine_us/variables/gov/simulation/capital_gains_responses.py:2`): attribute 'simulation' on value expression
- **is_usda_disabled** (`policyengine_us/variables/gov/usda/is_usda_disabled.py:3`): unbound name 'np'
- **is_usda_elderly** (`policyengine_us/variables/gov/usda/is_usda_elderly.py:3`): parameter 'gov.usda.elderly_age_threshold' outside emitted subtrees
- **snap_fpg** (`policyengine_us/variables/gov/usda/snap/income/snap_fpg.py:3`): person ref to non-person variable 'state_group_str'
- **snap_gross_test_income** (`policyengine_us/variables/gov/usda/snap/income/gross/snap_gross_test_income.py:36`): add() without literal variable list
- **is_snap_abawd_hr1_in_effect** (`policyengine_us/variables/gov/usda/snap/eligibility/work_requirements/is_snap_abawd_hr1_in_effect.py:15`): unrecognized call select
- **additional_medicare_tax** (`policyengine_us/variables/gov/irs/tax/federal_income/additional_medicare_tax.py:6`): unsupported parameter subscript on 'gov.irs.payroll.medicare.additional.exclusion'
- **employee_medicare_tax** (`policyengine_us/variables/gov/irs/tax/payroll/medicare/employee_medicare_tax.py:3`): parameter 'gov.irs.payroll.medicare.rate.employee' outside emitted subtrees
- **employee_social_security_tax** (`policyengine_us/variables/gov/irs/tax/payroll/social_security/employee_social_security_tax.py:3`): parameter 'gov.irs.payroll.social_security.rate.employee' outside emitted subtrees
- **snap_excess_medical_expense_deduction** (`policyengine_us/variables/gov/usda/snap/income/deductions/snap_excess_medical_expense_deduction.py:16`): person ref to non-person variable 'state_code_str'
- **snap_excess_shelter_expense_deduction** (`policyengine_us/variables/gov/usda/snap/income/deductions/shelter/snap_excess_shelter_expense_deduction.py:17`): person ref to non-person variable 'snap_region_str'
- **snap_standard_deduction** (`policyengine_us/variables/gov/usda/snap/income/deductions/snap_standard_deduction.py:5`): person ref to non-person variable 'state_group_str'
- **snap_child_support_gross_income_deduction** (`policyengine_us/variables/gov/usda/snap/income/gross/snap_child_support_gross_income_deduction.py:3`): person ref to non-person variable 'state_code_str'
- **snap_unearned_income** (`policyengine_us/variables/gov/usda/snap/income/snap_unearned_income.py:6`): add() without literal variable list
- **snap_income_counted_share** (`policyengine_us/variables/gov/usda/snap/income/ineligible_members/snap_income_counted_share.py:5`): unrecognized call select
- **child_care_subsidies** (`?:0`): adds/subtracts via unknown parameter path 'gov.hhs.ccdf.child_care_subsidy_programs'
- **pre_subsidy_childcare_expenses** (`policyengine_us/variables/household/expense/childcare/pre_subsidy_childcare_expenses.py:4`): attribute 'spm_unit' on value expression
- **spm_unit_size** (`policyengine_us/variables/household/demographic/spm_unit/spm_unit_size.py:2`): unrecognized call spm_unit.nb_persons
- **snap_excluded_child_earner** (`policyengine_us/variables/gov/usda/snap/income/snap_excluded_child_earner.py:2`): non-simple assignment target
- **snap_self_employment_expense_deduction** (`policyengine_us/variables/gov/usda/snap/income/deductions/self_employment/snap_self_employment_expense_deduction.py:7`): person ref to non-person variable 'state_code'

## Pruned (deliberate scope cuts)

- **adjusted_gross_income**: AGI machinery out of Phase-1 subtree scope
- **employment_income**: behavioral-response chain (gov/simulation) out of scope
- **immigration_status**: str->enum conversion formula — enum input
- **loss_limited_net_capital_gains**: capital-loss limitation chain out of scope
- **meets_snap_abawd_work_requirements**: consumes uprated hours inputs — input (findings §11)
- **meets_snap_general_work_requirements**: consumes uprated hours inputs — input (findings §11)
- **net_investment_income**: adds via parameter path — resolve when AGI subtree lands
- **self_employment_income**: behavioral-response chain out of scope
- **snap_gross_self_employment_income_person**: consumes uprated year inputs at month (PE path-dependent; findings §11)
- **sstb_self_employment_income**: behavioral-response chain out of scope
- **takes_up_eitc**: stochastic takeup — input by design
