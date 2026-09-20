# Databricks notebook source
# MAGIC %md
# MAGIC # Notebook 03: Diabetes Readmission Risk Analysis
# MAGIC ## Real Data Insight: HbA1c Control & Hospital Readmissions
# MAGIC
# MAGIC Dataset: Diabetes 130-US Hospitals (1999-2008) | 101,766 patient records | 10 years of clinical care
# MAGIC
# MAGIC Research Question: Does uncontrolled diabetes (poor HbA1c) predict 30-day readmission?
# MAGIC
# MAGIC Operational Hypothesis: Real-time glucose monitoring surfaces control gaps BEFORE crisis → prevents readmission cascade
# MAGIC
# MAGIC What we'll discover:
# MAGIC - How HbA1c control level correlates with readmission rates
# MAGIC - Which patients are flagged as high-risk (early warning signals)
# MAGIC - Cost impact of preventable readmissions
# MAGIC - How data architecture enables predictive intervention vs. reactive treatment
# MAGIC
# MAGIC Your Role as COO: "I architect data systems that make operational silos visible. Healthcare operations = turning HbA1c + utilization data into predictive alerts that prevent readmission."

# COMMAND ----------

# MAGIC %sql
# MAGIC -- First, let's peek at the data structure
# MAGIC SELECT * FROM diabetic_data LIMIT 5

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Data Quality Check: How many records and what's missing?
# MAGIC SELECT 
# MAGIC   COUNT(*) as total_records,
# MAGIC   COUNT(DISTINCT patient_nbr) as unique_patients,
# MAGIC   COUNT(readmitted) as readmit_records,
# MAGIC   COUNT(A1Cresult) as a1c_records,
# MAGIC   COUNT(number_inpatient) as prior_inpatient_records
# MAGIC FROM diabetic_data

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Core Analysis: HbA1c Control → 30-Day Readmission Correlation
# MAGIC SELECT 
# MAGIC   CASE 
# MAGIC     WHEN A1Cresult = 'Normal' THEN 'Normal (<7%)'
# MAGIC     WHEN A1Cresult = '>7' THEN 'Elevated (>7%)'
# MAGIC     WHEN A1Cresult = '>8' THEN 'Poorly Controlled (>8%)'
# MAGIC     ELSE 'Unknown'
# MAGIC   END as a1c_control_level,
# MAGIC   
# MAGIC   readmitted,
# MAGIC   COUNT(*) as patient_count
# MAGIC   
# MAGIC FROM diabetic_data
# MAGIC GROUP BY 
# MAGIC   CASE 
# MAGIC     WHEN A1Cresult = 'Normal' THEN 'Normal (<7%)'
# MAGIC     WHEN A1Cresult = '>7' THEN 'Elevated (>7%)'
# MAGIC     WHEN A1Cresult = '>8' THEN 'Poorly Controlled (>8%)'
# MAGIC     ELSE 'Unknown'
# MAGIC   END,
# MAGIC   readmitted
# MAGIC ORDER BY a1c_control_level, readmitted DESC

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Combine A1C + Prior Utilization = High-Risk Stratification
# MAGIC SELECT 
# MAGIC   CASE 
# MAGIC     WHEN A1Cresult = '>8' THEN 'Poorly Controlled'
# MAGIC     ELSE 'Better Controlled/Unknown'
# MAGIC   END as a1c_status,
# MAGIC   
# MAGIC   CASE 
# MAGIC     WHEN number_inpatient + number_emergency >= 3 THEN 'High Prior Util (3+ visits)'
# MAGIC     ELSE 'Lower Prior Util'
# MAGIC   END as prior_utilization_risk,
# MAGIC   
# MAGIC   COUNT(*) as patient_count,
# MAGIC   SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) as readmitted_30_days,
# MAGIC   ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as readmit_rate_percent
# MAGIC   
# MAGIC FROM diabetic_data
# MAGIC GROUP BY 
# MAGIC   CASE WHEN A1Cresult = '>8' THEN 'Poorly Controlled' ELSE 'Better Controlled/Unknown' END,
# MAGIC   CASE WHEN number_inpatient + number_emergency >= 3 THEN 'High Prior Util (3+ visits)' ELSE 'Lower Prior Util' END
# MAGIC ORDER BY readmit_rate_percent DESC

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Full Risk Profile: A1C + Prior Util + Medication Burden + Severity
# MAGIC SELECT 
# MAGIC   CASE 
# MAGIC     WHEN A1Cresult = '>8' THEN 'Poorly Controlled'
# MAGIC     ELSE 'Better Controlled/Unknown'
# MAGIC   END as a1c_status,
# MAGIC   
# MAGIC   CASE 
# MAGIC     WHEN number_inpatient + number_emergency >= 3 THEN 'High Prior Util (3+ visits)'
# MAGIC     ELSE 'Lower Prior Util'
# MAGIC   END as prior_utilization_risk,
# MAGIC   
# MAGIC   COUNT(*) as patient_count,
# MAGIC   SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) as readmitted_30_days,
# MAGIC   ROUND(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as readmit_rate_percent,
# MAGIC   ROUND(AVG(num_medications), 1) as avg_medications,
# MAGIC   ROUND(AVG(time_in_hospital), 1) as avg_length_of_stay
# MAGIC   
# MAGIC FROM diabetic_data
# MAGIC GROUP BY 
# MAGIC   CASE WHEN A1Cresult = '>8' THEN 'Poorly Controlled' ELSE 'Better Controlled/Unknown' END,
# MAGIC   CASE WHEN number_inpatient + number_emergency >= 3 THEN 'High Prior Util (3+ visits)' ELSE 'Lower Prior Util' END
# MAGIC ORDER BY readmit_rate_percent DESC

