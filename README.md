# Healthcare Databricks Portfolio

Hands-on data and AI work applied to real healthcare operations problems: readmissions, discharge handoffs, and data quality. Built on Databricks Free Edition with public data.

Every result in these notebooks comes from code that ran on the data shown. Where a question can't be answered with the available data, the notebook says so.

## Featured: Notebook 12, Readmission Risk Model
A hand-weighted risk formula (Notebook 09) tested against trained models on 13,998 held-out patients:
- Hand-weighted formula: ROC-AUC 0.557, barely better than chance
- Logistic regression: ROC-AUC 0.647; at a 10% outreach list it reaches about 307 at-risk patients vs. 178 for the same 1,400 calls
- Strongest risk signal: discharge destination (rehab 26.4% readmitted vs. home 6.9%)
- Fairness gate across race, gender, and age: PASS, enforced in code before scores are written

[Open Notebook 12](./notebooks/12-readmission-risk-model.py)

## Notebooks
| # | Notebook | What it covers |
|---|----------|----------------|
| 01 | delta-lake-intro | Delta tables, inserts, queries |
| 02 | healthcare-sql-queries | Filtering, grouping, aggregation |
| 03 | diabetes-readmission-analysis | First look at the real dataset; readmission by HbA1c and prior utilization |
| 04 | delta-time-travel-status-tracking | Table versioning, duplicate audit, deduplication |
| 05 | upserts-incremental-loads | MERGE INTO for incremental updates |
| 06 | data-quality-as-code | Automated data quality rules |
| 07 | streaming-simulation-kafka-patterns | Micro-batch processing patterns (simulated) |
| 08 | real-time-dashboards | Operational KPIs and rule-based risk tiers |
| 09 | weighted-patient-similarity | Hand-weighted patient similarity scoring |
| 10 | multitable-joins-operational-analytics | Multi-table joins for cohort analysis |
| 11 | rule-based-discharge-support | Similarity + operational rules + compliance checks |
| 12 | readmission-risk-model | Trained models, leakage controls, MLflow tracking, fairness gate |

## Data
Diabetes 130-US Hospitals for Years 1999–2008, UCI Machine Learning Repository (Strack et al., 2014): https://archive.ics.uci.edu/dataset/296/diabetes-130-us-hospitals-for-years-1999-2008

The data is historical (1999–2008). Results show patterns in that data, not current hospital rates.

## Status
Notebooks 01–12 complete. Next: Notebook 13, public CMS durable medical equipment data and anomaly detection. See [PROGRESS.md](./PROGRESS.md).

---
*Ali Al-Khafaji*
