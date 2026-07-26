# Lawlib — Design

**Status:** Accepted (2026-07-26). Complements [lawlib-handoff.md](lawlib-handoff.md), which holds the strategic context, extractor semantics (§5), numerics policy (§6), and differential-testing acceptance criteria (§7). This document records the architectural decisions layered on top of the handoff: the two-repo split, Lean-community conventions, module hierarchy, revisioning, and the contracts between the repos.

---

## 1. Two-repo architecture

| Repo | Contents | Language | Role |
|---|---|---|---|
| `lawlib` | The Lean library: hand-written core + committed generated code + manifest | Lean 4 | The product. Buildable by anyone with `lake build` alone. |
| `pe2lean` | Extractor + differential test harness | Python | The tool. Emits into a `lawlib` checkout; never a runtime dependency of `lawlib`. |

Rationale: `lawlib` follows the mathlib model — a self-contained Lean library a community can depend on, browse, and eventually contribute proofs to. Its consumers must never need a working Python/policyengine-us environment. `pe2lean` is developer tooling with a completely different dependency profile (numpy, policyengine-us, pytest) and release cadence.

### 1.1 Local development layout

`pe2lean` is cloned *inside* the `lawlib` working tree as a nested, independent git repo (not a submodule), and ignored by `lawlib`'s `.gitignore`:

```
lawlib/                      # git repo #1
  .gitignore                 # contains: pe2lean/
  Lawlib/ Lawlib.lean Main.lean lakefile.toml lean-toolchain ...
  docs/
  pe2lean/                   # git repo #2, nested, gitignored by repo #1
    src/pe2lean/ harness/ tests/ pyproject.toml ...
```

This keeps the default `pe2lean extract` target (`../Lawlib/Gen`, relative to the nested checkout) trivially correct on every developer machine while keeping the histories fully independent. A submodule is deliberately avoided: submodule pinning would couple `lawlib`'s history to `pe2lean`'s, and the coupling we actually want is the *version pin in the manifest* (§4), not a git-level one.

## 2. Lean-community conventions adopted

- **Naming:** library `Lawlib`, root module `Lawlib.lean` that imports every module (mathlib idiom; also what `lake` expects).
- **Build:** `lakefile.toml` (current community default for new projects), `lean-toolchain` pinned to the latest stable Lean release. **Zero dependencies in Phase 1** — everything the generated code needs (`Rat` exact rationals, `DecidableEq` deriving, `Lean.Data.Json` for the harness) is in Lean core, so `lake build` works instantly with no mathlib cache. mathlib is added in Phase 2 when theorems need its order/algebra lemmas; since mathlib's `ℚ` is literally core's `Rat` with instances layered on top, adding it later changes no generated definition. The toolchain pin tracks versions mathlib supports so the Phase 2 upgrade stays cheap.
- **CI:** GitHub Actions using `leanprover/lean-action`, with `lake exe cache get` for mathlib olean caching. Build must be warning-clean; `lake build` is the only step needed to compile.
- **Style:** hand-written code (`Lawlib/Core/`) follows mathlib style — `UpperCamelCase` types/modules, `lowerCamelCase` defs, doc-strings on every public declaration.
- **Deliberate deviation:** generated defs keep PolicyEngine's `snake_case` variable names (`eitc_phase_in`, not `eitcPhaseIn`). Provenance and mechanical 1:1 mapping to the upstream source outrank naming style inside `Lawlib/Gen/`; the deviation is confined there and noted in the README.
- **Docs:** doc-gen4 from day one is not required, but every generated def carries a doc-string with source path, pe-us version, and statutory citation (handoff §4), so doc generation is cheap to add later.
- **Hosting:** both repos on GitHub. Default branch `main`, PRs + CI gating, tags for releases (§4).

## 3. `lawlib` repo layout

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
  rejection_report.md          # generated: what wasn't translated, and why
  docs/                        # handoff, this design, future finding writeups
  README.md
