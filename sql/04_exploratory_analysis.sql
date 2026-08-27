USE InsurancePortfolioAnalytics;
GO

/* ============================================================
04. EXPLORATORY PORTFOLIO ANALYSIS

Purpose:
Explore the structure, growth and performance of the motor
insurance portfolio after data cleaning and reconciliation.

Key areas:
- Portfolio size and growth
- Policy mix
- Premium development
- Claims experience
- Exposure
- Claims frequency and severity
- Loss ratios
- Risk segmentation

Source:
staging.motor_insurance_portfolio

Finalised for portfolio repository: 2026
============================================================ */

/* ============================================================
01. PORTFOLIO OVERVIEW BY YEAR
============================================================ */

SELECT
    [year],
    COUNT(*) AS policy_records,
    COUNT(DISTINCT insured_id) AS distinct_insureds,

    SUM(TRY_CONVERT(decimal(18,4), total_exposure))
        AS total_exposure,

    SUM(TRY_CONVERT(decimal(18,4), total_premium))
        AS total_premium,

    SUM(TRY_CONVERT(decimal(18,4), total_claims))
        AS total_claims,

    SUM(TRY_CONVERT(decimal(18,4), total_incurred))
        AS total_incurred

FROM staging.motor_insurance_portfolio

GROUP BY [year]

ORDER BY [year];
GO

/* ------------------------------------------------------------
SECTION 1 FINDING

The motor insurance portfolio expanded substantially between
2022 and 2024.

Policy records increased from 67,172 in 2022 to 168,133 in 2024,
while total premium increased from approximately £18.70m to
£51.04m.

Claims and incurred losses also increased materially over the
same period. Further analysis is therefore required to determine
whether portfolio growth has been accompanied by deterioration
or improvement in underwriting performance.
------------------------------------------------------------ */

/* ============================================================
02. YEAR-ON-YEAR PORTFOLIO GROWTH

Purpose:
Measure annual growth in policy volume, premium and incurred
claims costs.
============================================================ */

WITH yearly_summary AS
(
    SELECT
        [year],
        COUNT(*) AS policy_records,

        SUM(TRY_CONVERT(decimal(18,4), total_premium))
            AS total_premium,

        SUM(TRY_CONVERT(decimal(18,4), total_incurred))
            AS total_incurred

    FROM staging.motor_insurance_portfolio
    GROUP BY [year]
),

growth_analysis AS
(
    SELECT
        [year],
        policy_records,
        total_premium,
        total_incurred,

        LAG(policy_records) OVER (ORDER BY [year])
            AS previous_policy_records,

        LAG(total_premium) OVER (ORDER BY [year])
            AS previous_premium,

        LAG(total_incurred) OVER (ORDER BY [year])
            AS previous_incurred

    FROM yearly_summary
)

SELECT
    [year],
    policy_records,
    total_premium,
    total_incurred,

    ROUND(
        100.0 * (policy_records - previous_policy_records)
        / NULLIF(previous_policy_records, 0), 2
    ) AS policy_growth_pct,

    ROUND(
        100.0 * (total_premium - previous_premium)
        / NULLIF(previous_premium, 0), 2
    ) AS premium_growth_pct,

    ROUND(
        100.0 * (total_incurred - previous_incurred)
        / NULLIF(previous_incurred, 0), 2
    ) AS incurred_growth_pct

FROM growth_analysis
ORDER BY [year];
GO

/* ------------------------------------------------------------
SECTION 2 FINDING

The portfolio experienced strong year-on-year growth.

In 2023:
- Policy volume increased by 76.91%
- Premium increased by 89.03%
- Incurred losses increased by 91.43%

In 2024:
- Policy volume increased by 41.48%
- Premium increased by 44.40%
- Incurred losses increased by 62.24%

Although portfolio growth remained strong, incurred losses grew
considerably faster than premium in 2024. This may indicate
deteriorating claims experience and requires further investigation
through frequency, severity and loss-ratio analysis.
------------------------------------------------------------ */

/* ============================================================
03. CORE ACTUARIAL PERFORMANCE METRICS

Purpose:
Evaluate pricing adequacy and claims performance using exposure,
premium, claim frequency, severity and loss ratio.
============================================================ */

