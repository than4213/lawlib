# Lawlib — Handoff: PolicyEngine → Lean 4 Transpiler, Phase 1 (EITC Subtree)

**Project name:** Lawlib (deliberately echoing mathlib: the ambition is a community-maintained formal library of law, starting from the US tax-benefit system).
**Status:** *Historical.* This was the founding brief, written before any
code existed. It is kept for the design rationale in §1 and the reasoning
behind the rejection-based approach — the numbers, scope, and structure it
describes have all been superseded. For the current state see
[the README](../README.md); for scope, [scope.md](scope.md); for doctrine,
[categories.md](categories.md).
**Original audience:** A coding agent with no prior context on this project.
**Original Phase 1 goal:** A rejection-based extractor that translates the EITC variable subtree of `policyengine-us` into compiling, executable Lean 4, validated by differential testing against the live Python implementation.

---

## 1. Strategic context (why this exists)

US statutory law has two families of formalization:

- **Deep embeddings** (Catala, s(CASP), Z3 encodings): logic is inspectable syntax, so formal engines can check consistency, completeness, and equivalence. Coverage: a handful of Internal Revenue Code sections, done as research.
- **Shallow embeddings** (PolicyEngine US, built on the OpenFisca framework): the largest living formalization of US law — most of the federal income tax code plus SNAP and other benefit programs, all 50 states — but each rule is an opaque Python/NumPy formula. It can be *run* and *read*, not *reasoned over*. Correctness rests entirely on unit tests.

This project bridges them: recover a deep, symbolic representation from PolicyEngine's shallow one by transpiling its formulas into Lean 4. Lean is chosen over Coq/F* for three reasons: (a) mathlib provides real/rational arithmetic and order theory for free, (b) Lean 4 programs are executable, so the transpiled artifact is simultaneously spec and engine, and (c) the AI-assisted proving ecosystem (which will eventually discharge proof obligations at scale) is concentrated on Lean.

