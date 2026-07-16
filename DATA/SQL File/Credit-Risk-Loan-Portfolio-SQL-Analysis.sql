/*
====================================================================
PROJECT: CREDIT RISK & LOAN PORTFOLIO ANALYTICS
====================================================================
*/
CREATE DATABASE Bank_Loan;
USE Bank_loan;
DESCRIBE loan_data;

SELECT * FROM loan_data ;

-- QUESTION 1: SYSTEM-WIDE DATA INTEGRITY AUDIT:
-- Profile the dataset to calculate the exact frequency of
-- logical anomalies (e.g., impossible ages, extreme employment lengths) 
-- and missing variables across the portfolio.

SELECT PERSON_AGE FROM loan_data ;

-- Profile Age Anomalies (Count how many rows have impossible ages)
SELECT COUNT(person_age) AS AGE_ERROR FROM LOAN_DATA 
WHERE  PERSON_AGE > 100 ;

-- Profile Employment Anomalies (Count how many rows have extreme employment experiences)
SELECT COUNT(person_emp_exp) AS EMP_ERRORS FROM loan_data 
WHERE person_emp_exp > 75 ;

-- The Answer 
SELECT 
    -- 1. AGE ANOMALY COUNTER
    -- Flags rows where the applicant's age is structurally impossible (> 100).
    SUM(CASE 
        WHEN person_age > 100 THEN 1
        ELSE 0
    END) AS AGE_ERROR,

    -- 2. EMPLOYMENT EXPERIENCE ANOMALY COUNTER
    -- Flags rows where the recorded years of employment exceed a working lifetime (> 75).
    SUM(CASE 
        WHEN person_emp_exp > 75 THEN 1
        ELSE 0
    END) AS EXP_ERROR,

    -- 3. MISSING INTEREST RATE COUNTER
    -- Identifies and counts records where the crucial pricing metric (interest rate) is completely blank.
    SUM(CASE 
        WHEN loan_int_rate IS NULL THEN 1
        ELSE 0
    END) AS NULL_VALUE

FROM 
    loan_data;

-- QUESTION 2: HIGH-RISK DATA EXCLUSION EXPOSURE:
-- Calculate the total funded capital (loan_amnt) locked inside anomalous or incomplete rows 
-- to show stakeholders the exact financial footprint of our dirty data.

SELECT  SUM(loan_amnt) AS Total_Loan_Amount FROM loan_data
WHERE person_age > 100;

SELECT SUM(loan_amnt) AS TOTAL_LOAN_AMOUNT FROM LOAN_DATA
WHERE person_emp_exp > 75;

-- The Answer
SELECT SUM(
CASE 
	-- Check 1: Isolate and flag age anomalies first
	    WHEN COALESCE(person_age, 999) > 100 THEN loan_amnt 
            
	-- Check 2: If age is fine, check and flag employment experience anomalies
        WHEN  COALESCE(person_emp_exp, 999)> 75 THEN loan_amnt 
            
	-- Check 3: If metrics are fine, check and flag missing interest rates
		WHEN loan_int_rate IS NULL THEN loan_amnt
            
	-- Clean Data: If the row passes all checks, assign a 0 value so it doesn't alter the sum
		ELSE 0 
END) AS TOTAL_AMOUNT 
FROM loan_data;
            
-- Question 3: Clean Portfolio Baseline KPIs :
-- Isolate the healthy data and establish the foundational metrics: 
-- total clean loan count, total capital deployed, average interest rate, and average borrower age.  

-- Count rows that pass basic data rules
SELECT COUNT(*) AS CLEAN_LOAN_DATA 
FROM loan_data
WHERE person_age <= 100 AND person_emp_exp <= 75;

-- Count rows with wrong age (100 or older)
SELECT COUNT(*) AS INVALID_age 
FROM loan_data
WHERE person_age >= 100;

-- Count rows with wrong work experience (75 years or more)
SELECT COUNT(*) AS INVALID_EXP 
FROM loan_data
WHERE person_emp_exp >= 75;

