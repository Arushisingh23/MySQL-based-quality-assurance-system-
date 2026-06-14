-- ============================================================
-- VALIDATION MODULE 1: Row Count & Completeness Checks
-- Purpose: Ensure no records are silently dropped or duplicated
--          when views join multiple tables
-- ============================================================
USE enterprise_archive;

-- ------------------------------------------------------------
-- CHECK 1.1: Order count in source vs view (no row loss)
-- Expected: counts match
-- ------------------------------------------------------------
SELECT
    'CHECK 1.1 - Order row count' AS check_name,
    (SELECT COUNT(*) FROM sales_orders WHERE customer_id IN
        (SELECT customer_id FROM customers WHERE is_active = 1)) AS source_count,
    (SELECT COUNT(DISTINCT order_id) FROM vw_order_summary)      AS view_count,
    CASE
        WHEN (SELECT COUNT(*) FROM sales_orders WHERE customer_id IN
              (SELECT customer_id FROM customers WHERE is_active = 1))
           = (SELECT COUNT(DISTINCT order_id) FROM vw_order_summary)
        THEN 'PASS'
        ELSE 'FAIL — row count mismatch'
    END AS result;


-- ------------------------------------------------------------
-- CHECK 1.2: Every active customer with orders appears in revenue view
-- Expected: no active customer with non-cancelled orders missing
-- ------------------------------------------------------------
SELECT
    'CHECK 1.2 - Customer coverage in revenue view' AS check_name,
    c.customer_id,
    c.customer_name,
    'MISSING from vw_customer_revenue' AS result
FROM customers c
WHERE c.is_active = 1
  AND EXISTS (
      SELECT 1 FROM sales_orders so
      WHERE so.customer_id = c.customer_id
        AND so.status NOT IN ('CANCELLED')
  )
  AND c.customer_id NOT IN (SELECT customer_id FROM vw_customer_revenue);
-- Zero rows = PASS


-- ------------------------------------------------------------
-- CHECK 1.3: Invoice count — every INVOICED order has an invoice
-- Expected: zero rows returned
-- ------------------------------------------------------------
SELECT
    'CHECK 1.3 - Orphaned INVOICED orders (no invoice record)' AS check_name,
    so.order_id,
    so.status,
    so.order_date
FROM sales_orders so
WHERE so.status = 'INVOICED'
  AND so.order_id NOT IN (SELECT order_id FROM invoices);
-- Zero rows = PASS


-- ------------------------------------------------------------
-- CHECK 1.4: Detect duplicate order_ids in vw_order_summary
-- Expected: zero rows
-- ------------------------------------------------------------
SELECT
    'CHECK 1.4 - Duplicate order_ids in vw_order_summary' AS check_name,
    order_id,
    COUNT(*) AS occurrences
FROM vw_order_summary
GROUP BY order_id
HAVING COUNT(*) > 1;
-- Zero rows = PASS
