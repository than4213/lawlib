import Lawlib

/-!
Differential-harness entry point (design §6.2): reads a household JSON
from stdin — `{"date": "YYYY-MM-DD", "tax_unit": {...}}`, rationals as
`"num/den"` strings — evaluates the translated EITC chain, and prints a
JSON object of variable name → exact rational.
-/

open Lean Lawlib Lawlib.Gen

def results (t : TaxUnit) (d : Date) : Json :=
  evalJson t d

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
