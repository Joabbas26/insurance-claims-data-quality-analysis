-- Project 1: Insurance Claims Data Cleaning in SQLite
-- Assumption: You imported insurance_claims_messy.csv into DB Browser for SQLite
-- and named the raw table: raw_claims
--
-- Keep raw_claims unchanged. All cleaning happens in new tables.

-- ============================================================
-- PART 1: RAW DATA AUDIT
-- ============================================================

-- Row count
SELECT COUNT(*) AS raw_row_count
FROM raw_claims;

-- Check duplicate full rows
SELECT COUNT(*) AS exact_duplicate_rows
FROM (
    SELECT *, COUNT(*) AS row_count
    FROM raw_claims
    GROUP BY 
        claim_id, months_as_customer, age, policy_number, policy_bind_date,
        policy_state, policy_csl, policy_deductable, policy_annual_premium,
        umbrella_limit, insured_zip, insured_sex, insured_education_level,
        insured_occupation, insured_hobbies, insured_relationship,
        "capital-gains", "capital-loss", incident_date, incident_type,
        collision_type, incident_severity, authorities_contacted,
        incident_state, incident_city, incident_location,
        incident_hour_of_the_day, number_of_vehicles_involved,
        property_damage, bodily_injuries, witnesses, police_report_available,
        total_claim_amount, injury_claim, property_claim, vehicle_claim,
        auto_make, auto_model, auto_year, fraud_reported
    HAVING COUNT(*) > 1
);

-- Check duplicate claim IDs
SELECT claim_id, COUNT(*) AS duplicate_count
FROM raw_claims
WHERE claim_id IS NOT NULL AND TRIM(claim_id) <> ''
GROUP BY claim_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, claim_id;

-- Check missing important IDs
SELECT
    SUM(CASE WHEN claim_id IS NULL OR TRIM(claim_id) = '' THEN 1 ELSE 0 END) AS missing_claim_id,
    SUM(CASE WHEN policy_number IS NULL OR TRIM(policy_number) = '' THEN 1 ELSE 0 END) AS missing_policy_number
FROM raw_claims;

-- Check inconsistent state values
SELECT policy_state, COUNT(*) AS records
FROM raw_claims
GROUP BY policy_state
ORDER BY records DESC;

SELECT incident_state, COUNT(*) AS records
FROM raw_claims
GROUP BY incident_state
ORDER BY records DESC;

-- Check messy yes/no values
SELECT property_damage, COUNT(*) AS records
FROM raw_claims
GROUP BY property_damage
ORDER BY records DESC;

SELECT police_report_available, COUNT(*) AS records
FROM raw_claims
GROUP BY police_report_available
ORDER BY records DESC;

-- ============================================================
-- PART 2: CREATE CLEANED STAGE TABLE
-- ============================================================

DROP TABLE IF EXISTS claims_clean_stage;

