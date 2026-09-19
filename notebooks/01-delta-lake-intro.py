# Databricks notebook source
# MAGIC %sql
# MAGIC SELECT 'Welcome to Databricks' as message

# COMMAND ----------

# MAGIC %sql
# MAGIC CREATE TABLE IF NOT EXISTS healthcare_patients (
# MAGIC   patient_id INT,
# MAGIC   name STRING,
# MAGIC   age INT,
# MAGIC   condition STRING,
# MAGIC   created_date TIMESTAMP
# MAGIC )
# MAGIC USING DELTA;

# COMMAND ----------

# MAGIC %sql
# MAGIC INSERT INTO healthcare_patients VALUES
# MAGIC (1, 'John Doe', 45, 'Diabetes', current_timestamp()),
# MAGIC (2, 'Jane Smith', 52, 'Hypertension', current_timestamp()),
# MAGIC (3, 'Bob Johnson', 67, 'Heart Disease', current_timestamp());

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT * FROM healthcare_patients;

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT * FROM healthcare_patients VERSION AS OF 0;

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT * FROM healthcare_patients

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT COUNT(*) as patient_count FROM healthcare_patients