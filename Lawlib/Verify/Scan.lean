import Lawlib.Core.Money
import Lawlib.Core.Date
import Lawlib.Gen.Entities
import Lawlib.Gen.Params
import Lawlib.Gen.Vars.Trunk
import Lawlib.Gen.Memo

/-!
# Canonical scan households (precompiled)

`mkTaxUnit` constructs the full domain-split `TaxUnit` record (~1,600
defaulted fields). Lean's interpreter crashes on eager closed-term
extraction for record construction at this scale (segfault in
`libleanshared`), so this module lives in the precompiled `LawlibGen`
library: `native_decide` and `#eval` call these as native symbols.
-/

namespace Lawlib.Verify

open Lawlib Lawlib.Gen Lawlib.Gen.Vars

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
    { core_p1 := { age := 30, is_tax_unit_head := true, has_tin := true,
                   employment_income := income } }
  let spouse : Person :=
    { core_p1 := { age := 30, is_tax_unit_spouse := true, has_tin := true } }
  let child : Person :=
    { core_p1 := { age := 8, has_tin := true } }
  { members := [head] ++ (if g = .joint then [spouse] else []) ++ List.replicate n child
    core := { filing_status := if g = .joint then .JOINT else .SINGLE }
    irs := { adjusted_gross_income := income
             takes_up_eitc := true
             tax_unit_is_required_to_file := true } }

/-- PolicyEngine semantics (the translated `eitc`) on that household —
per-variable definition, used by the *symbolic* theorems. -/
def pe (g : Group) (n : Nat) (x : Rat) : Rat :=
  eitc (mkTaxUnit g n x) d2023

/-- The same semantics through the fused memoized evaluator
(`Lawlib.Gen.Memo`) — each variable computed once, so `native_decide`
can evaluate hundreds of thousands of points. The two definitions
compute the same value (same IR, sharing made explicit); grid theorems
are stated over `peM`. -/
def peM (g : Group) (n : Nat) (x : Rat) : Rat :=
  (Memo.eval (mkTaxUnit g n x) d2023).p2.eitc

def rabs (q : Rat) : Rat := if q < 0 then -q else q

end Lawlib.Verify
