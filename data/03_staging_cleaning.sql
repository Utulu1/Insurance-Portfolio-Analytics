/* ============================================================
   INSURANCE PORTFOLIO PERFORMANCE ANALYTICS
   03 - STAGING CLEANING & TYPE CONVERSION

   Purpose:
   Convert the raw text-based source data into a validated,
   analysis-ready staging table with appropriate SQL data types.

   Layer: STAGING
   Author: Anthony Utulu Analytics
   ============================================================ */

USE InsurancePortfolioAnalytics;
GO


/* ============================================================
   01. CREATE TYPED STAGING TABLE
   ============================================================ */

CREATE TABLE staging.motor_insurance_portfolio
(
    insured_id                    BIGINT          NOT NULL,
    [year]                        SMALLINT        NOT NULL,

    policy_type                   NVARCHAR(20)    NULL,
    policy_status                 NVARCHAR(10)    NULL,
    business_type                 NVARCHAR(10)    NULL,
    payment_frequency             NVARCHAR(10)    NULL,
    bonus_score                   INT             NULL,

    driver_age                    SMALLINT        NULL,
    vehicle_age                   SMALLINT        NULL,
    age_driving_licence           SMALLINT        NULL,

    fuel_type                     NVARCHAR(10)    NULL,
    vehicle_value                 DECIMAL(18,4)   NULL,
    seats                         SMALLINT        NULL,
    power_to_weight_ratio         DECIMAL(18,4)   NULL,
    vehicle_brand                 NVARCHAR(100)   NULL,
    municipality_type             NVARCHAR(10)    NULL,
    circulation_area              NVARCHAR(10)    NULL,

    total_premium                 DECIMAL(18,4)   NULL,
    liability_premium             DECIMAL(18,4)   NULL,
    property_damage_premium       DECIMAL(18,4)   NULL,
    theft_premium                 DECIMAL(18,4)   NULL,
    fire_premium                  DECIMAL(18,4)   NULL,
    glass_premium                 DECIMAL(18,4)   NULL,
    legal_protection_premium      DECIMAL(18,4)   NULL,
    occupants_premium             DECIMAL(18,4)   NULL,

    total_claims                  INT             NULL,
    liability_claims              INT             NULL,
    liability_property_claims     INT             NULL,
    liability_injury_claims       INT             NULL,
    property_claims               INT             NULL,
    theft_claims                  INT             NULL,
    fire_claims                   INT             NULL,
    glass_claims                  INT             NULL,
    legal_protection_claims       INT             NULL,
    occupants_claims              INT             NULL,

    total_incurred                DECIMAL(18,4)   NULL,
    liability_incurred            DECIMAL(18,4)   NULL,
    liability_property_incurred   DECIMAL(18,4)   NULL,
    liability_injury_incurred     DECIMAL(18,4)   NULL,
    property_incurred             DECIMAL(18,4)   NULL,
    theft_incurred                DECIMAL(18,4)   NULL,
    fire_incurred                 DECIMAL(18,4)   NULL,
    glass_incurred                DECIMAL(18,4)   NULL,
    legal_protection_incurred     DECIMAL(18,4)   NULL,
    occupants_incurred            DECIMAL(18,4)   NULL,

    total_exposure                DECIMAL(18,6)   NULL,
    liability_exposure            DECIMAL(18,6)   NULL,

    CONSTRAINT PK_staging_motor_insurance
        PRIMARY KEY (insured_id, [year])
);
GO


SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'staging';
GO


/* ============================================================
   02. CONTROLLED RAW-TO-STAGING LOAD

   Purpose:
   Transform raw text fields into appropriate SQL data types,
   convert source-coded 'NA' values to NULL, and preserve
   valid numerical values for downstream analytics.
   ============================================================ */