**Precedent that de-risks this:** Catala has been embedded into Coq ("Turning Catala into a Proof Platform for the Law," Delaët et al., ProLaLa 2022; Delaët's 2022–2025 PhD). Nobody has done proof-assistant work on PolicyEngine or on US law in Lean. This is a first.

**Eventual payoff (out of scope for Phase 1, but shapes the design):**
1. Structural theorems: net-income continuity except at enumerated cliffs, phase-out monotonicity, marginal-rate bounds.
2. Mechanical checks: exhaustiveness, unreachable branches, dead parameters.
3. Differential verification: prove PolicyEngine's encoding of a section extensionally equal to Catala's independent encoding of the same section — or extract a counterexample, which is a machine-discovered statutory ambiguity.

### 1a. Adoption strategy (a design constraint, not marketing)

The hard requirement on this project is that the canonical artifact is a **deep embedding** — inspectable syntax a formal engine can reason over, never terminal closures. The adoption bet is the **verified-twin pattern**: nobody is asked to learn a new language. PolicyEngine contributors keep writing PolicyEngine Python; the extractor maintains the symbolic Lean twin in CI; and the *product* Lawlib ships to the outside world is **findings** — automatically generated, never-wrong reports of the form "this PR introduces an unintended benefit cliff at $23,410 for single filers with two children," posted as CI comments and writeups. Adoption tracks true surprising findings, not architecture. Two consequences for the agent:
- Anything that risks a false finding (a mistranslation) is worse than anything that reduces coverage (a rejection). This is why the extractor is rejection-based (§5).
- The finding-report path gets built early (see milestone M6), even in crude form, rather than waiting for Phase 2.

Terminological note: the generated Lean `def`s are, strictly, a shallow embedding *within* Lean — but Lean terms are data (`Expr`) accessible to metaprogramming, so the representation is deep relative to the checking engine, which is what the requirement means. The deep/shallow line that matters is engine-facing, not human-facing.

## 2. Phase 1 scope

**In scope**
- A Python-side extractor (`pe2lean`) that reads `policyengine-us` variable definitions and parameter YAML for the **federal EITC subtree** and emits Lean 4 source.
- A small hand-written Lean prelude (`PolicyEngine/Core.lean`) defining the semantic domain: money as exact rationals, entity structures, parameter lookup, the vector-operation primitives.
- A differential test harness: generate random households, evaluate EITC in both Python and compiled Lean, compare exactly (after the rounding policy in §6).
- CI that re-runs extraction + diff tests, pinned to a specific `policyengine-us` version.

**Explicitly out of scope for Phase 1**
- Any proofs. Phase 1 produces *definitions* that compile and agree with Python. Theorems are Phase 2.
- State taxes, benefits programs, microdata/microsimulation, behavioral responses.
- Handling every formula in the repo. The extractor **rejects** what it cannot translate (see §5). Phase 1 succeeds if the EITC subtree extracts cleanly; a rejection report for the rest of the codebase is a deliverable, not a failure.
- Catala interop (Phase 3).

**Why EITC:** it is self-contained, heavily parameterized (phase-in/phase-out rates, thresholds by filing status and child count — a naturally enum-shaped computation), economically important, has known cliff/plateau structure worth proving things about later, and its Catala-adjacent literature (Lawsky's §121/§132 work) gives Phase 3 a comparison target.

## 3. Source material: how policyengine-us is structured

Repo: `https://github.com/PolicyEngine/policyengine-us` (pip: `policyengine-us`). Pin an exact release in `requirements.txt` and record it in `EXTRACTION_MANIFEST.json`; the codebase changes weekly with legislation.

Three things matter:

**Variables.** Each is a Python class in `policyengine_us/variables/...` subclassing `Variable`, with class attributes (`entity` ∈ {Person, TaxUnit, SPMUnit, Family, Household, MaritalUnit}, `value_type` ∈ {float, int, bool, Enum, str}, `definition_period`, usually `YEAR`, `unit`, e.g. USD) and optionally a `formula(entity, period, parameters)` method. Variables without a formula are **inputs**. The EITC subtree lives under `policyengine_us/variables/gov/irs/credits/eitc/`. Start from the root variable `eitc` (or `earned_income_tax_credit` — verify the current name in the pinned version) and walk the dependency closure: every variable name referenced via `tax_unit("x", period)`, `person("x", period)`, `add(...)`, etc. Expect roughly 15–40 variables in the closure; inputs (e.g. `employment_income`, `age`, `is_tax_unit_dependent`, filing status) terminate the recursion.

**Parameters.** YAML files under `policyengine_us/parameters/gov/irs/credits/eitc/`, forming a tree mirrored by the Python access path `parameters(period).gov.irs.credits.eitc.<...>`. Leaf values are date-keyed:

```yaml
values:
  2023-01-01: 0.34
  2024-01-01: 0.34
```

Some are scales/brackets (piecewise structures) rather than scalars; some are indexed by number of children. Parameters are **data, not code** — this is the already-transparent part of PolicyEngine, and it maps directly to Lean structures indexed by date.

**Formula bodies.** Vectorized NumPy over entity arrays. The idioms that appear in practice (this list is close to exhaustive for tax-credit code):

- arithmetic: `+ - * /`, comparisons, boolean `& | ~`
- `where(cond, a, b)`, `select([c1, c2, ...], [v1, v2, ...], default)`
- `min_(a, b)`, `max_(a, b)`, `clip(x, lo, hi)`
- entity aggregation/broadcast: `tax_unit.sum(person_level_values)`, `tax_unit.max(...)`, `tax_unit.any(...)`, `person.tax_unit("x", period)` (broadcast down), `tax_unit.members(...)`
- parameter lookup, including bracket/scale application: `p.phase_in_rate[n_children]`, `scale.calc(income)`
- occasional `np.round`/rounding helpers, `astype`, and Enum comparisons (`filing_status == FilingStatus.JOINT`)

Semantically, each formula is a **total, terminating, effect-free function** from (inputs of its entity + values of other variables + parameters at a date) to a value. Vectorization is an implementation detail: the per-member semantics is scalar. The extractor's job is to recover that scalar function.

## 4. Target design: the Lean side

Directory `lean/` with a `lakefile.lean`, toolchain pinned via `lean-toolchain` (latest stable Lean 4). Depend on mathlib (for `ℚ`, `Decidable`, order lemmas; acceptable cost even though Phase 1 proves nothing — Phase 2 needs it and switching later is painful).

**`PolicyEngine/Core.lean` (hand-written, small — target under 300 lines):**

```lean
/-- Money and rates are exact rationals. Never Float. See §6. -/
abbrev USD := ℚ
abbrev Rate := ℚ

/-- Statutory rounding: round half up to whole dollars (verify against
    the specific rounding PolicyEngine applies for EITC, and encode
    THAT; the rounding rule is part of the law, not a numeric accident). -/
def roundUSD (x : USD) : USD := ...

structure Date where
  year : Nat
  month : Nat
  day : Nat
deriving DecidableEq, Repr

/-- A date-keyed parameter: the YAML `values` map becomes a sorted list
    of (effective_date, value); lookup = last entry ≤ query date. -/
structure DatedParam (α : Type) where
  entries : List (Date × α)   -- sorted ascending, nonempty
def DatedParam.at (p : DatedParam α) (d : Date) : α := ...
```

**Entity model.** Do not reproduce OpenFisca's dynamic entity system. Phase 1 needs only Person and TaxUnit:

```lean
structure Person where
  employment_income : USD
  self_employment_income : USD
  age : Nat
  is_disabled : Bool
  -- ... exactly the input variables the EITC closure demands, discovered by the extractor
structure TaxUnit where
  members : List Person
  filing_status : FilingStatus
  -- ... tax-unit-level inputs
```

`tax_unit.sum(f)` becomes `(t.members.map f).sum`; `any` becomes `List.any`; broadcasts become plain function application. The extractor emits these structures (they belong in generated code, since the field list is derived from the dependency closure), while `Core.lean` holds only the domain types above.

**Generated code shape.** One Lean def per PolicyEngine variable, one namespace per parameter subtree. Preserve provenance:

```lean
/-- policyengine_us/variables/gov/irs/credits/eitc/eitc_phase_in.py
    pe-us version 1.xxx.x, extracted 2026-07-26.
    26 U.S.C. §32(a)(1). -/
def eitc_phase_in (t : TaxUnit) (d : Date) : USD :=
  min (Params.eitc.max_amount.at d (childCount t))
      (Params.eitc.phase_in_rate.at d (childCount t) * earned_income t d)
```

Dependency order is topological (formulas are acyclic in practice; a cycle is an extractor error — report it, don't paper over it). Every generated def must carry the source path and, where the Python docstring cites it, the statutory reference — provenance is the point of the whole exercise.

Mark the root and make it runnable: a `Main.lean` that reads a JSON household from stdin and prints the EITC value, for the harness in §7. JSON codecs for `Person`/`TaxUnit` can be derived or hand-rolled; keep rationals in JSON as strings `"3417/100"` or integer cents to avoid float round-trips.

## 5. The extractor: rejection-based, not best-effort

`pe2lean/` is a Python package. Pipeline:

1. **Load** the pinned `policyengine-us` package; resolve the EITC root variable; compute the dependency closure by static inspection of formula source (`inspect.getsource` + `ast.parse`), *not* by tracing execution. Dynamic dispatch you cannot resolve statically → reject.
2. **Parse** each formula's AST into a small typed IR (~15 node kinds: Lit, ParamRef, VarRef, Arith, Cmp, BoolOp, Where, Select, MinMax, Clip, Agg, Broadcast, EnumCmp, Round, ScaleApply).
3. **Reject loudly** anything outside the IR: loops, try/except, mutation of nonlocal state, unrecognized function calls, string manipulation, `.astype` tricks that change semantics, dynamic parameter paths. A rejection names the file, line, AST node, and reason, and is collected into `rejection_report.md`. **A wrong translation is far worse than a rejection** — rejections are actionable (rewrite the formula upstream into the fragment, or extend the IR deliberately); silent mistranslations poison every downstream theorem.
4. **Type-check the IR** (money vs. rate vs. count vs. bool; entity level of every subexpression). PolicyEngine is dynamically typed; this step catches both extractor bugs and, occasionally, real upstream type confusions — log the latter as findings.
5. **Emit** Lean: parameters first (from YAML — this path is mechanical and should be near-total), then entity structures, then variable defs in topological order.

Practical warnings from the source material:
- Formulas access sibling values via string names (`tax_unit("eitc_phase_out", period)`); the closure walk must collect string literals from these call patterns.
- Bracket/scale parameters (`scale.calc(x)`) need a dedicated IR node and a `Core.lean` piecewise-linear apply function; do not inline them.
- Some formulas branch on `period` or use `period.start.year`; translate as `Date` accesses.
- `add(tax_unit, period, ["a", "b"])` is sugar for summing listed variables across members; common, worth first-class IR support.
- Enums: emit a Lean `inductive` per PolicyEngine Enum encountered (e.g. `FilingStatus`), deriving `DecidableEq`.

## 6. Numerics policy (the one genuinely subtle decision)

PolicyEngine computes in float64. The Lean semantics is **exact ℚ**. This divergence is intentional: the *law's* semantics is exact decimal arithmetic with statutory rounding, and IEEE 754 is an implementation accident of the Python engine. Consequences:

- Translate float literals via their decimal source text (`0.34` → `34/100`), never via their binary value. Read literals from the AST/YAML text, not from evaluated Python objects.
- Divergences in differential testing of the form "Lean says $3,417, Python says $3,416.9999999998" are **findings about PolicyEngine**, not test failures. The harness must compare after applying the statutory rounding to both sides, and log pre-rounding deltas above 1e-6 dollars separately.
- Locate where PolicyEngine rounds EITC (search the subtree for rounding calls and check its own unit tests' precision) and mirror exactly that placement of `roundUSD` in generated code. If PolicyEngine's rounding placement differs from the statute's, that is a finding — record it, mirror PolicyEngine anyway (Phase 1 validates the *translation*, not the law), and file it for Phase 2.

## 7. Differential test harness (the trust anchor)

The extractor is now the trusted component; this harness is what earns that trust (translation-validation posture, à la CompCert).

- `harness/generate.py`: sample N random households — vary member count (1–8), ages, incomes (log-uniform 0–$300k, with mass at 0), filing statuses, disability flags, dependent structure. Include adversarial points: exact phase-in/phase-out boundary incomes at each child count (read thresholds from the parameter YAML), $0, negative self-employment income if the schema allows it.
- Evaluate each household through (a) `policyengine-us`'s `Simulation` API and (b) the compiled Lean binary via JSON stdin.
- Exact match after rounding policy. Any mismatch dumps the household JSON as a minimized repro case.
- **Acceptance for Phase 1: 100,000 households, zero unexplained mismatches, across at least tax years 2022–2025** (parameter lookup across years is where date bugs hide).

CI (GitHub Actions): build Lean, run extractor, fail if generated code differs from committed generated code (extraction must be deterministic), run 10k-household diff on every push and the 100k suite nightly. When bumping the pinned `policyengine-us` version, re-extract and re-run; a new rejection or mismatch blocks the bump.

## 8. Repository layout

```
lawlib/
  pe2lean/                  # extractor (Python)
    ir.py  parse.py  typecheck.py  emit_lean.py  params.py  closure.py
  lean/
    lakefile.lean  lean-toolchain
    PolicyEngine/Core.lean            # hand-written
    PolicyEngine/Generated/           # never hand-edited
    Main.lean
  harness/
    generate.py  run_diff.py
  rejection_report.md       # generated
  EXTRACTION_MANIFEST.json  # pe-us version, variable list, hashes, date
  README.md
```

## 9. Milestones

1. **M1 — skeleton:** Lake project builds; `Core.lean` compiles; extractor loads pinned pe-us and prints the EITC dependency closure with each variable classified translate/reject.
2. **M2 — parameters:** full EITC parameter YAML subtree → Lean, with a spot-check test comparing `DatedParam.at` lookups against PolicyEngine's parameter API for 20 (parameter, date) pairs.
3. **M3 — first formula:** simplest leaf formula translated end-to-end; single-household diff passes.
4. **M4 — full subtree:** entire EITC closure extracts (or is knowingly rejected with upstream-rewrite notes); Lean builds; 1k-household diff passes.
5. **M5 — acceptance:** 100k-household, multi-year diff clean; CI green; `rejection_report.md` and manifest committed; short writeup of any numeric/rounding findings about PolicyEngine discovered along the way.
6. **M6 — first finding (stretch, but prioritized over polish):** a crude cliff/discontinuity scanner over the generated defs — sweep earned income at fine granularity for each (filing status, child count) cell across tax years, flag every point where EITC (and, if inputs allow, EITC-inclusive net income) jumps discontinuously or the effective marginal rate exceeds a threshold; classify each as statutorily intended (matches a bracket boundary in the parameter YAML) or unexplained. No proof machinery needed — evaluation of exact-ℚ functions on a grid suffices. One unexplained item, verified by hand, becomes Lawlib's first published finding. This milestone exists because findings, not infrastructure, drive adoption (§1a).

## 10. Phase 2+ preview (do not build now, do not preclude)

- Theorems on the generated defs: `eitc` is continuous and piecewise-linear in earned income for fixed household shape; monotone on the phase-in; zero beyond the phase-out end. Failed proofs of continuity localize cliffs, upgrading M6's empirical grid scan into exhaustive symbolic guarantees.
- Exhaustiveness/dead-branch checks as `decide`-able props.
- Catala's IRC encodings transpiled into the same Lean namespace; equivalence theorem or counterexample (a machine-found statutory ambiguity).
- Extend the extractor fragment toward CTC/child-care credits (structurally similar to EITC).

## 11. Key references

- PolicyEngine US: github.com/PolicyEngine/policyengine-us; docs at policyengine.github.io/policyengine-us
- OpenFisca (framework semantics): openfisca.org/doc
- Catala: catala-lang.org; Merigoux, Chataing, Protzenko, "Catala: A Programming Language for the Law," ICFP 2021
- Delaët, Merigoux, Fromherz, "Turning Catala into a Proof Platform for the Law," ProLaLa 2022 (the Coq precedent for proof-assistant embedding of legal code)
- Lawsky's Z3/Catala inconsistency work on IRC §121 (arXiv 2511.11954 discusses the pipeline) — the model for what "findings" look like
- CUTECat (ESOP 2025): what becomes possible once legal logic is symbolic
- 26 U.S.C. §32 (the EITC statute itself — generated code should cite subsections)
