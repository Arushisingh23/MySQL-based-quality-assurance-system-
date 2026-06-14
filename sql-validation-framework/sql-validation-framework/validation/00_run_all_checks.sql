-- ============================================================
-- MASTER VALIDATION RUNNER
-- Run this file to execute all validation checks in sequence
-- and produce a consolidated QA report
-- ============================================================
USE enterprise_archive;

-- Results summary table (session-scoped)
CREATE TEMPORARY TABLE IF NOT EXISTS validation_log (
    check_id    INT AUTO_INCREMENT PRIMARY KEY,
    module      VARCHAR(60),
    check_name  VARCHAR(120),
    status      ENUM('PASS', 'FAIL', 'WARNING', 'INFO'),
    detail      VARCHAR(255),
    run_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ---- MODULE 1: Row Count Checks ----

INSERT INTO validation_log (module, check_name, status, detail)
SELECT
    'M1 - Row Count',
    'Order count: source vs vw_order_summary',
    CASE
        WHEN (SELECT COUNT(*) FROM sales_orders
              WHERE customer_id IN (SELECT customer_id FROM customers WHERE is_active = 1))
           = (SELECT COUNT(DISTINCT order_id) FROM vw_order_summary)
        THEN 'PASS' ELSE 'FAIL'
    END,
    CONCAT('Source: ',
        (SELECT COUNT(*) FROM sales_orders
         WHERE customer_id IN (SELECT customer_id FROM customers WHERE is_active = 1)),
        ' | View: ', (SELECT COUNT(DISTINCT order_id) FROM vw_order_summary));

INSERT INTO validation_log (module, check_name, status, detail)
SELECT
    'M1 - Row Count',
    'Duplicate order_ids in vw_order_summary',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(COUNT(*), ' duplicate order_id(s) found')
FROM (
    SELECT order_id FROM vw_order_summary GROUP BY order_id HAVING COUNT(*) > 1
) dupes;

INSERT INTO validation_log (module, check_name, status, detail)
SELECT
    'M1 - Row Count',
    'Orphaned INVOICED orders (no invoice record)',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(COUNT(*), ' INVOICED order(s) missing invoice record')
FROM sales_orders
WHERE status = 'INVOICED'
  AND order_id NOT IN (SELECT order_id FROM invoices);


-- ---- MODULE 2: NULL Handling ----

INSERT INTO validation_log (module, check_name, status, detail)
SELECT
    'M2 - NULL Handling',
    'NULL customer_name in vw_order_summary',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(COUNT(*), ' NULL customer_name row(s)')
FROM vw_order_summary WHERE customer_name IS NULL;

INSERT INTO validation_log (module, check_name, status, detail)
SELECT
    'M2 - NULL Handling',
    'NULL or zero net_amount in vw_order_summary',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'WARNING' END,
    CONCAT(COUNT(*), ' order(s) with NULL/zero net_amount')
FROM vw_order_summary WHERE net_amount IS NULL OR net_amount = 0;

INSERT INTO validation_log (module, check_name, status, detail)
SELECT
    'M2 - NULL Handling',
    'NULL payment_status in vw_invoice_payment_status',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(COUNT(*), ' invoice(s) with NULL payment_status')
FROM vw_invoice_payment_status WHERE payment_status IS NULL;


-- ---- MODULE 3: Join Integrity ----

INSERT INTO validation_log (module, check_name, status, detail)
SELECT
    'M3 - Join Integrity',
    'Orphaned order_items (no parent order)',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(COUNT(*), ' orphaned item(s)')
FROM order_items oi
LEFT JOIN sales_orders so ON oi.order_id = so.order_id
WHERE so.order_id IS NULL;

INSERT INTO validation_log (module, check_name, status, detail)
SELECT
    'M3 - Join Integrity',
    'Discontinued products in vw_product_sales_analysis',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(COUNT(*), ' discontinued product(s) found in view')
FROM vw_product_sales_analysis vpa
JOIN products p ON vpa.product_id = p.product_id
WHERE p.is_discontinued = 1;

INSERT INTO validation_log (module, check_name, status, detail)
SELECT
    'M3 - Join Integrity',
    'Inactive customers leaking into vw_order_summary',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END,
    CONCAT(COUNT(*), ' inactive customer row(s) found in view')
FROM vw_order_summary os
JOIN customers c ON os.customer_id = c.customer_id
WHERE c.is_active = 0;

INSERT INTO validation_log (module, check_name, status, detail)
SELECT
    'M3 - Join Integrity',
    'Invoice vs computed order net_amount mismatch',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'WARNING' END,
    CONCAT(COUNT(*), ' invoice(s) with >0.01 variance vs order total')
FROM invoices i
JOIN vw_order_summary os ON i.order_id = os.order_id
WHERE ABS(i.total_amount - os.net_amount) > 0.01;

INSERT INTO validation_log (module, check_name, status, detail)
SELECT
    'M3 - Join Integrity',
    'Overpayments detected in vw_invoice_payment_status',
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'WARNING' END,
    CONCAT(COUNT(*), ' overpaid invoice(s)')
FROM vw_invoice_payment_status
WHERE actual_paid > total_amount;


-- ============================================================
-- FINAL REPORT
-- ============================================================
SELECT
    check_id,
    module,
    check_name,
    status,
    detail,
    run_at
FROM validation_log
ORDER BY check_id;

-- Summary line
SELECT
    COUNT(*)                                    AS total_checks,
    SUM(status = 'PASS')                        AS passed,
    SUM(status = 'FAIL')                        AS failed,
    SUM(status = 'WARNING')                     AS warnings,
    CONCAT(ROUND(SUM(status = 'PASS') / COUNT(*) * 100, 1), '%') AS pass_rate
FROM validation_log;