INSERT INTO staging.motor_insurance_portfolio
(
    insured_id,
    [year],
    policy_type,
    policy_status,
    business_type,
    payment_frequency,
    bonus_score,
    driver_age,
    vehicle_age,
    age_driving_licence,
    fuel_type,
    vehicle_value,
    seats,
    power_to_weight_ratio,
    vehicle_brand,
    municipality_type,
    circulation_area,
    total_premium,
    liability_premium,
    property_damage_premium,
    theft_premium,
    fire_premium,
    glass_premium,
    legal_protection_premium,
    occupants_premium,
    total_claims,
    liability_claims,
    liability_property_claims,
    liability_injury_claims,
    property_claims,
    theft_claims,
    fire_claims,
    glass_claims,
    legal_protection_claims,
    occupants_claims,
    total_incurred,
    liability_incurred,
    liability_property_incurred,
    liability_injury_incurred,
    property_incurred,
    theft_incurred,
    fire_incurred,
    glass_incurred,
    legal_protection_incurred,
    occupants_incurred,
    total_exposure,
    liability_exposure
)
SELECT
    TRY_CONVERT(BIGINT, insured_id),
    TRY_CONVERT(SMALLINT, [year]),

    NULLIF(TRIM(policy_type), ''),
    NULLIF(TRIM(policy_status), ''),
    NULLIF(TRIM(business_type), ''),
    NULLIF(TRIM(payment_frequency), ''),
    TRY_CONVERT(INT, NULLIF(TRIM(bonus_score), 'NA')),

    TRY_CONVERT(SMALLINT, NULLIF(TRIM(driver_age), 'NA')),
    TRY_CONVERT(SMALLINT, NULLIF(TRIM(vehicle_age), 'NA')),
    TRY_CONVERT(SMALLINT, NULLIF(TRIM(age_driving_licence), 'NA')),

    NULLIF(TRIM(fuel_type), ''),

    TRY_CONVERT(DECIMAL(18,4),
        NULLIF(TRIM(vehicle_value), 'NA')),

    TRY_CONVERT(SMALLINT,
        NULLIF(TRIM(seats), 'NA')),

    TRY_CONVERT(DECIMAL(18,4),
        NULLIF(TRIM(power_to_weight_ratio), 'NA')),

    NULLIF(TRIM(vehicle_brand), ''),
    NULLIF(TRIM(municipality_type), ''),
    NULLIF(TRIM(circulation_area), ''),

    TRY_CONVERT(DECIMAL(18,4), total_premium),
    TRY_CONVERT(DECIMAL(18,4), liability_premium),
    TRY_CONVERT(DECIMAL(18,4), property_damage_premium),
    TRY_CONVERT(DECIMAL(18,4), theft_premium),
    TRY_CONVERT(DECIMAL(18,4), fire_premium),
    TRY_CONVERT(DECIMAL(18,4), glass_premium),
    TRY_CONVERT(DECIMAL(18,4), legal_protection_premium),
    TRY_CONVERT(DECIMAL(18,4), occupants_premium),

    TRY_CONVERT(INT, total_claims),
    TRY_CONVERT(INT, liability_claims),
    TRY_CONVERT(INT, liability_property_claims),
    TRY_CONVERT(INT, liability_injury_claims),
    TRY_CONVERT(INT, property_claims),
    TRY_CONVERT(INT, theft_claims),
    TRY_CONVERT(INT, fire_claims),
    TRY_CONVERT(INT, glass_claims),
    TRY_CONVERT(INT, legal_protection_claims),
    TRY_CONVERT(INT, occupants_claims),

    -- Handles ordinary decimals AND scientific notation
    TRY_CONVERT(
        DECIMAL(18,4),
        TRY_CONVERT(FLOAT, NULLIF(TRIM(total_incurred), 'NA'))
    ),

    TRY_CONVERT(DECIMAL(18,4), liability_incurred),
    TRY_CONVERT(DECIMAL(18,4), liability_property_incurred),
    TRY_CONVERT(DECIMAL(18,4), liability_injury_incurred),
    TRY_CONVERT(DECIMAL(18,4), property_incurred),
    TRY_CONVERT(DECIMAL(18,4), theft_incurred),
    TRY_CONVERT(DECIMAL(18,4), fire_incurred),
    TRY_CONVERT(DECIMAL(18,4), glass_incurred),
    TRY_CONVERT(DECIMAL(18,4), legal_protection_incurred),
    TRY_CONVERT(DECIMAL(18,4), occupants_incurred),

    TRY_CONVERT(DECIMAL(18,6), total_exposure),
    TRY_CONVERT(DECIMAL(18,6), liability_exposure)

FROM raw.motor_insurance_portfolio;
GO

/* ============================================================
   03. RAW-TO-STAGING RECONCILIATION

   Purpose:
   Confirm that all source records were successfully transferred
   to staging and that identified data-quality issues were
   transformed according to documented business rules.
   ============================================================ */

-- 1. Compare raw and staging row counts
SELECT
    (SELECT COUNT(*)
     FROM raw.motor_insurance_portfolio) AS raw_rows,

    (SELECT COUNT(*)
     FROM staging.motor_insurance_portfolio) AS staging_rows,

    (SELECT COUNT(*)
     FROM raw.motor_insurance_portfolio)
    -
    (SELECT COUNT(*)
     FROM staging.motor_insurance_portfolio) AS row_difference;
GO


-- 2. Confirm distinct insured IDs survived transformation
SELECT
    (SELECT COUNT(DISTINCT insured_id)
     FROM raw.motor_insurance_portfolio) AS raw_distinct_insured,

    (SELECT COUNT(DISTINCT insured_id)
     FROM staging.motor_insurance_portfolio) AS staging_distinct_insured;
GO


-- 3. Confirm documented NA values became SQL NULL
SELECT
    SUM(CASE WHEN vehicle_age IS NULL THEN 1 ELSE 0 END)
        AS null_vehicle_age,

    SUM(CASE WHEN age_driving_licence IS NULL THEN 1 ELSE 0 END)
        AS null_licence_age,

    SUM(CASE WHEN vehicle_value IS NULL THEN 1 ELSE 0 END)
        AS null_vehicle_value
FROM staging.motor_insurance_portfolio;
GO


-- 4. Confirm scientific-notation incurred value was preserved
SELECT
    insured_id,
    [year],
    total_incurred
FROM staging.motor_insurance_portfolio
WHERE insured_id = 38090
  AND [year] = 2023;
GO


-- 5. Check primary-key uniqueness in staging
SELECT
    insured_id,
    [year],
    COUNT(*) AS occurrence_count
FROM staging.motor_insurance_portfolio
GROUP BY insured_id, [year]
HAVING COUNT(*) > 1;
GO


/* ============================================================
   RECONCILIATION RESULT

   Raw records:              354,140
   Staging records:          354,140
   Row difference:           0

   Distinct insured IDs:     185,678 in both layers

   Data-quality corrections:
   - vehicle_age:            2 NA values converted to NULL
   - age_driving_licence:    2 NA values converted to NULL
   - vehicle_value:          513 NA values converted to NULL
   - total_incurred:         scientific-notation residual
                             converted to 0.0000

   Duplicate insured_id/year combinations: 0

   Conclusion:
   Raw-to-staging transformation successfully reconciled.
   No records were lost or duplicated.
   ============================================================ */