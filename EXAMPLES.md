# Examples

Three things you can do with this library: compute a household, read a
rule, and prove something about it. Every output below was produced by
the commands as written.

Build first (see the README for how long the first build takes):

```
lake build && lake build lawlib
```

## 1. Compute a household

The evaluator reads one JSON household per line and writes one line of
results. Fields you omit take their default, so you send only what you
mean:

```
echo '{"date":"2023-01-01","tax_unit":{"members":[{"core_p1":{"age":"30/1","employment_income":"20000/1","is_tax_unit_head":true}}],"core":{"filing_status":"SINGLE"},"irs":{"takes_up_eitc":true}}}' | ./.lake/build/bin/lawlib
```

A single filer, age 30, $20,000 of wages, 2023. Among the results:

| variable | value | why |
|---|---|---|
| `adjusted_gross_income` | 20000 | no above-the-line deductions were set |
| `taxable_income` | 6150 | $20,000 − the $13,850 standard deduction |
| `income_tax` | 615 | 10% of $6,150 — the first bracket |
| `eitc` | 0 | a childless filer at $20,000 is past the phase-out |

Money is exact, so amounts are fractions on the way in and out:
`"20000/1"` becomes `"615/1"`.

## 2. Watch a credit appear

Add a child and tell the model this household would file a return:

```
echo '{"date":"2023-01-01","tax_unit":{"members":[{"core_p1":{"age":"30/1","employment_income":"20000/1","is_tax_unit_head":true}},{"core_p1":{"age":"8/1","is_tax_unit_dependent":true}}],"core":{"filing_status":"HEAD_OF_HOUSEHOLD"},"irs":{"takes_up_eitc":true,"would_file_if_eligible_for_refundable_credit":true}}}' | ./.lake/build/bin/lawlib
```

Now `eitc` is **3995** — exactly the 2023 maximum for one child, because
$20,000 sits on the credit's plateau — and `income_tax` is **−3995**:
the credit is refundable, so the household is owed money.

That second flag matters. The Earned Income Credit is only paid on a
filed return, so the translated law gates the credit on filing. Leave
`would_file_if_eligible_for_refundable_credit` unset and it defaults to
false, and you get $0 with everything else looking correct — the
computation is right, the household simply never filed. Every input a
household may set is listed in `EXTRACTION_MANIFEST.json` under
`input_boundary`.

## 3. Read a rule

Every definition is ordinary Lean, carrying the source it came from:

```lean
/-- `policyengine_us/variables/gov/irs/credits/earned_income/eitc_reduction.py`
    policyengine-us 1.783.0, entity tax_unit, value_type float. -/
def eitc_reduction (t : TaxUnit) (d : Date) : Rat :=
  (eitc_phase_out_rate t d) *
    (max 0 ((max (eitc_earned_income t d) (adjusted_gross_income t d))
            - (eitc_phase_out_start t d)))
```

In an editor with the Lean extension, open
[`Lawlib/Theorems/Eitc2023.lean`](Lawlib/Theorems/Eitc2023.lean) and
jump to definitions from there: it proves the credit's closed form, so
following its references walks you down into the translated law.

## 4. Prove something

The theorems are ordinary Lean proofs about those definitions. This one
says the Earned Income Credit has no benefit cliffs — the credit moves
continuously with income, so no dollar earned ever costs a household
more than it gains:

```lean
theorem eitc_continuous : ∀ g n, n ≤ 3 → Continuous (pe g n)
```

The Child Tax Credit, by contrast, really does have cliffs, and
[`Lawlib/Theorems/Ctc2023.lean`](Lawlib/Theorems/Ctc2023.lean)
enumerates every one of them.

To state your own claim, import `Lawlib` and write it. If the proof
goes through, it is a fact about the law; if it does not, you have
found either a subtlety or a bug, and both are worth an issue.

## 5. Check that nothing broke

```
lake test
```

builds the test layer: the transcribed IRS table, the claims about it,
and the theorems that check the law against them. The cross-check
against a live PolicyEngine needs Python and lives in the translator
repository — see `scripts/verify` in
[pe2lean](https://github.com/than4213/pe2lean).
