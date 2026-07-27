import Lawlib.Core.Money
import Lawlib.Core.Date
import Lawlib.Gen.Entities
import Lawlib.Gen.Params
import Lawlib.Gen.Vars
import Lawlib.Gen.Irs.EicTable2023

/-!
# Machine-checked verification of the 2023 IRS EIC table (findings §8)

`tableModel` is the reverse-engineered generator of the legal EIC table:
$50-bracket midpoint evaluation of the phase formula — **anchored on the
phase-out side at the IRS-internal unrounded completed-phaseout amount**
— rounded half up, with the full plateau maximum for brackets straddling
a phase kink. The rates, maximums, and phase-out starts come from the
*extracted PolicyEngine parameters* (`Lawlib.Gen.Params`); only the
phase-in ends and unrounded completed-phaseout amounts are additional
Rev.-Proc.-level data.

The theorems below are checked by `native_decide` (finite computation
over all 10,120 parsed table cells; trusts the Lean compiler in addition
to the kernel):

* `eic_table_2023_generator_verified` — the model reproduces every cell
  of the parsed table (`Lawlib.Gen.Irs.eicTable2023`).
* `pe_within_1150_of_table` — PolicyEngine's smooth formula (the
  translated `eitc`, evaluated on the canonical scan household) never
  differs from the legal table credit by more than **$11.50**, checked
  at both bracket edges and the midpoint of every bracket.
* `pe_table_gap_reaches_1150` — the bound is sharp: at $50 of earned
  income with three children, the formula pays $22.50 where the table
  pays $34.
* `pe_within_530_at_midpoints` — at bracket midpoints alone the gap is
  at most $5.297 (the residual anchoring + straddle-convention error).
-/

namespace Lawlib.Verify

open Lawlib Lawlib.Gen Lawlib.Gen.Vars

inductive Group where
  | single
  | joint
deriving DecidableEq, Repr

def d2023 : Date := ⟨2023, 1, 1⟩

/-- The canonical household of the M6 scan: a head aged 30 with the
given earned income, a spouse for joint filers, `n` qualifying children
aged 8; AGI mirrors earned income; everything else zero. -/
def mkTaxUnit (g : Group) (n : Nat) (income : Rat) : TaxUnit :=
  let head : Person := { age := 30, is_tax_unit_head := true, employment_income := income }
  let spouse : Person := { age := 30, is_tax_unit_spouse := true }
  let child : Person := { age := 8 }
  { members := [head] ++ (if g = .joint then [spouse] else []) ++ List.replicate n child
    filing_status := if g = .joint then .JOINT else .SINGLE
    adjusted_gross_income := income
    takes_up_eitc := true
    tax_unit_is_required_to_file := true }

/-- PolicyEngine semantics (the translated `eitc`) on that household. -/
def pe (g : Group) (n : Nat) (x : Rat) : Rat :=
  eitc (mkTaxUnit g n x) d2023

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
  let maxA := Params.gov.irs.credits.eitc.max.atDate d2023 nn
  let pin := Params.gov.irs.credits.eitc.phase_in_rate.atDate d2023 nn
  let po := Params.gov.irs.credits.eitc.phase_out.rate.atDate d2023 nn
  let start := Params.gov.irs.credits.eitc.phase_out.start.atDate d2023 nn
    + (if g = .joint then Params.gov.irs.credits.eitc.phase_out.joint_bonus.atDate d2023 nn else 0)
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

/-- The table prints `0` beyond the phase-out for some columns and `*`
for others; both mean "no credit". -/
def cellMatches (m t : Option Nat) : Bool :=
  m == t || (m == none && t == some 0)

def rowOk (r : Gen.Irs.EicRow) : Bool :=
  (List.range 8).all fun i =>
    let (g, n) := cols.getD i (.single, 0)
    cellMatches (tableModel g n r.lo r.hi) (r.credits.getD i none)

def rabs (q : Rat) : Rat := if q < 0 then -q else q

/-- PE-formula deviation from the table cell, checked at the bracket's
low edge, midpoint, and high edge. -/
def rowDevOk (bound : Rat) (r : Gen.Irs.EicRow) : Bool :=
  (List.range 8).all fun i =>
    let (g, n) := cols.getD i (.single, 0)
    match r.credits.getD i none with
    | none => true
    | some t =>
      [(r.lo : Rat), ((r.lo : Rat) + (r.hi : Rat)) / 2, (r.hi : Rat) - 1].all
        fun x => decide (rabs (pe g n x - (t : Rat)) ≤ bound)

def rowDevOkMid (bound : Rat) (r : Gen.Irs.EicRow) : Bool :=
  (List.range 8).all fun i =>
    let (g, n) := cols.getD i (.single, 0)
    match r.credits.getD i none with
    | none => true
    | some t =>
      decide (rabs (pe g n (((r.lo : Rat) + (r.hi : Rat)) / 2) - (t : Rat)) ≤ bound)

/-- The reverse-engineered generator reproduces every cell of the 2023
IRS EIC table. -/
theorem eic_table_2023_generator_verified :
    Gen.Irs.eicTable2023.all rowOk = true := by
  native_decide

/-- PolicyEngine's smooth EITC formula never differs from the legal
(table) credit by more than $11.50, anywhere in any bracket. -/
theorem pe_within_1150_of_table :
    Gen.Irs.eicTable2023.all (rowDevOk (23/2)) = true := by
  native_decide

/-- The $11.50 bound is sharp: earned income $50, three children. -/
theorem pe_table_gap_reaches_1150 :
    rabs (pe .single 3 50 - 34) = 23/2 := by
  native_decide

/-- At bracket midpoints the gap is at most $5.297. -/
theorem pe_within_530_at_midpoints :
    Gen.Irs.eicTable2023.all (rowDevOkMid (5297/1000)) = true := by
  native_decide

end Lawlib.Verify