-- Calculate baseline portfolio metrics
SELECT        
    COUNT(*) AS Total_Loan_Count,                       -- Total number of clean loans
    SUM(loan_amnt) AS Total_Capital_deployed,            -- Total money given out
    ROUND(AVG(loan_int_rate), 2) AS AVG_Interest_Rate,  -- Average interest rate (rounded to 2 decimals)
    ROUND(AVG(person_age), 0) AS AVG_Person_Age          -- Average borrower age (rounded)
FROM 
    loan_data
WHERE 
    (person_age <= 100 AND person_age IS NOT NULL)       -- Remove wrong or missing ages
    AND 
    (person_emp_exp <= 75 AND person_emp_exp IS NOT NULL) -- Remove wrong or missing work experience
    AND 
    (loan_int_rate IS NOT NULL); -- Remove missing interest rates


-- Create a clean view for future queries
CREATE VIEW view_cleaned_loan_data AS 
SELECT * FROM loan_data 
WHERE 
    (person_age <= 100 AND person_age IS NOT NULL)
    AND 
    (person_emp_exp <= 75 AND person_emp_exp IS NOT NULL)
    AND 
    (loan_int_rate IS NOT NULL);
      
-- Question 4: Age-Bracket Capital Distribution: Group borrowers into 
-- demographic tiers (e.g. Young Adults(18-25), Prime Adults(26-49), Mature Adults(50-64), Seniors(above 65) )
-- to determine which age segment commands the highest volume of credit capital.

-- Age Bracket >> Young Adults(18-25), Prime Adults(26-49), Mature Adults(50-64), Seniors(above 65)
SELECT person_age,
(CASE 
    WHEN person_age BETWEEN 18 AND 25 THEN 'Young Adults'
    WHEN person_age BETWEEN 26 AND 49 THEN 'Prime Adults'
    WHEN person_age BETWEEN 50 AND 64 THEN 'Mature Adults'
    WHEN person_age >= 65 THEN 'Seniors'
    ELSE 'UNKNOWN'
END) AS Age_Category
FROM view_cleaned_loan_data;

-- The Answer
-- Calculate total, active, and defaulted capital per age group
WITH Portfolio_data AS (
SELECT 
(CASE
    WHEN person_age BETWEEN 18 AND 25 THEN 'Young Adults'
    WHEN person_age BETWEEN 26 AND 49 THEN 'Prime Adults'
    WHEN person_age BETWEEN 50 AND 64 THEN 'Mature Adults'
    WHEN person_age >= 65 THEN 'Seniors'
    ELSE 'UNKNOWN'
END) AS Age_Category, 
SUM(loan_amnt) AS Total_Credit_Capital,  -- Total money lent out
SUM(CASE WHEN loan_status = 0 THEN loan_amnt ELSE 0 END) AS Active_portfolio,    -- Sum of non-defaulted loans
SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END) AS Defaulted_portfolio   -- Sum of defaulted loans
FROM view_cleaned_loan_data 
GROUP BY Age_Category 
ORDER BY Total_Credit_Capital DESC 
)
-- Calculate final portfolio shares and percentages
SELECT Age_Category, 
       Total_Credit_Capital, 
       Active_Portfolio, 
       ROUND((Active_Portfolio / Total_Credit_Capital) * 100, 2) AS Active_Portfolio_Percentage,  -- Share of healthy loans
       Defaulted_Portfolio,
       ROUND((Defaulted_Portfolio / Total_Credit_Capital) * 100, 2) AS Defaulted_Portfolio_Percentage -- Share of unpaid loans
FROM Portfolio_data;

-- Key Insights of Age-Bracket Capital Distribution as Follows:
-- Highest Capital Concentration: Prime Adults (26–49) command the absolute highest volume of total credit capital, making them the bank's primary revenue driver.
-- Elevated Risk Profile: Young Adults (18–25) exhibit the highest Defaulted Portfolio Percentage, proving that younger, entry-level borrowers carry the highest risk of non-payment.
-- Portfolio Stability: Mature Adults (50–64) and Seniors (65+) command the lowest shares of capital but maintain the highest Active Portfolio Percentage, representing the most stable and reliable borrowers.

SELECT * FROM view_cleaned_loan_data;

-- Question 5: Employment Longevity VS Credit Allocation : 
-- Analyze how loan volumes and average loan amounts change relative to a 
-- borrower's years of employment experience.

