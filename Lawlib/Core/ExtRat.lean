import Lawlib.Core.Unspecified

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

/-- `x < cap`; `posInf` means the bound is absent. -/
def ltCap (x : Rat) : ExtRat → Bool
  | .posInf => true
  | .negInf => false
  | .fin q => x < q

/-- `x ≥ cap`; `posInf` can never be reached, `negInf` always is. -/
def geCap (x : Rat) : ExtRat → Bool
  | .posInf => false
  | .negInf => true
  | .fin q => x ≥ q

/-- `x > cap`; `posInf` can never be exceeded, `negInf` always is. -/
def gtCap (x : Rat) : ExtRat → Bool
  | .posInf => false
  | .negInf => true
  | .fin q => x > q

/-- `min x cap`, where `cap = posInf` means no cap applies. The
extractor only emits this for parameters that are never `-∞`; the
`negInf` arm is unreachable; it returns `unspecified` to stay total. -/
def minCap (x : Rat) : ExtRat → Rat
  | .posInf => x
  | .negInf => unspecified Rat
  | .fin q => min x q

end ExtRat

end Lawlib
