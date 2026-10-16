/* ============================================================
   06 - Analysis queries (SQL Server)
   Business question: which customers are most likely to default,
   and what should the bank change in approval or pricing?
   Run 04 and 05 first. Results are saved in sql/results/.
   ============================================================ */

USE LoanDefault;
GO

-- Q1. Portfolio KPIs
SELECT COUNT(*)                                             AS total_loans,
       SUM(default_flag)                                    AS defaults,
       ROUND(100.0 * SUM(default_flag) / COUNT(*), 2)       AS default_rate_pct,
       ROUND(AVG(1.0 * LoanAmount), 0)                      AS avg_loan_amount,
       ROUND(AVG(1.0 * Income), 0)                          AS avg_income,
       ROUND(AVG(1.0 * CreditScore), 0)                     AS avg_credit_score,
       ROUND(AVG(DTIRatio), 2)                              AS avg_dti,
       SUM(CAST(LoanAmount AS BIGINT))                      AS total_loan_value,
       SUM(CASE WHEN default_flag = 1 THEN CAST(LoanAmount AS BIGINT) ELSE 0 END) AS defaulted_loan_value,
       ROUND(100.0 * SUM(CASE WHEN default_flag = 1 THEN CAST(LoanAmount AS BIGINT) ELSE 0 END)
             / SUM(CAST(LoanAmount AS BIGINT)), 2)          AS value_default_rate_pct
FROM dbo.loan_clean;

-- Q2. Which factors separate defaulters best? (gap between highest and lowest segment rate, segments with 500+ loans)
SELECT dimension,
       MIN(default_rate_pct)                                    AS lowest_rate_pct,
       MAX(default_rate_pct)                                    AS highest_rate_pct,
       ROUND(MAX(default_rate_pct) - MIN(default_rate_pct), 2)  AS spread_pts
FROM dbo.segment_summary
WHERE loans >= 500
  AND dimension NOT IN ('Risk band', 'Risk points')
GROUP BY dimension
ORDER BY spread_pts DESC;

-- Q3. One factor at a time (change the dimension name to explore any other factor)
SELECT segment, loans, defaults, default_rate_pct, risk_lift, share_of_defaults_pct
FROM dbo.segment_summary
WHERE dimension = 'Loan-to-income band'
ORDER BY segment;

-- Q4. Top 10 highest-risk single segments (500+ loans)
WITH ranked AS (
    SELECT dimension, segment, loans, defaults, default_rate_pct, risk_lift,
           RANK() OVER (ORDER BY default_rate_pct DESC) AS rnk
    FROM dbo.segment_summary
    WHERE loans >= 500 AND dimension NOT IN ('Risk band', 'Risk points')
)
SELECT rnk, dimension, segment, loans, default_rate_pct, risk_lift
FROM ranked
WHERE rnk <= 10
ORDER BY rnk;

-- Q5. Top 10 lowest-risk single segments (500+ loans)
WITH ranked AS (
    SELECT dimension, segment, loans, defaults, default_rate_pct, risk_lift,
           RANK() OVER (ORDER BY default_rate_pct ASC) AS rnk
    FROM dbo.segment_summary
    WHERE loans >= 500 AND dimension NOT IN ('Risk band', 'Risk points')
)
SELECT rnk, dimension, segment, loans, default_rate_pct, risk_lift
FROM ranked
WHERE rnk <= 10
ORDER BY rnk;

-- Q6. Risk matrix: loan-to-income x income band
SELECT lti_band, income_band,
       COUNT(*) AS loans,
       SUM(default_flag) AS defaults,
       ROUND(100.0 * SUM(default_flag) / COUNT(*), 2) AS default_rate_pct
FROM dbo.loan_clean
GROUP BY lti_band, income_band
HAVING COUNT(*) >= 500
ORDER BY lti_band, income_band;

-- Q7. Risk matrix: credit score band x DTI band
SELECT credit_band, dti_band,
       COUNT(*) AS loans,
       ROUND(100.0 * SUM(default_flag) / COUNT(*), 2) AS default_rate_pct
FROM dbo.loan_clean
GROUP BY credit_band, dti_band
ORDER BY credit_band, dti_band;