SELECT
    [year],

    ROUND(
        SUM(TRY_CONVERT(decimal(18,4), total_premium))
        / NULLIF(SUM(TRY_CONVERT(decimal(18,4), total_exposure)), 0),
        2
    ) AS premium_per_exposure,

    ROUND(
        SUM(TRY_CONVERT(decimal(18,4), total_claims))
        / NULLIF(SUM(TRY_CONVERT(decimal(18,4), total_exposure)), 0),
        4
    ) AS claim_frequency,

    ROUND(
        SUM(TRY_CONVERT(decimal(18,4), total_incurred))
        / NULLIF(SUM(TRY_CONVERT(decimal(18,4), total_claims)), 0),
        2
    ) AS claim_severity,

    ROUND(
        100.0 *
        SUM(TRY_CONVERT(decimal(18,4), total_incurred))
        / NULLIF(SUM(TRY_CONVERT(decimal(18,4), total_premium)), 0),
        2
    ) AS loss_ratio_pct

FROM staging.motor_insurance_portfolio

GROUP BY [year]

ORDER BY [year];
GO

/* ------------------------------------------------------------
SECTION 3 FINDING

Core actuarial performance metrics indicate a deterioration in
portfolio underwriting performance over the three-year period.

Premium per unit of exposure declined from 446.12 in 2022 to
405.01 in 2024.

At the same time:
- Claim frequency increased from 0.3022 to 0.3117.
- Claim severity increased to 970.22 in 2024.
- The loss ratio deteriorated from 65.62% in 2022 to 74.66%
  in 2024.

The deterioration appears to reflect both weakening premium
adequacy and worsening claims experience.

The 2024 portfolio therefore warrants deeper segmentation
analysis to identify which parts of the book are driving the
increase in loss ratio.
------------------------------------------------------------ */

/* ============================================================
04. PORTFOLIO PERFORMANCE BY POLICY TYPE

Purpose:
Identify differences in premium adequacy and claims performance
across major policy types.
============================================================ */

SELECT
    [year],
    policy_type,

    COUNT(*) AS policy_records,

    ROUND(
        SUM(total_exposure), 2
    ) AS total_exposure,

    ROUND(
        SUM(total_premium), 2
    ) AS total_premium,

    SUM(total_claims) AS total_claims,

    ROUND(
        SUM(total_incurred), 2
    ) AS total_incurred,

    ROUND(
        SUM(total_claims)
        / NULLIF(SUM(total_exposure), 0),
        4
    ) AS claim_frequency,

    ROUND(
        SUM(total_incurred)
        / NULLIF(SUM(total_claims), 0),
        2
    ) AS claim_severity,

    ROUND(
        100.0 * SUM(total_incurred)
        / NULLIF(SUM(total_premium), 0),
        2
    ) AS loss_ratio_pct

FROM staging.motor_insurance_portfolio

GROUP BY
    [year],
    policy_type

ORDER BY
    [year],
    loss_ratio_pct DESC;
GO

/* ------------------------------------------------------------
SECTION 4 FINDING

Policy-type segmentation reveals significant differences in
underwriting performance.

COMP_N is the most concerning segment. Its loss ratio increased
from 72.79% in 2022 to 92.30% in 2023 and 102.37% in 2024.
In 2024, incurred claims therefore exceeded premium income for
this segment before allowing for expenses.

COMP_N also recorded the highest claim frequency at 1.1670
claims per unit of exposure in 2024.

Other notable deterioration:
- COMP_E: 65.99% (2022) to 78.78% (2024)
- TPG:    59.40% (2022) to 75.38% (2024)

CC, the largest policy segment, remained comparatively stable,
with a 2024 loss ratio of 65.77%.

The results suggest that the deterioration in overall portfolio
performance is concentrated disproportionately within specific
policy types, particularly COMP_N, with COMP_E and TPG also
requiring further investigation.
------------------------------------------------------------ */


/* ============================================================
05. PORTFOLIO PERFORMANCE BY BUSINESS TYPE

Purpose:
Assess whether underwriting performance differs by business
type and determine whether particular business segments are
contributing disproportionately to portfolio deterioration.
============================================================ */

