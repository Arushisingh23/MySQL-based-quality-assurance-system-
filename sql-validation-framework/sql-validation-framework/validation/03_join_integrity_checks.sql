-- ============================================================
-- VALIDATION MODULE 3: Join Correctness & Referential Integrity
-- Purpose: Detect wrong join types, orphaned records, and
--          cross-table consistency violations
-- ============================================================
USE enterprise_archive;

-- ------------------------------------------------------------
-- CHECK 3.1: Orphaned order_items (no matching order)
-- Catches INNER JOIN hiding records that should appear
-- ------------------------------------------------------------
SELECT
    'CHECK 3.1 - Orphaned order_items' AS check_name,
    oi.item_id,
    oi.order_id
FROM order_items oi
LEFT JOIN sales_orders so ON oi.order_id = so.order_id
WHERE so.order_id IS NULL;
-- Zero rows = PASS


-- ------------------------------------------------------------
-- CHECK 3.2: Verify CANCELLED orders are excluded from revenue views
-- They should NOT appear in vw_customer_revenue or vw_product_sales_analysis
-- ------------------------------------------------------------
SELECT
    'CHECK 3.2 - Cancelled orders leaking into vw_customer_revenue' AS check_name,
    vr.customer_id,
    vr.customer_name,
    so.order_id,
    so.status
FROM vw_customer_revenue vr
JOIN sales_orders so ON vr.customer_id = so.customer_id
WHERE so.status = 'CANCELLED';
-- Zero rows = PASS


-- ------------------------------------------------------------
-- CHECK 3.3: Discontinued products must not appear in product sales view
-- ------------------------------------------------------------
SELECT
    'CHECK 3.3 - Discontinued products in vw_product_sales_analysis' AS check_name,
    p.product_id,
    p.product_name,
    p.is_discontinued
FROM vw_product_sales_analysis vpa
JOIN products p ON vpa.product_id = p.product_id
WHERE p.is_discontinued = 1;
-- Zero rows = PASS


-- ------------------------------------------------------------
-- CHECK 3.4: Invoice amount vs computed order net_amount
-- Critical: invoiced amount should match sum of order line items
-- ------------------------------------------------------------
SELECT
    'CHECK 3.4 - Invoice vs order net_amount mismatch' AS check_name,
    i.invoice_id,
    i.order_id,
    i.total_amount              AS invoice_amount,
    os.net_amount               AS computed_net_amount,
    ABS(i.total_amount - os.net_amount) AS variance
FROM invoices i
JOIN vw_order_summary os ON i.order_id = os.order_id
WHERE ABS(i.total_amount - os.net_amount) > 0.01;  -- 1 cent tolerance
-- Zero rows = PASS (any row = data quality issue to investigate)


-- ------------------------------------------------------------
-- CHECK 3.5: Payment amount exceeds invoice total (overpayment)
-- ------------------------------------------------------------
SELECT
    'CHECK 3.5 - Overpayments detected' AS check_name,
    invoice_id,
    total_amount,
    actual_paid,
    outstanding_balance
FROM vw_invoice_payment_status
WHERE actual_paid > total_amount;
-- Zero rows = PASS


-- ------------------------------------------------------------
-- CHECK 3.6: Inactive customer records leaking into views
-- ------------------------------------------------------------
SELECT
    'CHECK 3.6 - Inactive customers in vw_order_summary' AS check_name,
    os.customer_id,
    os.customer_name,
    c.is_active
FROM vw_order_summary os
JOIN customers c ON os.customer_id = c.customer_id
WHERE c.is_active = 0;
-- Zero rows = PASS
