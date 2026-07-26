/-!
# Entity aggregation helpers

Scalar counterparts of PolicyEngine's vectorized entity operations
(design §4, handoff §3): `tax_unit.sum(...)` becomes `sumBy`, `any`
becomes `anyBy`, broadcasts become plain function application. The entity
structures themselves (`Person`, `TaxUnit`) are *generated* — their field
lists derive from the extracted dependency closure — so only the generic
helpers live here.
-/

namespace Lawlib

/-- `tax_unit.sum(person_level_expr)`. -/
def sumBy (xs : List α) (f : α → Rat) : Rat :=
  (xs.map f).foldl (· + ·) 0

/-- `tax_unit.any(person_level_expr)`. -/
def anyBy (xs : List α) (f : α → Bool) : Bool :=
  xs.any f

/-- `tax_unit.all(person_level_expr)`. -/
def allBy (xs : List α) (f : α → Bool) : Bool :=
  xs.all f

/-- Count of members satisfying `f` (PolicyEngine's `sum` over a boolean
person-level expression). -/
def countBy (xs : List α) (f : α → Bool) : Nat :=
  (xs.filter f).length

/-- `tax_unit.max(person_level_expr)`; `0` for an empty member list,
matching NumPy-with-default semantics — revisit at M3 if PolicyEngine
differs. -/
def maxBy (xs : List α) (f : α → Rat) : Rat :=
  (xs.map f).foldl max 0

end Lawlib