# COMMAND ----------

# MAGIC %md
# MAGIC # Cell 7: Key Findings & Operational Narrative
# MAGIC
# MAGIC ## Core Insights
# MAGIC
# MAGIC ### 1. Prior Utilization is the Dominant Risk Signal
# MAGIC - Patients with 3+ prior ER/inpatient visits = **23.28% readmission rate**
# MAGIC - Patients with 0-2 prior visits = **9.96% readmission rate**
# MAGIC - **2.6x difference** — prior utilization predicts readmission better than A1C control
# MAGIC
# MAGIC ### 2. High-Risk Patients are Medically Complex
# MAGIC - High prior utilizers: **17.3-17.8 medications** (polypharmacy burden)
# MAGIC - High prior utilizers: **4.8-5.1 day length of stay** (acute severity)
# MAGIC - Complexity = readmission risk
# MAGIC
# MAGIC ### 3. Data Gaps Tell a Story
# MAGIC - 70% of patients have "Unknown" A1C status
# MAGIC - This "Unknown" cohort has **14.2% readmission rate** (highest)
# MAGIC - Interpretation: Patients without A1C testing = sicker, more acute, deprioritized care
# MAGIC
# MAGIC ---
# MAGIC
# MAGIC ## Operational Implication
# MAGIC
# MAGIC **The high-risk patient is predictable:** Flag at discharge if prior utilization ≥ 3 + medication count ≥ 17.
# MAGIC
# MAGIC **The intervention opportunity:** Real-time glucose monitoring (Dexcom/CGM) + coordinated care handoff before discharge for this cohort.
# MAGIC
# MAGIC **The financial impact:** Preventing 10% of readmissions in the 9,192 "high prior util" patients = ~900 readmissions prevented = $9-12M annual savings (at $10-12K per readmission cost).
# MAGIC
# MAGIC ---
# MAGIC
# MAGIC ## C-Suite Positioning
# MAGIC
# MAGIC "I designed James AI to orchestrate 100+ autonomous agents managing 1,300+ CRM records with race-condition fixes and 88% data corruption recovery. That same reliability thinking applies to healthcare operations.
# MAGIC
# MAGIC Here's the insight: Uncontrolled diabetes gets the attention. But the real readmission driver is *prior utilization* — patients already known to the system as high-touch. These are your operationally visible patients.
# MAGIC
# MAGIC My infrastructure question: How do you surface that signal *before* discharge? How do you coordinate glucose monitoring + care + pharmacy + follow-up in a predictable way?
# MAGIC
# MAGIC That's data architecture enabling operational speed. That's where readmission prevention happens."
# MAGIC
# MAGIC ---
# MAGIC
# MAGIC ## Next Steps
# MAGIC
# MAGIC 1. **For Insurance Carriers:** Identify high prior-util patients at discharge → trigger real-time monitoring + care coordination → prevent 20% of readmissions
# MAGIC 2. **For Health Systems:** Build predictive alert at discharge (A1C unknown + prior util ≥3 = flag for intervention)
# MAGIC 3. **For DME/Monitoring Providers:** Target CGM deployment to high prior-util cohort → highest ROI
# MAGIC 4. **For Data Architecture:** Real-time data pipeline linking prior utilization → admission type → discharge readiness
# MAGIC
# MAGIC ---
# MAGIC
# MAGIC ## Conclusion
# MAGIC
# MAGIC Diabetes readmission prevention is solved by visibility, not by A1C control alone. The data shows: prior utilization + medication burden + care complexity = readmission risk. A data-driven healthcare operation surfaces this at discharge and intervenes. That's the competitive advantage.