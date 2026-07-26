# pe2lean rejection report

policyengine-us 1.783.0, root `eitc`.
24 translated, 24 boundary inputs, 6 rejections.

## Rejections

- **tax_unit_is_required_to_file** (`policyengine_us/variables/gov/irs/tax_unit_is_required_to_file.py:4`): parameter 'gov.irs.income.exemption.suspended' outside emitted subtrees
- **filing_status** (`policyengine_us/variables/household/demographic/tax_unit/filing_status.py:7`): unrecognized call select
- **is_tax_unit_head** (`policyengine_us/variables/household/demographic/tax_unit/is_tax_unit_head.py:5`): attribute 'tax_unit' on value expression
- **is_tax_unit_spouse** (`policyengine_us/variables/household/demographic/tax_unit/is_tax_unit_spouse.py:3`): attribute 'tax_unit' on value expression
- **self_employment_tax** (`policyengine_us/variables/gov/irs/tax/self_employment/self_employment_tax.py:2`): parameter 'gov.contrib.ubi_center.flat_tax.abolish_self_emp_tax' outside emitted subtrees
- **capital_gains_behavioral_response** (`policyengine_us/variables/gov/simulation/capital_gains_responses.py:2`): attribute 'simulation' on value expression

## Pruned (deliberate scope cuts)

- **adjusted_gross_income**: AGI machinery out of Phase-1 subtree scope
- **employment_income**: behavioral-response chain (gov/simulation) out of scope
- **loss_limited_net_capital_gains**: capital-loss limitation chain out of scope
- **net_investment_income**: adds via parameter path — resolve when AGI subtree lands
- **self_employment_income**: behavioral-response chain out of scope
- **sstb_self_employment_income**: behavioral-response chain out of scope
- **takes_up_eitc**: stochastic takeup — input by design
