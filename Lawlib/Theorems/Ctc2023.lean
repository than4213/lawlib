import Lawlib.Theorems.EicTable2023

/-!
# The CTC staircase: a complete cliff atlas (2023)

The contrast theorem to `eitc_continuous`: where the EITC is proven
continuous in earned income (no cliffs, `Theorems.Eitc2023`), the Child
Tax Credit is **discontinuous by statutory design** — §24(b)(2) reduces
the credit "by $50 for each $1,000 (or fraction thereof)" of income
over the threshold, a ceiling-function staircase the extractor
translates via `ratCeil`.

These theorems (by `native_decide`, on the canonical household with AGI
mirroring earned income) don't just show *a* cliff exists — they
enumerate **every** cliff on the whole-dollar grid and prove there are
no others:

* single, 1 child: exactly 40 cliffs of exactly $50, at exactly
  $200,000 + $1,000k for k = 0…39; flat everywhere else on
  $0–$250,000.
* joint, 2 children: exactly 80 cliffs of $50 at $400,000 + $1,000k,
  k = 0…79; flat everywhere else on $0–$500,000.

A symbolic (`¬ContinuousAt`) version awaits the CTC closed-form
normalization (the unfold currently exceeds simp's step budget; the
grid theorem is the stronger statement for the atlas anyway).
-/

namespace Lawlib.Theorems

open Lawlib Lawlib.Theorems Lawlib.Gen Lawlib.Gen.Vars

/-- CTC on the canonical household (all members with TINs/valid SSNs). -/
def peC (g : Group) (n : Nat) (x : Rat) : Rat :=
  ctc (mkTaxUnit g n x) d2023

/-- The dollar-grid jump at `x`: credit at `x+1` minus credit at `x`. -/
def jumpAt (g : Group) (n : Nat) (x : Nat) : Rat :=
  peC g n (x + 1) - peC g n x

/-- A cliff of exactly −$50 must occur at threshold + $1,000·k (while the
credit lasts) and nowhere else. -/
def cliffOk (g : Group) (n : Nat) (threshold last : Nat) (x : Nat) : Bool :=
  if threshold ≤ x && x ≤ last && (x - threshold) % 1000 == 0 then
    jumpAt g n x == -50
  else
    jumpAt g n x == 0

/-- Sanity anchors: the plateau value and the first step down. -/
theorem ctc_single1_first_cliff :
    peC .single 1 200000 = 2000 ∧ peC .single 1 200001 = 1950 := by
  native_decide

/-- **Cliff atlas, single filer, 1 child (2023):** on every whole dollar
of earned income in $0–$250,000, the CTC drops by exactly $50 at
exactly $200,000 + $1,000·k (k = 0…39) and is flat at every other
dollar step. 40 cliffs, fully enumerated. -/
theorem ctc_cliff_atlas_single1 :
    ((List.range 250001).all fun x => cliffOk .single 1 200000 239000 x) = true := by
  native_decide

/-- **Cliff atlas, joint filers, 2 children (2023):** 80 cliffs of $50
at $400,000 + $1,000·k (k = 0…79); flat at every other dollar step in
$0–$500,000. -/
theorem ctc_cliff_atlas_joint2 :
    ((List.range 500001).all fun x => cliffOk .joint 2 400000 479000 x) = true := by
  native_decide

/-- The credit is exhausted exactly at the end of the staircase. -/
theorem ctc_exhausted :
    peC .single 1 240000 = 0 ∧ peC .joint 2 480000 = 0 := by
  native_decide

end Lawlib.Theorems
