/* ============================================================
   03 - Data quality checks on dbo.raw_loans
   Result on the Kaggle file: no NULLs, no duplicates, all values in range.
   The only issues are logical inconsistencies, which are FLAGGED in the
   clean view (04) instead of deleted.
   ============================================================ */

USE LoanDefault;
GO

-- 1. Row count and duplicate IDs
SELECT COUNT(*)                         AS total_rows,
       COUNT(DISTINCT LoanID)           AS distinct_loan_ids,
       COUNT(*) - COUNT(DISTINCT LoanID) AS duplicate_ids
FROM dbo.raw_loans;

-- 2. NULL count per column
SELECT
    SUM(CASE WHEN LoanID IS NULL THEN 1 ELSE 0 END) AS LoanID,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS Age,
    SUM(CASE WHEN Income IS NULL THEN 1 ELSE 0 END) AS Income,
    SUM(CASE WHEN LoanAmount IS NULL THEN 1 ELSE 0 END) AS LoanAmount,
    SUM(CASE WHEN CreditScore IS NULL THEN 1 ELSE 0 END) AS CreditScore,
    SUM(CASE WHEN MonthsEmployed IS NULL THEN 1 ELSE 0 END) AS MonthsEmployed,
    SUM(CASE WHEN NumCreditLines IS NULL THEN 1 ELSE 0 END) AS NumCreditLines,
    SUM(CASE WHEN InterestRate IS NULL THEN 1 ELSE 0 END) AS InterestRate,
    SUM(CASE WHEN LoanTerm IS NULL THEN 1 ELSE 0 END) AS LoanTerm,
    SUM(CASE WHEN DTIRatio IS NULL THEN 1 ELSE 0 END) AS DTIRatio,
    SUM(CASE WHEN Education IS NULL THEN 1 ELSE 0 END) AS Education,
    SUM(CASE WHEN EmploymentType IS NULL THEN 1 ELSE 0 END) AS EmploymentType,
    SUM(CASE WHEN MaritalStatus IS NULL THEN 1 ELSE 0 END) AS MaritalStatus,
    SUM(CASE WHEN HasMortgage IS NULL THEN 1 ELSE 0 END) AS HasMortgage,
    SUM(CASE WHEN HasDependents IS NULL THEN 1 ELSE 0 END) AS HasDependents,
    SUM(CASE WHEN LoanPurpose IS NULL THEN 1 ELSE 0 END) AS LoanPurpose,
    SUM(CASE WHEN HasCoSigner IS NULL THEN 1 ELSE 0 END) AS HasCoSigner,
    SUM(CASE WHEN default_flag IS NULL THEN 1 ELSE 0 END) AS default_flag
FROM dbo.raw_loans;

-- 3. Range check on numeric columns
SELECT MIN(Age) AS min_age, MAX(Age) AS max_age,
       MIN(Income) AS min_income, MAX(Income) AS max_income,
       MIN(LoanAmount) AS min_loan, MAX(LoanAmount) AS max_loan,
       MIN(CreditScore) AS min_score, MAX(CreditScore) AS max_score,
       MIN(MonthsEmployed) AS min_months, MAX(MonthsEmployed) AS max_months,
       MIN(InterestRate) AS min_rate, MAX(InterestRate) AS max_rate,
       MIN(DTIRatio) AS min_dti, MAX(DTIRatio) AS max_dti
FROM dbo.raw_loans;

-- 4. Distinct values of the categorical columns (look for typos / extra spaces)
SELECT 'Education' AS col, Education AS value, COUNT(*) AS n FROM dbo.raw_loans GROUP BY Education
UNION ALL SELECT 'EmploymentType', EmploymentType, COUNT(*) FROM dbo.raw_loans GROUP BY EmploymentType
UNION ALL SELECT 'MaritalStatus', MaritalStatus, COUNT(*) FROM dbo.raw_loans GROUP BY MaritalStatus
UNION ALL SELECT 'LoanPurpose', LoanPurpose, COUNT(*) FROM dbo.raw_loans GROUP BY LoanPurpose
UNION ALL SELECT 'HasMortgage', HasMortgage, COUNT(*) FROM dbo.raw_loans GROUP BY HasMortgage
UNION ALL SELECT 'HasDependents', HasDependents, COUNT(*) FROM dbo.raw_loans GROUP BY HasDependents
UNION ALL SELECT 'HasCoSigner', HasCoSigner, COUNT(*) FROM dbo.raw_loans GROUP BY HasCoSigner
ORDER BY col, value;

-- 5. Target balance (expect about 88.4% non-default / 11.6% default)
SELECT default_flag, COUNT(*) AS loans,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM dbo.raw_loans
GROUP BY default_flag;

-- 6. Logical inconsistencies (flagged in the view, not deleted)
SELECT
    SUM(CASE WHEN MonthsEmployed > (Age - 18) * 12 THEN 1 ELSE 0 END)                     AS tenure_longer_than_working_life,
    SUM(CASE WHEN EmploymentType = 'Unemployed' AND MonthsEmployed > 0 THEN 1 ELSE 0 END)  AS unemployed_with_job_months,
    SUM(CASE WHEN Age <= 22 AND Education = 'PhD' THEN 1 ELSE 0 END)                      AS age_22_or_less_with_phd,
    SUM(CASE WHEN CAST(LoanAmount AS FLOAT) / Income > 5 THEN 1 ELSE 0 END)               AS loan_above_5x_income
FROM dbo.raw_loans;
GO
