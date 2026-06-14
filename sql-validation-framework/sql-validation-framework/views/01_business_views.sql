-- ============================================================
-- Business Views
-- Simulates AI-generated SQL views that need validation
-- ============================================================
USE enterprise_archive;

-- ------------------------------------------------------------
-- VIEW 1: vw_order_summary
-- Full order details with customer and revenue calculation
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
    so.order_id,
    so.order_date,
    so.status,
    so.region,
    so.sales_rep,
    c.customer_id,
    c.customer_name,
    c.country,
    c.segment,
    COUNT(oi.item_id)                                           AS line_item_count,
    SUM(oi.quantity * oi.unit_price)                            AS gross_amount,
    SUM(oi.quantity * oi.unit_price * oi.discount_pct / 100)   AS total_discount,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS net_amount
FROM sales_orders so
JOIN customers c  ON so.customer_id = c.customer_id
JOIN order_items oi ON so.order_id  = oi.order_id
WHERE c.is_active = 1
GROUP BY
    so.order_id, so.order_date, so.status, so.region, so.sales_rep,
    c.customer_id, c.customer_name, c.country, c.segment;


-- ------------------------------------------------------------
-- VIEW 2: vw_invoice_payment_status
-- Joins invoices with payments; flags unpaid and partially paid
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_invoice_payment_status AS
SELECT
    i.invoice_id,
    i.order_id,
    i.invoice_date,
    i.total_amount,
    i.paid                              AS marked_paid,
    COALESCE(SUM(p.amount_paid), 0)    AS actual_paid,
    i.total_amount - COALESCE(SUM(p.amount_paid), 0) AS outstanding_balance,
    CASE
        WHEN COALESCE(SUM(p.amount_paid), 0) = 0              THEN 'UNPAID'
        WHEN COALESCE(SUM(p.amount_paid), 0) < i.total_amount THEN 'PARTIAL'
        WHEN COALESCE(SUM(p.amount_paid), 0) >= i.total_amount THEN 'PAID'
    END                                 AS payment_status
FROM invoices i
LEFT JOIN payments p ON i.invoice_id = p.invoice_id
GROUP BY i.invoice_id, i.order_id, i.invoice_date, i.total_amount, i.paid;


-- ------------------------------------------------------------
-- VIEW 3: vw_customer_revenue
-- Per-customer revenue aggregation with ranking (window function)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_revenue AS
SELECT
    c.customer_id,
    c.customer_name,
    c.country,
    c.segment,
    COUNT(DISTINCT so.order_id)     AS total_orders,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS lifetime_revenue,
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) DESC)
                                    AS revenue_rank,
    RANK() OVER (PARTITION BY c.country
                 ORDER BY SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) DESC)
                                    AS country_rank
FROM customers c
JOIN sales_orders so  ON c.customer_id = so.customer_id
JOIN order_items oi   ON so.order_id   = oi.order_id
WHERE c.is_active = 1
  AND so.status NOT IN ('CANCELLED')
GROUP BY c.customer_id, c.customer_name, c.country, c.segment;


-- ------------------------------------------------------------
-- VIEW 4: vw_product_sales_analysis
-- Product-level sales performance; excludes discontinued products
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_product_sales_analysis AS
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price                                AS list_price,
    COUNT(oi.item_id)                           AS times_ordered,
    SUM(oi.quantity)                            AS total_units_sold,
    AVG(oi.discount_pct)                        AS avg_discount_pct,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS total_revenue,
    LAG(SUM(oi.quantity), 1) OVER (
        PARTITION BY p.product_id
        ORDER BY YEAR(so.order_date)
    )                                           AS prev_year_units
FROM products p
JOIN order_items oi   ON p.product_id  = oi.product_id
JOIN sales_orders so  ON oi.order_id   = so.order_id
WHERE p.is_discontinued = 0
  AND so.status NOT IN ('CANCELLED')
GROUP BY p.product_id, p.product_name, p.category, p.unit_price, YEAR(so.order_date);


-- ------------------------------------------------------------
-- VIEW 5: vw_sales_rep_performance
-- Monthly KPIs per sales rep using window functions
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_sales_rep_performance AS
SELECT
    so.sales_rep,
    so.region,
    DATE_FORMAT(so.order_date, '%Y-%m')         AS order_month,
    COUNT(DISTINCT so.order_id)                 AS orders_closed,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)) AS monthly_revenue,
    SUM(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)))
        OVER (PARTITION BY so.sales_rep ORDER BY DATE_FORMAT(so.order_date, '%Y-%m')
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                                AS cumulative_revenue
FROM sales_orders so
JOIN order_items oi ON so.order_id = oi.order_id
WHERE so.status NOT IN ('CANCELLED', 'OPEN')
GROUP BY so.sales_rep, so.region, DATE_FORMAT(so.order_date, '%Y-%m');
