# Insurance Claims Data Cleaning and Data Quality Analysis

**Summary:** Cleaned 1,028 raw insurance claim records (40 columns) into a 1,000-record reporting table, identified and flagged 9 types of data quality issues, and built Excel and Power BI reports showing a 24.70% fraud rate across $52.5M in claims.

**Tools:** SQL (SQLite), Excel, Power BI (Power Query, DAX)

## Project Overview

This project focuses on cleaning and analyzing a messy insurance claims dataset. The goal was to take raw claims data with missing values, duplicate records, inconsistent formatting, invalid dates, negative claim amounts, and other quality issues, then turn it into a clean dataset that could be used for reporting and business analysis.

This project was built to show skills that are useful for Data Analyst, Data Quality Analyst, Operations Analyst, Insurance Analyst, and entry-level actuarial-related roles.

## Tools Used

* SQLite / DB Browser for SQLite
* SQL
* Excel
* Power BI
* Power Query
* DAX

## Business Problem

Insurance companies rely on clean claims data to understand costs, fraud risk, claim patterns, and operational issues. Messy data can lead to incorrect reporting, poor business decisions, and unreliable dashboards.

For this project, I cleaned a raw insurance claims dataset and created reporting outputs that answer questions such as:

* What are the biggest data quality issues?
* Which claim types have the highest total claim amount?
* Which states have the highest claim costs?
* What is the fraud rate in the dataset?
* How can the cleaned data be prepared for Excel and Power BI reporting?

## Dataset

The raw dataset contained 1,028 rows and 40 columns. The final cleaned reporting table contained 1,000 claim records after handling duplicate and missing claim ID issues.

## Data Quality Issues Found

The raw dataset included several data quality problems:

| Data Quality Issue       | Records Affected |
| ------------------------ | ---------------: |
| Negative Claim Amount    |               83 |
| Duplicate Claim ID       |               56 |
| Invalid Policy Bind Date |               41 |
| Missing Policy Number    |               36 |
| Invalid Incident Date    |               32 |
| Invalid Age              |               25 |
| Claim Total Mismatch     |               25 |
| Missing Claim ID         |               24 |
| Invalid Incident Hour    |               20 |

## Cleaning Steps Performed

Using SQL in DB Browser for SQLite, I performed the following cleaning steps:

* Preserved the original raw claims table
* Created a cleaned staging table
* Standardized claim IDs and policy numbers
* Standardized state abbreviations
* Cleaned yes/no fields such as fraud reported, police report available, and property damage
* Converted currency-formatted fields into numeric values
* Flagged missing claim IDs
* Flagged missing policy numbers
* Flagged duplicate claim IDs
* Flagged invalid ages
* Flagged invalid incident hours
* Flagged invalid dates
* Flagged negative claim amounts
* Flagged claim total mismatches
* Created a final clean reporting table for Excel and Power BI

## Key Metrics

| Metric               |       Value |
| -------------------- | ----------: |
| Total Claims         |       1,000 |
| Total Claim Amount   | $52,527,100 |
| Average Claim Amount |  $52,685.16 |
| Fraud Claim Count    |         247 |
| Fraud Rate           |      24.70% |

*Note: The average claim amount is calculated over the 997 claims that have a recorded claim amount.*

## Key Insights

1. Collision-related claims made up the largest share of total claim costs, especially single vehicle and multi-vehicle collisions.

2. Negative claim amounts, duplicate claim IDs, invalid dates, and missing policy numbers were the biggest data quality issues in the raw dataset.

3. NY had the highest total claim amount, while OH had the highest fraud rate, even though OH had fewer total claims than larger states.

4. The data quality audit showed that the raw dataset needed cleaning before it could be trusted for reporting or dashboard use.

The supporting summary tables are in the `data/` folder (`claims_by_incident_type.csv`, `claims_by_state.csv`, `data_quality_summary.csv`), and the queries are in `sql/project1_insurance_claims_analysis_queries.sql`.

## How to Run

1. Open `sql/project1_insurance_claims_sqlite_cleaning.sql` in DB Browser for SQLite (import `data/insurance_claims_messy.csv` first) and run it to build the cleaned tables.
2. Run `sql/project1_insurance_claims_analysis_queries.sql` to reproduce the summary metrics and tables.
3. Open `excel/Project1_Insurance_Claims_Excel_Summary.xlsx` for the Excel summary.
4. Open `powerbi/Insurance_Claims_Dashboard.pbix` in Power BI Desktop to view the dashboard.

## Power BI Dashboard

The Power BI report includes two pages:

### Claims Overview

This page shows:

* Total claims
* Total claim amount
* Average claim amount
* Fraud rate
* Claim amount by incident type
* Claim amount by state
* Claim count by month
* Fraud reported breakdown

### Data Quality Audit

This page shows:

* Total data quality issues
* Data quality issues by type
* Data quality summary table
* Data quality issues by state
* Average data quality issues by incident type

## Screenshots

### Claims Overview Dashboard

![Claims Overview Dashboard](screenshots/powerbi_claims_overview.png)

### Data Quality Audit Dashboard

![Data Quality Audit Dashboard](screenshots/powerbi_data_quality_audit.png)

### Excel Summary Dashboard

![Excel Summary Dashboard](screenshots/excel_dashboard.png)

## Repository Structure

```
insurance-claims-data-quality-analysis
│
├── data
│   ├── insurance_claims_messy.csv
│   ├── insurance_claims_clean.csv
│   ├── data_quality_summary.csv
│   ├── claims_by_incident_type.csv
│   ├── claims_by_state.csv
│   ├── claims_by_severity.csv
│   ├── claims_by_month.csv
│   └── claims_by_age_group.csv
│
├── sql
│   ├── project1_insurance_claims_sqlite_cleaning.sql
│   └── project1_insurance_claims_analysis_queries.sql
│
├── excel
│   └── Project1_Insurance_Claims_Excel_Summary.xlsx
│
├── powerbi
│   └── Insurance_Claims_Dashboard.pbix
│
├── screenshots
│   ├── excel_dashboard.png
│   ├── powerbi_claims_overview.png
│   └── powerbi_data_quality_audit.png
│
└── README.md
```

## What I Learned

This project helped me practice cleaning messy data, creating data quality checks, writing SQL queries, building Excel summaries, and creating Power BI dashboards. I also learned how important it is to validate raw data before using it for analysis or business reporting.

## How This Applies to Analyst Work

In a real company, analysts often receive messy data from different systems. Before creating reports or dashboards, the data needs to be checked, cleaned, standardized, and validated. This project shows that I can take raw business data, identify problems, clean it, analyze it, and present the results in a clear way.
