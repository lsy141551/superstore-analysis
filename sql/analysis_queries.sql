-- ============================================================
-- Superstore 数据分析 — SQL 等效查询
-- 演示 SQL 能力：聚合、窗口函数、CTE、RFM、留存分析
-- ============================================================

-- ====== 1. 月度销售 & 利润趋势 ======
SELECT
    strftime('%Y', order_date) AS year,
    strftime('%m', order_date) AS month,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY year, month
ORDER BY year, month;


-- ====== 2. 品类帕累托分析 (累计占比) ======
WITH subcat_sales AS (
    SELECT
        sub_category,
        SUM(sales) AS total_sales,
        SUM(profit) AS total_profit
    FROM orders
    GROUP BY sub_category
),
ranked AS (
    SELECT
        *,
        SUM(total_sales) OVER (ORDER BY total_sales DESC) AS running_sales,
        SUM(total_sales) OVER () AS grand_total
    FROM subcat_sales
)
SELECT
    sub_category,
    ROUND(total_sales, 0) AS sales,
    ROUND(total_profit, 0) AS profit,
    ROUND(total_sales / grand_total * 100, 1) AS sales_pct,
    ROUND(running_sales / grand_total * 100, 1) AS cumulative_pct,
    CASE
        WHEN running_sales / grand_total <= 0.8 THEN 'Top 80%'
        ELSE 'Bottom 20%'
    END AS pareto_group
FROM ranked
ORDER BY total_sales DESC;


-- ====== 3. 区域表现对比 ======
SELECT
    region,
    state,
    COUNT(DISTINCT order_id) AS order_count,
    COUNT(DISTINCT customer_id) AS customer_count,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY region, state
ORDER BY total_sales DESC;


-- ====== 4. 折扣层级分析 ======
SELECT
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.1 THEN 'Low (0-10%)'
        WHEN discount <= 0.3 THEN 'Medium (10-30%)'
        ELSE 'High (>30%)'
    END AS discount_tier,
    COUNT(*) AS line_items,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(SUM(sales), 0) AS total_sales,
    ROUND(SUM(profit), 0) AS total_profit,
    ROUND(AVG(profit / NULLIF(sales, 0)) * 100, 2) AS avg_margin_pct,
    ROUND(SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
        AS loss_rate_pct
FROM orders
GROUP BY discount_tier
ORDER BY MIN(discount);


-- ====== 5. 运输方式分析 ======
SELECT
    ship_mode,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(AVG(JULIANDAY(ship_date) - JULIANDAY(order_date)), 1) AS avg_processing_days,
    ROUND(SUM(sales), 0) AS total_sales,
    ROUND(AVG(profit / NULLIF(sales, 0)) * 100, 2) AS avg_profit_margin_pct
FROM orders
GROUP BY ship_mode
ORDER BY order_count DESC;


-- ====== 6. RFM 分析 ======
WITH rfm_base AS (
    SELECT
        customer_id,
        JULIANDAY((SELECT MAX(order_date) FROM orders) + 1)
            - JULIANDAY(MAX(order_date)) AS recency_days,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(sales) AS monetary
    FROM orders
    GROUP BY customer_id
),
rfm_scored AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,  -- 越低越好 → 反转
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,      -- 越高越好
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score        -- 越高越好
    FROM rfm_base
)
SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary, 0) AS monetary,
    r_score, f_score, m_score,
    r_score + f_score + m_score AS rfm_total_score,
    CASE
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score < 3 THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score < 3 AND m_score >= 3 THEN 'Big Spenders'
        WHEN r_score < 3 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
        WHEN r_score < 3 AND f_score < 3 AND m_score < 3 THEN 'Lost'
        ELSE 'Others'
    END AS customer_segment
FROM rfm_scored
ORDER BY rfm_total_score DESC;


-- ====== 7. 月度新客户 & 留存分析 ======
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    GROUP BY customer_id
),
monthly_cohort AS (
    SELECT
        o.customer_id,
        strftime('%Y-%m', f.first_order_date) AS cohort_month,
        strftime('%Y-%m', o.order_date) AS activity_month
    FROM orders o
    JOIN first_purchase f ON o.customer_id = f.customer_id
)
SELECT
    cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN activity_month = cohort_month
        THEN customer_id END) AS month_0,
    COUNT(DISTINCT CASE WHEN activity_month = strftime('%Y-%m',
        DATE(cohort_month || '-01', '+1 month')) THEN customer_id END) AS month_1,
    COUNT(DISTINCT CASE WHEN activity_month = strftime('%Y-%m',
        DATE(cohort_month || '-01', '+3 months')) THEN customer_id END) AS month_3,
    COUNT(DISTINCT CASE WHEN activity_month = strftime('%Y-%m',
        DATE(cohort_month || '-01', '+6 months')) THEN customer_id END) AS month_6
FROM monthly_cohort
GROUP BY cohort_month
ORDER BY cohort_month;


-- ====== 8. 加盟/交叉销售分析 ======
-- 哪些品类经常被一起购买？
WITH order_categories AS (
    SELECT
        order_id,
        category
    FROM orders
    GROUP BY order_id, category  -- 去重：一个订单中同一品类多行只算一次
)
SELECT
    a.category AS category_1,
    b.category AS category_2,
    COUNT(DISTINCT a.order_id) AS co_occurrence_count
FROM order_categories a
JOIN order_categories b
    ON a.order_id = b.order_id
    AND a.category < b.category  -- 避免重复和自我匹配
GROUP BY a.category, b.category
ORDER BY co_occurrence_count DESC;


-- ====== 9. YoY 同比增长 ======
WITH yearly AS (
    SELECT
        strftime('%Y', order_date) AS year,
        SUM(sales) AS total_sales,
        SUM(profit) AS total_profit,
        COUNT(DISTINCT order_id) AS order_count
    FROM orders
    GROUP BY year
)
SELECT
    year,
    ROUND(total_sales, 0) AS sales,
    ROUND(total_profit, 0) AS profit,
    order_count,
    ROUND(total_sales / LAG(total_sales) OVER (ORDER BY year) * 100 - 100, 2)
        AS sales_yoy_growth_pct,
    ROUND(total_profit / LAG(total_profit) OVER (ORDER BY year) * 100 - 100, 2)
        AS profit_yoy_growth_pct
FROM yearly
ORDER BY year;


-- ====== 10. Top N 产品 (每个品类 Top 3) ======
WITH product_sales AS (
    SELECT
        category,
        product_name,
        SUM(sales) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(sales) DESC) AS rank
    FROM orders
    GROUP BY category, product_name
)
SELECT category, product_name, ROUND(total_sales, 0) AS sales, rank
FROM product_sales
WHERE rank <= 3
ORDER BY category, rank;