SELECT
    [year],
    business_type,

    COUNT(*) AS policy_records,

    ROUND(SUM(total_exposure), 2) AS total_exposure,

    ROUND(SUM(total_premium), 2) AS total_premium,

    SUM(total_claims) AS total_claims,

    ROUND(SUM(total_incurred), 2) AS total_incurred,

    ROUND(
        SUM(total_premium)
        / NULLIF(SUM(total_exposure), 0),
        2
    ) AS premium_per_exposure,

    ROUND(
        SUM(total_claims)
        / NULLIF(SUM(total_exposure), 0),
        4
    ) AS claim_frequency,

    ROUND(
        SUM(total_incurred)
        / NULLIF(SUM(total_claims), 0),
        2
    ) AS claim_severity,

    ROUND(
        100.0 * SUM(total_incurred)
        / NULLIF(SUM(total_premium), 0),
        2
    ) AS loss_ratio_pct

FROM staging.motor_insurance_portfolio

GROUP BY
    [year],
    business_type

ORDER BY
    [year],
    loss_ratio_pct DESC;
GO

/* ------------------------------------------------------------
SECTION 5 FINDING

Business-type analysis shows different risk dynamics across the
portfolio.

In 2024, NB recorded the higher loss ratio at 76.78%, compared
with 72.84% for P.

NB did not have the higher claim frequency. Its 2024 frequency
was 0.2931 compared with 0.3289 for P. However, NB recorded
higher claim severity (1,018.47) and substantially lower premium
per exposure (388.85 versus 420.04).

This suggests that the weaker 2024 NB result is associated more
with premium adequacy and claim severity than claim frequency.

The portfolio mix also changed materially, with P increasing
from 1,407 policy records in 2022 to 71,731 in 2024.

Further interaction analysis is required to determine how
business type combines with the poorly performing policy types.
------------------------------------------------------------ */


/* ============================================================
06. POLICY TYPE × BUSINESS TYPE INTERACTION — 2024

Purpose:
Identify whether poor-performing policy types are concentrated
within particular business types and isolate segments driving
the 2024 deterioration.
============================================================ */

SELECT
    policy_type,
    business_type,

    COUNT(*) AS policy_records,

    ROUND(SUM(total_exposure), 2) AS total_exposure,

    ROUND(SUM(total_premium), 2) AS total_premium,

    SUM(total_claims) AS total_claims,

    ROUND(SUM(total_incurred), 2) AS total_incurred,

    ROUND(
        SUM(total_premium)
        / NULLIF(SUM(total_exposure), 0),
        2
    ) AS premium_per_exposure,

    ROUND(
        SUM(total_claims)
        / NULLIF(SUM(total_exposure), 0),
        4
    ) AS claim_frequency,

    ROUND(
        SUM(total_incurred)
        / NULLIF(SUM(total_claims), 0),
        2
    ) AS claim_severity,

    ROUND(
        100.0 * SUM(total_incurred)
        / NULLIF(SUM(total_premium), 0),
        2
    ) AS loss_ratio_pct

FROM staging.motor_insurance_portfolio

WHERE [year] = 2024

GROUP BY
    policy_type,
    business_type

ORDER BY
    loss_ratio_pct DESC;
GO

/* ------------------------------------------------------------
SECTION 6 FINDING

The 2024 policy-type/business-type interaction identifies COMP_N
as the portfolio's principal underwriting concern.

COMP_N + P recorded the highest loss ratio at 105.85%, meaning
incurred claims exceeded earned premium before allowing for
expenses. COMP_N + NB was also weak at 97.11%.

The primary driver appears to be claim frequency rather than
claim severity. Claim frequency reached 1.2495 for COMP_N + P
and 1.0476 for COMP_N + NB, substantially above the other
policy-type/business-type segments.

COMP_E also shows elevated loss ratios of 80.49% for NB and
77.27% for P, but with lower claim frequency and higher claim
severity, indicating a different risk dynamic.

The results suggest that portfolio deterioration is not uniform.
COMP_N requires particular investigation of claim frequency,
pricing adequacy and underlying risk characteristics.
------------------------------------------------------------ */


/* ============================================================
07. COMP_N DRIVER AGE ANALYSIS — 2024

Purpose:
Investigate whether the exceptionally high COMP_N claim
frequency is concentrated within particular driver age groups.
============================================================ */

