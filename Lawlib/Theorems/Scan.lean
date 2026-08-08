import Lawlib.Core.Money
import Lawlib.Core.Date
import Lawlib.Household
import Lawlib.Parameters
import Lawlib.USA
import Lawlib.Evaluator

/-!
# Canonical scan households (precompiled)

`mkTaxUnit` constructs the full domain-split `TaxUnit` record (~1,600
defaulted fields). Lean's interpreter crashes on eager closed-term
extraction for record construction at this scale (segfault in
`libleanshared`), so this module lives in the precompiled `LawlibGen`
library: `native_decide` and `#eval` call these as native symbols.
-/

namespace Lawlib.Theorems

open Lawlib Lawlib Lawlib.USA

inductive Group where
  | single
  | joint
deriving DecidableEq, Repr

def d2023 : Date := ⟨2023, 1, 1⟩

/-- The canonical household of the M6 scan: a head aged 30 with the
given earned income, a spouse for joint filers, `n` qualifying children
aged 8; AGI mirrors earned income; everything else zero. -/
def mkTaxUnit (g : Group) (n : Nat) (income : Rat) : TaxUnit :=
  let head : Person :=
    { coreP1 := { age := 30, isTaxUnitHead := true, hasTin := true,
                   employmentIncome := income } }
  let spouse : Person :=
    { coreP1 := { age := 30, isTaxUnitSpouse := true, hasTin := true } }
  let child : Person :=
    { coreP1 := { age := 8, hasTin := true } }
  { members := [head] ++ (if g = .joint then [spouse] else []) ++ List.replicate n child
    core := { filingStatus := if g = .joint then .JOINT else .SINGLE }
    -- AGI is now computed law: with only employment income set and no
    -- above-the-line deductions, it reduces to the head's earnings
    irs := { takesUpEitc := true
             wouldFileIfEligibleForRefundableCredit := true } }

/-- PolicyEngine semantics (the translated `eitc`) on that household —
per-variable definition, used by the *symbolic* theorems. -/
def pe (g : Group) (n : Nat) (x : Rat) : Rat :=
  eitc (mkTaxUnit g n x) d2023

/-- The same semantics through the fused memoized evaluator
(`Lawlib.Evaluator`) — each variable computed once, so `native_decide`
can evaluate hundreds of thousands of points. The two definitions
compute the same value (same IR, sharing made explicit); grid theorems
are stated over `peM`. -/
def peM (g : Group) (n : Nat) (x : Rat) : Rat :=
  Evaluator.eitc (mkTaxUnit g n x) d2023

def rabs (q : Rat) : Rat := if q < 0 then -q else q

end Lawlib.Theorems
