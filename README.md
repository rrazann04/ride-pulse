# Ride Pulse: Ride-Hailing Operations Dashboard

An analysis of 150,000 ride-hailing bookings in Delhi NCR during 2024, from a raw CSV file to a two-page Power BI dashboard.

**Tools:** SQL Server (T-SQL) · Power BI · DAX
**Data:** Uber Ride Analytics dataset (Kaggle), January–December 2024, fares in Indian rupees

---

## The question

Why do so many bookings fail, and when is demand highest?

## What I did

### 1. Import (SQL Server)
- Loaded **150,000** bookings with every column as text first, so the import couldn't fail on mixed values.

### 2. Profile and clean
- Converted the text `null` into real NULLs in numeric and text columns.
- Removed stray quote marks from booking and customer IDs.
- Converted dates, times, fares, distances, wait times and ratings to proper data types, with zero failed conversions.
- Found **1,233** repeated booking IDs. None were exact duplicates: each was a different ride, so I kept them all and gave every ride its own key (`RideKey`).
- Checked that the outcome flags (customer cancelled, driver cancelled, incomplete) matched the booking status exactly.

### 3. Model
| Table | Grain |
|---|---|
| `FactRides` | one row per booking |
| `DimDate` | one row per day of 2024, with weekday and weekend flags |

### 4. Report (Power BI)
- Measures for completion and cancellation rates, revenue from completed rides, average fare, ratings and pickup wait.
- Two pages: **Ride overview** and **Cancellations & vehicles**.
- A custom colour theme where each booking outcome keeps the same colour on every chart.

## Key findings

- Only **62%** of bookings ended in a completed ride.
- Drivers cancelled **18%** of bookings, more than twice the customer rate of **7%**.
- Completed rides brought in **₹47.3M**, at an average fare of **₹508**.
- Demand peaks in the evening, between **5 and 7 pm**. Riders wait **8.5 minutes** on average for pickup.

## Note on the data

This dataset is synthetic. Some splits (by weekday, vehicle type and cancellation reason) are unusually even, so I treat those patterns with caution rather than as real business findings.

## Files

| File | What it does |
|---|---|
| `01_profile.sql` | Profiles the raw import: date formats, statuses, repeated IDs, text "null" values |
| `02_clean_view.sql` | Builds the cleaned view and checks conversions and flags |
| `03_analysis.sql` | Business questions: performance, vehicle types, hours, cancellation reasons, monthly trend |
| `04_reporting_model.sql` | Builds FactRides and DimDate for Power BI and validates them |
| `RidePulse_theme.json` | Power BI colour theme used in the report |
| `Ride_Pulse_Dashboard.pdf` | PDF export of the two-page Power BI report |

Data source: [Uber Ride Analytics Dashboard dataset on Kaggle](https://www.kaggle.com/datasets/yashdevladdha/uber-ride-analytics-dashboard)