SELECT person_emp_exp,
	   SUM(loan_amnt) AS TOTAL_LOAN_VOLUME,
	   ROUND(AVG(loan_amnt),2) AS AVG_LOAN_AMOUNT
FROM view_cleaned_loan_data
GROUP BY person_emp_exp
ORDER BY PERSON_EMP_EXP ;

-- Borrowers with 0 years of experience command the highest total money borrowed (driven by Education or Venture).
-- As work experience increases, average loan amounts increase because the bank trusts their higher, established income.
-- At late-career stages (around 46 years of experience), loan volumes and sizes drop sharply because borrowers approach retirement age.

SELECT PERSON_AGE, COUNT(person_age) FROM view_cleaned_loan_data
WHERE Person_age = 25
GROUP BY PERSON_AGE;

SELECT 
    loan_intent,
    COUNT(*) AS Number_of_Loans,
    ROUND(AVG(person_income), 2) AS Avg_Income,
    ROUND(AVG(loan_amnt), 2) AS Avg_Loan_Amount
FROM 
    view_cleaned_loan_data
WHERE 
    person_emp_exp = 0
GROUP BY 
    loan_intent
ORDER BY 
    Number_of_Loans DESC ;

-- Key Insights: Employment Longevity vs. Credit Allocation
-- Entry-Level Capital Spike: Borrowers with 0 years of experience command the highest total money borrowed, heavily driven by high-volume applications for Education or Venture.
-- Trust-Based Loan Scaling: As work experience increases, average loan amounts increase because the bank trusts their higher, established income.
-- Retirement Drop-Off: At late-career stages (around 46 years of experience), loan volumes and sizes drop sharply because borrowers approach retirement age.


-- Question 6: Loan Intent & Purpose Evaluation: 
-- Segment the data by the underlying reason for the loan (e.g., Venture, Medical, Education, Home Improvement) 
-- to find the average funding size and interest rate for each category.

-- Calculate average interest rate and average funding size by loan purpose
SELECT loan_intent, 
       ROUND(AVG(loan_int_rate), 2) AS AVG_Loan_Int_Rate, -- Average interest rate per category
       ROUND(AVG(loan_amnt), 2) AS AVG_Funding_Size      -- Average loan amount per category
FROM view_cleaned_loan_data
GROUP BY loan_intent
ORDER BY AVG_Funding_Size DESC;

-- Key Insights: Loan Intent & Purpose Evaluation
-- Premium Capital Allocations: Home Improvement loans command both the highest average funding size and the highest average interest rate, representing the most expensive and capital-heavy category for the bank.
-- High-Risk Risk Pricing: Medical loans exhibit the lowest average funding size but carry the second-highest average interest rate, showing that the bank prices medical credit with tight exposure limits but higher risk premiums.

-- Question 7: The Leverage Ratio Tiering (LTI): 
-- Calculate each borrower's Loan-to-Income ratio. 
-- Group them into leverage risk tiers (Low, Medium, High, Critical) to find out how 
-- much capital is sitting in high-leverage positions.


-- Test query to inspect individual loan-to-income ratios
SELECT person_income, loan_amnt, loan_intent,
ROUND((loan_amnt/person_income) , 2) AS Leverage_Ratio_Tiering
FROM view_cleaned_loan_data
ORDER BY Leverage_Ratio_Tiering DESC;
 
-- Test query to find the maximum loan-to-income ratio per loan purpose
SELECT loan_intent,
ROUND(MAX(loan_amnt/person_income) , 2) AS Total_Leverage_Ratio_Tiering
FROM view_cleaned_loan_data
GROUP BY loan_intent;

