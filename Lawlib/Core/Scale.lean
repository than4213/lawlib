import Lawlib.Core.Date
import Lawlib.Core.Unspecified
import Lawlib.Core.ExtRat

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

/-- Marginal-rate application (Form 6251 line 18 and kin): each
bracket's rate applies only to the slice of `x` between that bracket's
threshold and the next one — the sum of `rate_i × slice_i`, not a
lookup. For ascending thresholds the slice between `tᵢ` and `tᵢ₊₁` is
`min x tᵢ₊₁ - min x tᵢ` (zero below, clipped above); the last bracket's
slice is `max 0 (x - t_last)`. -/
def marginalCalc (s : Scale) (d : Date) (x : Rat) : Rat :=
  let last := match s.brackets.getLast? with
    | some b => (max 0 (x - b.threshold.atDate d)) * b.amount.atDate d
    | none => unspecified Rat
  (s.brackets.zip (s.brackets.drop 1)).foldl (init := last)
    fun acc (b, nxt) =>
      acc + (min x (nxt.threshold.atDate d) - min x (b.threshold.atDate d))
              * b.amount.atDate d

/-- Last bracket's threshold at date `d` (PolicyEngine's
`scale.thresholds[-1]` idiom, e.g. the CTC child age limit).
`unspecified` for an empty scale. -/
def lastThreshold (s : Scale) (d : Date) : Rat :=
  match s.brackets.getLast? with
  | some b => b.threshold.atDate d
  | none => unspecified Rat

/-- The `i`-th bracket's rate/amount at date `d` (PolicyEngine's
`scale.rates[i]` idiom, e.g. the AMT 28% upper rate).
`unspecified` past the end. -/
def rateAt (s : Scale) (d : Date) (i : Nat) : Rat :=
  match s.brackets[i]? with
  | some b => b.amount.atDate d
  | none => unspecified Rat

/-- The `i`-th bracket's threshold at date `d` (PolicyEngine's
`scale.thresholds[i]` idiom). `unspecified` past the end. -/
def thresholdAt (s : Scale) (d : Date) (i : Nat) : Rat :=
  match s.brackets[i]? with
  | some b => b.threshold.atDate d
  | none => unspecified Rat

/-- Last bracket's rate/amount at date `d` (PolicyEngine's
`scale.rates[-1]` idiom, e.g. the top AMT rate).
`unspecified` for an empty scale. -/
def lastRate (s : Scale) (d : Date) : Rat :=
  match s.brackets.getLast? with
  | some b => b.amount.atDate d
  | none => unspecified Rat

end Scale

/-- A scale whose thresholds/amounts may be `±∞` (some state parameter
tables use unbounded brackets). Data-layer twin of `Scale`. -/
structure ScaleXBracket where
  threshold : DatedParam ExtRat
  amount : DatedParam ExtRat
deriving Repr

structure ScaleX where
  brackets : List ScaleXBracket
deriving Repr

namespace ScaleX

/-- Amount of the last bracket whose threshold at `d` is `≤ x`
(`negInf` thresholds always apply; `posInf` never). -/
def atDate (s : ScaleX) (d : Date) (x : Rat) : ExtRat :=
  s.brackets.foldl (init := .fin 0) fun acc b =>
    match b.threshold.atDate d with
    | .negInf => b.amount.atDate d
    | .posInf => acc
    | .fin t => if t ≤ x then b.amount.atDate d else acc

end ScaleX

end Lawlib
