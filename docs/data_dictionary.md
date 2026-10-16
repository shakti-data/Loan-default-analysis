# Data dictionary

## Source columns (`dbo.raw_loans`)

| Column | SQL type | Meaning |
|---|---|---|
| `LoanID` | NVARCHAR(10) | Unique loan ID |
| `Age` | INT | Borrower age in years (18-69) |
| `Income` | INT | Yearly income (15,000-149,999, currency not stated) |
| `LoanAmount` | INT | Loan amount (5,000-249,999) |
| `CreditScore` | INT | Credit score (300-849). Higher means a more reliable borrower |
| `MonthsEmployed` | INT | Months in the current job (0-119) |
| `NumCreditLines` | INT | Number of open credit accounts (1-4) |
| `InterestRate` | DECIMAL(5,2) | Yearly interest rate of the loan in % (2-25) |
| `LoanTerm` | INT | Repayment period in months (12, 24, 36, 48, 60) |
| `DTIRatio` | DECIMAL(3,2) | Debt-to-income: the share of income already used for debt payments (0.1-0.9) |
| `Education` | NVARCHAR | High School, Bachelor's, Master's, PhD |
| `EmploymentType` | NVARCHAR | Full-time, Part-time, Self-employed, Unemployed |
| `MaritalStatus` | NVARCHAR | Single, Married, Divorced |
| `HasMortgage` | NVARCHAR(3) | Yes / No. Borrower already has a home loan |
| `HasDependents` | NVARCHAR(3) | Yes / No. Borrower supports dependents |
| `LoanPurpose` | NVARCHAR | Home, Auto, Education, Business, Other |
| `HasCoSigner` | NVARCHAR(3) | Yes / No. Another person guarantees the loan |
| `default_flag` | INT | **Target.** 1 = defaulted, 0 = did not default (named `Default` in the CSV) |

## Columns added in `dbo.loan_clean`

| Column | How it is built |
|---|---|
| `age_band` | 18-24, 25-34, 35-44, 45-54, 55-64, 65+ |
| `income_band` | <40k, 40k-70k, 70k-100k, 100k+ |
| `loan_amount_band` | <50k, 50k-100k, 100k-150k, 150k-200k, 200k+ |
| `loan_to_income` | `LoanAmount / Income` (how many years of income the loan equals) |
| `lti_band` | <1x, 1x-2x, 2x-3x, 3x-5x, 5x+ |
| `credit_band` | Poor (<580), Fair (580-669), Good (670-739), Very good (740+) |
| `tenure_band` | <1 yr, 1-3 yrs, 3-5 yrs, 5+ yrs (from `MonthsEmployed`) |
| `interest_band` | <8%, 8-14%, 14-20%, 20%+ |
| `dti_band` | Low (<0.2), Medium (0.2-0.39), High (0.4-0.59), Very high (0.6+) |
| `mortgage_flag`, `dependents_flag`, `cosigner_flag` | Yes = 1, No = 0 |
| `tenure_flag` | 1 when `MonthsEmployed` > (Age - 18) x 12, which is not possible |
| `high_lti_flag` | 1 when loan-to-income is above 5 |
| `rf_low_income` | 1 when Income < 40,000 |
| `rf_high_lti` | 1 when loan-to-income >= 3 |
| `rf_short_tenure` | 1 when MonthsEmployed < 36 |
| `rf_no_cosigner` | 1 when there is no co-signer |
| `rf_unemployed` | 1 when EmploymentType is Unemployed |
| `rf_poor_credit` | 1 when CreditScore < 580 |
| `risk_points` | Sum of the six `rf_` columns (0 to 6) |
| `risk_band` | Low (0-1), Medium (2-3), High (4-6) |

Band labels start with a number so that they sort correctly in SQL and Power BI.
