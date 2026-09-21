-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Notebook 05: Upserts + Incremental Loads (MERGE INTO Pattern)
-- MAGIC
-- MAGIC ## Real-World Problem
-- MAGIC
-- MAGIC Healthcare operations update patient records in real-time:
-- MAGIC - Patient admitted yesterday → now has new lab results
-- MAGIC - Status changed from "Active" to "Discharged"
-- MAGIC - Medication count increased due to new treatment plan
-- MAGIC - Insurance coverage changed
-- MAGIC
-- MAGIC **Challenge:** How do you handle updates without losing history or creating duplicates?
-- MAGIC
-- MAGIC **Solution:** MERGE INTO (Upsert pattern). Match on key (patient_nbr + encounter_id), then:
-- MAGIC - UPDATE if exists
-- MAGIC - INSERT if new
-- MAGIC
-- MAGIC ## What We'll Build
-- MAGIC - Create baseline patient table (500 rows)
-- MAGIC - Simulate daily updates coming in (50 new/changed records)
-- MAGIC - Use MERGE INTO to apply updates atomically
-- MAGIC - Track merge operations (how many updated vs inserted)

-- COMMAND ----------

-- Cell 2: Create baseline patient table with upsert keys

CREATE OR REPLACE TABLE patient_upsert_baseline AS
SELECT 
  patient_nbr,
  encounter_id,
  admission_type_id,
  discharge_disposition_id,
  A1Cresult,
  readmitted,
  num_medications,
  time_in_hospital,
  
  CASE 
    WHEN readmitted = '<30' THEN 'Readmitted_Within_30'
    WHEN readmitted = '>30' THEN 'Readmitted_After_30'
    ELSE 'Not_Readmitted'
  END as patient_status,
  
  CASE 
    WHEN num_medications >= 17 THEN 'Active_High_Complexity'
    WHEN num_medications >= 10 THEN 'Active_Standard'
    ELSE 'Active_Low_Complexity'
  END as care_level,
  
  CURRENT_TIMESTAMP() as last_updated,
  CURRENT_DATE() as data_date
  
FROM diabetic_data
LIMIT 500

-- COMMAND ----------

-- Verify the table exists and check its row count
SELECT 
  'patient_upsert_baseline' as table_name,
  COUNT(*) as row_count
FROM patient_upsert_baseline

-- COMMAND ----------

-- Cell 3: Create staging table with updates (50 records: mix of new + updated existing)

CREATE OR REPLACE TABLE patient_updates_staging AS
SELECT 
  patient_nbr,
  encounter_id + 500 as encounter_id,  -- Offset encounter IDs to simulate new encounters
  admission_type_id,
  discharge_disposition_id,
  A1Cresult,
  CASE WHEN RAND() < 0.20 THEN '<30' WHEN RAND() < 0.10 THEN '>30' ELSE 'NO' END as readmitted,
  num_medications + CAST(RAND() * 3 AS INT) as num_medications,  -- Simulate medication changes
  time_in_hospital,
  
  CASE 
    WHEN RAND() < 0.20 THEN 'Readmitted_Within_30'
    WHEN RAND() < 0.10 THEN 'Readmitted_After_30'
    ELSE 'Not_Readmitted'
  END as patient_status,
  
  CASE 
    WHEN (num_medications + CAST(RAND() * 3 AS INT)) >= 17 THEN 'Active_High_Complexity'
    WHEN (num_medications + CAST(RAND() * 3 AS INT)) >= 10 THEN 'Active_Standard'
    ELSE 'Active_Low_Complexity'
  END as care_level,
  
  CURRENT_TIMESTAMP() as last_updated,
  CURRENT_DATE() as data_date
  
FROM diabetic_data
LIMIT 50

-- COMMAND ----------

-- Check staging table directly
SELECT 
  patient_nbr,
  encounter_id,
  num_medications,
  care_level,
  last_updated
FROM patient_updates_staging
LIMIT 10

-- COMMAND ----------

-- Cell 4: MERGE INTO - Upsert pattern (atomic update + insert)

MERGE INTO patient_upsert_baseline AS target
USING patient_updates_staging AS source
ON target.patient_nbr = source.patient_nbr 
  AND target.encounter_id = source.encounter_id

WHEN MATCHED THEN
  UPDATE SET 
    num_medications = source.num_medications,
    readmitted = source.readmitted,
    patient_status = source.patient_status,
    care_level = source.care_level,
    last_updated = source.last_updated

WHEN NOT MATCHED THEN
  INSERT (
    patient_nbr,
    encounter_id,
    admission_type_id,
    discharge_disposition_id,
    A1Cresult,
    readmitted,
    num_medications,
    time_in_hospital,
    patient_status,
    care_level,
    last_updated,
    data_date
  )
  VALUES (
    source.patient_nbr,
    source.encounter_id,
    source.admission_type_id,
    source.discharge_disposition_id,
    source.A1Cresult,
    source.readmitted,
    source.num_medications,
    source.time_in_hospital,
    source.patient_status,
    source.care_level,
    source.last_updated,
    source.data_date
  )

-- COMMAND ----------

-- Cell 5: Verify baseline table after merge
SELECT 
  'Total rows in baseline after merge' as metric,
  COUNT(*) as count
FROM patient_upsert_baseline

UNION ALL

SELECT 
  'Unique patients',
  COUNT(DISTINCT patient_nbr)
FROM patient_upsert_baseline

UNION ALL

SELECT 
  'New encounters (encounter_id >= 500)',
  COUNT(*)
FROM patient_upsert_baseline
WHERE encounter_id >= 500

-- COMMAND ----------

-- Cell 6: Which patients got new encounters via MERGE?

SELECT 
  patient_nbr,
  COUNT(*) as total_encounters,
  MIN(encounter_id) as earliest_encounter,
  MAX(encounter_id) as latest_encounter,
  COUNT(CASE WHEN encounter_id >= 500 THEN 1 END) as new_encounters_from_merge,
  AVG(num_medications) as avg_medications,
  MAX(care_level) as current_care_level
FROM patient_upsert_baseline
GROUP BY patient_nbr
HAVING COUNT(*) > 1
ORDER BY total_encounters DESC
LIMIT 10

-- COMMAND ----------

-- Cell 7: Operational merge summary

SELECT 
  'Total encounters post-merge' as metric,
  COUNT(*) as count,
  NULL as pct
FROM patient_upsert_baseline

UNION ALL

SELECT 
  'Unique patients with readmissions',
  COUNT(DISTINCT patient_nbr),
  NULL
FROM (
  SELECT patient_nbr
  FROM patient_upsert_baseline
  GROUP BY patient_nbr
  HAVING COUNT(*) > 1
)

UNION ALL

SELECT 
  'High-complexity active patients',
  COUNT(DISTINCT patient_nbr),
  NULL
FROM patient_upsert_baseline
WHERE care_level = 'Active_High_Complexity'

UNION ALL

SELECT 
  'Avg medications (all patients)',
  ROUND(AVG(num_medications), 1),
  NULL
FROM patient_upsert_baseline

UNION ALL

SELECT 
  'Avg medications (high-complexity only)',
  ROUND(AVG(num_medications), 1),
  NULL
FROM patient_upsert_baseline
WHERE care_level = 'Active_High_Complexity'