import Lawlib.Core.Money

/-!
# Catala runtime semantics (the fragment Lawlib consumes)

Faithful Lean image of `catala_runtime.ml` for the operators the §32
encoding uses. Catala money is **integer cents**; `money × decimal`
multiplies exactly and rounds to the nearest cent, **ties away from
zero** (`runtimes/ocaml/catala_runtime.ml`, `round` and
`o_mult_mon_rat`).
-/

namespace Lawlib.Catala

/-- Catala money: integer cents. -/
abbrev CMoney := Int

/-- Round to nearest integer, ties away from zero:
`sgn(q) * floor(|q| + 1/2)`. -/
def qRound (q : Rat) : Int :=
  if q < 0 then -(ratFloor (-q + 1/2)) else ratFloor (q + 1/2)

/-- `o_mult_mon_rat`: multiply exactly, round to nearest cent. -/
def multMonRat (m : CMoney) (r : Rat) : CMoney :=
  qRound ((m : Rat) * r)

/-- Catala cents → Lawlib dollars (exact). -/
def toUSD (m : CMoney) : Rat :=
  (m : Rat) / 100

end Lawlib.Catala
