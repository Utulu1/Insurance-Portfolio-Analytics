/* ============================================================
   INSURANCE PORTFOLIO PERFORMANCE ANALYTICS
   02 - DATA QUALITY AUDIT

   Purpose:
   Assess the completeness, consistency and validity of the
   raw insurance portfolio data before transformation.

   Layer: RAW
   Author: Anthony Utulu Analytics
   ============================================================ */

USE InsurancePortfolioAnalytics;
GO


/* ============================================================
   01. DATASET STRUCTURE & BASIC COMPLETENESS
   ============================================================ */

-- Confirm total number of imported records
SELECT
    COUNT(*) AS total_rows
FROM raw.motor_insurance_portfolio;
GO


-- Confirm number of source columns
SELECT
    COUNT(*) AS total_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_NAME = 'motor_insurance_portfolio';
GO


-- Review a sample of the raw source data
SELECT TOP (10) *
FROM raw.motor_insurance_portfolio;
GO


/* ============================================================
   02. DUPLICATE & KEY INTEGRITY AUDIT
   ============================================================ */

-- Number of distinct insured entities
SELECT
    COUNT(DISTINCT insured_id) AS distinct_insured_ids
FROM raw.motor_insurance_portfolio;
GO


-- Distribution of records by year
SELECT
    [year],
    COUNT(*) AS record_count
FROM raw.motor_insurance_portfolio
GROUP BY [year]
ORDER BY [year];
GO


-- Test whether insured_id + year forms a unique business key
SELECT
    insured_id,
    [year],
    COUNT(*) AS occurrence_count
FROM raw.motor_insurance_portfolio
GROUP BY insured_id, [year]
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;
GO


-- Count how many duplicated insured_id/year combinations exist
SELECT
    COUNT(*) AS duplicate_key_combinations
FROM
(
    SELECT
        insured_id,
        [year]
    FROM raw.motor_insurance_portfolio
    GROUP BY insured_id, [year]
    HAVING COUNT(*) > 1
) AS duplicates;
GO


/* ============================================================
   03. MISSING & BLANK VALUE AUDIT
   ============================================================ */

SELECT
    COUNT(*) AS total_rows,

    -- Core identifiers
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(insured_id)), '') IS NULL THEN 1 ELSE 0 END)
        AS missing_insured_id,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM([year])), '') IS NULL THEN 1 ELSE 0 END)
        AS missing_year,

    -- Policy characteristics
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(policy_type)), '') IS NULL THEN 1 ELSE 0 END)
        AS missing_policy_type,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(policy_status)), '') IS NULL THEN 1 ELSE 0 END)
        AS missing_policy_status,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(business_type)), '') IS NULL THEN 1 ELSE 0 END)
        AS missing_business_type,

    -- Driver / vehicle characteristics
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(driver_age)), '') IS NULL THEN 1 ELSE 0 END)
        AS missing_driver_age,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(vehicle_age)), '') IS NULL THEN 1 ELSE 0 END)
        AS missing_vehicle_age,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(vehicle_value)), '') IS NULL THEN 1 ELSE 0 END)
        AS missing_vehicle_value,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(vehicle_brand)), '') IS NULL THEN 1 ELSE 0 END)
        AS missing_vehicle_brand,

    -- Core financial measures
    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(total_premium)), '') IS NULL THEN 1 ELSE 0 END)
        AS missing_total_premium,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(total_claims)), '') IS NULL THEN 1 ELSE 0 END)
        AS missing_total_claims,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(total_incurred)), '') IS NULL THEN 1 ELSE 0 END)
        AS missing_total_incurred,

    SUM(CASE WHEN NULLIF(LTRIM(RTRIM(total_exposure)), '') IS NULL THEN 1 ELSE 0 END)
        AS missing_total_exposure

FROM raw.motor_insurance_portfolio;
GO


/* ============================================================
   04. FULL DATASET COLUMN COMPLETENESS AUDIT
   Purpose:
   Examine NULL counts across all 47 source variables to identify
   fields requiring treatment before the staging layer is created.
   ============================================================ */

SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN insured_id IS NULL THEN 1 ELSE 0 END) AS missing_insured_id,
    SUM(CASE WHEN [year] IS NULL THEN 1 ELSE 0 END) AS missing_year,
    SUM(CASE WHEN policy_type IS NULL THEN 1 ELSE 0 END) AS missing_policy_type,
    SUM(CASE WHEN policy_status IS NULL THEN 1 ELSE 0 END) AS missing_policy_status,
    SUM(CASE WHEN business_type IS NULL THEN 1 ELSE 0 END) AS missing_business_type,
    SUM(CASE WHEN payment_frequency IS NULL THEN 1 ELSE 0 END) AS missing_payment_frequency,
    SUM(CASE WHEN bonus_score IS NULL THEN 1 ELSE 0 END) AS missing_bonus_score,
    SUM(CASE WHEN driver_age IS NULL THEN 1 ELSE 0 END) AS missing_driver_age,
    SUM(CASE WHEN vehicle_age IS NULL THEN 1 ELSE 0 END) AS missing_vehicle_age,
    SUM(CASE WHEN age_driving_licence IS NULL THEN 1 ELSE 0 END) AS missing_age_driving_licence,
    SUM(CASE WHEN fuel_type IS NULL THEN 1 ELSE 0 END) AS missing_fuel_type,
    SUM(CASE WHEN vehicle_value IS NULL THEN 1 ELSE 0 END) AS missing_vehicle_value,
    SUM(CASE WHEN seats IS NULL THEN 1 ELSE 0 END) AS missing_seats,
    SUM(CASE WHEN power_to_weight_ratio IS NULL THEN 1 ELSE 0 END) AS missing_power_to_weight_ratio,
    SUM(CASE WHEN vehicle_brand IS NULL THEN 1 ELSE 0 END) AS missing_vehicle_brand,
    SUM(CASE WHEN municipality_type IS NULL THEN 1 ELSE 0 END) AS missing_municipality_type,
    SUM(CASE WHEN circulation_area IS NULL THEN 1 ELSE 0 END) AS missing_circulation_area,

    SUM(CASE WHEN total_premium IS NULL THEN 1 ELSE 0 END) AS missing_total_premium,
    SUM(CASE WHEN liability_premium IS NULL THEN 1 ELSE 0 END) AS missing_liability_premium,
    SUM(CASE WHEN property_damage_premium IS NULL THEN 1 ELSE 0 END) AS missing_property_damage_premium,
    SUM(CASE WHEN theft_premium IS NULL THEN 1 ELSE 0 END) AS missing_theft_premium,
    SUM(CASE WHEN fire_premium IS NULL THEN 1 ELSE 0 END) AS missing_fire_premium,
    SUM(CASE WHEN glass_premium IS NULL THEN 1 ELSE 0 END) AS missing_glass_premium,
    SUM(CASE WHEN legal_protection_premium IS NULL THEN 1 ELSE 0 END) AS missing_legal_protection_premium,
    SUM(CASE WHEN occupants_premium IS NULL THEN 1 ELSE 0 END) AS missing_occupants_premium,

    SUM(CASE WHEN total_claims IS NULL THEN 1 ELSE 0 END) AS missing_total_claims,
    SUM(CASE WHEN liability_claims IS NULL THEN 1 ELSE 0 END) AS missing_liability_claims,
    SUM(CASE WHEN liability_property_claims IS NULL THEN 1 ELSE 0 END) AS missing_liability_property_claims,
    SUM(CASE WHEN liability_injury_claims IS NULL THEN 1 ELSE 0 END) AS missing_liability_injury_claims,
    SUM(CASE WHEN property_claims IS NULL THEN 1 ELSE 0 END) AS missing_property_claims,
    SUM(CASE WHEN theft_claims IS NULL THEN 1 ELSE 0 END) AS missing_theft_claims,
    SUM(CASE WHEN fire_claims IS NULL THEN 1 ELSE 0 END) AS missing_fire_claims,
    SUM(CASE WHEN glass_claims IS NULL THEN 1 ELSE 0 END) AS missing_glass_claims,
    SUM(CASE WHEN legal_protection_claims IS NULL THEN 1 ELSE 0 END) AS missing_legal_protection_claims,
    SUM(CASE WHEN occupants_claims IS NULL THEN 1 ELSE 0 END) AS missing_occupants_claims,

    SUM(CASE WHEN total_incurred IS NULL THEN 1 ELSE 0 END) AS missing_total_incurred,
    SUM(CASE WHEN liability_incurred IS NULL THEN 1 ELSE 0 END) AS missing_liability_incurred,
    SUM(CASE WHEN liability_property_incurred IS NULL THEN 1 ELSE 0 END) AS missing_liability_property_incurred,
    SUM(CASE WHEN liability_injury_incurred IS NULL THEN 1 ELSE 0 END) AS missing_liability_injury_incurred,
    SUM(CASE WHEN property_incurred IS NULL THEN 1 ELSE 0 END) AS missing_property_incurred,
    SUM(CASE WHEN theft_incurred IS NULL THEN 1 ELSE 0 END) AS missing_theft_incurred,
    SUM(CASE WHEN fire_incurred IS NULL THEN 1 ELSE 0 END) AS missing_fire_incurred,
    SUM(CASE WHEN glass_incurred IS NULL THEN 1 ELSE 0 END) AS missing_glass_incurred,
    SUM(CASE WHEN legal_protection_incurred IS NULL THEN 1 ELSE 0 END) AS missing_legal_protection_incurred,
    SUM(CASE WHEN occupants_incurred IS NULL THEN 1 ELSE 0 END) AS missing_occupants_incurred,

    SUM(CASE WHEN total_exposure IS NULL THEN 1 ELSE 0 END) AS missing_total_exposure,
    SUM(CASE WHEN liability_exposure IS NULL THEN 1 ELSE 0 END) AS missing_liability_exposure

