/* ============================================================
   INSURANCE PORTFOLIO PERFORMANCE ANALYTICS
   SQL Data Pipeline
   Anthony Utulu Analytics
   ============================================================ */


/* ============================================================
   01. DATABASE SETUP
   ============================================================ */

CREATE DATABASE InsurancePortfolioAnalytics;
GO

USE InsurancePortfolioAnalytics;
GO


/* ============================================================
   02. SCHEMA CREATION
   ============================================================ */

CREATE SCHEMA raw;
GO

CREATE SCHEMA staging;
GO

CREATE SCHEMA analytics;
GO


/* ============================================================
   03. RAW TABLE CREATION
   ============================================================ */

CREATE TABLE raw.motor_insurance_portfolio
(
    -- all 47 columns here
);
GO


/* ============================================================
   04. RAW DATA IMPORT
   ============================================================ */

BULK INSERT raw.motor_insurance_portfolio
FROM 'C:\Files fromOneDrive\Actuarial Business Analysis\Insurance-Portfolio-Performance-Analytics\data\raw\Dataset of motor insurance portfolio.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);
GO


/* ============================================================
   05. DATA VALIDATION
   ============================================================ */

SELECT COUNT(*) AS RawRowCount
FROM raw.motor_insurance_portfolio;
GO