-- Q8. Employment type x co-signer
SELECT EmploymentType, HasCoSigner,
       COUNT(*) AS loans,
       ROUND(100.0 * SUM(default_flag) / COUNT(*), 2) AS default_rate_pct
FROM dbo.loan_clean
GROUP BY EmploymentType, HasCoSigner
ORDER BY EmploymentType, HasCoSigner;

-- Q9. Defaulters vs non-defaulters (averages)
SELECT CASE WHEN default_flag = 1 THEN 'Defaulted' ELSE 'Did not default' END AS customer_group,
       COUNT(*)                              AS loans,
       ROUND(AVG(1.0 * Age), 1)              AS avg_age,
       ROUND(AVG(1.0 * Income), 0)           AS avg_income,
       ROUND(AVG(1.0 * LoanAmount), 0)       AS avg_loan_amount,
       ROUND(AVG(loan_to_income), 2)         AS avg_loan_to_income,
       ROUND(AVG(1.0 * CreditScore), 0)      AS avg_credit_score,
       ROUND(AVG(1.0 * MonthsEmployed), 1)   AS avg_months_employed,
       ROUND(AVG(InterestRate), 2)           AS avg_interest_rate,
       ROUND(AVG(DTIRatio), 2)               AS avg_dti
FROM dbo.loan_clean
GROUP BY default_flag
ORDER BY default_flag DESC;

-- Q10. Money at risk by loan purpose (value of defaulted loans)
SELECT LoanPurpose,
       COUNT(*)                                            AS loans,
       ROUND(100.0 * SUM(default_flag) / COUNT(*), 2)      AS default_rate_pct,
       SUM(CASE WHEN default_flag = 1 THEN CAST(LoanAmount AS BIGINT) ELSE 0 END) AS defaulted_loan_value,
       ROUND(100.0 * SUM(CASE WHEN default_flag = 1 THEN CAST(LoanAmount AS BIGINT) ELSE 0 END)
             / SUM(SUM(CASE WHEN default_flag = 1 THEN CAST(LoanAmount AS BIGINT) ELSE 0 END)) OVER (), 2) AS share_of_defaulted_value_pct
FROM dbo.loan_clean
GROUP BY LoanPurpose
ORDER BY defaulted_loan_value DESC;

-- Q11. Risk scorecard: default rate by risk points (0-6), with cumulative share of loans and defaults from the riskiest end
WITH s AS (
    SELECT risk_points,
           COUNT(*) AS loans,
           SUM(default_flag) AS defaults
    FROM dbo.loan_clean
    GROUP BY risk_points
)
SELECT risk_points,
       loans,
       defaults,
       ROUND(100.0 * defaults / loans, 2) AS default_rate_pct,
       ROUND(100.0 * SUM(loans)    OVER (ORDER BY risk_points DESC ROWS UNBOUNDED PRECEDING) / SUM(loans)    OVER (), 2) AS cum_pct_of_loans,
       ROUND(100.0 * SUM(defaults) OVER (ORDER BY risk_points DESC ROWS UNBOUNDED PRECEDING) / SUM(defaults) OVER (), 2) AS cum_pct_of_defaults
FROM s
ORDER BY risk_points;

-- Q12. Risk bands: share of loans vs share of defaults
SELECT risk_band,
       COUNT(*) AS loans,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)                   AS pct_of_loans,
       SUM(default_flag) AS defaults,
       ROUND(100.0 * SUM(default_flag) / SUM(SUM(default_flag)) OVER (), 2) AS pct_of_defaults,
       ROUND(100.0 * SUM(default_flag) / COUNT(*), 2)                       AS default_rate_pct
FROM dbo.loan_clean
GROUP BY risk_band
ORDER BY risk_band;

-- Q13. Do the flagged inconsistent rows behave differently?
SELECT 'tenure_flag' AS flag, tenure_flag AS flag_value, COUNT(*) AS loans,
       ROUND(100.0 * SUM(default_flag) / COUNT(*), 2) AS default_rate_pct
FROM dbo.loan_clean GROUP BY tenure_flag
UNION ALL
SELECT 'high_lti_flag', high_lti_flag, COUNT(*),
       ROUND(100.0 * SUM(default_flag) / COUNT(*), 2)
FROM dbo.loan_clean GROUP BY high_lti_flag
ORDER BY flag, flag_value;
