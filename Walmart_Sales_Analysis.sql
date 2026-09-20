-- Walmart Sales Analysis
-- Database: csv_project
-- Table: walmartsales_1
--
-- This file contains the cleaned, final SQL queries used for the analysis.
-- MySQL 8.0+ is recommended because the analysis uses CTEs and window functions.

USE csv_project;

-- ============================================================
-- 1. Branch Sales Growth Analysis
-- Identify branch-level sales growth over time using monthly sales
-- and month-over-month growth.
-- ============================================================

WITH monthly_sales AS (
    SELECT
        Branch,
        DATE_FORMAT(Date_sale, '%Y-%m') AS sales_month,
        SUM(Total) AS monthly_sales
    FROM walmartsales_1
    GROUP BY
        Branch,
        DATE_FORMAT(Date_sale, '%Y-%m')
),

sales_growth AS (
    SELECT
        Branch,
        sales_month,
        monthly_sales,
        LAG(monthly_sales) OVER (
            PARTITION BY Branch
            ORDER BY sales_month
        ) AS previous_month_sales
    FROM monthly_sales
),

growth_with_rank AS (
    SELECT
        Branch,
        sales_month,
        monthly_sales,
        previous_month_sales,
        ROW_NUMBER() OVER (
            PARTITION BY Branch
            ORDER BY sales_month
        ) AS first_month_rank,
        ROW_NUMBER() OVER (
            PARTITION BY Branch
            ORDER BY sales_month DESC
        ) AS last_month_rank
    FROM sales_growth
),

branch_growth AS (
    SELECT
        Branch,
        ROUND(AVG(
            CASE
                WHEN previous_month_sales IS NOT NULL
                     AND previous_month_sales <> 0
                THEN (monthly_sales - previous_month_sales)
                     / previous_month_sales * 100
            END
        ), 2) AS average_monthly_growth_percentage,
        MAX(CASE WHEN first_month_rank = 1 THEN sales_month END) AS first_month,
        MAX(CASE WHEN first_month_rank = 1 THEN monthly_sales END) AS first_month_sales,
        MAX(CASE WHEN last_month_rank = 1 THEN sales_month END) AS last_month,
        MAX(CASE WHEN last_month_rank = 1 THEN monthly_sales END) AS last_month_sales
    FROM growth_with_rank
    GROUP BY Branch
)

SELECT
    Branch,
    first_month,
    ROUND(first_month_sales, 2) AS first_month_sales,
    last_month,
    ROUND(last_month_sales, 2) AS last_month_sales,
    average_monthly_growth_percentage,
    ROUND(
        (last_month_sales - first_month_sales)
        / NULLIF(first_month_sales, 0) * 100,
        2
    ) AS overall_growth_percentage
FROM branch_growth
ORDER BY overall_growth_percentage DESC;


-- ============================================================
-- 2. Most Profitable Product Line by Branch
-- Identify the product line generating the highest gross income
-- for each branch.
-- ============================================================

WITH product_profit AS (
    SELECT
        Branch,
        Product_line,
        SUM(gross_income) AS total_gross_income,
        SUM(cogs) AS total_cogs
    FROM walmartsales_1
    GROUP BY
        Branch,
        Product_line
),

ranked_products AS (
    SELECT
        Branch,
        Product_line,
        ROUND(total_gross_income, 2) AS total_gross_income,
        ROUND(total_cogs, 2) AS total_cogs,
        RANK() OVER (
            PARTITION BY Branch
            ORDER BY total_gross_income DESC
        ) AS profit_rank
    FROM product_profit
)

SELECT
    Branch,
    Product_line,
    total_gross_income,
    total_cogs
FROM ranked_products
WHERE profit_rank = 1
ORDER BY Branch, Product_line;


-- ============================================================
-- 3. Customer Segmentation Based on Spending Patterns
-- Segment customers into High, Medium, and Low spending groups
-- using total and average purchase amounts.
-- ============================================================

WITH customer_spending AS (
    SELECT
        Customer_ID,
        SUM(Total) AS total_spending,
        AVG(Total) AS average_spending,
        COUNT(*) AS number_of_purchases
    FROM walmartsales_1
    GROUP BY Customer_ID
),

benchmarks AS (
    SELECT
        AVG(total_spending) AS overall_avg_total,
        AVG(average_spending) AS overall_avg_spending
    FROM customer_spending
)

SELECT
    c.Customer_ID,
    ROUND(c.total_spending, 2) AS total_spending,
    ROUND(c.average_spending, 2) AS average_spending,
    c.number_of_purchases,
    CASE
        WHEN c.total_spending >= b.overall_avg_total
             AND c.average_spending >= b.overall_avg_spending
            THEN 'High'
        WHEN c.total_spending < b.overall_avg_total
             AND c.average_spending < b.overall_avg_spending
            THEN 'Low'
        ELSE 'Medium'
    END AS spending_category
FROM customer_spending c
CROSS JOIN benchmarks b
ORDER BY c.total_spending DESC;


-- ============================================================
-- 4. Detection of Unusual Sales Transactions
-- Identify transactions that are more than two standard deviations
-- away from the average sales value within their product line.
-- ============================================================

