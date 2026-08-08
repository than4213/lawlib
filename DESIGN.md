# Lawlib — Design

How this library is built, and why. Start with the principle in §1: the
rest of the architecture follows from it.

---

## 1. The governing principle: constructed systems, not observed data

Lawlib is built on one strict rule: **things we construct and things
we observe are different kinds of knowledge, and they never mix
silently.**

### The two columns

| | Constructed (math, CS, law) | Observed (the sciences) |
|---|---|---|
| What it is | Made of texts — the text *is* the thing | About the world |
| How truth is settled | By derivation: prove it from the texts | By evidence: observe and infer |
| Native tool | Machine-checked proof, exact arithmetic | Statistics, measurement, replication |
| Can a formalization be complete? | Yes | No — always a model plus evidence |
| Lives in | lawlib (the library) | the test/claims layer |

Law belongs in the first column. No experiment can confirm or refute
what 26 U.S.C. §32 says — the text settles it. That is why lawlib can
be exact (fractions, never floating point) and proved (theorems, not
test suites): "the EITC has no benefit cliffs" is true in the same way
"addition is commutative" is true.

Statistics is the engine of the second column — the foundation for
finding out what's true about the world. It is *not needed* in the
first column at all. Keeping it out of the library is not a
limitation; it is the design.

### Law's ambiguity is incompleteness, not observation

Law is often ambiguous — but not because it is about the world. It is
ambiguous because its texts are **incomplete**. When a decision is
needed at an ambiguous point, whoever decides — an agency, a court —
is not discovering a fact. They are **making more law**: a further
text, from a further source.