SELECT
    CASE
        WHEN driver_age < 25 THEN 'Under 25'
        WHEN driver_age BETWEEN 25 AND 34 THEN '25-34'
        WHEN driver_age BETWEEN 35 AND 44 THEN '35-44'
        WHEN driver_age BETWEEN 45 AND 54 THEN '45-54'
        WHEN driver_age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS driver_age_band,

    COUNT(*) AS policy_records,

    ROUND(SUM(total_exposure), 2) AS total_exposure,

    ROUND(SUM(total_premium), 2) AS total_premium,

    SUM(total_claims) AS total_claims,

    ROUND(SUM(total_incurred), 2) AS total_incurred,

    ROUND(
        SUM(total_premium) /
        NULLIF(SUM(total_exposure), 0),
        2
    ) AS premium_per_exposure,

    ROUND(
        SUM(total_claims) /
        NULLIF(SUM(total_exposure), 0),
        4
    ) AS claim_frequency,

    ROUND(
        SUM(total_incurred) /
        NULLIF(SUM(total_claims), 0),
        2
    ) AS claim_severity,

    ROUND(
        100.0 * SUM(total_incurred) /
        NULLIF(SUM(total_premium), 0),
        2
    ) AS loss_ratio_pct

FROM staging.motor_insurance_portfolio

WHERE [year] = 2024
  AND policy_type = 'COMP_N'

GROUP BY
    CASE
        WHEN driver_age < 25 THEN 'Under 25'
        WHEN driver_age BETWEEN 25 AND 34 THEN '25-34'
        WHEN driver_age BETWEEN 35 AND 44 THEN '35-44'
        WHEN driver_age BETWEEN 45 AND 54 THEN '45-54'
        WHEN driver_age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END

ORDER BY loss_ratio_pct DESC;
GO

/* ------------------------------------------------------------
SECTION 7 FINDING

COMP_N's poor 2024 performance is not concentrated within a
single driver age group.

Claim frequency exceeded 1.14 across all age bands, indicating
that the elevated frequency observed for COMP_N is broadly
distributed across the portfolio.

The 25-34 segment recorded a 117.05% loss ratio with claim
frequency of 1.2401, while the 35-44 segment recorded a 107.75%
loss ratio across 2,129 policy records, making it a significant
contributor to overall COMP_N performance.

The Under-25 segment produced the highest loss ratio at 117.69%,
but contains only six policy records and is therefore too small
to support a reliable underwriting conclusion.

Overall, driver age alone does not appear to explain the high
COMP_N claim frequency. Further segmentation is required to
identify the underlying risk drivers.
------------------------------------------------------------ */


/* ============================================================
08. COMP_N VEHICLE AGE ANALYSIS — 2024

Purpose:
Investigate whether COMP_N's elevated claim frequency and loss
ratio are concentrated among vehicles of particular ages.
============================================================ */

SELECT
    CASE
        WHEN vehicle_age IS NULL THEN 'Unknown'
        WHEN vehicle_age <= 2 THEN '0-2 years'
        WHEN vehicle_age BETWEEN 3 AND 5 THEN '3-5 years'
        WHEN vehicle_age BETWEEN 6 AND 10 THEN '6-10 years'
        WHEN vehicle_age BETWEEN 11 AND 15 THEN '11-15 years'
        ELSE '16+ years'
    END AS vehicle_age_band,

    COUNT(*) AS policy_records,

    ROUND(SUM(total_exposure), 2) AS total_exposure,

    ROUND(SUM(total_premium), 2) AS total_premium,

    SUM(total_claims) AS total_claims,

    ROUND(SUM(total_incurred), 2) AS total_incurred,

    ROUND(
        SUM(total_premium) /
        NULLIF(SUM(total_exposure), 0),
        2
    ) AS premium_per_exposure,

    ROUND(
        SUM(total_claims) /
        NULLIF(SUM(total_exposure), 0),
        4
    ) AS claim_frequency,

    ROUND(
        SUM(total_incurred) /
        NULLIF(SUM(total_claims), 0),
        2
    ) AS claim_severity,

    ROUND(
        100.0 * SUM(total_incurred) /
        NULLIF(SUM(total_premium), 0),
        2
    ) AS loss_ratio_pct

FROM staging.motor_insurance_portfolio

WHERE [year] = 2024
  AND policy_type = 'COMP_N'

