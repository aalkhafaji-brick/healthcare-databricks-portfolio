# Databricks notebook source
import numpy as np
import pandas as pd
SOURCE_TABLE="diabetic_data"
raw=spark.table(SOURCE_TABLE).toPandas()
raw=raw.replace("?",np.nan)
print(F"Loaded {len(raw):,} encounters, {raw['patient_nbr'].nunique():,} unique patients")

# COMMAND ----------

NUMERIC = ["time_in_hospital", "num_lab_procedures", "num_procedures", "num_medications",
           "number_outpatient", "number_emergency", "number_inpatient", "number_diagnoses"]
CATEGORICAL = ["age", "gender", "admission_type_id", "discharge_disposition_id", "admission_source_id",
               "A1Cresult", "max_glu_serum", "change", "diabetesMed", "insulin"]

df = raw.copy()
for c in NUMERIC + ["encounter_id", "patient_nbr", "discharge_disposition_id"]:
    df[c] = pd.to_numeric(df[c], errors="coerce")

df = df[~df["discharge_disposition_id"].isin([11, 13, 14, 19, 20, 21])]
print("After removing hospice/death:", len(df))

df = df.sort_values("encounter_id").drop_duplicates("patient_nbr", keep="first")
print("After one encounter per patient:", len(df))

for c in CATEGORICAL:
    df[c] = df[c].astype(str).replace({"nan": "Missing", "None": "NotMeasured"})

df["target"] = (df["readmitted"] == "<30").astype(int)
print(f"Readmitted within 30 days: {df['target'].mean():.2%}")

# COMMAND ----------

raw["readmitted"].value_counts()

# COMMAND ----------

from sklearn.model_selection import train_test_split

SEED = 42
X = df[NUMERIC + CATEGORICAL]
y = df["target"].values

X_train, X_test, y_train, y_test, idx_train, idx_test = train_test_split(
    X, y, df.index, test_size=0.2, stratify=y, random_state=SEED)

print(f"Train: {len(X_train):,} | Test: {len(X_test):,}")
print(f"Readmission rate - train: {y_train.mean():.2%} | test: {y_test.mean():.2%}")

# COMMAND ----------

from sklearn.metrics import roc_auc_score, average_precision_score

def heuristic_score(d):
    prior = d["number_outpatient"] + d["number_emergency"] + d["number_inpatient"]
    return d["num_medications"] * 1.5 + prior * 2.0 + d["time_in_hospital"] * 1.0

h = heuristic_score(X_test).values

results = {}
results["heuristic_nb09"] = {
    "roc_auc": roc_auc_score(y_test, h),
    "pr_auc": average_precision_score(y_test, h),
}
print(results["heuristic_nb09"])

# COMMAND ----------

import mlflow
import mlflow.sklearn
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import HistGradientBoostingClassifier

pre = ColumnTransformer([
    ("num", StandardScaler(), NUMERIC),
    ("cat", OneHotEncoder(handle_unknown="ignore", sparse_output=False), CATEGORICAL),
])

models = {
    "logistic_regression": LogisticRegression(max_iter=2000, class_weight="balanced"),
    "gradient_boosting": HistGradientBoostingClassifier(max_iter=300, learning_rate=0.05,
                                                        class_weight="balanced", random_state=SEED),
}

mlflow.sklearn.autolog(log_models=True, silent=True)
fitted = {}
for name, clf in models.items():
    with mlflow.start_run(run_name=f"nb12_{name}"):
        pipe = Pipeline([("pre", pre), ("clf", clf)]).fit(X_train, y_train)
        p = pipe.predict_proba(X_test)[:, 1]
        results[name] = {"roc_auc": roc_auc_score(y_test, p),
                         "pr_auc": average_precision_score(y_test, p)}
        mlflow.log_metrics({f"test_{k}": v for k, v in results[name].items()})
        fitted[name] = (pipe, p)

display(pd.DataFrame(results).T.round(3))

# COMMAND ----------

CHOSEN = "logistic_regression"   # change this if your CDO decision is gradient_boosting

def capture(y_true, score, frac):
    top = np.argsort(-score)[: int(len(score) * frac)]
    return y_true[top].sum() / y_true.sum(), y_true[top].mean()

chosen_p = fitted[CHOSEN][1]
rows = []
for frac in [0.05, 0.10, 0.20, 0.30]:
    for label, s in [("guessed_weights", h), (CHOSEN, chosen_p)]:
        caught, hit = capture(y_test, s, frac)
        rows.append({"call_list": f"top {int(frac*100)}%", "method": label,
                     "readmissions_caught": round(caught, 3), "hit_rate": round(hit, 3),
                     "lift_vs_random": round(hit / y_test.mean(), 2)})
display(pd.DataFrame(rows))

# COMMAND ----------

