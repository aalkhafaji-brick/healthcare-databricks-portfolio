# Databricks Healthcare Portfolio — Progress Tracker
**6-Month Learning Journey: Sept 2026–March 2027**
**Goal: C-suite (COO/CDO) positioning via Databricks + AI/data architecture mastery**

---

## Week 1 (Sept 18-24, 2026) ✅ COMPLETE
**Focus: Databricks Fundamentals + Delta Lake Introduction**

### Checklist
- ✅ First Delta Lake notebook (01-delta-lake-intro) created
- ✅ Healthcare data imported and verified (3 rows)
- ✅ GitHub repo initialized with folder structure
- ✅ Databricks Academy: Fundamentals course completed
- ✅ Healthcare SQL queries notebook (02-healthcare-sql-queries) created
- ✅ Healthcare dataset sourced (Diabetes 130-US Hospitals, Kaggle)
- ✅ Notebook 03: Real diabetes readmission analysis (101,766 records)

### Notebooks Completed
1. **01-delta-lake-intro.py** — Delta table creation, SELECT, COUNT verification
2. **02-healthcare-sql-queries.py** — WHERE, GROUP BY, AVG, ORDER BY, INSERT operations
3. **03-diabetes-readmission-analysis.py** — Real dataset, 7 cells: context + data inspection + quality checks + risk stratification + C-suite narrative

### Key Findings (Notebook 03)
- Prior utilization (3+ ER/inpatient visits) = 23.28% readmission rate vs. 9.96% baseline (2.6x difference)
- High prior utilizers: 17.3–17.8 avg medications, 4.8–5.1 day LOS
- "Unknown" A1C cohort (70% of data) = 14.2% readmission rate — data gaps = operational red flags
- Financial impact: ~900 prevented readmissions = $9–12M annual savings

### Time Logged
- Monday–Friday: 20–22 hours
- Databricks Academy: 90% score
- GitHub commits: 3 notebooks pushed

### Next Week
Week 2: Delta time-travel + data quality fundamentals

---

## Week 2 (Sept 25-Oct 1, 2026) ✅ COMPLETE
**Focus: Delta Time-Travel + Data Quality Audit + Deduplication Strategy**

### Notebooks Completed
4. **04-delta-time-travel-status-tracking.sql** — Delta versioning + operational status tracking

### Notebook 04: Detailed Breakdown

**Table Created:** `patient_status_tracking` (1,000 rows from diabetic_data)

**Columns:**
- patient_nbr, encounter_id, admission_type_id, discharge_disposition_id
- A1Cresult, readmitted, num_medications, time_in_hospital
- patient_status (CASE WHEN: Readmitted_Within_30 | Readmitted_After_30 | Not_Readmitted | Unknown_Status)
- care_level (CASE WHEN: Active_High_Complexity | Active_Standard | Active_Low_Complexity)
- data_snapshot_date, data_update_timestamp

**Cells Executed:**
1. Markdown context + C-suite narrative
2. CREATE OR REPLACE TABLE patient_status_tracking (1,000 rows)
3. Query current snapshot (SELECT LIMIT 10)
4. INSERT 100 rows simulating Day 10 status updates
5. DESCRIBE HISTORY patient_status_tracking — showed 3 versions with timestamps
6. Data quality audit — found 260 duplicate patient encounters (8.33%)
7. Deduplication strategy — kept most recent per patient using ROW_NUMBER() + PARTITION BY
8. Smart querying — operational metrics extraction

### Key Operational Metrics
| Metric | Count | Insight |
|--------|-------|---------|
| Active patients (current snapshot) | 940 | Real-time census |
| Readmitted within 30 days | 124 | 13.2% readmission rate across all encounters |
| High-complexity current | 329 | 35% of active patients = highest-touch cohort |
| Original table rows | 1,200 | All encounters (history preserved) |
| Cleaned table rows | 940 | Deduped (most recent per patient) |

### Data Quality Findings
- Zero missing values in: patient_status, care_level, A1Cresult, encounter_id
- 260 duplicate encounters (8.33% of data) — mostly same patients with multiple admission cycles
- Strategy: Keep all encounters in original table, query strategically based on operational need

### Technical Lessons Learned
1. **Delta versioning** — Every write creates a new version. Query any point in time with VERSION AS OF
2. **Data architecture principle** — Keep ALL data, query what you need (not delete and forget)
3. **Deduplication pattern** — ROW_NUMBER() OVER (PARTITION BY patient_nbr ORDER BY timestamp DESC) WHERE rn = 1
4. **Smart query design** — Example 1: Current status | Example 2: Historical readmissions | Example 3: Risk cohorts
5. **Operational visibility** — 329 high-complexity patients = intervention opportunity = data-driven COO decision

### GitHub Commits
- Pushed 04-delta-time-travel-status-tracking.sql (281 lines)
- Commit: "Notebook 04: Delta time-travel, data quality audit, deduplication strategy"

### Time Logged
- 8–10 hours (Notebook 04 development + troubleshooting + GitHub)

### Next Week
Week 3: Upserts + incremental loads (preparing for streaming/batch patterns)

---

## Upcoming Notebooks (Weeks 3-6)
- **Notebook 05** — Upserts + incremental loads (MERGE INTO pattern)
- **Notebook 06** — Data quality as code (automated anomaly detection)
- **Notebook 07** — Real-time streaming simulation (Kafka patterns)
- **Notebooks 08-10** — Phase 2: LLM infrastructure (retrieval-augmented analysis)

---

## Free Resources Used
- Databricks Community Edition
- Kaggle: Diabetes 130-US Hospitals Dataset (1999-2008, 101,766 records)
- GitHub: Version control + portfolio building
- Databricks Academy: SQL + Delta fundamentals

---

## GitHub Repository
**https://github.com/aalkhafaji-brick/healthcare-databricks-portfolio**

**Folder Structure:**
```
healthcare-databricks-portfolio/
├── README.md
├── PROGRESS.md (this file)
├── docs/james-ai-to-databricks.md
├── notebooks/
│   ├── 01-delta-lake-intro.py ✅
│   ├── 02-healthcare-sql-queries.py ✅
│   ├── 03-diabetes-readmission-analysis.py ✅
│   └── 04-delta-time-travel-status-tracking.sql ✅
├── phase-1-dashboard/
├── phase-2-platform/
├── phase-3a-llm/
├── phase-3b-operations/
└── interview-prep/
```
