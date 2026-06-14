-- ============================================================
-- VALIDATION MODULE 4: Query Performance Analysis
-- Purpose: Identify missing indexes, full table scans, and
--          expensive join operations before deployment
-- ============================================================
USE enterprise_archive;

-- ------------------------------------------------------------
-- STEP 1: Recommended indexes for this schema
-- Run once after schema creation
-- ------------------------------------------------------------

-- Foreign key join indexes
CREATE INDEX IF NOT EXISTS idx_orders_customer   ON sales_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_items_order       ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_items_product     ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_invoices_order    ON invoices(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_invoice  ON payments(invoice_id);

-- Filter indexes (commonly used in WHERE clauses)
CREATE INDEX IF NOT EXISTS idx_orders_status     ON sales_orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_date       ON sales_orders(order_date);
CREATE INDEX IF NOT EXISTS idx_customers_active  ON customers(is_active);
CREATE INDEX IF NOT EXISTS idx_products_disc     ON products(is_discontinued);

-- Composite index for sales rep performance view
CREATE INDEX IF NOT EXISTS idx_orders_rep_date   ON sales_orders(sales_rep, order_date);


-- ------------------------------------------------------------
-- STEP 2: EXPLAIN plan checks
-- Run these and verify type is NOT 'ALL' (full table scan)
-- Acceptable types: ref, eq_ref, range, index, const
-- ------------------------------------------------------------

-- Check vw_order_summary join plan
EXPLAIN
SELECT order_id, customer_name, net_amount
FROM vw_order_summary
WHERE region = 'EMEA'
ORDER BY net_amount DESC;

-- Check vw_customer_revenue aggregation plan
EXPLAIN
SELECT customer_name, lifetime_revenue, revenue_rank
FROM vw_customer_revenue
WHERE segment = 'Enterprise'
ORDER BY revenue_rank;

-- Check vw_invoice_payment_status LEFT JOIN plan
EXPLAIN
SELECT invoice_id, payment_status, outstanding_balance
FROM vw_invoice_payment_status
WHERE payment_status = 'UNPAID';


-- ------------------------------------------------------------
-- STEP 3: Identify slow patterns — correlated subqueries
-- Replace with JOIN if found in AI-generated views
-- ------------------------------------------------------------

-- SLOW pattern (correlated subquery — avoid):
-- SELECT *, (SELECT SUM(amount_paid) FROM payments WHERE invoice_id = i.invoice_id)
-- FROM invoices i;

-- FAST pattern (already used in our view — LEFT JOIN + GROUP BY):
EXPLAIN
SELECT i.invoice_id, COALESCE(SUM(p.amount_paid), 0) AS actual_paid
FROM invoices i
LEFT JOIN payments p ON i.invoice_id = p.invoice_id
GROUP BY i.invoice_id;


-- ------------------------------------------------------------
-- STEP 4: Row estimate sanity check for large datasets
-- Expected ratios help catch cartesian join bugs
-- ------------------------------------------------------------
SELECT
    'order_items to sales_orders ratio' AS metric,
    ROUND(
        (SELECT COUNT(*) FROM order_items) /
        (SELECT COUNT(*) FROM sales_orders), 2
    ) AS ratio,
    '~1.5–3 expected for typical enterprise data' AS benchmark;

SELECT
    'invoices to INVOICED orders ratio' AS metric,
    ROUND(
        (SELECT COUNT(*) FROM invoices) /
        NULLIF((SELECT COUNT(*) FROM sales_orders WHERE status = 'INVOICED'), 0), 2
    ) AS ratio,
    '~1.0 expected (1 invoice per invoiced order)' AS benchmark;