GROUP BY
    CASE
        WHEN vehicle_age IS NULL THEN 'Unknown'
        WHEN vehicle_age <= 2 THEN '0-2 years'
        WHEN vehicle_age BETWEEN 3 AND 5 THEN '3-5 years'
        WHEN vehicle_age BETWEEN 6 AND 10 THEN '6-10 years'
        WHEN vehicle_age BETWEEN 11 AND 15 THEN '11-15 years'
        ELSE '16+ years'
    END

ORDER BY loss_ratio_pct DESC;
GO

/* ------------------------------------------------------------
SECTION 8 FINDING

Vehicle age provides a stronger indication of COMP_N risk
deterioration than driver age.

Vehicles aged 11-15 years recorded a 132.94% loss ratio and
claim frequency of 1.2754 across 779 policy records, identifying
this as a material high-risk segment.

Vehicles aged 6-10 years also recorded a loss ratio above 100%
at 113.16%.

The 0-2 year category produced an exceptionally high 264.24%
loss ratio, but contains only 15 policy records and is therefore
too small to support a reliable portfolio-level conclusion.

Vehicles aged 16+ represent the majority of COMP_N exposure,
with 5,725 policy records and a 97.61% loss ratio. Although this
segment remains below a 100% claims loss ratio, its performance
indicates limited margin before operating expenses.

Overall, vehicle age appears to provide greater explanatory
value for COMP_N deterioration than driver age, particularly
within the 11-15 year vehicle segment.
------------------------------------------------------------ */


/* ============================================================
09. COMP_N VEHICLE AGE × BUSINESS TYPE — 2024

Purpose:
Determine whether the poor-performing COMP_N vehicle-age
segments are concentrated within particular business types.
============================================================ */

SELECT
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

    ROUND(SUM(total_exposure), 2) AS total_exposure,

    ROUND(SUM(total_premium), 2) AS total_premium,

    SUM(total_claims) AS total_claims,

    ROUND(SUM(total_incurred), 2) AS total_incurred,

    ROUND(
        SUM(total_premium) /
        NULLIF(SUM(total_exposure), 0),
        2
    ) AS premium_per_exposure,

    ROUND(
        SUM(total_claims) /
        NULLIF(SUM(total_exposure), 0),
        4
    ) AS claim_frequency,

    ROUND(
        SUM(total_incurred) /
        NULLIF(SUM(total_claims), 0),
        2
    ) AS claim_severity,

    ROUND(
        100.0 * SUM(total_incurred) /
        NULLIF(SUM(total_premium), 0),
        2
    ) AS loss_ratio_pct

FROM staging.motor_insurance_portfolio

WHERE [year] = 2024
  AND policy_type = 'COMP_N'

GROUP BY
    CASE
        WHEN vehicle_age IS NULL THEN 'Unknown'
        WHEN vehicle_age <= 2 THEN '0-2 years'
        WHEN vehicle_age BETWEEN 3 AND 5 THEN '3-5 years'
        WHEN vehicle_age BETWEEN 6 AND 10 THEN '6-10 years'
        WHEN vehicle_age BETWEEN 11 AND 15 THEN '11-15 years'
        ELSE '16+ years'
    END,
    business_type

ORDER BY loss_ratio_pct DESC;
GO

/* ------------------------------------------------------------
SECTION 9 FINDING

The interaction between vehicle age and business type provides
further evidence that COMP_N deterioration is concentrated in
specific risk segments.

The 11-15 year P segment recorded a 141.90% loss ratio and
claim frequency of 1.2951 across 431 policy records. The
corresponding NB segment also performed poorly, with a 119.50%
loss ratio and claim frequency of 1.2481.

The largest commercially significant concern is the 16+ year P
segment. Across 3,189 policy records, it recorded claim
frequency of 1.2452 and a loss ratio of 102.62%, compared with
89.90% for 16+ year NB business.

Although the 0-2 year NB segment recorded an extreme 482.72%
loss ratio, it contains only eight policy records and should not
be used independently to support portfolio-level conclusions.

Overall, the analysis indicates that COMP_N deterioration is
associated with both vehicle age and business type, with P
business showing particularly weak performance in the larger
older-vehicle segments.
------------------------------------------------------------ */


