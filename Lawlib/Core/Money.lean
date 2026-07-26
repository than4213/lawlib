/-!
# Money and rates

Money amounts and rates are exact rationals (`Rat`), never `Float`.
The law's semantics is exact decimal arithmetic with statutory rounding;
IEEE 754 is an implementation accident of the Python engine
(design §6 numerics policy).
-/

namespace Lawlib

/-- A dollar amount, exact. -/
abbrev USD := Rat

/-- A dimensionless rate (e.g. a phase-in percentage), exact. -/
abbrev Rate := Rat

/-- Floor of a rational as an integer: `⌊x⌋`.

Uses Euclidean division, which rounds toward `-∞` for the positive
denominator that `Rat` guarantees. -/
def ratFloor (x : Rat) : Int :=
  x.num.ediv (x.den : Int)

/-- Statutory rounding: round half up to the nearest whole dollar,
`⌊x + 1/2⌋`.

TODO(M3): verify against the rounding PolicyEngine actually applies in the
EITC subtree and encode THAT — the rounding rule is part of the law, not a
numeric accident. -/
def roundUSD (x : USD) : USD :=
  (ratFloor (x + 1/2) : Int)

end Lawlib
