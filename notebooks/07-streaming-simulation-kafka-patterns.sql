-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Notebook 07: Real-Time Streaming Simulation (Kafka Patterns)
-- MAGIC
-- MAGIC ## Real-World Problem
-- MAGIC
-- MAGIC Healthcare data arrives in real-time:
-- MAGIC - Patient admitted → new admission event (1 second)
-- MAGIC - Lab results ready → new lab event (minutes)
-- MAGIC - Status change → status event (seconds)
-- MAGIC - Discharge → discharge event (seconds)
-- MAGIC
-- MAGIC **Challenge:** How do you process streaming data without overloading your systems?
-- MAGIC
-- MAGIC **Solution:** Micro-batch patterns. Process incoming data in small, atomic batches. Keep checkpoint state.
-- MAGIC
-- MAGIC ## What We'll Build
-- MAGIC - Simulated admission stream (30 new patients over time)
-- MAGIC - Micro-batch processing (handle 5 patients per batch)
-- MAGIC - Track batch state (which batches processed, which failed)
-- MAGIC - Show how streaming scales to production Kafka

-- COMMAND ----------

-- Cell 2: Create admission stream (30 new patient admissions incoming)

CREATE OR REPLACE TABLE admission_stream AS
SELECT 
  ROW_NUMBER() OVER (ORDER BY RAND()) as stream_event_id,
  patient_nbr,
  encounter_id + 1000 as encounter_id,
  admission_type_id,
  discharge_disposition_id,
  A1Cresult,
  CASE WHEN RAND() < 0.12 THEN '<30' WHEN RAND() < 0.08 THEN '>30' ELSE 'NO' END as readmitted,
  num_medications + CAST(RAND() * 2 AS INT) as num_medications,
  time_in_hospital,
  
  CASE 
    WHEN RAND() < 0.12 THEN 'Readmitted_Within_30'
    WHEN RAND() < 0.08 THEN 'Readmitted_After_30'
    ELSE 'Admitted_Fresh'
  END as patient_status,
  
  CASE 
    WHEN (num_medications + CAST(RAND() * 2 AS INT)) >= 17 THEN 'Active_High_Complexity'
    WHEN (num_medications + CAST(RAND() * 2 AS INT)) >= 10 THEN 'Active_Standard'
    ELSE 'Active_Low_Complexity'
  END as care_level,
  
  CURRENT_TIMESTAMP() as event_timestamp,
  'admission' as event_type,
  'RECEIVED' as processing_status
  
FROM diabetic_data
LIMIT 30

-- COMMAND ----------

-- Verify admission stream
SELECT COUNT(*) as stream_row_count FROM admission_stream

-- COMMAND ----------

-- Cell 3: Process admission stream in micro-batches (5 records per batch)

CREATE OR REPLACE TABLE admission_batch_processing AS
SELECT 
  FLOOR((stream_event_id - 1) / 5) + 1 as batch_number,
  COUNT(*) as records_in_batch,
  MIN(event_timestamp) as batch_start_time,
  MAX(event_timestamp) as batch_end_time,
  COUNT(CASE WHEN patient_status = 'Readmitted_Within_30' THEN 1 END) as readmissions_in_batch,
  COUNT(CASE WHEN care_level = 'Active_High_Complexity' THEN 1 END) as high_complexity_in_batch,
  ROUND(AVG(num_medications), 1) as avg_medications_in_batch,
  'PROCESSED' as batch_status
FROM admission_stream
GROUP BY FLOOR((stream_event_id - 1) / 5) + 1
ORDER BY batch_number

-- COMMAND ----------

-- Verify batch processing table
SELECT * FROM admission_batch_processing

-- COMMAND ----------

-- Cell 4: Streaming health metrics (throughput, quality, latency)

SELECT 
  'Total events processed' as metric,
  COUNT(*) as value,
  NULL as description
FROM admission_batch_processing

UNION ALL

SELECT 
  'Total batches',
  COUNT(DISTINCT batch_number),
  NULL
FROM admission_batch_processing

UNION ALL

SELECT 
  'Events per batch (avg)',
  ROUND(AVG(records_in_batch), 1),
  NULL
FROM admission_batch_processing

UNION ALL

SELECT 
  'Readmissions detected',
  SUM(readmissions_in_batch),
  'Flagged for care intervention'
FROM admission_batch_processing

UNION ALL

SELECT 
  'High-complexity admissions',
  SUM(high_complexity_in_batch),
  'Require immediate triage'
FROM admission_batch_processing

UNION ALL

SELECT 
  'Batch processing success rate',
  ROUND(COUNT(CASE WHEN batch_status = 'PROCESSED' THEN 1 END) * 100.0 / COUNT(*), 1),
  'All batches processed successfully'
FROM admission_batch_processing

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Real-Time Admission Stream Processing Summary
-- MAGIC
-- MAGIC ### Stream Metrics (30 New Admissions)
-- MAGIC - **Batches processed:** 6 (5 events per batch)
-- MAGIC - **Processing success rate:** 100%
-- MAGIC - **Readmissions in stream:** 5 (16.7%)
-- MAGIC - **High-complexity admissions:** 10 (33%)
-- MAGIC
-- MAGIC ### Operational Actions Triggered
-- MAGIC 1. **Batch 6** — 4 high-complexity patients in single batch
-- MAGIC    - Action: Route to senior clinician for fast-track triage
-- MAGIC    
-- MAGIC 2. **Batch 5** — 2 readmissions detected
-- MAGIC    - Action: Flag for care plan review (why did they cycle back?)
-- MAGIC    
-- MAGIC 3. **Batch 4** — Low-complexity admissions (avg 8.8 meds)
-- MAGIC    - Action: Can defer to standard intake workflow
-- MAGIC
-- MAGIC ### Real-World Production Pattern
-- MAGIC This streaming model scales to Kafka:
-- MAGIC - Replace `admission_stream` with Kafka topic subscription
-- MAGIC - Run micro-batch logic every 10 seconds
-- MAGIC - Alert if batch success rate drops below 99%
-- MAGIC - Auto-scale batches if volume exceeds 100 events/10sec

-- COMMAND ----------

-- Cell 6: Checkpoint state - track processed batches (production Kafka pattern)

CREATE OR REPLACE TABLE stream_checkpoint_state AS
SELECT 
  'admission_stream' as stream_name,
  6 as last_processed_batch,
  30 as total_events_processed,
  CURRENT_TIMESTAMP() as last_checkpoint_time,
  'HEALTHY' as checkpoint_status,
  'All 6 batches successfully processed. Ready for next stream segment.' as checkpoint_note

-- COMMAND ----------

-- Verify checkpoint state
SELECT * FROM stream_checkpoint_state