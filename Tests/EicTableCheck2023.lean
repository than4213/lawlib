import Tests.EicTableData2023
import Lawlib.Verify.EicTable2023

/-!
# Fixture check: the generator reproduces the transcribed 2023 EIC table

Test-side of findings §8 (see `Lawlib/Verify/EicTable2023.lean` for the
law-side generator). The 10,120-cell transcription is a fixture — the
printed table is fully determined by `tableModel`, so the table lives
here, not in the library (docs/categories.md).
-/

namespace Lawlib.Verify

open Lawlib Lawlib.Gen Lawlib.Gen.Vars

/-- The table prints `0` beyond the phase-out for some columns and `*`
for others; both mean "no credit". -/
def cellMatches (m t : Option Nat) : Bool :=
  m == t || (m == none && t == some 0)

def rowOk (r : Gen.Irs.EicRow) : Bool :=
  (List.range 8).all fun i =>
    let (g, n) := cols.getD i (.single, 0)
    cellMatches (tableModel g n r.lo r.hi) (r.credits.getD i none)

/-- PE-formula deviation from the table cell, checked at the bracket's
low edge, midpoint, and high edge. -/
def rowDevOk (bound : Rat) (r : Gen.Irs.EicRow) : Bool :=
  (List.range 8).all fun i =>
    let (g, n) := cols.getD i (.single, 0)
    match r.credits.getD i none with
    | none => true
    | some t =>
      [(r.lo : Rat), ((r.lo : Rat) + (r.hi : Rat)) / 2, (r.hi : Rat) - 1].all
        fun x => decide (rabs (peM g n x - (t : Rat)) ≤ bound)

def rowDevOkMid (bound : Rat) (r : Gen.Irs.EicRow) : Bool :=
  (List.range 8).all fun i =>
    let (g, n) := cols.getD i (.single, 0)
    match r.credits.getD i none with
    | none => true
    | some t =>
      decide (rabs (peM g n (((r.lo : Rat) + (r.hi : Rat)) / 2) - (t : Rat)) ≤ bound)

/-- The reverse-engineered generator reproduces every cell of the 2023
IRS EIC table. -/
theorem eic_table_2023_generator_verified :
    Gen.Irs.eicTable2023.all rowOk = true := by
  native_decide


end Lawlib.Verify