A concrete case (findings #8–9): the statute's literal EITC arithmetic
gives $599.76; the IRS's published tables say $600. Neither is "the
real value" in any experimental sense. They are two texts from two
sources of law, and the right move is what this project did:
formalize both and **prove exactly how far apart they are** — 24
cents. No data was consulted, because none is relevant.

Mathematics does the same thing constantly. `0^0 = 1` is a convention
completing an underdetermined definition; Lean's own `x / 0 = 0` is a
convention chosen so division is always defined. Nobody claims an
experiment justified either. Math's human record is fallible the same
way law's is — a famous "proof" of the four-color theorem stood
accepted for eleven years before the error was found — which is why
proof checkers exist: the checker is mathematics' court of final
appeal, and lawlib inherits it.

One structure law has that math doesn't need: in math, a convention
binds no one — rival conventions can coexist because nothing turns on
uniformity. Law requires uniformity, so it carries a **binding order
of authority** over its texts: statute, regulation, agency practice,
judicial decision, each with precedence and effective dates. That
ordering is itself law, itself a text, itself formalizable. Law is
math **plus a ranking of its texts** — a feature to model, not a leak
to plug.

What genuinely remains about the world is only the archival question:
*is this text really what the institution published?* That is
answered by document hashes and citations — bookkeeping, not
statistics.

### Programs have the same split, one level down

A program is a text; a *run* of it is a physical event. Finding #16
is the specimen: correct Lean source, but the compiled binary
corrupted memory. So "both engines agreed on 100,000 households" is
evidence about runs — it lives in the CI logs and the findings list,
never inside the library.

### The one crossing

The boundary between the columns is **typed, not walled**. Exactly one
kind of statement crosses it — the certified conditional:

> IF this dataset is the file with hash H, and the outside computation
> reported total T, THEN lawlib's total is within ε of T.

The proof checker certifies the arrow. It never certifies the "if".
The world enters only as named, unasserted hypotheses with their
evidence graded — and only in the test layer, never the library.

Held strictly, this shapes the whole repository:

- **`Lawlib/` is law only** — no data, no floats, no claims, no
  axioms. A new survey, a re-run, a re-measurement can never
  invalidate a lawlib proof.
- **Whatever the law itself generates is not stored as content.** The
  10,120-cell IRS table is *derivable* from a five-line rule, so the
  rule is in the library and the transcription is a test fixture.
- **`Tests/` holds everything that touches the world**: fixtures,
  claims about printed artifacts and executed programs, and their
  certified conditionals. It imports the library; the library never
  imports it.
- **Population studies never enter lawlib.** Poverty rates, program
  totals, optimization results — statements about people — are for a
  separate claims layer, with statistics, when that phase comes.

---

## 2. Scope: what counts as law here

**Lawlib contains United States federal law** — statutes and the
administrative rules made under their delegated authority — as
mechanically translated from policyengine-us.

### The authority taxonomy

| Content | Authority | In lawlib? |
|---|---|---|
| Statutes (IRC, Food and Nutrition Act, SSA…) | Congress | **Yes** |
| Regulations, Rev. Procs., published tables | Agencies, delegated | **Yes** (tagged administrative) |
| State/local/territory programs | State agencies/legislatures | **Out of scope for now** (regenerate with `pe2lean extract --scope all` when states become a priority) |
| `contrib/` reform proposals | Nobody — unenacted | No (not law) |
| CBO/BEA/TAXSIM comparison constructs | Modeling | No (not law) |
| Household modeling (poverty lines, cliffs, weights, expense rollups) | Modeling | No — where federal law references such quantities (e.g. childcare expenses in SNAP), they are **boundary inputs**: facts about households, supplied by the caller |
| Uprated projections | Forecasts | No (dropped since v0.8.1; the adjustment *rules* stay) |
| `household/demographic/` definitions (dependency, filing relationships) | Encodes statutory definitions | **Yes** |

### Completeness goal

Within this scope, the goal is **completeness**: every federal formula
either faithfully translated or a *documented* rejection
(pe2lean's `TODO.md`), and that list is a work queue to
drive to zero by extending the typed IR — never by loosening it.
Current state: 493 translated federal variables, 994 parameters,
64-variable diff-validated tier, quarantine empty.

---

## 3. Enacted law versus projected values

*Scan of policyengine-us 1.783.0's 5,615 parameter files (2026-08-01).*

### What the data actually shows

- Only **214 files** contain any entry dated ≥ 2027.
- Many far-future dates are **enacted law, not projections**: the DOE
  high-efficiency electric home rebate caps run to 2032 because the IRA
  says so; TCJA sunsets, OBBBA phase-in schedules, and program
  expirations all carry legitimate future effective dates.
- Genuinely projected values (inflation-uprated beyond the last
  published Rev. Proc.) sit in files whose values carry
  `metadata.uprating` — e.g. `gov/irs/credits/eitc/max.yaml` lists
  2017–2026 with `uprating: gov.irs.uprating`. As of this PE version
  those extend only ~1 year past the last IRS publication; the
  2030s-dated tail (findings §4) is mostly statutory schedules plus a
  handful of state uprating tables.

So a **date cutoff is wrong** in both directions, and the volume needing
classification is small (~214 files).

### Proposed rule (needs sign-off)

Classify each dated entry, recorded in `EXTRACTION_MANIFEST.json`:

1. `enacted` — entry in a file with no `uprating` metadata, or dated ≤
   the parameter's last referenced publication.
2. `projected` — entry in an uprating-bearing series dated after the
   last value corroborated by a reference (published Rev.-Proc. year).
3. `scheduled` — future-dated entry in a non-uprated series (statutory
   schedule; this is law).

`pe2lean extract --enacted-only` would then drop `projected` entries
(the twin refuses to answer for dates it has no law for — `DatedParam`
lookups past the last enacted entry could return the last enacted value
exactly as PE does today, or be flagged; **open question for Nathanael**).

### Open questions

1. Drop projected entries entirely, or keep them in a separate
   a clearly-labeled `Projected` namespace (data preserved, marked as forecast)?
2. When a date query lands beyond the last enacted entry, should
   `atDate` answer (carry-forward, PE-compatible) or should the
   manifest record the enacted-coverage horizon per parameter?
3. Is "last referenced publication year" per-file metadata reliable
   enough, or do we pin the IRS uprating boundary globally (last Rev.
   Proc. year = 2026)?

### Resolution (2026-08-01, decided with Nathanael)

A projection is not law — it is a forecast of a future administrative
act (projection = enacted adjustment rule x forecast CPI; the rule is
law and stays, the forecast number is not and goes). Implemented in
pe2lean v0.8.1:

- Uprating-bearing series drop entries dated >= 2027-01-01 except the
  statutory seed (series-first) entry: 429 entries / 55 parameters.
- Ledger in EXTRACTION_MANIFEST.json (projected_dropped) and the
  rejection report; future-year estimates can re-enter via the claims
  layer as T5 claims.
- atDate stays total (carry-forward is how law works for non-uprated
  parameters); Params.enactedHorizon (2026-12-31) is exported and the
  evaluator fails fast on later dates.

---

## 4. What is proved, and what is assumed

Uncertainty management for lawlib, in the
[Claimlib](https://github.com/than4213) claims-as-Props style: what the
kernel can't certify is a named `Prop` in
[`Tests/Claims.lean`](Tests/Claims.lean), never asserted; results
depending on it are certified *conditionals*. This ledger grades the
evidence behind each claim and names the cheapest way to firm it up.
Best guesses are welcome here — at their honest tier.

### Tiers

| Tier | Meaning | Trust base |
|---|---|---|
| **T0** | kernel-checked theorem | Lean kernel |
| **T1** | `native_decide` theorem (finite computation) | kernel + Lean compiler |
| **T2** | differential evidence (randomized, adversarial, repeated) | test harness + both engines |
| **T3** | tool-verified transcription of an external artifact | parser + source artifact |
| **T4** | probe / observation (reproducible, small n) | the probe script |
| **T5** | conjecture — best guess awaiting resources | the author's judgment |

### Interior results (no claims needed)

All of `Lawlib/Theorems/`: the trapezoid closed
forms, `eitc_continuous`, monotonicity, exact phase-out endpoints (T0);
the table-generator verification, PE-vs-table $11.50 bound, Catala
cross-encoding bounds and exact 24¢/50¢ plateau gaps, CTC cliff atlas
(T1). These are unconditional statements about *committed data*.

### Live claims

| Claim | Statement | Tier | Evidence | Firms up by |
|---|---|---|---|---|
| `claim_table_transcription` | committed `eicTable2023` = the printed IRS table | T3 | coordinate-based PDF parse; 1,265/1,267 rows; generator-consistency (T1) | independent transcription; the 2 split rows; IRS machine-readable data |
| `claim_pe_twin_eitc` | executed PE ≡ translated `eitc` ± 2¢ on canonical domain | T2 | 100k households/night, 5 years, 0 mismatches | more years/structure; asymptotic only |
| *(implicit)* CTC twin | executed PE ≡ translated `ctc` ± tolerance | T2 | 1k × 29 vars clean | promote to a named claim Prop |
| *(implicit)* Catala faithful | `catala2lean` output ≡ Catala interpreter | T1/T3 | 6 interpreter outputs as `native_decide` theorems | more test scopes; certified backend path |
| *(prose)* findings §9 legal reading | §32(f) makes the administered figure operative | T5 | statutory reading, unreviewed | legal review |
| *(prose)* findings §11 | PE set-input period coercion is path-dependent (0 / ÷12 / uprated) | T4 | 3 probes, 2026-07-27, reproducible scripts | policyengine-core source analysis (in progress); upstream confirmation |
| *(pending)* SNAP twin | translated SNAP chain ≡ executed PE | **T5** | translation builds (`snap-wip`); diff blocked on §11 | resolve input-semantics convention, then T2 |

### Composition examples

`Lawlib/Claims.lean` shows the pattern: `real_table_generator` and
`pe_formula_within_1150_of_real_table` turn T1 interior theorems into
statements about the *real* table under the T3 transcription claim;
`pe_executed_matches_real_table_at_20k` chains T3 + T2 to bound
*executed PolicyEngine* against the real table. The kernel certifies
every link; the ledger prices the endpoints.

### Policy

New assertions enter at their honest tier with evidence and a firm-up
path — a T5 guess with a named Prop beats an unstated assumption inside
a proof. Promotions are commits: better evidence moves a row up and the
git history records when and why.

### Data–logic membrane claims (retired from the library per
DESIGN.md §1 — population-facing claims belong to a separate
claims layer, not to a library of law; recoverable from git history)

| Claim | Tier | Evidence |
|---|---|---|
| `claim_cohort_hash` | T3 | `pe2lean-aggregate 1200 2000060` regenerates the artifact byte-for-byte; sha256 `9575863e…` |
| `claim_pe_cohort_eitc_total` | T4 | one pinned run (policyengine-us 1.783.0): PE EITC total over the 250-household year-2023 cohort ≈ $7,271.47 |
| `claim_twin_bound_on_cohort` | T2 | the same cohort diff-checked household-by-household; max observed \|PE − twin\| = 377/1280000 ≈ $0.000295 |

Certified conditional: `lawlib_cohort_eitc_total` — under the two
claims, lawlib's own cohort total is within 250 × $0.000295 ≈ $0.074
of PolicyEngine's number, by kernel-checked algebra alone
(`sum_dev_bound`). The pattern (opaque artifact + hash claim + tiered
numbers + triangle-inequality theorem) is the template for every
external aggregate — survey statistics included.

### Differential evidence ledger

Nightly acceptance (roots tier 8k + full tier 500 per night, rotating
seeds) accumulates fresh samples behind `claim_pe_twin_*`; deep-soak
history before the ledger began: ~500k households across the M5/M6 and
v0.6–v0.8 eras, zero mismatches beyond float32 tolerance.

---

## 5. Architecture

**Status:** Accepted (2026-07-26). Records the architectural decisions of the project: the two-repo split, Lean-community conventions, module hierarchy, revisioning, and the contracts between the repositories.

---

### 1. Two-repo architecture

| Repo | Contents | Language | Role |
|---|---|---|---|
| `lawlib` | The Lean library: hand-written core + committed generated code + manifest | Lean 4 | The product. Buildable by anyone with `lake build` alone. |
| `pe2lean` | Extractor + differential test harness | Python | The tool. Emits into a `lawlib` checkout; never a runtime dependency of `lawlib`. |

Rationale: `lawlib` follows the mathlib model — a self-contained Lean library a community can depend on, browse, and eventually contribute proofs to. Its consumers must never need a working Python/policyengine-us environment. `pe2lean` is developer tooling with a completely different dependency profile (numpy, policyengine-us, pytest) and release cadence.

#### 1.1 Local development layout

The two repositories are checked out as **siblings** inside a workspace directory:

```
starlib/                     # workspace, not source-controlled
  lawlib/                    # git repo #1
    Lawlib/                  # Core/, USA/, Parameters/, Theorems/
    Tests/ docs/ lakefile.toml lean-toolchain ...
  pe2lean/                   # git repo #2
    src/pe2lean/ scripts/ tests/ pyproject.toml ...
```

Each tool defaults to finding the other at `../lawlib` / `../pe2lean`, and both accept an explicit path. A submodule is deliberately avoided: submodule pinning would couple `lawlib`'s history to `pe2lean`'s, and the coupling we actually want is the *version pin in the manifest* (§4), not a git-level one.

(Earlier development nested `pe2lean` inside the `lawlib` working tree, gitignored. That made one repository's layout depend on the other's, and it meant a checkout of `lawlib` implied a directory that was not part of it. Siblings under a workspace generalize to further repositories without special cases.)

### 2. Lean-community conventions adopted

- **Naming:** library `Lawlib`, root module `Lawlib.lean` that imports every module (mathlib idiom; also what `lake` expects).
- **Build:** `lakefile.toml` (current community default for new projects), `lean-toolchain` pinned to the latest stable Lean release. Phase 1 ran with **zero dependencies** (everything generated code needs — `Rat`, `DecidableEq`, `Lean.Data.Json` — is core); **Phase 2 added mathlib** (pinned release tag matching the toolchain) for the order/algebra lemmas behind the ∀-theorems in `Lawlib/Theorems/`. As predicted, the flip changed no generated definition — mathlib's `ℚ` is core's `Rat` — with one caveat worth recording: Phase 1's home-grown `Min/Max Rat` instances had to be deleted in favor of mathlib's (identical definitionally, but lemmas target mathlib's instance path). Consumers now want `lake exe cache get` before building.
- **CI:** GitHub Actions using `leanprover/lean-action`, with `lake exe cache get` for mathlib olean caching. Build must be warning-clean; `lake build` is the only step needed to compile.
- **Style:** hand-written code (`Lawlib/Core/`) follows mathlib style — `UpperCamelCase` types/modules, `lowerCamelCase` defs, doc-strings on every public declaration.
- **Deliberate deviation:** generated defs keep PolicyEngine's `snake_case` variable names (`eitc_phase_in`, not `eitcPhaseIn`). Provenance and mechanical 1:1 mapping to the upstream source outrank naming style inside the generated modules; the deviation is confined there and noted in the README.
- **Docs:** doc-gen4 from day one is not required, but every generated def carries a doc-string with source path, pe-us version, and statutory citation (handoff §4), so doc generation is cheap to add later.
- **Hosting:** both repos on GitHub. Default branch `main`, PRs + CI gating, tags for releases (§4).

### 3. `lawlib` repo layout

```
lawlib/
  Lawlib.lean                  # root import file (imports Core + Gen roots)
  Lawlib/
    Core/                      # hand-written, < 300 lines total (handoff §4)
      Money.lean               #   USD := ℚ, Rate := ℚ, roundUSD
      Date.lean                #   Date, DatedParam, DatedParam.at
      Entity.lean              #   aggregation/broadcast helpers over List Person
      Json.lean                #   rational-as-string codecs for the harness
    Gen/                       # generated — NEVER hand-edited (CI-enforced, §5)
      Entities.lean            #   Person, TaxUnit, FilingStatus (field lists derived
                               #   from the dependency closure)
      Gov/Irs/Credits/Eitc/    #   mirrors policyengine_us/{parameters,variables}/gov/...
        Params.lean            #   YAML parameter subtree → DatedParam structures
        Variables.lean         #   one def per variable, topological order
  Main.lean                    # JSON household on stdin → EITC value on stdout
  lakefile.toml
  lean-toolchain
  EXTRACTION_MANIFEST.json     # generated: pe-us version, pe2lean version, variable
                               # list, source hashes, extraction date, law-date coverage
  docs/                        # handoff, this design, future finding writeups
  README.md
```

Notes:
- The `Gov/Irs/Credits/Eitc` path is the PE directory path case-converted to Lean module convention (`irs` → `Irs`); the conversion is mechanical and defined once in the emitter. Statute-based organization (`US/IRC/Section32`) was considered and rejected for now: the PE→statute mapping is curatorial, not mechanical, and a misfiled module is worse than an ugly path. Statutory citations live in doc-strings until a Phase-3 curated layer.
- `EXTRACTION_MANIFEST.json` is a generated artifact but is *committed* in `lawlib`: it describes the committed generated code, naming every declared input the caller must supply. What the translator could not yet express is pe2lean's work queue, not a property of the law, and lives in that repository.

### 4. Revisioning: law dates vs. git revisions

Two distinct time axes, deliberately kept apart:

1. **Effective date of law** — *data, inside the library.* Every parameter is a `DatedParam`: a sorted list of `(effective_date, value)`; lookup takes the last entry ≤ the query date. One checkout of `lawlib` computes any tax year in its covered range. This mirrors PolicyEngine and is required for cross-year rules (lookback provisions, prior-year references) that a single computation may need — a branch-per-year scheme cannot express those.
2. **Codification/extraction version** — *git history.* Each accepted extraction is tagged `pe-us-<version>` (e.g. `pe-us-1.155.0`) after CI passes. The manifest records, per extraction: the pe-us version, the pe2lean version, content hashes of every source file, and the **law-date coverage window** (the min/max effective dates present in the extracted parameters). No timestamp — the manifest is byte-deterministic so CI's re-extract-and-diff check needs no masking; extraction dates come from git history.

The "map from date of law to revision" the handoff asks for is therefore answered at two levels: within a checkout, `DatedParam.at` *is* the map; across history, `git tag` + the manifest's coverage window tell you which revision to check out for any (law date, codification date) pair. A `REVISIONS.md` index (one line per tag: tag, pe-us version, coverage window, notable changes) is maintained in `lawlib` so the mapping is browsable without spelunking tags.

Amendment history bonus: because pe-us version bumps arrive as diffs to *generated Lean*, `git diff pe-us-A pe-us-B -- Lawlib/USA/` is a machine-readable changelog of how the encoded law changed between codifications — this falls out for free and feeds the findings pipeline later.

### 5. `pe2lean` repo layout

```
pe2lean/
  pyproject.toml               # package metadata; policyengine-us pinned EXACTLY
  src/pe2lean/
    __init__.py  cli.py        # `pe2lean extract`, `pe2lean report`
    closure.py                 # dependency-closure walk (static AST, handoff §5.1)
    parse.py                   # Python AST → IR
    ir.py                      # ~15 typed node kinds (handoff §5.2)
    typecheck.py               # money/rate/count/bool + entity-level checking
    params.py                  # YAML parameter subtree → Lean
    emit_lean.py               # IR → Lean source; owns the path/name conversion
    manifest.py                # EXTRACTION_MANIFEST.json writer
  harness/
    generate.py                # random + adversarial household generation (handoff §7)
    run_diff.py                # Python-vs-Lean differential runner
  tests/                       # pytest: golden IR snapshots, emitter unit tests
  README.md
```

CLI contract: `pe2lean extract --lawlib <path>` (default `../lawlib`) writes **only** the files pe2lean owns in `lawlib`: `Lawlib/USA/`, `Lawlib/Parameters/`, `Household.lean`, `Categories.lean`, `Evaluator.lean`, `Serialization.lean`, and `EXTRACTION_MANIFEST.json`. It never touches `Lawlib/Core/`, `Main.lean`, or build files. Extraction is deterministic: same pe-us pin + same pe2lean version ⇒ byte-identical output (sorted iteration everywhere, no timestamps except the manifest's dated fields).

### 6. Cross-repo contracts

Three interfaces, all owned by this design:

1. **Generated-code contract** (§5): which paths pe2lean may write, determinism, and the manifest schema.
2. **Household JSON schema:** the harness and `Main.lean` share a JSON format for households — rationals encoded as strings (`"3417/100"`) or integer cents, never floats (handoff §6). The schema is versioned in a `schema_version` field; both sides reject unknown versions.
3. **Version pinning:** `lawlib`'s manifest pins `pe2lean` (exact version) and `policyengine-us` (exact version). `pe2lean`'s `pyproject.toml` pins `policyengine-us` to the same exact version. A pe-us bump is a PR to `pe2lean` (update pin, fix new rejections) followed by a PR to `lawlib` (re-extracted output + manifest); CI on the latter blocks on new mismatches per handoff §7.

### 7. CI

**`lawlib` CI (GitHub Actions):**
- every push/PR: `lake exe cache get`, `lake build` (warning-clean), then install the pinned `pe2lean` + `policyengine-us`, re-run extraction into a temp dir, and `diff -r` against the committed modules + manifest — any drift fails (determinism + never-hand-edited enforcement in one check); then the 10k-household differential run.
- nightly: 100k-household, multi-year differential suite (handoff §7 acceptance).

**`pe2lean` CI:**
- every push/PR: pytest; end-to-end smoke — extract into a scratch `lawlib` checkout, `lake build`, 1k-household diff.

Neither CI triggers the other; the coupling is the explicit version-pin PR flow in §6.3. (Bot-driven cross-repo PRs were considered and deferred — no cross-repo tokens/automation until the manual flow proves out.)

### 8. Milestones

Unchanged from handoff §9 (M1–M6), with the repo split folded in:
- **M1 (skeleton)** now means: both repos initialized with the layouts above, `lawlib` CI green on an empty-`Gen` build, `pe2lean` prints the classified EITC closure.
- Extraction deliverables (manifest, diff-clean) land as commits plus a `pe-us-<version>` tag in `lawlib`.
- M6 (cliff scanner / first finding) lives in `pe2lean` (`harness/` or a `findings/` sibling), since it evaluates the compiled Lean binary over grids — no Lean metaprogramming needed in Phase 1.

### 9. Decisions log

| Decision | Choice | Alternatives rejected |
|---|---|---|
| Repo split | `lawlib` (Lean) + `pe2lean` (tooling), nested-gitignored local layout | monorepo (handoff default); submodule |
| Transpiler name | `pe2lean` | `PolicyEngineToLawlib`, `lawlib-extractor` |
| Generated code home | committed in `lawlib`, CI re-derives and diffs | bot PRs; extract-at-build-time |
| Revisioning | date-keyed data + `pe-us-*` tags + manifest coverage windows | branch-per-law-year; per-year frozen views |
| Module hierarchy | `Lawlib/Core` hand-written + `Lawlib/USA` by administering agency | statute-based (`US/IRC/Section32`); flat `Generated/` |
| Build config | `lakefile.toml` | `lakefile.lean` |
| mathlib | deferred to Phase 2 (core `Rat` suffices; same type, so no migration) | depend now per handoff §4 |
| Generated naming | keep PE `snake_case` in `Gen/`, mathlib style in `Core/` | full mathlib-style renaming |
