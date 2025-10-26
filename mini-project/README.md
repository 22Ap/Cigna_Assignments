## Mini Project: Simple E‑commerce Order System (Oracle SQL/PLSQL)

This repository contains a small Oracle SQL / PL/SQL mini-project that implements a simple e-commerce order system. It includes table schemas, sample data, business logic (functions, procedures, triggers), and test-case scripts.

Files (in execution order)
- `01.table-schema.sql` — table/sequence definitions (Customers, Products, Orders, OrderItems, Payments and supporting sequences).
- `02.sample-data.sql` — inserts sample customers and products.
- `03.function-procedures-triggers.sql` — business logic: discount/tax functions, inventory trigger, order placement and cancellation procedures.
- `04.test-cases.sql` — test script that runs example orders, prints DBMS_OUTPUT messages, and queries final state.


Table Schemas

1) `Customers`
- `customer_id` NUMBER(10) PRIMARY KEY (populated by `cust_seq`)
- `first_name` VARCHAR2(50) NOT NULL
- `last_name` VARCHAR2(50) NOT NULL
- `email` VARCHAR2(100) UNIQUE NOT NULL
- `phone_number` VARCHAR2(20)

2) `Products`
- `product_id` NUMBER(10) PRIMARY KEY (populated by `prod_seq`)
- `name` VARCHAR2(100) NOT NULL
- `price` NUMBER(10,2) NOT NULL
- `stock_quantity` NUMBER(10) NOT NULL CHECK (stock_quantity >= 0)

3) `Orders`
- `order_id` NUMBER(10) PRIMARY KEY (populated by `order_seq`)
- `customer_id` NUMBER(10) NOT NULL REFERENCES `Customers`(customer_id)
- `order_date` DATE DEFAULT SYSDATE NOT NULL
- `status` VARCHAR2(20) DEFAULT 'Pending' NOT NULL
- `sub_total` NUMBER(10,2) NOT NULL
- `discount_applied` NUMBER(10,2) DEFAULT 0
- `tax_amount` NUMBER(10,2) DEFAULT 0
- `total_amount` NUMBER(10,2) NOT NULL

4) `OrderItems`
- `order_item_id` NUMBER(10) PRIMARY KEY (populated by `item_seq`)
- `order_id` NUMBER(10) NOT NULL REFERENCES `Orders`(order_id) ON DELETE CASCADE
- `product_id` NUMBER(10) NOT NULL REFERENCES `Products`(product_id)
- `quantity` NUMBER(5) NOT NULL CHECK (quantity > 0)
- `unit_price` NUMBER(10,2) NOT NULL
- UNIQUE constraint on (order_id, product_id)

5) `Payments`
- `payment_id` NUMBER(10) PRIMARY KEY (populated by `pay_seq`)
- `order_id` NUMBER(10) NOT NULL REFERENCES `Orders`(order_id) ON DELETE CASCADE
- `payment_date` DATE DEFAULT SYSDATE NOT NULL
- `amount` NUMBER(10,2) NOT NULL
- `method` VARCHAR2(50) NOT NULL

Sequences
- `cust_seq`, `prod_seq`, `order_seq`, `item_seq`, `pay_seq` — auto-increment helpers used in sample script to create IDs.

PL/SQL Components

Functions
- `calculate_discount(p_subtotal IN NUMBER, p_quantity IN NUMBER) RETURN NUMBER`
  - Business logic:
    - 15% discount if p_quantity >= 5 AND p_subtotal >= 400
    - 5% discount if p_quantity > 2
    - otherwise 0
  - Returns discount amount (not rate).

- `calculate_tax(p_taxable_amount IN NUMBER) RETURN NUMBER`
  - Uses a fixed tax rate constant `c_tax_rate := 0.08` (8%) and returns tax amount.

Trigger
- `trg_update_inventory` (AFTER INSERT ON OrderItems FOR EACH ROW)
  - Decrements `Products.stock_quantity` by `:NEW.quantity` when a new order item is inserted.
  - Note: the project checks stock before inserting; the trigger enforces inventory change centrally.

Procedures
- `place_order_proc(p_customer_id IN NUMBER, p_product_id IN NUMBER, p_quantity IN NUMBER)`
  - Flow:
    1. Query product price and stock. If not found, raises application error.
    2. If available stock < requested quantity, raises a custom `e_insufficient_stock` and ROLLBACK.
    3. Compute `sub_total`, call `calculate_discount`, then `calculate_tax`, and compute `total_amount`.
    4. Insert row into `Orders` (status `'Pending'` initially).
    5. Insert row into `OrderItems` (fires `trg_update_inventory` to reduce stock).
    6. Insert a `Payments` row (simulated immediate payment).
    7. Update `Orders` status to `'Confirmed'`.
    8. COMMIT and DBMS_OUTPUT message on success.
  - Exception handling: on insufficient stock, outputs an error message and ROLLBACK. On OTHERS, outputs SQLERRM and ROLLBACK.

- `cancel_order_proc(p_order_id IN NUMBER)`
  - Flow:
    1. Lookup order status; if NOT FOUND, raise application error.
    2. If status is `'Cancelled'` or `'Shipped'`, raise application error (can't cancel).
    3. Update `Orders` status to `'Cancelled'`.
    4. For each `OrderItems` row for the order, add the quantity back to `Products.stock_quantity` (refund inventory).
    5. COMMIT and DBMS_OUTPUT message on success.
  - Exception handling: OTHERS logs and ROLLBACK.

How to run (recommended order)
1. Use an Oracle client such as SQL*Plus/SQLcl or SQL Developer. Connect to the schema where you want the objects created.
2. Enable server output so DBMS_OUTPUT messages are visible:

   -- in SQL*Plus / SQLcl / SQL Developer
   SET SERVEROUTPUT ON SIZE 1000000;

3. Run the DDL script to create tables and sequences:

   @01.table-schema.sql

4. Populate sample data:

   @02.sample-data.sql

5. Create functions, triggers, and procedures (business logic):

   @03.function-procedures-triggers.sql

6. Run the test-case script which executes sample orders and prints reports:

   @04.test-cases.sql

