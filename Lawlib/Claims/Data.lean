import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Algebra.Order.AbsoluteValue.Basic
import Mathlib.Algebra.Order.Ring.Abs
import Lawlib.Verify.Scan
import Lawlib.Claims

/-!
# The data–logic membrane (first vertical slice)

External computations enter lawlib as *tiered claims about opaque
symbols*, never as facts. This module exercises the full pattern on one
real number: the executed-PolicyEngine EITC total over a reproducible
seeded cohort.

The division of labor:

* the **artifact** (300 seeded households, exact JSONL) lives outside
  the kernel, bound here by content hash — T3 is the honest ceiling for
  data too large or too external to commit as a term;
* the **numbers** (PE's total, the pointwise twin bound) are claims
  with the provenance in their docstrings;
* the **theorem** is the kernel's contribution: *given* the pointwise
  bound and the external total, lawlib's own total is pinned to an
  interval — pure algebra, no evaluation, no trust in the data.

Produced by `pe2lean-aggregate 1200 2000060` — 246 year-2023
households, PE total ≈ $765.51 — (pe2lean v0.8.4,
policyengine-us 1.783.0).
-/

namespace Lawlib.Claims

open Lawlib Lawlib.Gen Lawlib.Verify

/-! ## Vocabulary (reality's symbols) -/

/-- SHA-256 of a string, as an abstract symbol. -/
opaque sha256 : String → String

/-- The exact JSONL artifact of the seed-2000060 cohort's year-2023
households, as fed to both engines. -/
opaque cohortSeed2000060Jsonl : String

/-- Those households as lawlib values (the decoding of the artifact). -/
opaque cohortSeed2000060 : List TaxUnit

/-- Executed PolicyEngine's `eitc` on an arbitrary household (the
Simulation API, pinned policyengine-us 1.783.0) — generalizes
`peEitcExecuted` beyond the canonical scan domain. -/
opaque peExecutedEitc : TaxUnit → Date → Rat

/-! ## Claims -/

/-- **Artifact integrity** (T3 — tool-verified): the cohort artifact is
the one whose hash is recorded; `pe2lean-aggregate` reproduces it
byte-for-byte from the seed. -/
def claim_cohort_hash : Prop :=
  sha256 cohortSeed2000060Jsonl = "24a0c235f50deb9506cd20a3b2b1e24db0ddaff90cf07440bf1a78659be28848"

/-- **External total** (T4 — one pinned run): executed PolicyEngine's
EITC total over the cohort. -/
def claim_pe_cohort_eitc_total : Prop :=
  (cohortSeed2000060.map (fun t => peExecutedEitc t d2023)).sum
    = (3135523 / 4096 : Rat)

/-- **Pointwise twin bound on this cohort** (T2 — differential: this
exact cohort was diff-checked household-by-household; the recorded
maximum |PE − twin| is the bound). -/
def claim_twin_bound_on_cohort : Prop :=
  ∀ t ∈ cohortSeed2000060,
    rabs (peExecutedEitc t d2023 - Memo.eitc t d2023)
      ≤ (139847 / 4000000000 : Rat)

/-! ## The kernel's contribution -/

/-- Triangle-inequality bound for sums of pointwise-close functions:
the workhorse of every aggregate certified through the membrane. -/
theorem sum_dev_bound {α : Type} (f g : α → Rat) (ε : Rat) :
    ∀ (l : List α), (∀ a ∈ l, rabs (f a - g a) ≤ ε) →
      rabs ((l.map f).sum - (l.map g).sum) ≤ l.length * ε
  | [], _ => by simp [rabs]
  | a :: l, h => by
    have hd := h a (List.mem_cons_self ..)
    have tl := sum_dev_bound f g ε l (fun b hb => h b (List.mem_cons_of_mem _ hb))
    have habs : ∀ q : Rat, rabs q = |q| := fun q => by
      unfold rabs; split
      · exact (abs_of_neg (by assumption)).symm
      · exact (abs_of_nonneg (not_lt.mp (by assumption))).symm
    simp only [habs] at hd tl ⊢
    have : (f a + (l.map f).sum) - (g a + (l.map g).sum)
         = (f a - g a) + ((l.map f).sum - (l.map g).sum) := by ring
    simp only [List.map_cons, List.sum_cons, List.length_cons, this]
    calc |(f a - g a) + ((l.map f).sum - (l.map g).sum)|
        ≤ |f a - g a| + |(l.map f).sum - (l.map g).sum| := abs_add_le _ _
      _ ≤ ε + l.length * ε := by exact add_le_add hd tl
      _ = (l.length + 1) * ε := by ring
      _ = ((l.length : Nat) + 1 : Nat) * ε := by push_cast; ring

/-- **Certified conditional**: under the pointwise twin bound and the
external total, lawlib's own EITC total over the cohort is pinned to an
interval around PolicyEngine's number — without the kernel evaluating a
single household or trusting the artifact. -/
theorem lawlib_cohort_eitc_total
    (hb : claim_twin_bound_on_cohort)
    (ht : claim_pe_cohort_eitc_total) :
    rabs ((cohortSeed2000060.map (fun t => Memo.eitc t d2023)).sum
          - (3135523 / 4096 : Rat))
      ≤ cohortSeed2000060.length * (139847 / 4000000000 : Rat) := by
  have := sum_dev_bound (fun t => peExecutedEitc t d2023)
                        (fun t => Memo.eitc t d2023)
                        (139847 / 4000000000 : Rat) cohortSeed2000060 hb
  rw [ht] at this
  have hsym : ∀ a b : Rat, rabs (a - b) = rabs (b - a) := by
    intro a b; simp only [rabs]; split <;> split <;> rename_i h1 h2 <;> linarith
  rw [hsym]
  exact this

end Lawlib.Claims
