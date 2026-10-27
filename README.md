# Healthcare Databricks Portfolio

Hands-on data and AI work applied to real healthcare operations problems: readmissions, durable medical equipment (DME) resupply, Medicare Advantage plan changes, data governance, and trustworthy AI. Built on Databricks Free Edition with public data.

Every result in these notebooks comes from code that ran on the data shown. Where a question can't be answered with the available data, the notebook says so. I designed and directed the work; the code was written with AI assistance. This is independent work on public data, not production work for an employer.

## Featured work

**Notebooks 13–17: CPAP resupply, from raw Medicare data to an executive dashboard**
- **13:** 1.35M Medicare DME records. Resupply runs at about half the Medicare allowance. Apparent over-ordering was mostly small-sample noise; the signal that held up was under-supply of low-cost items such as filters.
- **14:** Unity Catalog governance: column classification, masking of names and addresses, a shareable view with no identifiers, and automatic lineage.
- **15:** The analysis as a scheduled Databricks Job with 9 quality gates across four groups (ingestion integrity, data sufficiency, privacy, and freshness) that stop the pipeline and alert on failure. Gates were tested by deliberately breaking them; the freshness gate checks CMS's data catalog for a newer data year.
- **16:** AI summaries with two-layer evaluation. 0 of 12 contained an unsupported number, an AI auditor approved all 12, and human review still found misleading wording in most.
- **17:** A published Operations Command Center dashboard that reads only governed views and shows AI text only after human approval.

**Notebook 18: Michigan Medicare Advantage plan exits for 2027.** About 33,000–35,000 Michigan members are in plans that end; 82% come from one insurer's two plans, concentrated in West Michigan. More than 4 in 10 members are in a plan that ends, merges, or shrinks.

**Notebook 19: Michigan hospital readmissions.** Data pulled through the CMS API with automatic retry. 75.6% of Michigan hospitals had more hip and knee replacement readmissions than expected, compared with 47.9% nationally.

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
| 15 | scheduled-pipeline-quality-gates | Scheduled Job, 9 quality gates including freshness, run log, failure tests |
| 16 | llm-layer-with-evaluation | AI summaries, number verification, AI auditor, human review |
| 17 | operations-command-center | Published dashboard on governed views |
| 18 | medicare-advantage-plan-exits-michigan | 2027 plan crosswalk matched to enrollment, duplicate guardrails, suppression ranges |
| 19 | hospital-readmission-penalties-michigan | CMS API ingestion with retry, footnote handling, sensitivity check |

## Data
- **Notebooks 03–12:** Diabetes 130-US Hospitals for Years 1999–2008, UCI Machine Learning Repository (Strack et al., 2014): https://archive.ics.uci.edu/dataset/296/diabetes-130-us-hospitals-for-years-1999-2008
- **Notebooks 13–17:** Medicare Durable Medical Equipment, Devices & Supplies by Referring Provider and Service, 2024 (CMS): https://data.cms.gov/provider-summary-by-type-of-service/medicare-durable-medical-equipment-devices-supplies/medicare-durable-medical-equipment-devices-supplies-by-referring-provider-and-service
- **Notebook 18:** CMS 2027 Plan Crosswalk and Monthly Enrollment by Contract/Plan/State/County, October 2026.
- **Notebook 19:** CMS Hospital Readmissions Reduction Program, FY 2026 results (performance period July 2021–June 2024): https://data.cms.gov/provider-data/dataset/9n3s-kdb3

Results describe patterns in that data, not current rates.

## Publishing rule
No individual provider, insurer, or hospital names or identifiers appear in any output, notebook display, or dashboard. Results are reported by item, specialty, condition, plan category, and region. An outlier flag is a statistical signal compared with peers, not evidence of wrongdoing.

## Status
Notebooks 01–19 complete. See [PROGRESS.md](./PROGRESS.md).

---
*Ali Al-Khafaji*