# Databricks notebook source
# MAGIC %md
# MAGIC # Healthcare SQL Queries
# MAGIC ## Week 1: SQL Practice on Patient Data
# MAGIC
# MAGIC This notebook demonstrates:
# MAGIC - Basic SELECT queries
# MAGIC - Filtering (WHERE)
# MAGIC - Aggregation (GROUP BY, COUNT, AVG)
# MAGIC - Sorting (ORDER BY)
# MAGIC - INSERT operations
# MAGIC - Delta versioning

# COMMAND ----------

# MAGIC %sql
# MAGIC -- All patients in the table
# MAGIC SELECT * FROM healthcare_patients

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Filter patients with Diabetes condition
# MAGIC SELECT name, age, condition FROM healthcare_patients 
# MAGIC WHERE condition = 'Diabetes'

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Count patients by condition
# MAGIC SELECT condition, COUNT(*) as patient_count
# MAGIC FROM healthcare_patients
# MAGIC GROUP BY condition
# MAGIC ORDER BY patient_count DESC

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Average age by medical condition
# MAGIC SELECT condition, AVG(age) as avg_age
# MAGIC FROM healthcare_patients
# MAGIC GROUP BY condition

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Find patients over 50 years old
# MAGIC SELECT name, age FROM healthcare_patients
# MAGIC WHERE age > 50
# MAGIC ORDER BY age DESC

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Add new patient record
# MAGIC INSERT INTO healthcare_patients VALUES
# MAGIC (4, 'Alice Brown', 38, 'Asthma', current_timestamp())

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Verify total patient count after insert
# MAGIC SELECT COUNT(*) as total_patients FROM healthcare_patients

# COMMAND ----------

# MAGIC %sql
# MAGIC -- Show all patients (now 4 rows)
# MAGIC SELECT * FROM healthcare_patients