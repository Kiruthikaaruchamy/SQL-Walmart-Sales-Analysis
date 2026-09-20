# Walmart Sales Analysis using SQL

## Project Overview

This project analyzes Walmart sales data using MySQL to identify sales trends, customer purchasing behavior, product performance, payment preferences, and revenue contribution.

The analysis uses SQL queries, Common Table Expressions (CTEs), window functions, aggregations, ranking, and statistical calculations to derive business insights from transactional sales data.

## Tools Used

- MySQL
- SQL
- Common Table Expressions (CTEs)
- Window Functions
- Aggregate Functions
- Subqueries
- Statistical Analysis

## Analysis Performed

1. Analyzed monthly sales performance across branches and calculated month-over-month sales growth to identify changes in branch performance.

2. Identified the most profitable product line for each branch by analyzing total gross income and cost of goods sold.

3. Segmented customers into High, Medium, and Low spending categories based on their total and average purchase amounts.

4. Detected unusual sales transactions by comparing individual transaction values with the average sales and standard deviation within each product line.

5. Analyzed customer payment preferences by city and identified the most frequently used payment method in each city.

6. Analyzed monthly sales performance by gender to understand purchasing patterns across male and female customers.

7. Analyzed product-line preferences among Member and Normal customers and identified the most frequently purchased product category for each customer type.

8. Identified repeat customers by analyzing the time interval between consecutive purchases and detecting purchases made within 30 days.

9. Identified the top five customers based on their total revenue contribution.

10. Analyzed weekly sales trends by calculating total sales for each day of the week and comparing sales performance across weekdays.

## SQL Concepts Demonstrated

- SELECT and filtering
- GROUP BY and HAVING
- Aggregate functions
- CASE statements
- Subqueries
- Common Table Expressions (CTEs)
- Window functions
- LAG()
- RANK()
- DENSE_RANK()
- Date functions
- Statistical calculations
- Customer segmentation
- Trend analysis

## Project Files

- `Walmart_Sales_Analysis.sql` – Contains the SQL queries used for the analysis.
- `Walmart_Sales_Dataset.csv` – Contains the Walmart sales dataset used for analysis.

## Key Business Areas

- Sales Growth Analysis
- Branch Performance
- Product Profitability
- Customer Segmentation
- Anomaly Detection
- Payment Preferences
- Gender-wise Sales Analysis
- Customer Purchase Preferences
- Repeat Customer Analysis
- Top Customer Revenue Contribution
- Weekly Sales Trend Analysis
