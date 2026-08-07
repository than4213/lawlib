import Tests.EicTableCheck2023

/-!
# Claims: the bridge from committed data to reality

Uncertainty management in the Claimlib style (claims-as-Props): every
statement lawlib cannot *prove* is a named `Prop` **object** — never
asserted, so `#print axioms` stays clean for the whole library — and
every downstream result that depends on one takes it as an explicit
hypothesis. What the kernel certifies is the *conditional*; how much to
believe the hypothesis is an evidence question, graded in
[docs/CLAIMS.md](../docs/CLAIMS.md) and eventually scored by a claim
registry.

The pattern (from Claimlib's design):
* `opaque` — reality's symbols: the actual printed IRS table, actual
  PolicyEngine behavior. Valueless vocabulary.
* `def claim_* : Prop := …` — a statement *about* those symbols.
  Evidence tier lives in the docstring, not in the kernel.
* `theorem … (h : claim_*) : …` — certified conditionals; the
  machine-checked interior results compose with claims into statements
  about the world.

Tiers used in docstrings (T0 strongest):
T0 kernel theorem · T1 `native_decide` theorem · T2 differential
evidence · T3 tool-verified transcription · T4 probe/observation ·
T5 conjecture (best guess, awaiting resources).
-/

namespace Lawlib.Claims

open Lawlib Lawlib.Gen Lawlib.Theorems

/-! ## Observable vocabulary (reality's symbols) -/

/-- The 2023 Earned Income Credit table as actually printed in the IRS
Form 1040 instructions (irs.gov `i1040gi--2023.pdf`, sha256
`90c8759c…`), in the row shape of `Gen.Irs.EicRow`. An abstract symbol:
lawlib holds a *transcription* of it, not the thing itself. -/
opaque irsEicTable2023 : Array Gen.Irs.EicRow

/-- PolicyEngine US 1.783.0's EITC as executed by its Simulation API on
the canonical household domain (`Theorems.mkTaxUnit`): filing group,
children, earned income (= AGI) ↦ credit in dollars. -/
opaque peEitcExecuted : Group → Nat → Rat → Rat

/-! ## Claims -/

/-- **Transcription claim** (tier T3 — tool-verified): the committed
table data equals the printed table. Evidence: parsed by
`pe2lean-tablecheck` from the PDF's text layer with coordinate-based
extraction; 1,265 of 1,267 rows (the 2 footnoted split rows at
phase-out ends are absent from the transcription, see findings §8);
independently consistent with the reverse-engineered generator on all
10,120 cells (T1). Firms up by: independent re-transcription, or IRS
publishing machine-readable tables. -/
def claim_table_transcription : Prop :=
  irsEicTable2023 = Gen.Irs.eicTable2023

/-- **Twin claim, EITC** (tier T2 — differential): on the canonical
domain, executed PolicyEngine agrees with the translated `eitc` to
within a cent. Evidence: 100,000 randomized+adversarial households per
night across 2021–2025, zero mismatches beyond float32 tolerance
(max observed delta $0.0159, findings §1/§6). Firms up by: more years,
more adversarial structure; can never reach T0 from outside PE. -/
def claim_pe_twin_eitc : Prop :=
  ∀ g n x, 0 ≤ x → rabs (peEitcExecuted g n x - pe g n x) ≤ 1/50

/-! ## Certified conditionals: interior theorems composed with claims
become statements about the world -/

/-- Under the transcription claim, the reverse-engineered generator
reproduces every cell of the **real printed table** (interior: T1
`eic_table_2023_generator_verified`). Further certified conditionals
(`pe_formula_within_1150_of_real_table`,
`pe_executed_matches_real_table_at_20k`) live in
`Verify/PeTable2023.lean` pending a Lean toolchain fix. -/
theorem real_table_generator (h : claim_table_transcription) :
    irsEicTable2023.all rowOk = true := by
  rw [h]; exact eic_table_2023_generator_verified

end Lawlib.Claims
