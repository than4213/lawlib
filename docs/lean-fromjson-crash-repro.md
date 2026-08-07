# Lean 4.32.1: segfault in compiled code decoding a 156-field structure

Standalone reproducer for the runtime crash that blocked lawlib's Phase
B2 (findings 16). To be filed upstream + posted to the Lean Zulip.

## Summary

A structure with **156 or more fields** and a derived `Lean.FromJson`
instance segfaults **in compiled executables** when `fromJson?` is
applied. 155 fields work. The crash is deterministic and the boundary
is exact (bisected: 155 passes, 156 crashes).

- Crash site: `mi_malloc_small` ← `lean_alloc_ctor` ←
  `lp_<pkg>_instFromJsonBig_fromJson` ← `lean_obj_once_cold` — i.e.
  inside the lazy once-initialization of the derived instance's closed
  term, on an ordinary constructor allocation.
- The **interpreter is unaffected**: `lake env lean --run Main.lean`
  decodes correctly; only the compiled binary crashes.
- Sometimes the segfault fires later (heap corruption): with wider
  structures (~210 fields) the decode "succeeds" and an unrelated later
  allocation crashes (`Json.compress`, mimalloc segment alloc, ...).
- Toolchain: leanprover/lean4:v4.32.1, Linux x86-64 (WSL2), default
  lake project, no dependencies.

## Reproducer

`lakefile.toml`:
```toml
name = "repro"
version = "0.1.0"
defaultTargets = ["repro"]

[[lean_exe]]
name = "repro"
root = "Main"
```

Generate `Main.lean` (change 156 → 155 to see it pass):
```bash
python3 - <<'PY'
n = 156
decl = "\n".join(f"  f{i} : Nat" for i in range(n))
open("Main.lean","w").write(f"""import Lean.Data.Json
open Lean

structure Big where
{decl}
deriving FromJson

def main : IO Unit := do
  let j := Json.mkObj <| (List.range {n}).map fun i => (s!"f{{i}}", toJson i)
  match fromJson? (α := Big) j with
  | .error e => IO.println s!"decode error: {{e}}"
  | .ok b => IO.println s!"decoded: f0={{b.f0}} f155={{b.f155}}"
  let xs := (List.range 100000).map (· * 2)
  IO.println s!"alloc wave ok: {{xs.length}}"
""")
PY
lake build && ./.lake/build/bin/repro   # segfault (exit 139)
lake env lean --run Main.lean           # works: "decoded: f0=0 f155=155"
```

## Notes for the report

- Found while compiling a ~200-field generated structure (US household
  model in github.com/than4213/lawlib); at that width the corruption is
  deferred and the crash wanders, which cost several days to localize.
- Plain construction of the same structure (`{ f0 := 42 }` with
  defaults) is fine — only the derived-`FromJson` decode path in
  compiled code breaks.
- Deriving `Repr`/`ToJson` alongside doesn't change the behavior;
  `FromJson` alone suffices.
- Reproduces identically on **v4.32.2** (latest stable) and on
  **v4.33.0-rc1** — re-verified 2026-08-07 on a clean project with no
  dependencies: compiled binary exits 139 (SIGSEGV), the interpreter
  on the same file prints `decoded: f0=0 f155=155`.

## Workaround (what lawlib does)

pe2lean caps every generated structure at 128 fields, splitting wider
domains into `_pN` part-structs (`extract.py STRUCT_FIELD_CAP`), and
splits the memoized evaluator's output record the same way.