/* ============================================================
10. EXECUTIVE ANALYTICAL FINDINGS AND UNDERWRITING RECOMMENDATIONS

Purpose:
Summarise the principal portfolio findings identified during
the exploratory analysis and translate them into commercially
relevant underwriting and portfolio-management recommendations.
============================================================ */


/* ------------------------------------------------------------
10.1 PORTFOLIO PERFORMANCE

The motor insurance portfolio expanded substantially between
2022 and 2024.

Policy records increased from 67,172 in 2022 to 168,133 in
2024, while total premium increased from approximately £18.70m
to £51.04m.

However, underwriting performance deteriorated during this
growth period. The portfolio loss ratio increased from 65.62%
in 2022 to 66.46% in 2023 and 74.66% in 2024.

Claim frequency also increased from 0.3022 in 2022 to 0.3117
in 2024, while premium per exposure declined from £446.12 to
£405.01.

This combination indicates that portfolio growth was accompanied
by increasing claims pressure and weakening premium adequacy.
------------------------------------------------------------ */


/* ------------------------------------------------------------
10.2 PRINCIPAL UNDERWRITING CONCERN — COMP_N

COMP_N emerged as the weakest-performing policy type in 2024.

The segment recorded a loss ratio of 102.37%, meaning incurred
claims exceeded premium before allowing for operating expenses.

The primary driver of deterioration appears to be claim
frequency rather than unusually high claim severity.

Further segmentation showed that both P and NB COMP_N business
performed poorly, with P business recording the weaker overall
result.
------------------------------------------------------------ */


/* ------------------------------------------------------------
10.3 RISK-SEGMENT FINDINGS

Driver age did not provide a sufficient standalone explanation
for COMP_N deterioration because elevated claim frequency was
observed across multiple age groups.

Vehicle age provided stronger segmentation.

Vehicles aged 11-15 years within COMP_N recorded a 132.94%
loss ratio, while vehicles aged 6-10 years recorded 113.16%.

Further interaction analysis identified particularly weak
performance within:

- COMP_N / 11-15 year / P:
  141.90% loss ratio and 1.2951 claim frequency.

- COMP_N / 11-15 year / NB:
  119.50% loss ratio and 1.2481 claim frequency.

- COMP_N / 16+ year / P:
  102.62% loss ratio across 3,189 policy records.

The 16+ year P segment is particularly important because of its
material portfolio size.

Extreme results observed within very small segments should be
treated cautiously and should not independently drive pricing
or underwriting decisions.
------------------------------------------------------------ */


/* ------------------------------------------------------------
10.4 UNDERWRITING AND PORTFOLIO RECOMMENDATIONS

Based on the exploratory analysis, the following actions are
recommended:

1. Review COMP_N pricing adequacy, particularly where current
   premium levels may not sufficiently reflect observed claim
   frequency.

2. Investigate the underwriting and risk-selection characteristics
   of COMP_N P business, with particular attention to vehicles
   aged 11 years and above.

3. Review renewal and new-business performance separately within
   COMP_N to determine whether portfolio deterioration reflects
   differences in risk selection, pricing or portfolio mix.

4. Introduce regular monitoring of claim frequency, claim
   severity and loss ratio by policy type, business type and
   vehicle-age segment.

5. Avoid making pricing decisions from very small segments
   without additional credibility analysis or supporting data.

6. Conduct further actuarial modelling before implementing
   pricing changes, controlling simultaneously for relevant
   rating factors and exposure differences.
------------------------------------------------------------ */


/* ------------------------------------------------------------
10.5 MANAGEMENT CONCLUSION

The analysis indicates that the portfolio's rapid growth has
been accompanied by deterioration in underwriting performance.

The deterioration is not uniform across the portfolio.
COMP_N represents the clearest area of concern, with elevated
claim frequency driving weak loss-ratio performance.

Vehicle age and business type provide useful segmentation of
this risk, particularly within older-vehicle P business.

Management attention should therefore focus on pricing adequacy,
risk selection and portfolio monitoring within COMP_N while
protecting better-performing segments from unnecessary
portfolio-wide corrective action.

The exploratory analysis identifies where further actuarial
investigation should be concentrated; it does not by itself
establish causal relationships or prescribe final pricing
changes.
------------------------------------------------------------ */


/* ============================================================
END OF EXPLORATORY PORTFOLIO ANALYSIS
============================================================ */
