/* ============================================================
   05 - dbo.segment_summary
   One row per (dimension, segment): loans, defaults, default rate,
   risk lift (segment rate / overall rate) and share of all defaults.
   Used by the analysis queries in 06.
   ============================================================ */

USE LoanDefault;
GO

CREATE OR ALTER VIEW dbo.segment_summary AS
WITH seg AS (
    SELECT 'Age band' AS dimension, age_band AS segment, COUNT(*) AS loans, SUM(default_flag) AS defaults
    FROM dbo.loan_clean GROUP BY age_band
    UNION ALL
    SELECT 'Income band', income_band, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY income_band
    UNION ALL
    SELECT 'Loan amount band', loan_amount_band, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY loan_amount_band
    UNION ALL
    SELECT 'Loan-to-income band', lti_band, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY lti_band
    UNION ALL
    SELECT 'Credit score band', credit_band, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY credit_band
    UNION ALL
    SELECT 'Job tenure band', tenure_band, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY tenure_band
    UNION ALL
    SELECT 'Interest rate band', interest_band, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY interest_band
    UNION ALL
    SELECT 'DTI band', dti_band, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY dti_band
    UNION ALL
    SELECT 'Employment type', EmploymentType, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY EmploymentType
    UNION ALL
    SELECT 'Loan purpose', LoanPurpose, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY LoanPurpose
    UNION ALL
    SELECT 'Education', Education, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY Education
    UNION ALL
    SELECT 'Marital status', MaritalStatus, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY MaritalStatus
    UNION ALL
    SELECT 'Has co-signer', HasCoSigner, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY HasCoSigner
    UNION ALL
    SELECT 'Has mortgage', HasMortgage, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY HasMortgage
    UNION ALL
    SELECT 'Has dependents', HasDependents, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY HasDependents
    UNION ALL
    SELECT 'Loan term (months)', CAST(LoanTerm AS VARCHAR(20)), COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY CAST(LoanTerm AS VARCHAR(20))
    UNION ALL
    SELECT 'Open credit lines', CAST(NumCreditLines AS VARCHAR(20)), COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY CAST(NumCreditLines AS VARCHAR(20))
    UNION ALL
    SELECT 'Risk band', risk_band, COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY risk_band
    UNION ALL
    SELECT 'Risk points', CAST(risk_points AS VARCHAR(20)), COUNT(*), SUM(default_flag)
    FROM dbo.loan_clean GROUP BY CAST(risk_points AS VARCHAR(20))
),
overall AS (
    SELECT COUNT(*) AS total_loans,
           SUM(default_flag) AS total_defaults,
           1.0 * SUM(default_flag) / COUNT(*) AS overall_rate
    FROM dbo.loan_clean
)
SELECT
    s.dimension,
    s.segment,
    s.loans,
    s.defaults,
    ROUND(100.0 * s.defaults / s.loans, 2)                   AS default_rate_pct,
    ROUND((1.0 * s.defaults / s.loans) / o.overall_rate, 2)  AS risk_lift,
    ROUND(100.0 * s.defaults / o.total_defaults, 2)          AS share_of_defaults_pct
FROM seg s
CROSS JOIN overall o;
GO
