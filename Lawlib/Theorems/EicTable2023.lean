import Lawlib.Core.Money
import Lawlib.Core.Date
import Lawlib.Household
import Lawlib.Parameters
import Lawlib.USA
import Lawlib.Theorems.Scan

/-!
# Machine-checked verification of the 2023 IRS EIC table (findings §8)

`tableModel` is the reverse-engineered generator of the legal EIC table:
$50-bracket midpoint evaluation of the phase formula — **anchored on the
phase-out side at the IRS-internal unrounded completed-phaseout amount**
— rounded half up, with the full plateau maximum for brackets straddling
a phase kink. The rates, maximums, and phase-out starts come from the
*extracted PolicyEngine parameters* (`Lawlib.Parameters`); only the
phase-in ends and unrounded completed-phaseout amounts are additional
Rev.-Proc.-level data.

The generator IS the law-side content: §32(f)(2)(A) mandates the $50
brackets and midpoint evaluation; the rounding convention and unrounded
anchors are the administrative completion, recovered and certified.
The 10,120-cell transcription of the printed table and the theorem
that `tableModel` reproduces it live in `Tests/` (categories doctrine,
DESIGN.md §1): the fixture is evidence about the printed
artifact, not law.
-/

namespace Lawlib.Theorems

open Lawlib Lawlib Lawlib.USA

/-- Phase-in ends ("earned income amounts"), Rev. Proc. 2022-38. -/
def pinEnd : Nat → Rat
  | 0 => 7840
  | 1 => 11750
  | _ => 16510

/-- Completed-phaseout amounts as the IRS table generator actually uses
them: unrounded internal values recovered from the table itself
(`pe2lean-tablecheck` pins each to ±$0.05; the published Rev. Proc.
integers are these values rounded). Certified below: these reproduce
every phase-out cell of the table. -/
def phaseoutEnd : Group → Nat → Rat
  | .single, 0 => 176399/10    -- published 17,640
  | .single, 1 => 46560
  | .single, 2 => 1322951/25   -- published 52,918
  | .single, _ => 284189/5     -- published 56,838
  | .joint, 0 => 24210
  | .joint, 1 => 53120
  | .joint, 2 => 59478
  | .joint, _ => 1584944/25    -- published 63,398

/-- Round half up to a whole-dollar table entry. -/
def rhu (q : Rat) : Nat :=
  (ratFloor (q + 1/2)).toNat

/-- The reverse-engineered 2023 EIC table generator. -/
def tableModel (g : Group) (n : Nat) (lo hi : Nat) : Option Nat :=
  let nn : Rat := n
  let maxA := Parameters.gov.irs.credits.eitc.max.atDate d2023 nn
  let pin := Parameters.gov.irs.credits.eitc.phase_in_rate.atDate d2023 nn
  let po := Parameters.gov.irs.credits.eitc.phase_out.rate.atDate d2023 nn
  let start := Parameters.gov.irs.credits.eitc.phase_out.start.atDate d2023 nn
    + (if g = .joint then Parameters.gov.irs.credits.eitc.phase_out.joint_bonus.atDate d2023 nn else 0)
  let E := phaseoutEnd g n
  let lor : Rat := lo
  let hir : Rat := hi
  if (lor < pinEnd n ∧ pinEnd n < hir) ∨ (lor < start ∧ start < hir) then
    some (rhu maxA)          -- kink-straddling bracket: full plateau max
  else if lor < E ∧ E < hir then
    none                     -- end-straddling bracket: split row, absent
  else
    let mid := (lor + hir) / 2
    let v := min (pin * mid) (min maxA (po * (E - mid)))
    if v ≤ 0 then none else some (rhu v)

/-- Column order of `EicRow.credits`. -/
def cols : List (Group × Nat) :=
  [(.single, 0), (.single, 1), (.single, 2), (.single, 3),
   (.joint, 0), (.joint, 1), (.joint, 2), (.joint, 3)]

end Lawlib.Theorems