```

Notes:
- The `Gov/Irs/Credits/Eitc` path is the PE directory path case-converted to Lean module convention (`irs` → `Irs`); the conversion is mechanical and defined once in the emitter. Statute-based organization (`US/IRC/Section32`) was considered and rejected for now: the PE→statute mapping is curatorial, not mechanical, and a misfiled module is worse than an ugly path. Statutory citations live in doc-strings until a Phase-3 curated layer.
- `EXTRACTION_MANIFEST.json` and `rejection_report.md` are generated artifacts but are *committed* in `lawlib` — they describe the committed generated code and are part of the library's public claim about its own coverage.

## 4. Revisioning: law dates vs. git revisions

Two distinct time axes, deliberately kept apart:

1. **Effective date of law** — *data, inside the library.* Every parameter is a `DatedParam`: a sorted list of `(effective_date, value)`; lookup takes the last entry ≤ the query date. One checkout of `lawlib` computes any tax year in its covered range. This mirrors PolicyEngine and is required for cross-year rules (lookback provisions, prior-year references) that a single computation may need — a branch-per-year scheme cannot express those.
2. **Codification/extraction version** — *git history.* Each accepted extraction is tagged `pe-us-<version>` (e.g. `pe-us-1.155.0`) after CI passes. The manifest records, per extraction: the pe-us version, the pe2lean version, content hashes of every source file, and the **law-date coverage window** (the min/max effective dates present in the extracted parameters). No timestamp — the manifest is byte-deterministic so CI's re-extract-and-diff check needs no masking; extraction dates come from git history.

The "map from date of law to revision" the handoff asks for is therefore answered at two levels: within a checkout, `DatedParam.at` *is* the map; across history, `git tag` + the manifest's coverage window tell you which revision to check out for any (law date, codification date) pair. A `REVISIONS.md` index (one line per tag: tag, pe-us version, coverage window, notable changes) is maintained in `lawlib` so the mapping is browsable without spelunking tags.

Amendment history bonus: because pe-us version bumps arrive as diffs to *generated Lean*, `git diff pe-us-A pe-us-B -- Lawlib/Gen/` is a machine-readable changelog of how the encoded law changed between codifications — this falls out for free and feeds the findings pipeline later.

## 5. `pe2lean` repo layout

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

CLI contract: `pe2lean extract --lawlib <path>` (default `..`, per the nested layout) writes **only** the files pe2lean owns in `lawlib`: everything under `Lawlib/Gen/`, `EXTRACTION_MANIFEST.json`, and `rejection_report.md`. It never touches `Lawlib/Core/`, `Main.lean`, or build files. Extraction is deterministic: same pe-us pin + same pe2lean version ⇒ byte-identical output (sorted iteration everywhere, no timestamps except the manifest's dated fields).

## 6. Cross-repo contracts

Three interfaces, all owned by this design:

1. **Generated-code contract** (§5): which paths pe2lean may write, determinism, and the manifest schema.
2. **Household JSON schema:** the harness and `Main.lean` share a JSON format for households — rationals encoded as strings (`"3417/100"`) or integer cents, never floats (handoff §6). The schema is versioned in a `schema_version` field; both sides reject unknown versions.
3. **Version pinning:** `lawlib`'s manifest pins `pe2lean` (exact version) and `policyengine-us` (exact version). `pe2lean`'s `pyproject.toml` pins `policyengine-us` to the same exact version. A pe-us bump is a PR to `pe2lean` (update pin, fix new rejections) followed by a PR to `lawlib` (re-extracted output + manifest); CI on the latter blocks on new mismatches per handoff §7.

## 7. CI

**`lawlib` CI (GitHub Actions):**
- every push/PR: `lake exe cache get`, `lake build` (warning-clean), then install the pinned `pe2lean` + `policyengine-us`, re-run extraction into a temp dir, and `diff -r` against the committed `Lawlib/Gen/` + manifest — any drift fails (determinism + never-hand-edited enforcement in one check); then the 10k-household differential run.
- nightly: 100k-household, multi-year differential suite (handoff §7 acceptance).

**`pe2lean` CI:**
- every push/PR: pytest; end-to-end smoke — extract into a scratch `lawlib` checkout, `lake build`, 1k-household diff.

Neither CI triggers the other; the coupling is the explicit version-pin PR flow in §6.3. (Bot-driven cross-repo PRs were considered and deferred — no cross-repo tokens/automation until the manual flow proves out.)

## 8. Milestones

Unchanged from handoff §9 (M1–M6), with the repo split folded in:
- **M1 (skeleton)** now means: both repos initialized with the layouts above, `lawlib` CI green on an empty-`Gen` build, `pe2lean` prints the classified EITC closure.
- The M4/M5 deliverables (`rejection_report.md`, manifest, diff-clean) land as commits + the first `pe-us-<version>` tag in `lawlib`.
- M6 (cliff scanner / first finding) lives in `pe2lean` (`harness/` or a `findings/` sibling), since it evaluates the compiled Lean binary over grids — no Lean metaprogramming needed in Phase 1.

## 9. Decisions log

| Decision | Choice | Alternatives rejected |
|---|---|---|
| Repo split | `lawlib` (Lean) + `pe2lean` (tooling), nested-gitignored local layout | monorepo (handoff default); submodule |
| Transpiler name | `pe2lean` | `PolicyEngineToLawlib`, `lawlib-extractor` |
| Generated code home | committed in `lawlib`, CI re-derives and diffs | bot PRs; extract-at-build-time |
| Revisioning | date-keyed data + `pe-us-*` tags + manifest coverage windows | branch-per-law-year; per-year frozen views |
| Module hierarchy | `Lawlib/Core` hand-written + `Lawlib/Gen` mirroring PE's `gov/...` path | statute-based (`US/IRC/Section32`); flat `Generated/` |
| Build config | `lakefile.toml` | `lakefile.lean` |
| mathlib | deferred to Phase 2 (core `Rat` suffices; same type, so no migration) | depend now per handoff §4 |
| Generated naming | keep PE `snake_case` in `Gen/`, mathlib style in `Core/` | full mathlib-style renaming |
