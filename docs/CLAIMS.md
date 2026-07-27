# The claims ledger

Uncertainty management for lawlib, in the
[Claimlib](https://github.com/than4213) claims-as-Props style: what the
kernel can't certify is a named `Prop` in
[`Lawlib/Claims.lean`](../Lawlib/Claims.lean), never asserted; results
depending on it are certified *conditionals*. This ledger grades the
evidence behind each claim and names the cheapest way to firm it up.
Best guesses are welcome here — at their honest tier.

## Tiers

| Tier | Meaning | Trust base |
|---|---|---|
| **T0** | kernel-checked theorem | Lean kernel |
| **T1** | `native_decide` theorem (finite computation) | kernel + Lean compiler |
| **T2** | differential evidence (randomized, adversarial, repeated) | test harness + both engines |
| **T3** | tool-verified transcription of an external artifact | parser + source artifact |
| **T4** | probe / observation (reproducible, small n) | the probe script |
| **T5** | conjecture — best guess awaiting resources | the author's judgment |

## Interior results (no claims needed)

All of `Lawlib/Theorems/` and `Lawlib/Verify/`: the trapezoid closed
forms, `eitc_continuous`, monotonicity, exact phase-out endpoints (T0);
the table-generator verification, PE-vs-table $11.50 bound, Catala
cross-encoding bounds and exact 24¢/50¢ plateau gaps, CTC cliff atlas
(T1). These are unconditional statements about *committed data*.

## Live claims

| Claim | Statement | Tier | Evidence | Firms up by |
|---|---|---|---|---|
| `claim_table_transcription` | committed `eicTable2023` = the printed IRS table | T3 | coordinate-based PDF parse; 1,265/1,267 rows; generator-consistency (T1) | independent transcription; the 2 split rows; IRS machine-readable data |
| `claim_pe_twin_eitc` | executed PE ≡ translated `eitc` ± 2¢ on canonical domain | T2 | 100k households/night, 5 years, 0 mismatches | more years/structure; asymptotic only |
| *(implicit)* CTC twin | executed PE ≡ translated `ctc` ± tolerance | T2 | 1k × 29 vars clean | promote to a named claim Prop |
| *(implicit)* Catala faithful | `catala2lean` output ≡ Catala interpreter | T1/T3 | 6 interpreter outputs as `native_decide` theorems | more test scopes; certified backend path |
| *(prose)* findings §9 legal reading | §32(f) makes the administered figure operative | T5 | statutory reading, unreviewed | legal review |
| *(prose)* findings §11 | PE set-input period coercion is path-dependent (0 / ÷12 / uprated) | T4 | 3 probes, 2026-07-27, reproducible scripts | policyengine-core source analysis (in progress); upstream confirmation |
| *(pending)* SNAP twin | translated SNAP chain ≡ executed PE | **T5** | translation builds (`snap-wip`); diff blocked on §11 | resolve input-semantics convention, then T2 |

## Composition examples

`Lawlib/Claims.lean` shows the pattern: `real_table_generator` and
`pe_formula_within_1150_of_real_table` turn T1 interior theorems into
statements about the *real* table under the T3 transcription claim;
`pe_executed_matches_real_table_at_20k` chains T3 + T2 to bound
*executed PolicyEngine* against the real table. The kernel certifies
every link; the ledger prices the endpoints.

## Policy

New assertions enter at their honest tier with evidence and a firm-up
path — a T5 guess with a named Prop beats an unstated assumption inside
a proof. Promotions are commits: better evidence moves a row up and the
git history records when and why.