FROM raw.motor_insurance_portfolio;
GO


/* ============================================================
   05. NUMERICAL BUSINESS-RULE VALIDATION
   Purpose:
   Identify potentially invalid or economically implausible
   values in key insurance portfolio measures.
   ============================================================ */
/* ============================================================
   05. NUMERICAL BUSINESS-RULE VALIDATION
   Purpose:
   Validate numerical fields while preserving the raw source
   table in its original imported form.

   TRY_CONVERT is used because raw-layer fields are stored as
   text and should not be permanently transformed at this stage.
   ============================================================ */

SELECT

    -- Age checks
    SUM(CASE
        WHEN TRY_CONVERT(decimal(18,4), driver_age) < 16
          OR TRY_CONVERT(decimal(18,4), driver_age) > 100
        THEN 1 ELSE 0
    END) AS invalid_driver_age,

    SUM(CASE
        WHEN TRY_CONVERT(decimal(18,4), vehicle_age) < 0
          OR TRY_CONVERT(decimal(18,4), vehicle_age) > 100
        THEN 1 ELSE 0
    END) AS invalid_vehicle_age,

    SUM(CASE
        WHEN TRY_CONVERT(decimal(18,4), age_driving_licence) < 0
          OR TRY_CONVERT(decimal(18,4), age_driving_licence)
             > TRY_CONVERT(decimal(18,4), driver_age)
        THEN 1 ELSE 0
    END) AS invalid_licence_age,

    -- Vehicle checks
    SUM(CASE
        WHEN TRY_CONVERT(decimal(18,4), vehicle_value) < 0
        THEN 1 ELSE 0
    END) AS negative_vehicle_value,

    SUM(CASE
        WHEN TRY_CONVERT(decimal(18,4), seats) <= 0
        THEN 1 ELSE 0
    END) AS invalid_seats,

    SUM(CASE
        WHEN TRY_CONVERT(decimal(18,4), power_to_weight_ratio) < 0
        THEN 1 ELSE 0
    END) AS negative_power_to_weight_ratio,

    -- Premium checks
    SUM(CASE
        WHEN TRY_CONVERT(decimal(18,4), total_premium) < 0
        THEN 1 ELSE 0
    END) AS negative_total_premium,

    -- Claims checks
    SUM(CASE
        WHEN TRY_CONVERT(decimal(18,4), total_claims) < 0
        THEN 1 ELSE 0
    END) AS negative_total_claims,

    -- Incurred loss checks
    SUM(CASE
        WHEN TRY_CONVERT(decimal(18,4), total_incurred) < 0
        THEN 1 ELSE 0
    END) AS negative_total_incurred,

    -- Exposure checks
    SUM(CASE
        WHEN TRY_CONVERT(decimal(18,4), total_exposure) < 0
        THEN 1 ELSE 0
    END) AS negative_total_exposure,

    SUM(CASE
        WHEN TRY_CONVERT(decimal(18,4), liability_exposure) < 0
        THEN 1 ELSE 0
    END) AS negative_liability_exposure

FROM raw.motor_insurance_portfolio;
GO


/* ============================================================
   06. NUMERIC CONVERSION INTEGRITY
   Purpose:
   Identify non-null source values that cannot be converted
   to the numerical data types required for analysis.
   ============================================================ */

