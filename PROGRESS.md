# Progress Log

Databricks learning plan, Sept 2026 – March 2027, applied to healthcare operations. Workspace: Databricks Free Edition.

Datasets: Diabetes 130-US Hospitals (1999–2008), UCI Machine Learning Repository (Strack et al., 2014), 101,766 encounters (Notebooks 03–12). Medicare DME by Referring Provider and Service, 2024, CMS, 1,347,255 rows (Notebooks 13–17).

Only results produced by the notebooks are recorded here. No cost or savings figures are claimed; a defensible estimate would need a sourced cost per readmission and a prevention rate measured in a pilot.

---

## Foundations (Sept 18–20, 2026)
**01 – delta-lake-intro:** Created a Delta table, inserted and queried records.
**02 – healthcare-sql-queries:** Filtering, grouping, averages, ordering.
**03 – diabetes-readmission-analysis:** First analysis of the full dataset.
- Patients with 3+ prior ER/inpatient visits: 23.3% readmitted vs. 10.0% baseline
- Unmeasured HbA1c group: 14.2% readmitted
- Later corrected by Notebook 12: medication count adds no predictive value once other factors are known

Also completed: Databricks Academy fundamentals course.

## Data engineering patterns (Sept 21–22, 2026)
**04 – delta-time-travel-status-tracking:** Table versioning and history; found 260 duplicate encounters (8.3%) in a 1,200-row sample; deduplicated with ROW_NUMBER().
**05 – upserts-incremental-loads:** MERGE INTO: 50 staged records into a 500-row table (550 rows, 488 unique patients).
**06 – data-quality-as-code:** 5 automated rules; 99.96% pass rate; 1 medication outlier flagged.
**07 – streaming-simulation-kafka-patterns:** Simulated micro-batch processing: 30 events in 6 batches.
**08 – real-time-dashboards:** Census and rule-based risk tiers on a 488-patient sample (10.4% readmitted). Note: static historical data, not a live feed.

## Rule-based decision support (Sept 22, 2026)
**09 – weighted-patient-similarity:** Hand-weighted similarity scoring across 488 patient profiles.
**10 – multitable-joins-operational-analytics:** Dimensional joins; HIGH-risk cohort of 114 patients with 7.0-day vs. 4.1-day average stay.
**11 – rule-based-discharge-support:** Combines 09 and 10 with data quality and audit checks.

*09 and 11 were renamed on Sept 23 to describe their methods accurately. They use hand-set rules, not embeddings or AI models.*

## Validated modeling (Sept 23, 2026)
**12 – readmission-risk-model:** 69,990 patients after removing hospice/death discharges and keeping one visit per patient (leakage control). 80/20 stratified split.
- Notebook 09 weights: ROC-AUC 0.557, PR-AUC 0.108
- Logistic regression (chosen; tied with gradient boosting, simpler to explain): ROC-AUC 0.647, PR-AUC 0.172
- 10% outreach list: ~307 vs. ~178 readmitted patients reached with the same 1,400 calls
- Strongest factor: discharge destination (rehab 26.4%, SNF 13.4%, home 6.9%); 2,474 patients with no recorded destination were readmitted at 10.1%
- Fairness gate (race, gender, age): PASS; scores written to Delta only if the gate passes; runs tracked in MLflow
- Limit: the data records whether a patient returned, not why or when

## CPAP resupply: data to dashboard (Sept 24 – Oct 5, 2026)
**13 – cms-dme-anomaly-detection:** National 2024 Medicare DME data, 1,347,255 rows.
- Data quality catch: the default CSV reader shifted columns for one wheelchair code (K0056); fixed with correct quote handling, and a guardrail now stops the notebook if it recurs
- Patient counts hidden for privacy in 69% of rows; visible rows still cover 75–96% of CPAP services
- CPAP devices and supplies make up roughly 40% of DME claims, mostly recurring resupply
- No prescriber averaged above Medicare's replacement limits (likely because over-limit units are denied); median resupply ran at about half the allowance
- Robust peer comparison flagged 173 of 160,582 rows; with a 20-patient minimum, 27 survived (7 high, 20 low), and 17 of the 20 low flags were on items under $20 per unit

**14 – unity-catalog-governance:** Identity columns classified (restricted / internal / public); names and street addresses masked, verified without displaying any name; shareable view with no identifiers and groups of 11+ prescribers; automatic lineage confirmed. Accepted risk: the NPI stays unmasked in bronze for the pipeline and is never displayed.

**15 – scheduled-pipeline-quality-gates:** The Notebook 13 flow as a monthly Databricks Job with 8 quality gates (ingestion integrity, data sufficiency, privacy), a run log, and failure email. A deliberate gate failure was logged and stopped the pipeline. Scheduled run reproduced Notebook 13 exactly (160,582 rows) in about 2 minutes. Known gap: the source link is fixed to the 2024 file, so a freshness check is needed.

**16 – llm-layer-with-evaluation:** Llama 3.3 70B wrote 12 item summaries from the shareable view. Code verified all 51 numbers (0 unsupported); a second model (Qwen3) approved all 12; human review found wording problems ("require," "usage," widened scope, "habits") in most.

**17 – operations-command-center:** Published dashboard on governed views: % of allowance received by item (48–70%), flags far below / above peers (20 / 7), data age (21 months), pipeline health, template statements that always say "received," and AI summaries shown only after human approval (2 of 12 approved, with reviewer and reason recorded).

## Next
Phase 4: interview readiness. Later: a freshness gate for new CMS releases, and real embedding-based search (the honest version of Notebook 09).