-- Intermediate analysis: Breakdown by loan purpose and leverage risk tier
WITH LTI_DATA AS (
SELECT  Loan_intent,
       SUM(loan_amnt) AS Total_Loan_Amount,
(CASE 
      WHEN person_income IS NULL OR person_income = 0 THEN 'Missing/Invalid Income'
      WHEN ROUND((loan_amnt/person_income) , 2) BETWEEN 0.00 AND 0.15 THEN 'Low LRT'
      WHEN ROUND((loan_amnt/person_income) , 2) BETWEEN 0.16 AND 0.30 THEN 'Moderate LRT'
      WHEN ROUND((loan_amnt/person_income) , 2) BETWEEN 0.31 AND 0.55 THEN 'High LRT'
      ELSE 'Critical LRT'
END ) AS Leverage_Ratio_Tiering
FROM view_cleaned_loan_data
GROUP BY Leverage_Ratio_Tiering, loan_intent
)
SELECT loan_intent, Leverage_Ratio_Tiering, Total_Loan_Amount,
ROUND(( Total_Loan_Amount / SUM(Total_Loan_Amount) OVER() ) * 100, 2) AS Pct_Of_Total_Bank_Portfolio
FROM LTI_Data
ORDER BY Leverage_Ratio_Tiering, loan_intent ASC, Total_Loan_Amount DESC ;
 
-- The Answer: Final aggregate portfolio concentration by leverage risk tier
WITH LTI_DATA AS (
SELECT  
       SUM(loan_amnt) AS Total_Loan_Amount,
(CASE 
      WHEN loan_amnt IS NULL OR loan_amnt = 0 THEN 'Missing/Invalid Loan Amount'
      WHEN person_income IS NULL OR person_income = 0 THEN 'Missing/Invalid Income'
      WHEN ROUND((loan_amnt/person_income) , 2) BETWEEN 0.00 AND 0.15 THEN 'Low LRT'
      WHEN ROUND((loan_amnt/person_income) , 2) BETWEEN 0.16 AND 0.30 THEN 'Moderate LRT'
      WHEN ROUND((loan_amnt/person_income) , 2) BETWEEN 0.31 AND 0.55 THEN 'High LRT'
      ELSE 'Critical LRT'
END ) AS Leverage_Ratio_Tiering
FROM view_cleaned_loan_data
GROUP BY Leverage_Ratio_Tiering
)
SELECT  Leverage_Ratio_Tiering, Total_Loan_Amount,
ROUND(( Total_Loan_Amount / SUM(Total_Loan_Amount) OVER() ) * 100, 2) AS Pct_Of_Total_Bank_Portfolio
FROM LTI_Data
ORDER BY  Total_Loan_Amount DESC ;

-- Key Insights: The Leverage Ratio Tiering (LTI)

-- Portfolio Capital Density: The vast majority of the bank's total deployed capital is concentrated within the Moderate and High LRT tiers, 
-- showing that the loan book leans heavily toward leveraged accounts.

-- Critical Exposure Vector: The Critical LRT segment represents a significant vulnerability, pinpointing exactly how much capital has been issued to borrowers whose 
-- loan amounts dwarf their annual income.

-- Risk Mitigation Target: Segmenting this by Loan Intent highlights which specific loan products (like Debt Consolidation or Medical) are pushing borrowers into dangerous high-leverage positions.


-- Question 8: Interest Rate vs. Risk Tier Alignment:
-- Analyze whether the historical interest rates assigned to high-leverage or high-risk 
-- categories are high enough to justify the risk, or if pricing is misaligned.

-- Calculate leverage tiers, total capital, average interest rates, and portfolio percentages
WITH LTI_DATA AS (
SELECT   
(CASE 
      WHEN loan_amnt IS NULL OR loan_amnt = 0 THEN 'Missing/Invalid Loan Amount'
      WHEN person_income IS NULL OR person_income = 0 THEN 'Missing/Invalid Income'
      WHEN ROUND((loan_amnt/person_income) , 2) BETWEEN 0.00 AND 0.15 THEN 'Low LRT'
      WHEN ROUND((loan_amnt/person_income) , 2) BETWEEN 0.16 AND 0.30 THEN 'Moderate LRT'
      WHEN ROUND((loan_amnt/person_income) , 2) BETWEEN 0.31 AND 0.55 THEN 'High LRT'
      ELSE 'Critical LRT'
END ) AS Leverage_Ratio_Tiering, 
loan_amnt, 
loan_int_rate 
FROM view_cleaned_loan_data
)
SELECT  Leverage_Ratio_Tiering, 
        SUM(loan_amnt) AS Total_Loan_Amount, -- Total money lent out per tier
        ROUND(AVG(loan_int_rate), 2) AS Average_Interest_Rate, -- Average interest rate charged per tier
        ROUND(( SUM(loan_amnt) / SUM(SUM(loan_amnt)) OVER() ) * 100, 2) AS Percentage_Of_Total_Bank_Portfolio -- Share of total bank capital