SELECT
    SUM(CASE WHEN driver_age IS NOT NULL
                  AND TRY_CONVERT(decimal(18,4), driver_age) IS NULL
             THEN 1 ELSE 0 END) AS invalid_driver_age_format,

    SUM(CASE WHEN vehicle_age IS NOT NULL
                  AND TRY_CONVERT(decimal(18,4), vehicle_age) IS NULL
             THEN 1 ELSE 0 END) AS invalid_vehicle_age_format,

    SUM(CASE WHEN age_driving_licence IS NOT NULL
                  AND TRY_CONVERT(decimal(18,4), age_driving_licence) IS NULL
             THEN 1 ELSE 0 END) AS invalid_licence_age_format,

    SUM(CASE WHEN vehicle_value IS NOT NULL
                  AND TRY_CONVERT(decimal(18,4), vehicle_value) IS NULL
             THEN 1 ELSE 0 END) AS invalid_vehicle_value_format,

    SUM(CASE WHEN seats IS NOT NULL
                  AND TRY_CONVERT(decimal(18,4), seats) IS NULL
             THEN 1 ELSE 0 END) AS invalid_seats_format,

    SUM(CASE WHEN power_to_weight_ratio IS NOT NULL
                  AND TRY_CONVERT(decimal(18,4), power_to_weight_ratio) IS NULL
             THEN 1 ELSE 0 END) AS invalid_power_weight_format,

    SUM(CASE WHEN total_premium IS NOT NULL
                  AND TRY_CONVERT(decimal(18,4), total_premium) IS NULL
             THEN 1 ELSE 0 END) AS invalid_total_premium_format,

    SUM(CASE WHEN total_claims IS NOT NULL
                  AND TRY_CONVERT(decimal(18,4), total_claims) IS NULL
             THEN 1 ELSE 0 END) AS invalid_total_claims_format,

    SUM(CASE WHEN total_incurred IS NOT NULL
                  AND TRY_CONVERT(decimal(18,4), total_incurred) IS NULL
             THEN 1 ELSE 0 END) AS invalid_total_incurred_format,

    SUM(CASE WHEN total_exposure IS NOT NULL
                  AND TRY_CONVERT(decimal(18,4), total_exposure) IS NULL
             THEN 1 ELSE 0 END) AS invalid_total_exposure_format,

    SUM(CASE WHEN liability_exposure IS NOT NULL
                  AND TRY_CONVERT(decimal(18,4), liability_exposure) IS NULL
             THEN 1 ELSE 0 END) AS invalid_liability_exposure_format

FROM raw.motor_insurance_portfolio;
GO


/* ============================================================
   07. INVESTIGATION OF NUMERIC CONVERSION FAILURES
   Purpose:
   Inspect source values that failed numerical conversion before
   making any cleaning or transformation decisions.
   ============================================================ */

-- 1. Vehicle age conversion failures
SELECT
    vehicle_age,
    COUNT(*) AS occurrence_count
FROM raw.motor_insurance_portfolio
WHERE vehicle_age IS NOT NULL
  AND TRY_CONVERT(decimal(18,4), vehicle_age) IS NULL
GROUP BY vehicle_age
ORDER BY occurrence_count DESC;
GO


-- 2. Driving licence age conversion failures
SELECT
    age_driving_licence,
    COUNT(*) AS occurrence_count
FROM raw.motor_insurance_portfolio
WHERE age_driving_licence IS NOT NULL
  AND TRY_CONVERT(decimal(18,4), age_driving_licence) IS NULL
GROUP BY age_driving_licence
ORDER BY occurrence_count DESC;
GO


-- 3. Vehicle value conversion failures
SELECT
    vehicle_value,
    COUNT(*) AS occurrence_count
FROM raw.motor_insurance_portfolio
WHERE vehicle_value IS NOT NULL
  AND TRY_CONVERT(decimal(18,4), vehicle_value) IS NULL
GROUP BY vehicle_value
ORDER BY occurrence_count DESC;
GO


-- 4. Total incurred conversion failures
SELECT
    total_incurred,
    COUNT(*) AS occurrence_count
FROM raw.motor_insurance_portfolio
WHERE total_incurred IS NOT NULL
  AND TRY_CONVERT(decimal(18,4), total_incurred) IS NULL
GROUP BY total_incurred
ORDER BY occurrence_count DESC;
GO


/* ============================================================
   08. INVESTIGATE MISSING SOURCE VALUES
   Purpose:
   Examine records containing 'NA' values and determine whether
   missingness follows identifiable business patterns.
   ============================================================ */

-- Count NA vehicle values by year
SELECT
    [year],
    COUNT(*) AS missing_vehicle_value_count
FROM raw.motor_insurance_portfolio
WHERE vehicle_value = 'NA'
GROUP BY [year]
ORDER BY [year];
GO


-- Count NA vehicle values by policy type
SELECT
    policy_type,
    COUNT(*) AS missing_vehicle_value_count
FROM raw.motor_insurance_portfolio
WHERE vehicle_value = 'NA'
GROUP BY policy_type
ORDER BY missing_vehicle_value_count DESC;
GO


-- Count NA vehicle values by business type
SELECT
    business_type,
    COUNT(*) AS missing_vehicle_value_count
FROM raw.motor_insurance_portfolio
WHERE vehicle_value = 'NA'
GROUP BY business_type
ORDER BY missing_vehicle_value_count DESC;
GO


-- Inspect the two records with missing vehicle age
SELECT *
FROM raw.motor_insurance_portfolio
WHERE vehicle_age = 'NA';
GO


-- Inspect the two records with missing driving licence age
SELECT *
FROM raw.motor_insurance_portfolio
WHERE age_driving_licence = 'NA';
GO


-- Inspect the scientific-notation total incurred record
SELECT *
FROM raw.motor_insurance_portfolio
WHERE total_incurred = '6.53699316899292e-14';
GO