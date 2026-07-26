import Lawlib

/-!
Differential-harness entry point (design §6.2): reads a household JSON
from stdin — `{"date": "YYYY-MM-DD", "tax_unit": {...}}`, rationals as
`"num/den"` strings — evaluates the translated EITC chain, and prints a
JSON object of variable name → exact rational.
-/

open Lean Lawlib Lawlib.Gen Lawlib.Gen.Gov.Irs.Credits.Eitc

def results (t : TaxUnit) (d : Date) : Json :=
  Json.mkObj
    [ ("eitc_child_count", toJson (eitc_child_count t d))
    , ("eitc_phase_in_rate", toJson (eitc_phase_in_rate t d))
    , ("eitc_maximum", toJson (eitc_maximum t d))
    , ("eitc_phase_out_rate", toJson (eitc_phase_out_rate t d))
    , ("eitc_phase_out_start", toJson (eitc_phase_out_start t d))
    , ("eitc_phased_in", toJson (eitc_phased_in t d))
    , ("eitc_reduction", toJson (eitc_reduction t d))
    , ("eitc", toJson (eitc t d))
    ]

def main : IO Unit := do
  let input ← (← IO.getStdin).readToEnd
  let out : Except String Json := do
    let j ← Json.parse input
    let d ← fromJson? (α := Date) (← j.getObjVal? "date")
    let t ← fromJson? (α := TaxUnit) (← j.getObjVal? "tax_unit")
    pure (results t d)
  match out with
  | .ok j => IO.println j.compress
  | .error e => do
    (← IO.getStderr).putStrLn s!"lawlib: bad input: {e}"
    IO.Process.exit 1
