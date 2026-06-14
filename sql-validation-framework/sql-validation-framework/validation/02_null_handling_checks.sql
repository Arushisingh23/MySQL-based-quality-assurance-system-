-- ============================================================
-- VALIDATION MODULE 2: NULL Handling Checks
-- Purpose: Catch missing values in critical fields that would
--          cause incorrect aggregations or silent data loss
-- ============================================================
USE enterprise_archive;

-- ------------------------------------------------------------
-- CHECK 2.1: NULL customer_name in order summary view
-- ------------------------------------------------------------
SELECT
    'CHECK 2.1 - NULL customer_name in vw_order_summary' AS check_name,
    COUNT(*) AS null_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM vw_order_summary
WHERE customer_name IS NULL;


-- ------------------------------------------------------------
-- CHECK 2.2: NULL or zero net_amount (would distort revenue)
-- ------------------------------------------------------------
SELECT
    'CHECK 2.2 - NULL or zero net_amount in vw_order_summary' AS check_name,
    order_id,
    customer_name,
    net_amount
FROM vw_order_summary
WHERE net_amount IS NULL OR net_amount = 0;
-- Zero rows = PASS


-- ------------------------------------------------------------
-- CHECK 2.3: Payments table COALESCE check
-- Confirm vw_invoice_payment_status handles invoices with no payments
-- Expected: actual_paid = 0, payment_status = 'UNPAID' (not NULL)
-- ------------------------------------------------------------
SELECT
    'CHECK 2.3 - Invoices with no payments handled correctly' AS check_name,
    invoice_id,
    total_amount,
    actual_paid,
    payment_status
FROM vw_invoice_payment_status
WHERE actual_paid = 0;
-- Should show unpaid invoices with payment_status = 'UNPAID', not NULL


-- ------------------------------------------------------------
-- CHECK 2.4: NULL discount handling in order_items
-- discount_pct defaults to 0 but verify no NULLs slipped in
-- ------------------------------------------------------------
SELECT
    'CHECK 2.4 - NULL discount_pct in order_items' AS check_name,
    COUNT(*) AS null_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL — update default' END AS result
FROM order_items
WHERE discount_pct IS NULL;


-- ------------------------------------------------------------
-- CHECK 2.5: NULL region or sales_rep in sales performance view
-- ------------------------------------------------------------
SELECT
    'CHECK 2.5 - NULL sales_rep or region in vw_sales_rep_performance' AS check_name,
    sales_rep,
    region,
    order_month
FROM vw_sales_rep_performance
WHERE sales_rep IS NULL OR region IS NULL;
-- Zero rows = PASS
