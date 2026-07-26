/-!
# Dates and date-keyed parameters

A `Date` is a plain (year, month, day) triple ordered chronologically; no
calendar arithmetic is performed. A `DatedParam` mirrors a PolicyEngine
parameter YAML `values` map: entries sorted ascending by effective date,
nonempty by construction, looked up by "last entry effective on or before
the query date" (design §4).
-/

namespace Lawlib

structure Date where
  year : Nat
  month : Nat
  day : Nat
deriving DecidableEq, Repr

namespace Date

/-- Chronological `a ≤ b`, Bool-valued for direct use in lookups. -/
def ble (a b : Date) : Bool :=
  Nat.blt a.year b.year || (a.year == b.year &&
    (Nat.blt a.month b.month || (a.month == b.month && Nat.ble a.day b.day)))

instance : LE Date := ⟨fun a b => ble a b = true⟩
instance : DecidableRel (· ≤ · : Date → Date → Prop) :=
  fun _ _ => decEq _ _

end Date

/-- A date-keyed parameter value: the YAML `values` map as a nonempty,
ascending-sorted list of `(effective_date, value)` entries.

The head entry is stored separately so emptiness is impossible by
construction. -/
structure DatedParam (α : Type) where
  head : Date × α
  tail : List (Date × α)
deriving Repr

namespace DatedParam

/-- The value effective on date `d`: the last entry whose effective date is
`≤ d`.

If `d` precedes every entry, the earliest value is returned; the extractor
guarantees queries stay within the covered window, so that clamp is never
semantically load-bearing. -/
def atDate (p : DatedParam α) (d : Date) : α :=
  go p.head.2 p.tail
where
  go (v : α) : List (Date × α) → α
    | [] => v
    | (d', v') :: rest => if Date.ble d' d then go v' rest else v

end DatedParam

end Lawlib
