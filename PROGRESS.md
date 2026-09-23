# Progress Log

Databricks learning plan, Sept 2026 – March 2027, applied to healthcare operations. Workspace: Databricks Free Edition. Dataset: Diabetes 130-US Hospitals (1999–2008), UCI Machine Learning Repository (Strack et al., 2014), 101,766 encounters.

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

## Next
**13:** Public CMS durable medical equipment data, anomaly detection.
Then: Unity Catalog governance, scheduled pipelines with data quality checks, a real LLM layer with evaluation, and an operations command center capstone.
