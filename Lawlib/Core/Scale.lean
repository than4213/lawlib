import Lawlib.Core.Date

/-!
# Bracket scales

PolicyEngine "single_amount" scale parameters: a list of brackets, each
with a threshold and an amount, both date-keyed. Lookup at date `d` and
point `x` returns the amount of the last bracket whose threshold at `d`
is `≤ x`. In the EITC subtree these are indexed by number of qualifying
children (`threshold_unit: child`); the same structure serves
income-indexed single-amount scales.

`marginal_rate` scales (piecewise application, like income tax brackets)
are a different beast and get their own type when a subtree needs one.
-/

namespace Lawlib

structure ScaleBracket where
  threshold : DatedParam Rat
  amount : DatedParam Rat
deriving Repr

/-- A single-amount bracket scale; brackets in ascending threshold order. -/
structure Scale where
  brackets : List ScaleBracket
deriving Repr

namespace Scale

/-- Amount of the last bracket whose threshold (at date `d`) is `≤ x`.

Returns `0` if `x` is below every threshold; PolicyEngine scales start at
threshold 0, so for nonnegative `x` this default is unreachable. -/
def atDate (s : Scale) (d : Date) (x : Rat) : Rat :=
  s.brackets.foldl (init := 0) fun acc b =>
    if b.threshold.atDate d ≤ x then b.amount.atDate d else acc

end Scale

end Lawlib
