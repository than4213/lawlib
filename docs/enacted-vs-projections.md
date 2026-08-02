# Enacted law vs. uprated projections (charter: laws only)

*Scan of policyengine-us 1.783.0's 5,615 parameter files (2026-08-01).*

## What the data actually shows

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

## Proposed rule (needs sign-off)

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

## Open questions

1. Drop projected entries entirely, or keep them in a separate
   `Lawlib.Gen.Projected` namespace (data preserved, clearly labeled)?
2. When a date query lands beyond the last enacted entry, should
   `atDate` answer (carry-forward, PE-compatible) or should the
   manifest record the enacted-coverage horizon per parameter?
3. Is "last referenced publication year" per-file metadata reliable
   enough, or do we pin the IRS uprating boundary globally (last Rev.
   Proc. year = 2026)?

## Resolution (2026-08-01, decided with Nathanael)

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
