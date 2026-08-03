# Parked: population-facing claims (destined for claimlib)

`Data.lean` was the first data-membrane vertical slice: an opaque
cohort artifact (household data) + its sha256 + an externally-computed
PolicyEngine total (T4) + a pointwise twin bound (T2) + a
kernel-proved triangle-inequality lemma + a certified conditional
("IF the data is D and PE reported T, THEN lawlib's total is within
eps of T").

Parked out of the Lawlib library under the categories doctrine
(docs/categories.md): lawlib contains law only — claims about
*populations and datasets* are claims-layer content and belong in a
separate library (claimlib). The generic lemma and the certified-
conditional pattern move there when that phase starts.

The cohort numbers here are stale anyway (v0.9.0-era input schema);
regenerate with `pe2lean-aggregate` before reviving.
