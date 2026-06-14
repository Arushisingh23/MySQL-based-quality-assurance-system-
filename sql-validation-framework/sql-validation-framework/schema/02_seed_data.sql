-- ============================================================
-- Seed Data — realistic enterprise dataset
-- ============================================================
USE enterprise_archive;

-- CUSTOMERS
INSERT INTO customers (customer_name, country, segment) VALUES
('Siemens AG',            'Germany',       'Enterprise'),
('Tata Consultancy',      'India',         'Enterprise'),
('Bosch GmbH',            'Germany',       'Enterprise'),
('Infosys Ltd',           'India',         'Enterprise'),
('Metro AG',              'Germany',       'SMB'),
('Reliance Industries',   'India',         'Enterprise'),
('Zalando SE',            'Germany',       'SMB'),
('Wipro Ltd',             'India',         'SMB'),
('SAP SE',                'Germany',       'Enterprise'),
('HCL Technologies',      'India',         'Enterprise'),
('Deutsche Bank',         'Germany',       'Enterprise'),
('Mahindra & Mahindra',   'India',         'SMB'),
('Henkel AG',             'Germany',       'SMB'),
('Tech Mahindra',         'India',         'SMB'),
('Bayer AG',              'Germany',       'Enterprise'),
-- intentionally inactive record for validation testing
('OldCorp GmbH',          'Germany',       'Consumer', '2019-01-01', 0);

-- PRODUCTS
INSERT INTO products (product_name, category, unit_price) VALUES
('SAP Archive Module',         'Software License',  12500.00),
('Legacy Migration Toolkit',   'Software License',   8750.00),
('DB Validation Suite',        'Software License',   6200.00),
('Data Archiving Appliance',   'Hardware',          22000.00),
('Cloud Storage Bundle - 1TB', 'Cloud Service',      1800.00),
('Annual Support Plan',        'Support',            3500.00),
('MySQL Performance Tuner',    'Software License',   4100.00),
('Enterprise Reporting Pack',  'Software License',   5500.00),
-- discontinued product to test view filtering
('Legacy Connector v1',        'Software License',    900.00);

UPDATE products SET is_discontinued = 1 WHERE product_name = 'Legacy Connector v1';

-- SALES ORDERS
INSERT INTO sales_orders (customer_id, order_date, status, region, sales_rep) VALUES
(1,  '2023-01-15', 'INVOICED',   'EMEA',  'Klaus Bauer'),
(2,  '2023-02-10', 'INVOICED',   'APAC',  'Priya Nair'),
(3,  '2023-03-05', 'SHIPPED',    'EMEA',  'Klaus Bauer'),
(4,  '2023-04-20', 'INVOICED',   'APAC',  'Rahul Mehta'),
(5,  '2023-05-12', 'CONFIRMED',  'EMEA',  'Anna Schmidt'),
(6,  '2023-06-08', 'INVOICED',   'APAC',  'Priya Nair'),
(7,  '2023-07-19', 'OPEN',       'EMEA',  'Anna Schmidt'),
(8,  '2023-08-25', 'CANCELLED',  'APAC',  'Rahul Mehta'),
(9,  '2023-09-11', 'INVOICED',   'EMEA',  'Klaus Bauer'),
(10, '2023-10-03', 'SHIPPED',    'APAC',  'Priya Nair'),
(11, '2023-11-14', 'INVOICED',   'EMEA',  'Anna Schmidt'),
(12, '2023-12-01', 'OPEN',       'APAC',  'Rahul Mehta'),
(1,  '2024-01-22', 'INVOICED',   'EMEA',  'Klaus Bauer'),
(3,  '2024-02-14', 'CONFIRMED',  'EMEA',  'Anna Schmidt'),
(6,  '2024-03-30', 'INVOICED',   'APAC',  'Priya Nair');

-- ORDER ITEMS
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_pct) VALUES
(1,  1, 1, 12500.00, 5.00),
(1,  6, 1,  3500.00, 0.00),
(2,  2, 2,  8750.00, 10.00),
(2,  7, 1,  4100.00, 0.00),
(3,  4, 1, 22000.00, 0.00),
(3,  5, 3,  1800.00, 5.00),
(4,  1, 1, 12500.00, 8.00),
(4,  3, 1,  6200.00, 0.00),
(5,  8, 2,  5500.00, 0.00),
(6,  2, 1,  8750.00, 0.00),
(6,  6, 2,  3500.00, 5.00),
(7,  5, 5,  1800.00, 10.00),
(8,  9, 1,   900.00, 0.00),   -- cancelled order with discontinued product
(9,  1, 2, 12500.00, 0.00),
(9,  3, 1,  6200.00, 5.00),
(10, 7, 1,  4100.00, 0.00),
(11, 1, 1, 12500.00, 0.00),
(11, 8, 1,  5500.00, 0.00),
(12, 5, 10, 1800.00, 15.00),
(13, 2, 1,  8750.00, 0.00),
(13, 6, 1,  3500.00, 0.00),
(14, 4, 1, 22000.00, 5.00),
(15, 1, 2, 12500.00, 10.00),
(15, 3, 1,  6200.00, 0.00);

-- INVOICES
INSERT INTO invoices (order_id, invoice_date, total_amount, paid) VALUES
(1,  '2023-01-20', 15800.00, 1),
(2,  '2023-02-15', 21350.00, 1),
(4,  '2023-04-25', 17700.00, 1),
(6,  '2023-06-12', 15425.00, 1),
(9,  '2023-09-15', 30825.00, 1),
(11, '2023-11-18', 18000.00, 0),   -- unpaid invoice for validation
(13, '2024-01-27', 12250.00, 1),
(15, '2024-04-02', 28700.00, 0);   -- unpaid invoice

-- PAYMENTS
INSERT INTO payments (invoice_id, payment_date, amount_paid, method) VALUES
(1, '2023-02-01', 15800.00, 'Bank Transfer'),
(2, '2023-03-01', 21350.00, 'Bank Transfer'),
(3, '2023-05-10', 17700.00, 'Credit Card'),
(4, '2023-07-01', 15425.00, 'Bank Transfer'),
(5, '2023-10-01', 30825.00, 'Bank Transfer'),
(7, '2024-02-10', 12250.00, 'Cheque');
