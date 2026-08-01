# Zulip draft 1: bug thread (post first, in #lean4 or #general)

**Topic: Segfault: compiled `FromJson` on structures with ≥ 156 fields**

Hi! While mechanically translating a large statutory model into Lean
(more on that in a separate thread once it's polished), we hit a
runtime crash with a crisp boundary, and I wanted to report it with a
minimal repro before filing an issue.

**TL;DR**: on v4.32.1 and v4.32.2 (Linux x86-64), a structure with
**156+ fields** and `deriving Lean.FromJson` segfaults *in compiled
executables* when `fromJson?` runs. 155 fields are fine — we bisected
the boundary exactly. The interpreter (`lake env lean --run`) decodes
the same program correctly; only compiled code breaks. With wider
structures (~200 fields) the corruption is deferred — the decode
"succeeds" and some unrelated later allocation crashes — which made
this delightful to localize.

Backtrace bottoms out in `mi_malloc_small` ← `lean_alloc_ctor` ←
`lp_…_instFromJsonBig_fromJson` ← `lean_obj_once_cold`, i.e. during the
lazy initialization of the derived instance's closed term.

Repro (single file + empty lake project): [attach/inline the generator
from docs/lean-fromjson-crash-repro.md]

Happy to file this on GitHub — is there prior art I should link? And is
there a known object-model or codegen limit near 155 that this is
tripping?
