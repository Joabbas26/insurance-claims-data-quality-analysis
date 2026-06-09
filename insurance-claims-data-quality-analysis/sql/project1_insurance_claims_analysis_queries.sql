-- Project 1: Insurance Claims Analysis Layer
-- Run this AFTER project1_insurance_claims_sqlite_cleaning.sql
-- Assumes you already have claims_clean_stage and claims_final.

-- ============================================================
-- PART 1: DATA QUALITY SUMMARY VIEW
-- ============================================================

DROP VIEW IF EXISTS v_data_quality_summary;

CREATE VIEW v_data_quality_summary AS
WITH issue_counts AS (
    SELECT 'Missing Claim ID' AS issue, SUM(missing_claim_id_flag) AS records FROM claims_clean_stage
    UNION ALL
    SELECT 'Missing Policy Number', SUM(missing_policy_number_flag) FROM claims_clean_stage
    UNION ALL
    SELECT 'Duplicate Claim ID', SUM(duplicate_claim_id_flag) FROM claims_clean_stage
    UNION ALL
    SELECT 'Invalid Age', SUM(invalid_age_flag) FROM claims_clean_stage
    UNION ALL
    SELECT 'Invalid Incident Hour', SUM(invalid_incident_hour_flag) FROM claims_clean_stage
    UNION ALL
    SELECT 'Invalid Policy Bind Date', SUM(invalid_policy_bind_date_flag) FROM claims_clean_stage
    UNION ALL
    SELECT 'Invalid Incident Date', SUM(invalid_incident_date_flag) FROM claims_clean_stage
    UNION ALL
    SELECT 'Negative Claim Amount', SUM(negative_claim_amount_flag) FROM claims_clean_stage
    UNION ALL
    SELECT 'Claim Total Mismatch', SUM(claim_total_mismatch_flag) FROM claims_clean_stage
)
SELECT
    issue,
    records,
    ROUND(100.0 * records / (SELECT COUNT(*) FROM claims_clean_stage), 2) AS pct_of_raw_records
FROM issue_counts
ORDER BY records DESC;

-- ============================================================
-- PART 2: ROW-LEVEL DATA QUALITY VIEW
-- Use this to investigate which rows had the most issues.
-- ============================================================

DROP VIEW IF EXISTS v_data_quality_records;

CREATE VIEW v_data_quality_records AS
SELECT
    source_row_id,
    claim_id,
    policy_number,
    age,
    incident_date,
    total_claim_amount,
    data_quality_issue_count,
    missing_claim_id_flag,
    missing_policy_number_flag,
    duplicate_claim_id_flag,
    invalid_age_flag,
    invalid_incident_hour_flag,
    invalid_policy_bind_date_flag,
    invalid_incident_date_flag,
    negative_claim_amount_flag,
    claim_total_mismatch_flag
FROM claims_clean_stage
WHERE data_quality_issue_count > 0
ORDER BY data_quality_issue_count DESC, source_row_id ASC;

-- ============================================================
-- PART 3: KPI SUMMARY VIEW
-- ============================================================

DROP VIEW IF EXISTS v_claims_kpi_summary;

