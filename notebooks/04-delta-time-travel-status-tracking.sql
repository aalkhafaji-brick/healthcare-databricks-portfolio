-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Notebook 04: Delta Time Travel & Operational Status Tracking
-- MAGIC
-- MAGIC ## Real-World Problem
-- MAGIC
-- MAGIC Healthcare operations need to track patient status changes over time:
-- MAGIC - Patient admitted → under care → discharged → (possibly) readmitted
-- MAGIC - Insurance active → inactive → reactivated
-- MAGIC - DME equipment active → returned → reordered
-- MAGIC - Monitoring enrolled → paused → resumed
-- MAGIC
-- MAGIC **Challenge:** As new data streams in (admissions, discharges, readmissions), how do you know what the system looked like on any given date?
-- MAGIC
-- MAGIC **Solution:** Delta Lake versioning. Every write creates a new version. Query any point in time.
-- MAGIC
-- MAGIC ## What We'll Build
-- MAGIC
-- MAGIC - Create a patient status table with time-tracking
-- MAGIC - Simulate 20 days of status changes
-- MAGIC - Use Delta time-travel to query historical snapshots
-- MAGIC - Find data quality issues (missing dates, orphans, inconsistencies)

-- COMMAND ----------

-- Cell 2: Create Delta table with operational status tracking
-- This table will track patient status over time with version history

CREATE OR REPLACE TABLE patient_status_tracking AS
SELECT 
  patient_nbr,
  encounter_id,
  admission_type_id,
  discharge_disposition_id,
  A1Cresult,
  readmitted,
  num_medications,
  time_in_hospital,
  
  -- Status assignment logic
  CASE 
    WHEN readmitted = '<30' THEN 'Readmitted_Within_30'
    WHEN readmitted = '>30' THEN 'Readmitted_After_30'
    WHEN readmitted = 'NO' THEN 'Not_Readmitted'
    ELSE 'Unknown_Status'
  END as patient_status,
  
  -- Flag active vs inactive (simulating continuous monitoring)
  CASE 
    WHEN num_medications >= 17 THEN 'Active_High_Complexity'
    WHEN num_medications >= 10 THEN 'Active_Standard'
    ELSE 'Active_Low_Complexity'
  END as care_level,
  
  -- Data tracking (this will be key for time-travel)
  CURRENT_DATE() as data_snapshot_date,
  CURRENT_TIMESTAMP() as data_update_timestamp
  
FROM diabetic_data
LIMIT 1000

-- COMMAND ----------

-- Cell 3: Query current snapshot of patient status
-- This is what the operational system looks like TODAY

SELECT 
  patient_nbr,
  encounter_id,
  patient_status,
  care_level,
  A1Cresult,
  readmitted,
  num_medications,
  time_in_hospital,
  data_snapshot_date,
  data_update_timestamp
FROM patient_status_tracking
LIMIT 10

-- COMMAND ----------

-- Cell 4: Simulate 20 days of status updates (CORRECTED)

INSERT INTO patient_status_tracking
SELECT 
  patient_nbr,
  encounter_id + 1000 as encounter_id,
  admission_type_id,
  discharge_disposition_id,
  A1Cresult,
  CASE WHEN RAND() < 0.15 THEN '<30' WHEN RAND() < 0.10 THEN '>30' ELSE 'NO' END as readmitted,
  num_medications + 1 as num_medications,
  time_in_hospital,
  
  -- ADD BACK THE MISSING COLUMNS
  CASE 
    WHEN RAND() < 0.15 THEN 'Readmitted_Within_30'
    WHEN RAND() < 0.10 THEN 'Readmitted_After_30'
    ELSE 'Not_Readmitted'
  END as patient_status,
  
  CASE 
    WHEN (num_medications + 1) >= 17 THEN 'Active_High_Complexity'
    WHEN (num_medications + 1) >= 10 THEN 'Active_Standard'
    ELSE 'Active_Low_Complexity'
  END as care_level,
  
  DATE_ADD(CURRENT_DATE(), 10) as data_snapshot_date,
  CURRENT_TIMESTAMP() as data_update_timestamp
  
FROM diabetic_data
LIMIT 100

-- COMMAND ----------

-- Quick verification: Did all columns populate?
SELECT 
  patient_nbr,
  patient_status,
  care_level,
  data_snapshot_date,
  num_medications
FROM patient_status_tracking
WHERE data_snapshot_date = DATE_ADD(CURRENT_DATE(), 10)
LIMIT 5

