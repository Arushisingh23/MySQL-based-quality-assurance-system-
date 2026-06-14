-- ============================================================
-- SQL-Driven Data Validation Framework
-- Schema: Enterprise Sales & Order Management
-- Simulates a legacy ERP archiving scenario (similar to SAP SD)
-- ============================================================

CREATE DATABASE IF NOT EXISTS enterprise_archive;
USE enterprise_archive;

-- ------------------------------------------------------------
-- 1. CUSTOMERS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    customer_id     INT PRIMARY KEY AUTO_INCREMENT,
    customer_name   VARCHAR(150) NOT NULL,
    country         VARCHAR(80),
    segment         ENUM('Enterprise', 'SMB', 'Consumer') DEFAULT 'SMB',
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active       TINYINT(1) DEFAULT 1
);

-- ------------------------------------------------------------
-- 2. PRODUCTS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    product_id      INT PRIMARY KEY AUTO_INCREMENT,
    product_name    VARCHAR(200) NOT NULL,
    category        VARCHAR(100),
    unit_price      DECIMAL(12, 2) NOT NULL,
    currency        CHAR(3) DEFAULT 'USD',
    is_discontinued TINYINT(1) DEFAULT 0
);

-- ------------------------------------------------------------
-- 3. SALES ORDERS (header - like SAP VBAK)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sales_orders (
    order_id        INT PRIMARY KEY AUTO_INCREMENT,
    customer_id     INT NOT NULL,
    order_date      DATE NOT NULL,
    status          ENUM('OPEN', 'CONFIRMED', 'SHIPPED', 'INVOICED', 'CANCELLED') DEFAULT 'OPEN',
    region          VARCHAR(80),
    sales_rep       VARCHAR(120),
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ------------------------------------------------------------
-- 4. ORDER LINE ITEMS (detail - like SAP VBAP)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_items (
    item_id         INT PRIMARY KEY AUTO_INCREMENT,
    order_id        INT NOT NULL,
    product_id      INT NOT NULL,
    quantity        INT NOT NULL,
    unit_price      DECIMAL(12, 2) NOT NULL,   -- price at time of order
    discount_pct    DECIMAL(5, 2) DEFAULT 0.00,
    CONSTRAINT fk_item_order   FOREIGN KEY (order_id)   REFERENCES sales_orders(order_id),
    CONSTRAINT fk_item_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ------------------------------------------------------------
-- 5. INVOICES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoices (
    invoice_id      INT PRIMARY KEY AUTO_INCREMENT,
    order_id        INT NOT NULL,
    invoice_date    DATE NOT NULL,
    total_amount    DECIMAL(14, 2) NOT NULL,
    paid            TINYINT(1) DEFAULT 0,
    CONSTRAINT fk_invoice_order FOREIGN KEY (order_id) REFERENCES sales_orders(order_id)
);

-- ------------------------------------------------------------
-- 6. PAYMENTS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
    payment_id      INT PRIMARY KEY AUTO_INCREMENT,
    invoice_id      INT NOT NULL,
    payment_date    DATE NOT NULL,
    amount_paid     DECIMAL(14, 2) NOT NULL,
    method          ENUM('Bank Transfer', 'Credit Card', 'Cheque') DEFAULT 'Bank Transfer',
    CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
);
