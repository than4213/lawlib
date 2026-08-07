import Lawlib.Theorems.Catala2023

/-!
# Exhaustive comparison of the two §32 encodings

The point results — including the exact 24¢/50¢ divergence — live in
`Catala2023`. This module holds the *exhaustive* check: every whole
dollar of earned income from $0 to $60,000, in eight filing cells, in
exact rational arithmetic. That is 480,008 evaluations of the full
EITC chain and takes roughly 25 minutes, so it is built by the nightly
job rather than on every push (`lake build Tests.CatalaSweep2023`).

Nothing else imports this file; it is a check, not a dependency.
-/

namespace Lawlib.Theorems

open Lawlib Lawlib.Gen.Vars

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


end Lawlib.Theorems
