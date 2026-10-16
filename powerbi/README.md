# Power BI dashboard

| File | Description |
|---|---|
| [`loan_default_dashboard.pbix`](loan_default_dashboard.pbix) | The dashboard (data imported from SQL Server) |
| [`screenshots/`](screenshots) | Screenshots of each report page |

## Data model

One table, `loan_clean`, imported from the SQL Server view `dbo.loan_clean` (database `LoanDefault`). It has 255,347 rows. Band columns have a number in front (`1. <40k`, `2. 40k-70k` and so on), so they sort in the right order. See the [data dictionary](../docs/data_dictionary.md) for all columns.

## Pages

| Page | Content |
|---|---|
| **Portfolio Overview** | KPI cards (total loans, total defaults, average loan amount, default rate), marital status slicers, defaults by employment type, and a key findings panel |
| **Risk Drivers** | Defaults by loan-to-income band, by income band, and by age band |

## DAX measures

All measures are in a table named `_Measures`.

```DAX
Total Loans           = COUNTROWS ( loan_clean )

Total Defaults        = SUM ( loan_clean[default_flag] )

Default Rate          = DIVIDE ( [Total Defaults], [Total Loans] )

Overall Default Rate  = CALCULATE ( [Default Rate], ALL ( loan_clean ) )

Rate vs Overall (pts) = ( [Default Rate] - [Overall Default Rate] ) * 100

Risk Lift             = DIVIDE ( [Default Rate], [Overall Default Rate] )

Share of Loans        = DIVIDE ( [Total Loans], CALCULATE ( [Total Loans], ALL ( loan_clean ) ) )

Share of Defaults     = DIVIDE ( [Total Defaults], CALCULATE ( [Total Defaults], ALL ( loan_clean ) ) )

Total Loan Value      = SUM ( loan_clean[LoanAmount] )
```

The average loan amount card uses the average of `LoanAmount`.

`Overall Default Rate` uses `ALL ( loan_clean )`, so it always shows the whole-portfolio rate. This makes it a fixed benchmark for `Rate vs Overall (pts)` and `Risk Lift`, even when slicers are applied.

## Validation

With no slicer selected, the cards match the SQL results in [`../sql/results`](../sql/results):

| Measure | Dashboard | SQL result |
|---|---|---|
| Total Loans | 255,347 (shown as 255K) | 255,347 |
| Total Defaults | 29,653 | 29,653 |
| Default Rate | 11.61% | 11.61% |
| Average Loan Amount | 127,579 | 127,579 |

## Notes

- The source data does not state a currency. The $ sign on the dashboard is a display label only.
- The scorecard columns (`risk_points`, `risk_band`) are available in the model for further report pages.