FROM LTI_Data
GROUP BY Leverage_Ratio_Tiering 
ORDER BY Total_Loan_Amount DESC;

-- Key Insights: Interest Rate vs Risk Tier Alignment

-- Risk-Pricing Alignment: The average interest rate scales upward across Low, Moderate, and High LRT tiers, confirming that the underwriting logic 
-- successfully charges higher premiums for taking on more leverage risk.

-- The Critical Premium Deficit: If the Critical LRT average interest rate does not show a significant protective jump compared to the High LRT tier, 
-- it exposes a structural pricing misalignment where the bank is under-pricing extreme tail risk.

-- Capital vs. Yield Optimization: Comparing the Percentage of Total Bank Portfolio against the Average Interest Rate pinpoints exactly which leverage group 
-- generates the highest yield relative to the capital assets deployed.


-- Question 9: Income Stream Concentration Analysis:
-- Evaluate the total outstanding loan exposure across different borrower income brackets 
-- to identify if the portfolio is overly dependent on low- or middle-income segments.

-- Test query to inspect individual borrower incomes from highest to lowest
SELECT * FROM view_cleaned_loan_data
ORDER BY person_income DESC;

-- The Answer: Calculate total loan exposure and portfolio percentage by income segment
SELECT 
(CASE    
    WHEN person_income BETWEEN 7000 AND 50000 THEN 'Low Income'
    WHEN person_income BETWEEN 50001 AND 150000 THEN 'Middle Income'
    ELSE 'High Income'
END ) AS Income_Segment,
SUM(loan_amnt) AS Total_Loan, -- Total money lent out per income tier
ROUND((SUM(loan_amnt) / SUM(SUM(loan_amnt)) OVER() * 100), 2) AS Percentage_of_Total_Portfolio -- Share of total bank capital
FROM view_cleaned_loan_data
GROUP BY Income_Segment;

-- Key Insights: Income Stream Concentration Analysis
-- Core Revenue Driver: The Middle Income segment typically holds the largest share of the portfolio, acting as the foundation for the bank’s total credit interest generation.
-- Macroeconomic Vulnerability: A heavy concentration in the Low Income tier exposes the bank to high systemic risk, as these borrowers are the most vulnerable to economic downturns, inflation, and job loss.
-- Premium Market Capture: The total capital volume sitting in the High Income tier reveals whether the bank is successfully acquiring low-risk, affluent clients to balance out its riskier segments.

-- Question 10: High-Exposure Concentration Ranking: 
-- Use SQL Window Functions (DENSE_RANK()) to identify and 
-- rank the top 10 highest-exposure borrowers within each specific loan intent category.

-- Create CTE to rank loan amounts within each loan category
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
-- Select top 10 ranks and count how many borrowers are tied at each amount
SELECT loan_intent, 
       loan_amnt, 
       Loan_intent_Ranks,
       COUNT(*) AS Total_Borrowers -- Number of borrowers clustered at this loan size
FROM Ranked_Loans
WHERE Loan_intent_Ranks <= 10 
GROUP BY loan_intent, loan_amnt, Loan_intent_Ranks
ORDER BY loan_intent, Loan_intent_Ranks;

-- Key Insights: High-Exposure Concentration Ranking

-- Underwriting Policy Ceiling: The window analysis reveals a strict policy cap across almost all categories—the highest loan amount (Rank 1) is universally fixed at exactly $35,000.

-- High-Density Tied Tiers: Rank 1 does not hold a single borrower; instead, it contains a massive cluster of separate borrowers all tied exactly at the $35,000 limit, 
-- particularly in Debt Consolidation and Medical categories.

-- Portfolio Concentration Risk: This heavy clustering at the absolute maximum limit exposes the bank to systemic boundary risk, showing that capital is heavily 
-- bunched together right at the underwriting ceiling.
 


