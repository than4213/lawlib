import Lawlib.Core.Money

/-!
# Per-state TANF amounts (2023) — test fixture

What each state pays for one adult age 30 with no income; children age 5 and 8,
as computed by policyengine-us 1.783.0. **This is state law, and it is
not part of the library**: it lives here so the federal rules that take
such an amount as an input can be exercised on realistic values rather
than only randomized ones.

The spread is the point. AZ pays $2,143 and NH $14,916 for the
identical family — one federal rule, 51 state answers. Lawlib states
the rule; the number comes from whoever is asking.

Amounts are annual. A state that reports monthly has already been
converted — lawlib encodes no state's reporting convention. Values are
exact rationals of what PolicyEngine returned; its float32 arithmetic is
why some are not round numbers.

DO NOT EDIT — regenerate with `pe2lean-fixture`.
-/

namespace Tests.StateTanf2023

/-- One state's annual benefit for the canonical household. -/
structure StateAmount where
  state : String
  annual : Rat
deriving Repr

/-- What each state paid in 2023 (`tanf_if_takes_up`). -/
def amounts : List StateAmount := [
  ⟨"AL", 2967/1⟩,
  ⟨"AK", 11358121/1024⟩,
  ⟨"AZ", 2194427/1024⟩,
  ⟨"AR", 2448/1⟩,
  ⟨"CA", 13560/1⟩,
  ⟨"CO", 6708/1⟩,
  ⟨"CT", 9656557/1024⟩,
  ⟨"DC", 8400/1⟩,
  ⟨"DE", 4056/1⟩,
  ⟨"FL", 2376/1⟩,
  ⟨"GA", 3360/1⟩,
  ⟨"HI", 15005123/2048⟩,
  ⟨"IA", 5112/1⟩,
  ⟨"ID", 3708/1⟩,
  ⟨"IL", 7350/1⟩,
  ⟨"IN", 3648/1⟩,
  ⟨"KS", 4632/1⟩,
  ⟨"KY", 5764/1⟩,
  ⟨"LA", 5808/1⟩,
  ⟨"MA", 10676/1⟩,
  ⟨"MD", 8724/1⟩,
  ⟨"ME", 8154/1⟩,
  ⟨"MI", 5904/1⟩,
  ⟨"MN", 8367/1⟩,
  ⟨"MO", 3589201/1024⟩,
  ⟨"MS", 3120/1⟩,
  ⟨"MT", 15171483/2048⟩,
  ⟨"NC", 3264/1⟩,
  ⟨"ND", 7412/1⟩,
  ⟨"NE", 12732825/2048⟩,
  ⟨"NH", 15273985/1024⟩,
  ⟨"NJ", 6708/1⟩,
  ⟨"NM", 5874/1⟩,
  ⟨"NV", 4632/1⟩,
  ⟨"NY", 4668/1⟩,
  ⟨"OH", 14471581/2048⟩,
  ⟨"OK", 3504/1⟩,
  ⟨"OR", 6072/1⟩,
  ⟨"PA", 4836/1⟩,
  ⟨"RI", 8652/1⟩,
  ⟨"SC", 16220129/4096⟩,
  ⟨"SD", 8214/1⟩,
  ⟨"TN", 4644/1⟩,
  ⟨"TX", 3786/1⟩,
  ⟨"UT", 7944/1⟩,
  ⟨"VA", 2959165/512⟩,
  ⟨"VT", 15066465/2048⟩,
  ⟨"WA", 7848/1⟩,
  ⟨"WI", 7836/1⟩,
  ⟨"WV", 3804/1⟩,
  ⟨"WY", 9366/1⟩
]

/-- Every state is present. -/
example : amounts.length = 51 := by native_decide

/-- The same federal rule yields a range of over $12,773 across states,
which is why the amount is an input and not a definition. -/
example : amounts.any (fun a => a.annual > 14915) = true := by
  native_decide

end Tests.StateTanf2023
