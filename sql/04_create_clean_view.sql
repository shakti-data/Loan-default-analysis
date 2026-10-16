/* ============================================================
   04 - Clean analysis view: dbo.loan_clean
   - adds readable bands (numbered so they sort correctly in Power BI)
   - adds loan_to_income and 1/0 flags
   - flags inconsistent rows (no rows are deleted)
   - adds a simple 0-6 risk scorecard (no age / marital status used)
   ============================================================ */

USE LoanDefault;
GO

CREATE OR ALTER VIEW dbo.loan_clean AS
WITH base AS (
    SELECT
        LoanID, Age, Income, LoanAmount, CreditScore, MonthsEmployed, NumCreditLines,
        InterestRate, LoanTerm, DTIRatio, Education, EmploymentType, MaritalStatus,
        HasMortgage, HasDependents, LoanPurpose, HasCoSigner, default_flag,
        CAST(LoanAmount AS FLOAT) / Income AS lti            -- loan amount / yearly income
    FROM dbo.raw_loans
),
scored AS (
    SELECT b.*,
        CASE WHEN Income < 40000                THEN 1 ELSE 0 END AS rf_low_income,
        CASE WHEN lti >= 3                      THEN 1 ELSE 0 END AS rf_high_lti,
        CASE WHEN MonthsEmployed < 36           THEN 1 ELSE 0 END AS rf_short_tenure,
        CASE WHEN HasCoSigner = 'No'            THEN 1 ELSE 0 END AS rf_no_cosigner,
        CASE WHEN EmploymentType = 'Unemployed' THEN 1 ELSE 0 END AS rf_unemployed,
        CASE WHEN CreditScore < 580             THEN 1 ELSE 0 END AS rf_poor_credit
    FROM base b
)
SELECT
    LoanID,
    Age,
    CASE WHEN Age < 25 THEN '18-24' WHEN Age < 35 THEN '25-34' WHEN Age < 45 THEN '35-44'
         WHEN Age < 55 THEN '45-54' WHEN Age < 65 THEN '55-64' ELSE '65+' END AS age_band,
    Income,
    CASE WHEN Income < 40000 THEN '1. <40k' WHEN Income < 70000 THEN '2. 40k-70k'
         WHEN Income < 100000 THEN '3. 70k-100k' ELSE '4. 100k+' END AS income_band,
    LoanAmount,
    CASE WHEN LoanAmount < 50000 THEN '1. <50k' WHEN LoanAmount < 100000 THEN '2. 50k-100k'
         WHEN LoanAmount < 150000 THEN '3. 100k-150k' WHEN LoanAmount < 200000 THEN '4. 150k-200k'
         ELSE '5. 200k+' END AS loan_amount_band,
    ROUND(lti, 2) AS loan_to_income,
    CASE WHEN lti < 1 THEN '1. <1x' WHEN lti < 2 THEN '2. 1x-2x' WHEN lti < 3 THEN '3. 2x-3x'
         WHEN lti < 5 THEN '4. 3x-5x' ELSE '5. 5x+' END AS lti_band,
    CreditScore,
    CASE WHEN CreditScore < 580 THEN '1. Poor (<580)' WHEN CreditScore < 670 THEN '2. Fair (580-669)'
         WHEN CreditScore < 740 THEN '3. Good (670-739)' ELSE '4. Very good (740+)' END AS credit_band,
    MonthsEmployed,
    CASE WHEN MonthsEmployed < 12 THEN '1. <1 yr' WHEN MonthsEmployed < 36 THEN '2. 1-3 yrs'
         WHEN MonthsEmployed < 60 THEN '3. 3-5 yrs' ELSE '4. 5+ yrs' END AS tenure_band,
    NumCreditLines,
    InterestRate,
    CASE WHEN InterestRate < 8 THEN '1. <8%' WHEN InterestRate < 14 THEN '2. 8-14%'
         WHEN InterestRate < 20 THEN '3. 14-20%' ELSE '4. 20%+' END AS interest_band,
    LoanTerm,
    DTIRatio,
    CASE WHEN DTIRatio < 0.2 THEN '1. Low (<0.2)' WHEN DTIRatio < 0.4 THEN '2. Medium (0.2-0.39)'
         WHEN DTIRatio < 0.6 THEN '3. High (0.4-0.59)' ELSE '4. Very high (0.6+)' END AS dti_band,
    Education,
    EmploymentType,
    MaritalStatus,
    LoanPurpose,
    HasMortgage,
    HasDependents,
    HasCoSigner,
    CASE WHEN HasMortgage   = 'Yes' THEN 1 ELSE 0 END AS mortgage_flag,
    CASE WHEN HasDependents = 'Yes' THEN 1 ELSE 0 END AS dependents_flag,
    CASE WHEN HasCoSigner   = 'Yes' THEN 1 ELSE 0 END AS cosigner_flag,
    -- data quality flags (rows are kept, just marked)
    CASE WHEN MonthsEmployed > (Age - 18) * 12 THEN 1 ELSE 0 END AS tenure_flag,
    CASE WHEN lti > 5 THEN 1 ELSE 0 END AS high_lti_flag,
    -- risk scorecard: 1 point per risk factor
    rf_low_income, rf_high_lti, rf_short_tenure, rf_no_cosigner, rf_unemployed, rf_poor_credit,
    (rf_low_income + rf_high_lti + rf_short_tenure + rf_no_cosigner + rf_unemployed + rf_poor_credit) AS risk_points,
    CASE WHEN (rf_low_income + rf_high_lti + rf_short_tenure + rf_no_cosigner + rf_unemployed + rf_poor_credit) <= 1 THEN '1. Low (0-1)'
         WHEN (rf_low_income + rf_high_lti + rf_short_tenure + rf_no_cosigner + rf_unemployed + rf_poor_credit) <= 3 THEN '2. Medium (2-3)'
         ELSE '3. High (4-6)' END AS risk_band,
    default_flag
FROM scored;
GO
