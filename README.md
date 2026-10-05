# Healthcare Databricks Portfolio

Hands-on data and AI work applied to real healthcare operations problems: readmissions, durable medical equipment (DME) resupply, data governance, and trustworthy AI. Built on Databricks Free Edition with public data.

Every result in these notebooks comes from code that ran on the data shown. Where a question can't be answered with the available data, the notebook says so.

## Featured work

**Notebooks 13–17: CPAP resupply, from raw Medicare data to an executive dashboard**
- **13:** 1.35M Medicare DME records. Resupply runs at about half the Medicare allowance. Apparent over-ordering was mostly small-sample noise; the signal that held up was under-supply of low-cost items such as filters.
- **14:** Unity Catalog governance: column classification, masking of names and addresses, a shareable view with no identifiers, and automatic lineage.
- **15:** The analysis as a scheduled Databricks Job with 8 quality gates that stop the pipeline and alert on failure. Gates were tested by deliberately breaking one.
- **16:** AI summaries with two-layer evaluation. 0 of 12 contained an unsupported number, an AI auditor approved all 12, and human review still found misleading wording in most.
- **17:** A published Operations Command Center dashboard that reads only governed views and shows AI text only after human approval.

**Notebook 12: readmission risk model.** A hand-weighted formula scored barely better than chance (ROC-AUC 0.557); a trained model reached 0.647 and passed a fairness check across race, gender, and age.

## Notebooks
| # | Notebook | What it covers |
|---|----------|----------------|
| 01 | delta-lake-intro | Delta tables, inserts, queries |
| 02 | healthcare-sql-queries | Filtering, grouping, aggregation |
| 03 | diabetes-readmission-analysis | First look at the diabetes dataset |
| 04 | delta-time-travel-status-tracking | Table versioning, duplicate audit, deduplication |
| 05 | upserts-incremental-loads | MERGE INTO for incremental updates |
| 06 | data-quality-as-code | Automated data quality rules |
| 07 | streaming-simulation-kafka-patterns | Micro-batch processing patterns (simulated) |
| 08 | real-time-dashboards | Operational KPIs and rule-based risk tiers |
| 09 | weighted-patient-similarity | Hand-weighted patient similarity scoring |
| 10 | multitable-joins-operational-analytics | Multi-table joins for cohort analysis |
| 11 | rule-based-discharge-support | Similarity + operational rules + compliance checks |
| 12 | readmission-risk-model | Trained models, leakage controls, MLflow, fairness gate |
| 13 | cms-dme-anomaly-detection | Medicare DME data, CSV parsing fix, policy limits, robust peer outliers |
| 14 | unity-catalog-governance | Classification tags, column masks, shareable view, lineage |
| 15 | scheduled-pipeline-quality-gates | Scheduled Job, 8 quality gates, run log, failure test |
| 16 | llm-layer-with-evaluation | AI summaries, number verification, AI auditor, human review |
| 17 | operations-command-center | Published dashboard on governed views |

## Data
- **Notebooks 03–12:** Diabetes 130-US Hospitals for Years 1999–2008, UCI Machine Learning Repository (Strack et al., 2014): https://archive.ics.uci.edu/dataset/296/diabetes-130-us-hospitals-for-years-1999-2008
- **Notebooks 13–17:** Medicare Durable Medical Equipment, Devices & Supplies by Referring Provider and Service, 2024 (CMS): https://data.cms.gov/provider-summary-by-type-of-service/medicare-durable-medical-equipment-devices-supplies/medicare-durable-medical-equipment-devices-supplies-by-referring-provider-and-service

Both datasets are historical. Results describe patterns in that data, not current rates.

## Publishing rule
No individual provider names or identifiers appear in any output, notebook display, or dashboard. Results are reported by item and specialty only. An outlier flag is a statistical signal compared with peers, not evidence of wrongdoing.

## Status
Notebooks 01–17 complete. See [PROGRESS.md](./PROGRESS.md).

---
*Ali Al-Khafaji*