CREATE VIEW v_claims_kpi_summary AS
SELECT
    COUNT(*) AS total_claims,
    COUNT(DISTINCT policy_number) AS total_policies,
    ROUND(SUM(total_claim_amount), 2) AS total_claim_amount,
    ROUND(AVG(total_claim_amount), 2) AS avg_claim_amount,
    ROUND(MIN(total_claim_amount), 2) AS min_claim_amount,
    ROUND(MAX(total_claim_amount), 2) AS max_claim_amount,
    SUM(CASE WHEN fraud_reported = 'Yes' THEN 1 ELSE 0 END) AS fraud_claim_count,
    ROUND(100.0 * SUM(CASE WHEN fraud_reported = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS fraud_rate_pct,
    ROUND(AVG(policy_annual_premium), 2) AS avg_annual_premium
FROM claims_final;

-- ============================================================
-- PART 4: BUSINESS ANALYSIS VIEWS
-- ============================================================

DROP VIEW IF EXISTS v_claims_by_incident_type;

CREATE VIEW v_claims_by_incident_type AS
SELECT
    incident_type,
    COUNT(*) AS claim_count,
    ROUND(SUM(total_claim_amount), 2) AS total_claim_amount,
    ROUND(AVG(total_claim_amount), 2) AS avg_claim_amount,
    SUM(CASE WHEN fraud_reported = 'Yes' THEN 1 ELSE 0 END) AS fraud_claim_count,
    ROUND(100.0 * SUM(CASE WHEN fraud_reported = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS fraud_rate_pct
FROM claims_final
GROUP BY incident_type
ORDER BY total_claim_amount DESC;

DROP VIEW IF EXISTS v_claims_by_state;

CREATE VIEW v_claims_by_state AS
SELECT
    incident_state,
    COUNT(*) AS claim_count,
    ROUND(SUM(total_claim_amount), 2) AS total_claim_amount,
    ROUND(AVG(total_claim_amount), 2) AS avg_claim_amount,
    SUM(CASE WHEN fraud_reported = 'Yes' THEN 1 ELSE 0 END) AS fraud_claim_count,
    ROUND(100.0 * SUM(CASE WHEN fraud_reported = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS fraud_rate_pct
FROM claims_final
GROUP BY incident_state
ORDER BY total_claim_amount DESC;

DROP VIEW IF EXISTS v_claims_by_severity;

CREATE VIEW v_claims_by_severity AS
SELECT
    incident_severity,
    COUNT(*) AS claim_count,
    ROUND(SUM(total_claim_amount), 2) AS total_claim_amount,
    ROUND(AVG(total_claim_amount), 2) AS avg_claim_amount,
    SUM(CASE WHEN fraud_reported = 'Yes' THEN 1 ELSE 0 END) AS fraud_claim_count,
    ROUND(100.0 * SUM(CASE WHEN fraud_reported = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS fraud_rate_pct
FROM claims_final
GROUP BY incident_severity
ORDER BY total_claim_amount DESC;

DROP VIEW IF EXISTS v_claims_by_month;

CREATE VIEW v_claims_by_month AS
SELECT
    strftime('%Y-%m', incident_date) AS incident_month,
    COUNT(*) AS claim_count,
    ROUND(SUM(total_claim_amount), 2) AS total_claim_amount,
    ROUND(AVG(total_claim_amount), 2) AS avg_claim_amount,
    SUM(CASE WHEN fraud_reported = 'Yes' THEN 1 ELSE 0 END) AS fraud_claim_count
FROM claims_final
WHERE incident_date IS NOT NULL
GROUP BY strftime('%Y-%m', incident_date)
ORDER BY incident_month;

DROP VIEW IF EXISTS v_claims_by_age_group;

CREATE VIEW v_claims_by_age_group AS
SELECT
    CASE
        WHEN age IS NULL THEN 'Unknown'
        WHEN age BETWEEN 18 AND 29 THEN '18-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        WHEN age BETWEEN 50 AND 59 THEN '50-59'
        WHEN age >= 60 THEN '60+'
        ELSE 'Unknown'
    END AS age_group,
    COUNT(*) AS claim_count,
    ROUND(SUM(total_claim_amount), 2) AS total_claim_amount,
    ROUND(AVG(total_claim_amount), 2) AS avg_claim_amount,
    SUM(CASE WHEN fraud_reported = 'Yes' THEN 1 ELSE 0 END) AS fraud_claim_count,
    ROUND(100.0 * SUM(CASE WHEN fraud_reported = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS fraud_rate_pct
FROM claims_final
GROUP BY age_group
ORDER BY
    CASE age_group
        WHEN '18-29' THEN 1
        WHEN '30-39' THEN 2
        WHEN '40-49' THEN 3
        WHEN '50-59' THEN 4
        WHEN '60+' THEN 5
        ELSE 6
    END;

-- ============================================================
-- PART 5: EXPORT TABLE FOR EXCEL / POWER BI
-- This creates a clean reporting table with useful calculated fields.
-- ============================================================

DROP TABLE IF EXISTS claims_powerbi_export;

CREATE TABLE claims_powerbi_export AS
SELECT
    claim_id,
    policy_number,
    months_as_customer,
    CASE
        WHEN months_as_customer IS NULL THEN 'Unknown'
        WHEN months_as_customer < 60 THEN 'Less than 5 years'
        WHEN months_as_customer < 120 THEN '5-9 years'
        WHEN months_as_customer < 240 THEN '10-19 years'
        ELSE '20+ years'
    END AS customer_tenure_group,
    age,
    CASE
        WHEN age IS NULL THEN 'Unknown'
        WHEN age BETWEEN 18 AND 29 THEN '18-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        WHEN age BETWEEN 50 AND 59 THEN '50-59'
        WHEN age >= 60 THEN '60+'
        ELSE 'Unknown'
    END AS age_group,
    policy_bind_date,
    policy_state,
    policy_csl,
    policy_deductible,
    policy_annual_premium,
    umbrella_limit,
    insured_zip,
    insured_sex,
    insured_education_level,
    insured_occupation,
    insured_hobbies,
    insured_relationship,
    capital_gains,
    capital_loss,
    incident_date,
    strftime('%Y', incident_date) AS incident_year,
    strftime('%m', incident_date) AS incident_month_num,
    strftime('%Y-%m', incident_date) AS incident_year_month,
    incident_type,
    collision_type,
    incident_severity,
    authorities_contacted,
    incident_state,
    incident_city,
    incident_hour_of_day,
    number_of_vehicles_involved,
    property_damage,
    bodily_injuries,
    witnesses,
    police_report_available,
    total_claim_amount,
    CASE
        WHEN total_claim_amount IS NULL THEN 'Unknown'
        WHEN total_claim_amount < 10000 THEN 'Under $10K'
        WHEN total_claim_amount < 25000 THEN '$10K-$24.9K'
        WHEN total_claim_amount < 50000 THEN '$25K-$49.9K'
        ELSE '$50K+'
    END AS claim_size_group,
    injury_claim_amount,
    property_claim_amount,
    vehicle_claim_amount,
    ROUND(
        CASE
            WHEN total_claim_amount IS NOT NULL AND policy_annual_premium IS NOT NULL AND policy_annual_premium <> 0
            THEN total_claim_amount / policy_annual_premium
            ELSE NULL
        END,
        2
    ) AS claim_to_premium_ratio,
    auto_make,
    auto_model,
    auto_year,
    fraud_reported,
    data_quality_issue_count
FROM claims_final;

-- ============================================================
-- PART 6: CHECK RESULTS
-- ============================================================

SELECT 'v_data_quality_summary' AS object_name, COUNT(*) AS rows_returned FROM v_data_quality_summary
UNION ALL
SELECT 'v_data_quality_records', COUNT(*) FROM v_data_quality_records
UNION ALL
SELECT 'v_claims_kpi_summary', COUNT(*) FROM v_claims_kpi_summary
UNION ALL
SELECT 'v_claims_by_incident_type', COUNT(*) FROM v_claims_by_incident_type
UNION ALL
SELECT 'v_claims_by_state', COUNT(*) FROM v_claims_by_state
UNION ALL
SELECT 'v_claims_by_severity', COUNT(*) FROM v_claims_by_severity
UNION ALL
SELECT 'v_claims_by_month', COUNT(*) FROM v_claims_by_month
UNION ALL
SELECT 'v_claims_by_age_group', COUNT(*) FROM v_claims_by_age_group
UNION ALL
SELECT 'claims_powerbi_export', COUNT(*) FROM claims_powerbi_export;