CREATE TABLE claims_clean_stage AS
WITH typed AS (
    SELECT
        rowid AS source_row_id,

        NULLIF(TRIM(claim_id), '') AS claim_id_original,

        CAST(months_as_customer AS INTEGER) AS months_as_customer,

        CAST(age AS INTEGER) AS age_raw,
        CASE 
            WHEN CAST(age AS INTEGER) BETWEEN 18 AND 100 THEN CAST(age AS INTEGER)
            ELSE NULL
        END AS age,

        CASE 
            WHEN NULLIF(TRIM(policy_number), '') IS NULL THEN NULL
            WHEN UPPER(TRIM(policy_number)) LIKE 'POL-%' THEN UPPER(TRIM(policy_number))
            ELSE 'POL-' || TRIM(policy_number)
        END AS policy_number,

        CASE
            WHEN TRIM(policy_bind_date) LIKE '____-__-__' THEN date(TRIM(policy_bind_date))
            WHEN TRIM(policy_bind_date) LIKE '__/__/____' THEN date(substr(TRIM(policy_bind_date), 7, 4) || '-' || substr(TRIM(policy_bind_date), 1, 2) || '-' || substr(TRIM(policy_bind_date), 4, 2))
            ELSE NULL
        END AS policy_bind_date,

        CASE UPPER(TRIM(policy_state))
            WHEN 'OHIO' THEN 'OH'
            WHEN 'ILLINOIS' THEN 'IL'
            WHEN 'INDIANA' THEN 'IN'
            ELSE UPPER(TRIM(policy_state))
        END AS policy_state,

        TRIM(policy_csl) AS policy_csl,
        CAST(policy_deductable AS INTEGER) AS policy_deductible,

        CAST(NULLIF(NULLIF(LOWER(REPLACE(REPLACE(TRIM(COALESCE(policy_annual_premium, '')), '$', ''), ',', '')), 'nan'), '') AS REAL) AS policy_annual_premium,

        CAST(umbrella_limit AS INTEGER) AS umbrella_limit,
        CAST(insured_zip AS TEXT) AS insured_zip,

        CASE UPPER(TRIM(insured_sex))
            WHEN 'MALE' THEN 'Male'
            WHEN 'FEMALE' THEN 'Female'
            ELSE 'Unknown'
        END AS insured_sex,

        TRIM(insured_education_level) AS insured_education_level,
        LOWER(TRIM(insured_occupation)) AS insured_occupation,
        LOWER(TRIM(insured_hobbies)) AS insured_hobbies,
        LOWER(TRIM(insured_relationship)) AS insured_relationship,

        CAST("capital-gains" AS INTEGER) AS capital_gains,
        CAST("capital-loss" AS INTEGER) AS capital_loss,

        CASE
            WHEN TRIM(incident_date) LIKE '____-__-__' THEN date(TRIM(incident_date))
            WHEN TRIM(incident_date) LIKE '__/__/____' THEN date(substr(TRIM(incident_date), 7, 4) || '-' || substr(TRIM(incident_date), 1, 2) || '-' || substr(TRIM(incident_date), 4, 2))
            ELSE NULL
        END AS incident_date,

        TRIM(incident_type) AS incident_type,

        CASE 
            WHEN UPPER(TRIM(collision_type)) IN ('?', 'UNKNOWN', 'UNKNOWN COLLISION', '') THEN 'Unknown'
            ELSE TRIM(collision_type)
        END AS collision_type,

        TRIM(incident_severity) AS incident_severity,

        CASE
            WHEN NULLIF(TRIM(authorities_contacted), '') IS NULL THEN 'Unknown'
            ELSE TRIM(authorities_contacted)
        END AS authorities_contacted,

        CASE UPPER(TRIM(incident_state))
            WHEN 'NEW YORK' THEN 'NY'
            WHEN 'SOUTH CAROLINA' THEN 'SC'
            WHEN 'WEST VIRGINIA' THEN 'WV'
            WHEN 'VIRGINIA' THEN 'VA'
            WHEN 'PENNSYLVANIA' THEN 'PA'
            WHEN 'NORTH CAROLINA' THEN 'NC'
            ELSE UPPER(TRIM(incident_state))
        END AS incident_state,

        UPPER(TRIM(incident_city)) AS incident_city,
        TRIM(incident_location) AS incident_location,

        CAST(incident_hour_of_the_day AS INTEGER) AS incident_hour_raw,
        CASE
            WHEN CAST(incident_hour_of_the_day AS INTEGER) BETWEEN 0 AND 23 THEN CAST(incident_hour_of_the_day AS INTEGER)
            ELSE NULL
        END AS incident_hour_of_day,

        CAST(number_of_vehicles_involved AS INTEGER) AS number_of_vehicles_involved,

        CASE
            WHEN UPPER(TRIM(COALESCE(property_damage, ''))) IN ('YES', 'Y', 'TRUE', '1') THEN 'Yes'
            WHEN UPPER(TRIM(COALESCE(property_damage, ''))) IN ('NO', 'N', 'FALSE', '0') THEN 'No'
            ELSE 'Unknown'
        END AS property_damage,

        CAST(bodily_injuries AS INTEGER) AS bodily_injuries,
        CAST(witnesses AS INTEGER) AS witnesses,

        CASE
            WHEN UPPER(TRIM(COALESCE(police_report_available, ''))) IN ('YES', 'Y', 'TRUE', '1') THEN 'Yes'
            WHEN UPPER(TRIM(COALESCE(police_report_available, ''))) IN ('NO', 'N', 'FALSE', '0') THEN 'No'
            ELSE 'Unknown'
        END AS police_report_available,

        CAST(NULLIF(NULLIF(LOWER(REPLACE(REPLACE(TRIM(COALESCE(total_claim_amount, '')), '$', ''), ',', '')), 'nan'), '') AS REAL) AS total_claim_amount_raw,
        CAST(NULLIF(NULLIF(LOWER(REPLACE(REPLACE(TRIM(COALESCE(injury_claim, '')), '$', ''), ',', '')), 'nan'), '') AS REAL) AS injury_claim_raw,
        CAST(NULLIF(NULLIF(LOWER(REPLACE(REPLACE(TRIM(COALESCE(property_claim, '')), '$', ''), ',', '')), 'nan'), '') AS REAL) AS property_claim_raw,
        CAST(NULLIF(NULLIF(LOWER(REPLACE(REPLACE(TRIM(COALESCE(vehicle_claim, '')), '$', ''), ',', '')), 'nan'), '') AS REAL) AS vehicle_claim_raw,

        TRIM(auto_make) AS auto_make,
        TRIM(auto_model) AS auto_model,
        CAST(auto_year AS INTEGER) AS auto_year,

        CASE UPPER(TRIM(fraud_reported))
            WHEN 'Y' THEN 'Yes'
            WHEN 'N' THEN 'No'
            ELSE 'Unknown'
        END AS fraud_reported,

        policy_bind_date AS policy_bind_date_original,
        incident_date AS incident_date_original
    FROM raw_claims
),
scored AS (
    SELECT
        *,
        COALESCE(claim_id_original, 'MISSING_' || source_row_id) AS claim_id,

        CASE WHEN claim_id_original IS NULL THEN 1 ELSE 0 END AS missing_claim_id_flag,
        CASE WHEN policy_number IS NULL THEN 1 ELSE 0 END AS missing_policy_number_flag,
        CASE WHEN age_raw NOT BETWEEN 18 AND 100 THEN 1 ELSE 0 END AS invalid_age_flag,
        CASE WHEN incident_hour_raw NOT BETWEEN 0 AND 23 THEN 1 ELSE 0 END AS invalid_incident_hour_flag,

        CASE 
            WHEN policy_bind_date IS NULL AND LOWER(TRIM(COALESCE(policy_bind_date_original, ''))) NOT IN ('', 'nan') THEN 1
            ELSE 0
        END AS invalid_policy_bind_date_flag,

        CASE 
            WHEN incident_date IS NULL AND LOWER(TRIM(COALESCE(incident_date_original, ''))) NOT IN ('', 'nan') THEN 1
            ELSE 0
        END AS invalid_incident_date_flag,

        CASE 
            WHEN COALESCE(total_claim_amount_raw, 0) < 0
              OR COALESCE(injury_claim_raw, 0) < 0
              OR COALESCE(property_claim_raw, 0) < 0
              OR COALESCE(vehicle_claim_raw, 0) < 0
            THEN 1 ELSE 0
        END AS negative_claim_amount_flag,

        CASE
            WHEN total_claim_amount_raw IS NOT NULL
             AND injury_claim_raw IS NOT NULL
             AND property_claim_raw IS NOT NULL
             AND vehicle_claim_raw IS NOT NULL
             AND ABS(ABS(total_claim_amount_raw) - (ABS(injury_claim_raw) + ABS(property_claim_raw) + ABS(vehicle_claim_raw))) > 1
            THEN 1 ELSE 0
        END AS claim_total_mismatch_flag,

        ABS(injury_claim_raw) AS injury_claim_amount,
        ABS(property_claim_raw) AS property_claim_amount,
        ABS(vehicle_claim_raw) AS vehicle_claim_amount,

        CASE
            WHEN injury_claim_raw IS NOT NULL 
             AND property_claim_raw IS NOT NULL 
             AND vehicle_claim_raw IS NOT NULL
            THEN ABS(injury_claim_raw) + ABS(property_claim_raw) + ABS(vehicle_claim_raw)
            ELSE ABS(total_claim_amount_raw)
        END AS total_claim_amount
    FROM typed
),
with_dup_flags AS (
    SELECT
        *,
        CASE
            WHEN claim_id_original IS NOT NULL 
             AND COUNT(*) OVER (PARTITION BY claim_id_original) > 1
            THEN 1 ELSE 0
        END AS duplicate_claim_id_flag
    FROM scored
)
SELECT
    source_row_id,
    claim_id,
    claim_id_original,
    policy_number,
    months_as_customer,
    age,
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
    incident_type,
    collision_type,
    incident_severity,
    authorities_contacted,
    incident_state,
    incident_city,
    incident_location,
    incident_hour_of_day,
    number_of_vehicles_involved,
    property_damage,
    bodily_injuries,
    witnesses,
    police_report_available,
    total_claim_amount,
    injury_claim_amount,
    property_claim_amount,
    vehicle_claim_amount,
    auto_make,
    auto_model,
    auto_year,
    fraud_reported,
    missing_claim_id_flag,
    missing_policy_number_flag,
    duplicate_claim_id_flag,
    invalid_age_flag,
    invalid_incident_hour_flag,
    invalid_policy_bind_date_flag,
    invalid_incident_date_flag,
    negative_claim_amount_flag,
    claim_total_mismatch_flag,
    (
        missing_claim_id_flag
        + missing_policy_number_flag
        + duplicate_claim_id_flag
        + invalid_age_flag
        + invalid_incident_hour_flag
        + invalid_policy_bind_date_flag
        + invalid_incident_date_flag
        + negative_claim_amount_flag
        + claim_total_mismatch_flag
    ) AS data_quality_issue_count