from sklearn.inspection import permutation_importance

chosen_pipe = fitted[CHOSEN][0]
imp = permutation_importance(chosen_pipe, X_test, y_test, scoring="roc_auc",
                             n_repeats=5, random_state=SEED)

importance = (pd.DataFrame({"feature": X_test.columns,
                            "auc_drop_when_shuffled": imp.importances_mean})
              .sort_values("auc_drop_when_shuffled", ascending=False).round(4))
display(importance)

# COMMAND ----------

by_dispo = (df.groupby("discharge_disposition_id")["target"]
              .agg(patients="count", readmit_rate="mean")
              .query("patients >= 200")
              .sort_values("readmit_rate", ascending=False)
              .reset_index())
by_dispo["readmit_rate"] = by_dispo["readmit_rate"].round(3)
display(by_dispo)

# COMMAND ----------

audit_df = df.loc[idx_test, ["race", "gender", "age"]].copy()
audit_df["y"] = y_test
audit_df["p"] = chosen_p

audit_rows = []
for col in ["race", "gender", "age"]:
    for grp, g in audit_df.groupby(col):
        if len(g) >= 200 and g["y"].nunique() == 2:
            audit_rows.append({"dimension": col, "group": grp, "n": len(g),
                               "base_rate": round(g["y"].mean(), 3),
                               "roc_auc": round(roc_auc_score(g["y"], g["p"]), 3)})
audit = pd.DataFrame(audit_rows)
display(audit)

overall = results[CHOSEN]["roc_auc"]
flagged = audit[audit["roc_auc"] < overall - 0.05]
gate = "PASS" if flagged.empty else "REVIEW"
print(f"Fairness gate: {gate} - {len(flagged)} group(s) more than 0.05 below overall {overall:.3f}")
overall = results[CHOSEN]["roc_auc"]
flagged = audit[audit["roc_auc"] < overall - 0.05]
gate = "PASS" if flagged.empty else "REVIEW"
print(f"Fairness gate: {gate} - {len(flagged)} group(s) more than 0.05 below overall {overall:.3f}")

# COMMAND ----------

if gate == "PASS":
    out = df.loc[idx_test, ["encounter_id", "patient_nbr"]].copy()
    out["risk_score"] = chosen_p
    out["risk_decile"] = pd.qcut(chosen_p, 10, labels=False, duplicates="drop") + 1
    out["model_name"] = CHOSEN
    out["scored_at"] = pd.Timestamp.now()
    spark.createDataFrame(out).write.mode("overwrite").saveAsTable("readmission_risk_scores")
    print(f"Wrote {len(out):,} scored rows to readmission_risk_scores")
else:
    print("Scores withheld pending fairness review.")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Findings: Notebook 12
# MAGIC
# MAGIC **Data:** UCI Diabetes 130-US Hospitals (1999–2008), Strack et al. 2014. 69,990 patients after removing hospice/death discharges and keeping one visit per patient. 30-day readmission base rate: 8.98%.
# MAGIC
# MAGIC **Guessed weights vs. learned model (test set, 13,998 patients):**
# MAGIC - Notebook 09 hand-weighted formula: ROC-AUC 0.557, PR-AUC 0.108
# MAGIC - Logistic regression: ROC-AUC 0.647, PR-AUC 0.172 (chosen; gradient boosting tied at 0.647, so the simpler, explainable model wins)
# MAGIC - At a 10% call list: about 307 vs. 178 at-risk patients reached with the same 1,400 calls
# MAGIC
# MAGIC **What drives risk:** Discharge destination was by far the strongest factor, followed by prior inpatient stays. Medication count, the heaviest weight in the formula, contributed nothing.
# MAGIC
# MAGIC **By destination:** Rehab 26.4%, other inpatient facility 20.6%, SNF 13.4%, home health 9.5%, home 6.9%. Destination unrecorded for 2,474 patients (10.1% readmitted).
# MAGIC
# MAGIC **Fairness gate:** PASS. All groups within 0.05 of overall. Ages 90–100 and 60–70 lowest; monitor.
# MAGIC
# MAGIC **What I'd tell a COO:** A validated model lets us reach at-risk patients before they come back instead of after. With the same 1,400 calls, we reach about 307 patients who would be readmitted instead of about 178. How far down the list we go should be set by call capacity and readmission cost, and a pilot is needed to prove the calls actually prevent readmissions.
# MAGIC
# MAGIC **What this data can't answer:** Whether facility readmissions come from how sick patients were or from how the handoff went. The dataset records whether a patient came back, but not why or when, so these are fields we'd need to start collecting to target remedies precisely.
# MAGIC
# MAGIC **What I'd need next:** The readmission diagnosis linked to the original stay's discharge diagnosis, present-on-admission flags, a timeline (discharge, facility arrival, readmission), and the receiving facility.