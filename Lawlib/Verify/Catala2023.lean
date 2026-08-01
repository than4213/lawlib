import Lawlib.Catala.Section32
import Lawlib.Theorems.Eitc2023

/-!
# Catala §32 vs PolicyEngine §32: machine-checked comparison (2023)

`Lawlib.Catala.earnedIncomeCredit` is transpiled from an *independent*
Catala encoding of 26 U.S.C. §32(a)–(b) written from the statute text;
`Lawlib.Verify.pe` is the PolicyEngine-derived encoding. The theorems
below (by `native_decide`):

* pin the transpiled function to the Catala interpreter's own outputs
  at the six test points (transpiler validation);
* bound the gap between the two encodings at every whole-dollar income
  $0–$60,000 in all 8 (filing group × child count) cells — **1 cent**
  for 1 and 2 children (pure cent-rounding), **25/51 cents** for 0 and
  3+ children, where the encodings genuinely diverge (findings §9:
  §32(a)(2)(A)'s literal `credit percentage × earned income amount` is
  $599.76 / $7,429.50, vs the rounded $600 / $7,430 used by
  PolicyEngine, Rev. Proc. 2022-38, and the §32(f) tables);
* exhibit the divergence exactly: 24 cents on the childless plateau,
  50 cents for three children.
-/

namespace Lawlib.Verify

open Lawlib Lawlib.Catala Lawlib.Theorems

/-- Catala encoding at whole-dollar income `x` (both earned and AGI),
in cents. -/
def catalaCents (jr : Bool) (n : Nat) (x : Nat) : Int :=
  earnedIncomeCredit (100 * (x : Int)) (100 * (x : Int)) (n : Int) jr

/-- Interpreter cross-check: the transpiled function reproduces the
Catala interpreter's outputs at the six committed test scopes. -/
theorem catala_transpiler_matches_interpreter :
    catalaCents false 1 10000 = 340000 ∧      -- TestPhaseIn1Child
    catalaCents false 1 20000 = 399500 ∧      -- TestPlateau1Child
    catalaCents false 1 30000 = 264629 ∧      -- TestPhaseOut1Child
    catalaCents false 0 7900 = 59976 ∧        -- TestChildlessPlateau
    catalaCents true 3 20000 = 742950 ∧       -- TestThreeKidsJointPlateau
    catalaCents false 0 17640 = 0 := by       -- TestChildlessZeroPoint
  native_decide

/-- Gap between the encodings at one point, in cents (exact ℚ). -/
def gapCents (g : Group) (jr : Bool) (n : Nat) (x : Nat) : Rat :=
  rabs (100 * pe g n x - (catalaCents jr n x : Rat))

def cellOk (g : Group) (jr : Bool) (n : Nat) (bound : Rat) : Bool :=
  (List.range 60001).all fun x => decide (gapCents g jr n x ≤ bound)

/-- At every whole-dollar earned income $0–$60,000: the independent
encodings agree to the cent where §32's arithmetic is unambiguous
(1 and 2 children), and differ by at most 25¢ / 51¢ where the statute
and administered practice disagree (0 / 3+ children, findings §9). -/
theorem catala_vs_pe_bounded :
    (cellOk .single false 0 25 && cellOk .single false 1 1 &&
     cellOk .single false 2 1 && cellOk .single false 3 51 &&
     cellOk .joint true 0 25 && cellOk .joint true 1 1 &&
     cellOk .joint true 2 1 && cellOk .joint true 3 51) = true := by
  native_decide

/-- The divergence is exact: on the childless plateau, PolicyEngine
pays 24 cents more than the literal statutory formula. -/
theorem plateau_gap_childless :
    100 * pe .single 0 7900 - (catalaCents false 0 7900 : Rat) = 24 := by
  native_decide

/-- …and 50 cents more with three children. -/
theorem plateau_gap_three_children :
    100 * pe .joint 3 20000 - (catalaCents true 3 20000 : Rat) = 50 := by
  native_decide

end Lawlib.Verify
