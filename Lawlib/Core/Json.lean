import Lean.Data.Json
import Lawlib.Core.Date

/-!
# JSON codecs for the differential harness

Rationals travel as strings `"num/den"` (or a bare integer string) —
never JSON numbers, which round-trip through floats (design §6.2).
Generated entity structures derive `FromJson` against these instances.
-/

namespace Lawlib

open Lean

instance : FromJson Rat where
  fromJson? j := do
    let s ← j.getStr?
    match s.splitOn "/" with
    | [n, d] =>
      let some n := n.toInt? | throw s!"bad rational numerator: {s}"
      let some d := d.toNat? | throw s!"bad rational denominator: {s}"
      if d == 0 then throw s!"zero denominator: {s}" else pure (mkRat n d)
    | [n] =>
      let some n := n.toInt? | throw s!"bad rational: {s}"
      pure (n : Rat)
    | _ => throw s!"bad rational: {s}"

instance : ToJson Rat where
  toJson q := Json.str s!"{q.num}/{q.den}"

/-- Dates travel as `"YYYY-MM-DD"`. -/
instance : FromJson Date where
  fromJson? j := do
    let s ← j.getStr?
    match s.splitOn "-" with
    | [y, m, d] =>
      let some y := y.toNat? | throw s!"bad date: {s}"
      let some m := m.toNat? | throw s!"bad date: {s}"
      let some d := d.toNat? | throw s!"bad date: {s}"
      pure ⟨y, m, d⟩
    | _ => throw s!"bad date: {s}"

end Lawlib