FROM with_dup_flags;

-- ============================================================
-- PART 3: CREATE FINAL CLEAN TABLE
-- Keeps one record per claim_id. Rows with missing claim IDs receive generated IDs.
-- When duplicated claim IDs exist, this keeps the row with fewer data-quality issues.
-- ============================================================

DROP TABLE IF EXISTS claims_final;

CREATE TABLE claims_final AS
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY claim_id
            ORDER BY data_quality_issue_count ASC, source_row_id ASC
        ) AS row_choice
    FROM claims_clean_stage
)
SELECT *
FROM ranked
WHERE row_choice = 1;

-- ============================================================
-- PART 4: FINAL QUALITY CHECKS
-- ============================================================

-- Raw vs cleaned row counts
SELECT 'raw_claims' AS table_name, COUNT(*) AS row_count FROM raw_claims
UNION ALL
SELECT 'claims_clean_stage', COUNT(*) FROM claims_clean_stage
UNION ALL
SELECT 'claims_final', COUNT(*) FROM claims_final;

-- Data quality issue summary
SELECT 'missing_claim_id' AS issue, SUM(missing_claim_id_flag) AS records FROM claims_clean_stage
UNION ALL
SELECT 'missing_policy_number', SUM(missing_policy_number_flag) FROM claims_clean_stage
UNION ALL
SELECT 'duplicate_claim_id', SUM(duplicate_claim_id_flag) FROM claims_clean_stage
UNION ALL
SELECT 'invalid_age', SUM(invalid_age_flag) FROM claims_clean_stage
UNION ALL
SELECT 'invalid_incident_hour', SUM(invalid_incident_hour_flag) FROM claims_clean_stage
UNION ALL
SELECT 'invalid_policy_bind_date', SUM(invalid_policy_bind_date_flag) FROM claims_clean_stage
UNION ALL
SELECT 'invalid_incident_date', SUM(invalid_incident_date_flag) FROM claims_clean_stage
UNION ALL
SELECT 'negative_claim_amount', SUM(negative_claim_amount_flag) FROM claims_clean_stage
UNION ALL
SELECT 'claim_total_mismatch', SUM(claim_total_mismatch_flag) FROM claims_clean_stage;

-- Check cleaned state values
SELECT policy_state, COUNT(*) AS records
FROM claims_final
GROUP BY policy_state
ORDER BY records DESC;

-- Check cleaned property damage values
SELECT property_damage, COUNT(*) AS records
FROM claims_final
GROUP BY property_damage
ORDER BY records DESC;

-- Check total claim amount range
SELECT
    MIN(total_claim_amount) AS min_total_claim,
    MAX(total_claim_amount) AS max_total_claim,
    ROUND(AVG(total_claim_amount), 2) AS avg_total_claim,
    ROUND(SUM(total_claim_amount), 2) AS total_claims_paid
FROM claims_final;

-- Simple business analysis query for your portfolio
SELECT
    incident_type,
    COUNT(*) AS claim_count,
    ROUND(SUM(total_claim_amount), 2) AS total_claim_amount,
    ROUND(AVG(total_claim_amount), 2) AS avg_claim_amount,
    ROUND(100.0 * SUM(CASE WHEN fraud_reported = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS fraud_rate_pct
FROM claims_final
GROUP BY incident_type
ORDER BY total_claim_amount DESC;