-- COMMAND ----------

-- Cell 5: Delta Time Travel - Query the data AS IT WAS at different versions

-- Check current table history
DESCRIBE HISTORY patient_status_tracking

-- COMMAND ----------

-- Cell 5B: Compare versions - show the data quality issue we fixed

SELECT 
  'Version 1 (Broken)' as version_label,
  COUNT(*) as total_rows,
  COUNT(CASE WHEN care_level IS NULL THEN 1 END) as null_care_levels,
  COUNT(CASE WHEN patient_status IS NULL THEN 1 END) as null_patient_status
FROM patient_status_tracking VERSION AS OF 1

UNION ALL

SELECT 
  'Version 2 (Fixed)' as version_label,
  COUNT(*) as total_rows,
  COUNT(CASE WHEN care_level IS NULL THEN 1 END) as null_care_levels,
  COUNT(CASE WHEN patient_status IS NULL THEN 1 END) as null_patient_status
FROM patient_status_tracking VERSION AS OF 2

-- COMMAND ----------

-- Dig deeper: What's ACTUALLY in Version 1?
SELECT 
  patient_status,
  care_level,
  COUNT(*) as count
FROM patient_status_tracking VERSION AS OF 1
GROUP BY patient_status, care_level
ORDER BY count DESC
LIMIT 10

-- COMMAND ----------

-- Cell 6: Data Quality Audit - Find the holes

SELECT 
  'Missing patient_status' as issue_type,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patient_status_tracking), 2) as percent_of_total
FROM patient_status_tracking
WHERE patient_status IS NULL

UNION ALL

SELECT 
  'Missing care_level' as issue_type,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patient_status_tracking), 2) as percent_of_total
FROM patient_status_tracking
WHERE care_level IS NULL

UNION ALL

SELECT 
  'Missing A1Cresult' as issue_type,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patient_status_tracking), 2) as percent_of_total
FROM patient_status_tracking
WHERE A1Cresult IS NULL

UNION ALL

SELECT 
  'Orphaned records (no encounter_id)' as issue_type,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patient_status_tracking), 2) as percent_of_total
FROM patient_status_tracking
WHERE encounter_id IS NULL

UNION ALL

SELECT 
  'Duplicate patient encounters (same day)' as issue_type,
  COUNT(*) - COUNT(DISTINCT encounter_id) as count,
  ROUND((COUNT(*) - COUNT(DISTINCT encounter_id)) * 100.0 / COUNT(*), 2) as percent_of_total
FROM patient_status_tracking

-- COMMAND ----------

-- Cell 7: Deduplication Strategy - Remove accidental duplicates
-- Keep the MOST RECENT encounter for each patient (highest timestamp)

CREATE OR REPLACE TABLE patient_status_tracking_cleaned AS
SELECT 
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
  data_snapshot_date,
  data_update_timestamp
FROM (
  SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY patient_nbr ORDER BY data_update_timestamp DESC) as rn
  FROM patient_status_tracking
)
WHERE rn = 1

-- COMMAND ----------

-- Check if tables exist
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE 'patient_status%'

-- COMMAND ----------

-- Check row counts individually
SELECT 'Original' as table_name, COUNT(*) as row_count FROM patient_status_tracking
UNION ALL
SELECT 'Cleaned' as table_name, COUNT(*) as row_count FROM patient_status_tracking_cleaned

-- COMMAND ----------

-- Cell 8: Smart querying - Keep all data, query strategically

-- Example 1: Current status (most recent per patient)
SELECT 'Current_Status' as query_type, COUNT(DISTINCT patient_nbr) as unique_patients
FROM (
  SELECT patient_nbr, care_level, ROW_NUMBER() OVER (PARTITION BY patient_nbr ORDER BY data_update_timestamp DESC) as rn
  FROM patient_status_tracking
)
WHERE rn = 1

UNION ALL

-- Example 2: All readmissions (including history)
SELECT 'Readmitted_Within_30', COUNT(*) as count
FROM patient_status_tracking
WHERE readmitted = '<30'

UNION ALL

-- Example 3: High complexity patients right now
SELECT 'High_Complexity_Current', COUNT(DISTINCT patient_nbr)
FROM (
  SELECT patient_nbr, care_level, ROW_NUMBER() OVER (PARTITION BY patient_nbr ORDER BY data_update_timestamp DESC) as rn
  FROM patient_status_tracking
)
WHERE rn = 1 AND care_level = 'Active_High_Complexity'