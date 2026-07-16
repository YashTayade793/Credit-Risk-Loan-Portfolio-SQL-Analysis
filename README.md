# 📊 Credit Risk & Loan Portfolio SQL Analysis

📌 Project Overview
This project analyzes a comprehensive Credit Risk dataset using SQL to evaluate loan portfolio performance, identify high-exposure risks, and diagnose core banking anomalies. By transforming raw historical application data into structured financial intelligence, this analysis uncovers critical risk distributions, systemic credit limits, and concentration vectors to support executive risk-mitigation decisions.

🎯 Project Objectives
* Evaluate overall loan book exposure and distribution metrics.
* Segment and rank high-risk borrowers across specific loan intentions.
* Expose systemic boundary limits and policy anomalies within current underwriting logic.
* Provide data-driven clarity on structural risk groupings to protect bank capital.
* Translate complex financial data patterns into actionable risk mitigation scripts.

🛠️ Tools & Technologies
* SQL (Data Aggregation, View Operations, Analytical Querying)
* Database Management System: MySQL / PostgreSQL / MS SQL Server

📚 SQL Concepts Used
* Multi-Level Query Isolation: Common Table Expressions (CTEs)
* Analytical Engines: Window Functions (DENSE_RANK(), PARTITION BY, ORDER BY)
* Structural Summarization: Advanced GROUP BY, COUNT(*) Multi-Aggregations
* Conditional Logic & Filters: Multi-clause WHERE, Logical Operators, HAVING
* Data Control & Segregation: CREATE VIEW, Window Filtering

---

## 📊 Business Questions Solved

### 📂 Phase 1: Data Quality & Financial Baseline
* **Question 1: System-Wide Data Integrity Audit**  
  Profiled the dataset to calculate the exact frequency of logical anomalies (e.g., impossible ages, extreme employment lengths) and missing variables across the portfolio.
* **Question 2: High-Risk Data Exclusion Exposure**  
  Calculated the total funded capital (`loan_amnt`) locked inside anomalous or incomplete rows to show stakeholders the exact financial footprint of our dirty data.
* **Question 3: Clean Portfolio Baseline KPIs**  
  Isolated the healthy data to establish foundational metrics: total clean loan count, total capital deployed, average interest rate, and average borrower age.

### 📂 Phase 2: Demographics & Risk Segmentation
* **Question 4: Age-Bracket Capital Distribution**  
  Grouped borrowers into demographic tiers (e.g., Gen Z, Millennials, Gen X, Boomers) to determine which age segment commands the highest volume of credit capital.
* **Question 5: Employment Longevity vs. Credit Allocation**  
  Analyzed how loan volumes and average loan amounts change relative to a borrower's years of employment experience.
* **Question 6: Loan Intent & Purpose Evaluation**  
  Segmented the data by the underlying reason for the loan (e.g., Venture, Medical, Education, Home Improvement) to find the average funding size and interest rate for each category.

### 📂 Phase 3: Credit Risk & Profitability Analytics
* **Question 7: The Leverage Ratio Tiering (LTI)**  
  Calculated each borrower's Loan-to-Income ratio and grouped them into leverage risk tiers (Low, Medium, High, Critical) to find out how much capital is sitting in high-leverage positions.
* **Question 8: Interest Rate vs. Risk Tier Alignment**  
  Analyzed whether the historical interest rates assigned to high-leverage or high-risk categories are high enough to justify the risk, or if pricing is misaligned.
* **Question 9: Income Stream Concentration Analysis**  
  Evaluated the total outstanding loan exposure across different borrower income brackets to identify if the portfolio is overly dependent on low- or middle-income segments.

### 📂 Advanced Credit Risk Architecture
* **Question 10: High-Exposure Risk Ranking by Intent**  
  Identified and ranked the top 10 highest credit exposures within each specific loan category, using a combination of CTEs and window functions to reveal borrower density at peak exposure levels.

---

## 💻 Featured Technical Solution

Below is the advanced SQL implementation used to isolate high-density risk concentrations across the bank's different loan products. For the full production script covering all ten steps, please view the main [queries.sql](./queries.sql) file.

```sql
WITH Ranked_Loans AS 
(
    SELECT loan_intent,  
           loan_amnt,
           DENSE_RANK() OVER( 
               PARTITION BY loan_intent 
               ORDER BY loan_amnt DESC 
           ) AS Loan_intent_Ranks
    FROM view_cleaned_loan_data
)
SELECT loan_intent, 
       loan_amnt, 
       Loan_intent_Ranks,
       COUNT(*) AS Total_Borrowers
FROM Ranked_Loans
WHERE Loan_intent_Ranks <= 10 
GROUP BY loan_intent, loan_amnt, Loan_intent_Ranks
ORDER BY loan_intent, Loan_intent_Ranks;
 
📈 Key Insights: High-Exposure Concentration Ranking

    Underwriting Policy Ceiling: The window analysis reveals a strict policy cap across almost all categories—the highest loan amount (Rank 1) is universally fixed at exactly $35,000.

    High-Density Tied Tiers: Rank 1 does not hold a single borrower; instead, it contains a massive cluster of separate borrowers all tied exactly at the $35,000 limit, particularly in the Debt Consolidation and Medical categories.

    Portfolio Concentration Risk: This heavy clustering at the absolute maximum limit exposes the bank to systemic boundary risk, showing that capital is heavily bunched together right at the underwriting ceiling.
