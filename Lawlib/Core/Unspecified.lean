/-!
# The unspecified value

Lean's convention for total functions is to return a junk value outside
the meaningful domain (Mathlib's `x / 0 = 0`). Lawlib follows the
convention but names the junk: an arm that returns `unspecified` is
declaring "the law does not speak here" — distinguishable, greppable,
and provable-about, unlike a bare `0`.

`unspecified` is definitionally `default`, so `unspecified = (0 : Rat)`
and proofs may unfold it freely; its value carries no meaning and no
theorem should depend on which junk value it is.
-/

namespace Lawlib

/-- The value of a total function outside its meaningful domain.
Definitionally `default`; the name marks intent, not content. -/
def unspecified (α : Type _) [Inhabited α] : α := default

@[simp] theorem unspecified_rat : unspecified Rat = 0 := rfl

end Lawlib
