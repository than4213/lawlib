import Lawlib

/-!
Differential-harness entry point (design §6.2): reads a household JSON
from stdin — `{"date": "YYYY-MM-DD", "tax_unit": {...}}`, rationals as
`"num/den"` strings — evaluates the translated EITC chain, and prints a
JSON object of variable name → exact rational.
-/

open Lean Lawlib Lawlib.Parameters

def results (t : TaxUnit) (d : Date) : Json :=
  evalJson t d

def processLine (line : String) : Except String Json := do
  let j ← Json.parse line
  let d ← fromJson? (α := Date) (← j.getObjVal? "date")
  if Date.ble enactedHorizon d ∧ d ≠ enactedHorizon then
    throw s!"date {d.year}-{d.month}-{d.day} is beyond the enacted horizon ({enactedHorizon.year}-{enactedHorizon.month}-{enactedHorizon.day}): no law here, only forecasts"
  let t ← fromJson? (α := TaxUnit) (← j.getObjVal? "tax_unit")
  pure (results t d)

/-- JSONL: one household per input line, one result object per output
line. A single line is the M3-era single-household mode. -/
def main : IO Unit := do
  let input ← (← IO.getStdin).readToEnd
  let stdout ← IO.getStdout
  let mut lineNo := 0
  for line in input.splitOn "\n" do
    lineNo := lineNo + 1
    let line := line.trim
    if line.isEmpty then
      continue
    match processLine line with
    | .ok j => stdout.putStrLn j.compress
    | .error e => do
      (← IO.getStderr).putStrLn
        s!"lawlib: bad input at line {lineNo} (length {line.length}): {e}; head: {line.take 120}"
      IO.Process.exit 1
