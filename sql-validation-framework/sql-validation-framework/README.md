# SQL-Driven Data Validation Framework

A MySQL-based framework for validating SQL views against enterprise relational schemas — designed to mirror real-world data quality checks performed in legacy system archiving and ERP decommissioning projects.

---

## Project Overview

This project simulates a **legacy enterprise sales & order management system** (modeled after SAP SD table structures like `VBAK`/`VBAP`) and implements a layered SQL validation pipeline to verify the correctness of business views before deployment into production archive environments.

The validation framework checks:
- **Row count integrity** — no silent row loss or duplication after joins
- **NULL handling** — critical fields always contain valid values
- **Join correctness** — right join types used, no orphaned records, no unintended data leakage
- **Business rule enforcement** — cancelled orders excluded, discontinued products filtered, inactive records isolated
- **Financial consistency** — invoice totals reconcile against order line item calculations
- **Query performance** — index recommendations and EXPLAIN plan analysis

---

## Schema Design

```
customers
    │
    └── sales_orders ──── order_items ──── products
              │
              └── invoices ──── payments
```

| Table | Description | SAP Analogy |
|---|---|---|
| `customers` | Customer master data | KNA1 |
| `products` | Product/material master | MARA |
| `sales_orders` | Order header | VBAK |
| `order_items` | Order line items | VBAP |
| `invoices` | Billing documents | VBRK |
| `payments` | Payment records | BKPF |

---

## Project Structure

```
sql-validation-framework/
├── schema/
│   ├── 01_create_schema.sql      # Table definitions with FK constraints
│   └── 02_seed_data.sql          # Realistic enterprise test data
├── views/
│   └── 01_business_views.sql     # 5 business views (simulating AI-generated SQL)
├── validation/
│   ├── 00_run_all_checks.sql     # Master runner — produces consolidated report
│   ├── 01_row_count_checks.sql   # Row count & completeness validation
│   ├── 02_null_handling_checks.sql   # NULL value checks across all views
│   ├── 03_join_integrity_checks.sql  # Join correctness & referential integrity
│   └── 04_performance_checks.sql    # Index recommendations & EXPLAIN plans
└── README.md
```

---

## Views Implemented

| View | Description | Key Techniques |
|---|---|---|
| `vw_order_summary` | Full order details with revenue | Multi-table JOIN, aggregation |
| `vw_invoice_payment_status` | Payment tracking with status flags | LEFT JOIN, COALESCE, CASE |
| `vw_customer_revenue` | Customer revenue with ranking | Window functions (RANK, PARTITION BY) |
| `vw_product_sales_analysis` | Product KPIs excluding discontinued | Window functions (LAG) |
| `vw_sales_rep_performance` | Monthly rep KPIs with running totals | Cumulative SUM OVER |

---

## How to Run

### 1. Set up the database
```sql
mysql -u root -p < schema/01_create_schema.sql
mysql -u root -p < schema/02_seed_data.sql
```

### 2. Deploy the views
```sql
mysql -u root -p enterprise_archive < views/01_business_views.sql
```

### 3. Run full validation suite
```sql
mysql -u root -p enterprise_archive < validation/00_run_all_checks.sql
```

### 4. Run individual modules
```sql
-- Row count checks only
mysql -u root -p enterprise_archive < validation/01_row_count_checks.sql

-- NULL handling checks only
mysql -u root -p enterprise_archive < validation/02_null_handling_checks.sql

-- Join integrity only
mysql -u root -p enterprise_archive < validation/03_join_integrity_checks.sql

-- Performance analysis
mysql -u root -p enterprise_archive < validation/04_performance_checks.sql
```

---

## Sample Validation Output

```
+----+--------------------+-------------------------------------------+--------+----------------------------------------------+
| id | module             | check_name                                | status | detail                                       |
+----+--------------------+-------------------------------------------+--------+----------------------------------------------+
|  1 | M1 - Row Count     | Order count: source vs vw_order_summary   | PASS   | Source: 14 | View: 14                         |
|  2 | M1 - Row Count     | Duplicate order_ids in vw_order_summary   | PASS   | 0 duplicate order_id(s) found                |
|  3 | M1 - Row Count     | Orphaned INVOICED orders                  | PASS   | 0 INVOICED order(s) missing invoice record   |
|  4 | M2 - NULL Handling | NULL customer_name in vw_order_summary    | PASS   | 0 NULL customer_name row(s)                  |
|  5 | M2 - NULL Handling | NULL or zero net_amount                   | PASS   | 0 order(s) with NULL/zero net_amount         |
|  6 | M2 - NULL Handling | NULL payment_status in invoice view       | PASS   | 0 invoice(s) with NULL payment_status        |
|  7 | M3 - Join Integrity| Orphaned order_items                      | PASS   | 0 orphaned item(s)                           |
|  8 | M3 - Join Integrity| Discontinued products in product view     | PASS   | 0 discontinued product(s) found in view      |
|  9 | M3 - Join Integrity| Inactive customers in vw_order_summary    | PASS   | 0 inactive customer row(s) found             |
| 10 | M3 - Join Integrity| Invoice vs order net_amount mismatch      | WARNING| 8 invoice(s) with >0.01 variance             |
| 11 | M3 - Join Integrity| Overpayments detected                     | PASS   | 0 overpaid invoice(s)                        |
+----+--------------------+-------------------------------------------+--------+----------------------------------------------+

+---------------+--------+--------+----------+-----------+
| total_checks  | passed | failed | warnings | pass_rate |
+---------------+--------+--------+----------+-----------+
| 11            | 10     | 0      | 1        | 90.9%     |
+---------------+--------+--------+----------+-----------+
```

---

## Key Concepts Demonstrated

- **View validation methodology** — systematic checks before deploying SQL into production
- **LEFT JOIN vs INNER JOIN awareness** — understanding which join type silently drops records
- **COALESCE for NULL safety** — ensures aggregations on optional relationships don't produce NULLs
- **Window functions** — RANK, LAG, cumulative SUM OVER for analytical views
- **Financial reconciliation** — cross-checking invoice totals against computed line item sums
- **Index strategy** — covering indexes for FK columns, filter columns, and composite patterns
- **EXPLAIN plan reading** — verifying no full table scans on large joins

---

## Relevance to Enterprise Archiving

In legacy system decommissioning (e.g. SAP ERP archiving), this type of validation framework is applied before migrating data into archive databases to ensure:

1. No business-critical records are lost during the archive extraction
2. All relationships between header and detail tables are preserved
3. Financial figures in the archive match the source system exactly
4. Queries against the archive perform within acceptable SLA limits

---

*Built as part of a MySQL view validation and quality assurance portfolio.*
