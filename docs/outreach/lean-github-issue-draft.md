# Draft: lean4 GitHub issue (file after the Zulip thread; paste-ready)

**Title**: Compiled code segfaults decoding a structure with ≥ 156 fields (derived `FromJson`); interpreter unaffected

**Labels suggestion**: bug, compiler:codegen

---

## Description

A structure with **156 or more fields** and a derived `Lean.FromJson`
instance segfaults **in compiled executables** when `fromJson?` runs.
155 fields work — we bisected the boundary exactly. The same program is
decoded correctly by the interpreter (`lake env lean --run Main.lean`);
only compiled binaries crash.

With wider structures (~200 fields) the corruption is deferred: the
decode appears to succeed and an unrelated later allocation crashes
(observed in `Json.compress`, `mi_segment_alloc`, and other sites),
i.e. the failure looks like heap corruption whose crash point wanders
with the workload.

## Reproduction

`lean-toolchain`: `leanprover/lean4:v4.32.1` (also reproduces on
v4.32.2). Linux x86-64 (WSL2, Ubuntu 24.04). Default lake project, no
dependencies.

```toml
# lakefile.toml
name = "repro"
version = "0.1.0"
defaultTargets = ["repro"]

[[lean_exe]]
name = "repro"
root = "Main"
```

Generate `Main.lean` (flip 156 → 155 to see it pass):

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
lake build && ./.lake/build/bin/repro   # Segmentation fault (exit 139)
lake env lean --run Main.lean           # OK: "decoded: f0=0 f155=155"
```

## Backtrace at the crash (gdb, n = 156)

```
#0  mi_malloc_small ()
#1  lean_alloc_ctor ()
#2  lp_repro_instFromJsonBig_fromJson ()
#3  lean_obj_once_cold ()
#4  _lean_main ()
```

i.e. inside the lazy once-initialization of the derived instance's
closed term, on an ordinary constructor allocation. Kernel fault
reports show reads at small offsets from null (`segfault at 10/27/28`),
consistent with a corrupted/uninitialized allocator or object pointer
rather than stack overflow (raising `--tstack` and `ulimit -s` to 1 GB+
changes nothing).

## Additional observations

- Plain construction of the same structure (record literal with
  defaults) is fine; only the derived-`FromJson` decode path in
  compiled code breaks.
- `deriving Repr`/`ToJson` alongside doesn't change behavior;
  `FromJson` alone suffices.
- Field types don't matter: all-`Nat`, and mixed
  `Rat`-like/`Bool`/`String` layouts crash identically at 156.
- Found while compiling a generated ~200-field structure in a large
  mechanically-generated codebase (github.com/than4213/lawlib); at that
  width the deferred-corruption variant cost us several days to
  localize, so a hard error above the supported width would be a
  kindness if the limit is intentional.

## Workaround

Cap generated structures at ≤ 128 fields (we split wider records into
nested part-structs).