WITH product_stats AS (
    SELECT
        Product_line,
        AVG(Total) AS average_sales,
        STDDEV(Total) AS sales_stddev
    FROM walmartsales_1
    GROUP BY Product_line
)

SELECT
    w.Invoice_ID,
    w.Branch,
    w.Product_line,
    w.Total AS sales_amount,
    ROUND(p.average_sales, 2) AS average_sales,
    ROUND(p.sales_stddev, 2) AS sales_stddev,
    CASE
        WHEN w.Total > p.average_sales + (2 * p.sales_stddev)
            THEN 'High Anomaly'
        WHEN w.Total < p.average_sales - (2 * p.sales_stddev)
            THEN 'Low Anomaly'
    END AS anomaly_type
FROM walmartsales_1 w
JOIN product_stats p
    ON w.Product_line = p.Product_line
WHERE
    w.Total > p.average_sales + (2 * p.sales_stddev)
    OR w.Total < p.average_sales - (2 * p.sales_stddev)
ORDER BY w.Product_line, w.Total DESC;


-- ============================================================
-- 5. Preferred Payment Method in Each City
-- Identify the most frequently used payment method in each city.
-- ============================================================

WITH payment_counts AS (
    SELECT
        City,
        Payment,
        COUNT(Invoice_ID) AS transaction_count
    FROM walmartsales_1
    GROUP BY City, Payment
),

ranked_payments AS (
    SELECT
        City,
        Payment,
        transaction_count,
        RANK() OVER (
            PARTITION BY City
            ORDER BY transaction_count DESC
        ) AS payment_rank
    FROM payment_counts
)

SELECT
    City,
    Payment,
    transaction_count
FROM ranked_payments
WHERE payment_rank = 1
ORDER BY City, Payment;


-- ============================================================
-- 6. Gender-wise Monthly Sales Analysis
-- Analyze monthly sales distribution by gender.
-- ============================================================

SELECT
    DATE_FORMAT(Date_sale, '%Y-%m') AS sales_month,
    Gender,
    ROUND(SUM(Total), 2) AS monthly_sales
FROM walmartsales_1
GROUP BY
    DATE_FORMAT(Date_sale, '%Y-%m'),
    Gender
ORDER BY sales_month, Gender;


-- ============================================================
-- 7. Product Line Preference by Customer Type
-- Identify the most frequently purchased product line for Member
-- and Normal customers.
-- ============================================================

WITH product_preferences AS (
    SELECT
        Customer_type,
        Product_line,
        COUNT(Invoice_ID) AS transaction_count
    FROM walmartsales_1
    GROUP BY
        Customer_type,
        Product_line
),

ranked_preferences AS (
    SELECT
        Customer_type,
        Product_line,
        transaction_count,
        RANK() OVER (
            PARTITION BY Customer_type
            ORDER BY transaction_count DESC
        ) AS preference_rank
    FROM product_preferences
)

SELECT
    Customer_type,
    Product_line,
    transaction_count
FROM ranked_preferences
WHERE preference_rank = 1
ORDER BY Customer_type, Product_line;


-- ============================================================
-- 8. Repeat Customer Identification
-- Identify customers who made another purchase within 30 days
-- of their previous purchase.
-- ============================================================

WITH customer_purchases AS (
    SELECT
        Customer_ID,
        Invoice_ID,
        Date_sale AS purchase_date,
        LAG(Date_sale) OVER (
            PARTITION BY Customer_ID
            ORDER BY Date_sale, Invoice_ID
        ) AS previous_purchase_date
    FROM walmartsales_1
),

repeat_purchases AS (
    SELECT
        Customer_ID,
        Invoice_ID,
        purchase_date,
        previous_purchase_date,
        DATEDIFF(purchase_date, previous_purchase_date) AS days_between_purchases
    FROM customer_purchases
    WHERE previous_purchase_date IS NOT NULL
)

SELECT
    Customer_ID,
    COUNT(*) AS repeat_purchases_within_30_days,
    MIN(days_between_purchases) AS minimum_days_between_purchases
FROM repeat_purchases
WHERE days_between_purchases BETWEEN 0 AND 30
GROUP BY Customer_ID
ORDER BY repeat_purchases_within_30_days DESC, Customer_ID;


-- ============================================================
-- 9. Top 5 Customers by Revenue Contribution
-- Identify the five customers generating the highest total revenue.
-- ============================================================

SELECT
    Customer_ID,
    ROUND(SUM(Total), 2) AS total_revenue
FROM walmartsales_1
GROUP BY Customer_ID
ORDER BY total_revenue DESC
LIMIT 5;


-- ============================================================
-- 10. Weekly Sales Trend Analysis
-- Compare total sales across days of the week.
-- ============================================================

SELECT
    DAYNAME(Date_sale) AS day_of_week,
    ROUND(SUM(Total), 2) AS total_sales
FROM walmartsales_1
GROUP BY
    DAYNAME(Date_sale),
    DAYOFWEEK(Date_sale)
ORDER BY DAYOFWEEK(Date_sale);


-- ============================================================
-- End of Walmart Sales Analysis
-- ============================================================
