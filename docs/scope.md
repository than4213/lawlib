# Lawlib's scope: federal enacted law (decision 2026-08-03)

**Lawlib contains United States federal law** — statutes and the
administrative rules made under their delegated authority — as
mechanically translated from policyengine-us.

## The authority taxonomy

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

## Completeness goal

Within this scope, the goal is **completeness**: every federal formula
either faithfully translated or a *documented* rejection
(`rejection_report.md`), and the rejection list is a work queue to
drive to zero by extending the typed IR — never by loosening it.
Current state: 493 translated federal variables, 994 parameters,
64-variable diff-validated tier, quarantine empty.
