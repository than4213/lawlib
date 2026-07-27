/-!
# Extended rationals

Some statutory limits are removed in certain years — e.g. ARPA struck the
EITC childless age cap for 2021, which PolicyEngine encodes as `.inf` in
the parameter YAML. `Rat` has no infinity, so parameters that can be
unbounded use `ExtRat`: a rational or `+∞`.
-/

namespace Lawlib

/-- A rational extended with `±∞` (statutory "no limit" bounds). -/
inductive ExtRat where
  | fin (q : Rat)
  | posInf
  | negInf
deriving DecidableEq, Repr

namespace ExtRat

/-- `x ≤ cap`, where `cap = posInf` means the limit is absent. -/
def leCap (x : Rat) : ExtRat → Bool
  | .posInf => true
  | .negInf => false
  | .fin q => x ≤ q

end ExtRat

end Lawlib
