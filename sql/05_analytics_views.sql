USE InsurancePortfolioAnalytics;
GO

/* ============================================================
05. ANALYTICS VIEWS FOR POWER BI

Purpose:
Create business-ready SQL views containing the core portfolio
KPIs and underwriting insights identified during exploratory
analysis.

These views will serve as the analytical source layer for
Power BI reporting and management decision support.

Layer: ANALYTICS
============================================================ */


/* ============================================================
01. YEARLY PORTFOLIO SUMMARY VIEW
============================================================ */

CREATE VIEW analytics.vw_portfolio_yearly_summary
AS

SELECT
    [year],

    COUNT(*) AS policy_records,

    COUNT(DISTINCT insured_id) AS distinct_insureds,

    SUM(total_exposure) AS total_exposure,

    SUM(total_premium) AS total_premium,

    SUM(total_claims) AS total_claims,

    SUM(total_incurred) AS total_incurred,

    SUM(total_premium)
        / NULLIF(SUM(total_exposure), 0)
        AS premium_per_exposure,

    SUM(total_claims)
        / NULLIF(SUM(total_exposure), 0)
        AS claim_frequency,

    SUM(total_incurred)
        / NULLIF(SUM(total_claims), 0)
        AS claim_severity,

    100.0 * SUM(total_incurred)
        / NULLIF(SUM(total_premium), 0)
        AS loss_ratio_pct

FROM staging.motor_insurance_portfolio

GROUP BY [year];
GO

/* ============================================================
02. POLICY TYPE PERFORMANCE VIEW

Purpose:
Provide annual underwriting performance metrics by policy type
for portfolio segmentation and Power BI reporting.
============================================================ */

CREATE VIEW analytics.vw_policy_type_performance
AS

SELECT
    [year],
    policy_type,

    COUNT(*) AS policy_records,

    SUM(total_exposure) AS total_exposure,

    SUM(total_premium) AS total_premium,

    SUM(total_claims) AS total_claims,

    SUM(total_incurred) AS total_incurred,

    SUM(total_premium)
        / NULLIF(SUM(total_exposure), 0)
        AS premium_per_exposure,

    SUM(total_claims)
        / NULLIF(SUM(total_exposure), 0)
        AS claim_frequency,

    SUM(total_incurred)
        / NULLIF(SUM(total_claims), 0)
        AS claim_severity,

    100.0 * SUM(total_incurred)
        / NULLIF(SUM(total_premium), 0)
        AS loss_ratio_pct

FROM staging.motor_insurance_portfolio

GROUP BY
    [year],
    policy_type;
GO


/* ============================================================
03. COMP_N RISK SEGMENT VIEW

Purpose:
Provide detailed 2024 risk segmentation for COMP_N by vehicle
age and business type, supporting investigation of the
portfolio's principal underwriting concern.
============================================================ */

CREATE VIEW analytics.vw_compn_risk_segments
AS

SELECT
    [year],

    CASE
        WHEN vehicle_age IS NULL THEN 'Unknown'
        WHEN vehicle_age <= 2 THEN '0-2 years'
        WHEN vehicle_age BETWEEN 3 AND 5 THEN '3-5 years'
        WHEN vehicle_age BETWEEN 6 AND 10 THEN '6-10 years'
        WHEN vehicle_age BETWEEN 11 AND 15 THEN '11-15 years'
        ELSE '16+ years'
    END AS vehicle_age_band,

    business_type,

    COUNT(*) AS policy_records,

    SUM(total_exposure) AS total_exposure,

    SUM(total_premium) AS total_premium,

    SUM(total_claims) AS total_claims,

    SUM(total_incurred) AS total_incurred,

    SUM(total_premium)
        / NULLIF(SUM(total_exposure), 0)
        AS premium_per_exposure,

    SUM(total_claims)
        / NULLIF(SUM(total_exposure), 0)
        AS claim_frequency,

    SUM(total_incurred)
        / NULLIF(SUM(total_claims), 0)
        AS claim_severity,

    100.0 * SUM(total_incurred)
        / NULLIF(SUM(total_premium), 0)
        AS loss_ratio_pct

FROM staging.motor_insurance_portfolio

WHERE policy_type = 'COMP_N'

GROUP BY
    [year],

    CASE
        WHEN vehicle_age IS NULL THEN 'Unknown'
        WHEN vehicle_age <= 2 THEN '0-2 years'
        WHEN vehicle_age BETWEEN 3 AND 5 THEN '3-5 years'
        WHEN vehicle_age BETWEEN 6 AND 10 THEN '6-10 years'
        WHEN vehicle_age BETWEEN 11 AND 15 THEN '11-15 years'
        ELSE '16+ years'
    END,

    business_type;
GO


/* ============================================================
VALIDATION QUERIES
Run after view creation to confirm expected outputs.
============================================================ */

SELECT *
FROM analytics.vw_portfolio_yearly_summary
ORDER BY [year];

SELECT *
FROM analytics.vw_policy_type_performance
ORDER BY [year], loss_ratio_pct DESC;

SELECT *
FROM analytics.vw_compn_risk_segments
WHERE [year] = 2024
ORDER BY loss_ratio_pct DESC;

/* ============================================================
ANALYTICS LAYER VALIDATION

The analytics layer was successfully created and validated.

Views created:
1. analytics.vw_portfolio_yearly_summary
2. analytics.vw_policy_type_performance
3. analytics.vw_compn_risk_segments

The views reproduce the validated portfolio KPIs and underwriting
findings established during exploratory analysis.

These views are now ready to serve as the trusted SQL source
for Power BI reporting and management decision support.
============================================================ */
