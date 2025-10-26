-- ====================================================================
-- File 4: Testing and Reports (testing_reports.sql)
-- Executes the PL/SQL procedures and runs final reports.
-- NOTE: This script assumes schema_ddl.sql, sample_data.sql, and
-- plsql_components.sql have been run successfully.
-- ====================================================================
SET SERVEROUTPUT ON;

-- Initial State Check
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Initial Product Stock ---');
END;
/



-- printing the status of inventory/stocks of products initially (before any order)
SELECT product_id, name, stock_quantity FROM Products ORDER BY product_id;



-- here we are going to place a successful order with below details 
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Test 1: Successful Order (Product 3: Keyboard, Qty 3 - triggers 5% discount) ---');
END;
/
-- Customer 1 (Anupam), Product 3 (Keyboard, Price 95.00), Quantity 3
-- Subtotal: 285.00. Discount (5%): 14.25. Taxable: 270.75. Tax (8%): 21.66. Total: 270.75 + 21.66 = 292.34
BEGIN
    place_order_proc(p_customer_id => 1, p_product_id => 3, p_quantity => 3);
END;
/

-- here we are going to place another successful order with below details
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Test 2: Successful Bulk Order (Product 1: Laptop, Qty 5 - triggers 15% discount) ---');
END;
/
-- Customer 2 (Ankita), Product 1 (Laptop, Price 1200.00), Quantity 5
BEGIN
    place_order_proc(p_customer_id => 2, p_product_id => 1, p_quantity => 5);
END;
/


-- now we are goint to print the status or inventory/stock of products after above orders
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Current Product Stock After Orders ---');
END;
/
SELECT product_id, name, stock_quantity FROM Products ORDER BY product_id;



-- here we are trying to place an order with insuffcient stock, we will check working of our exception handling here
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Test 3: Insufficient Stock (Product 4: USB-C Hub, Stock 5, Request 10) ---');
END;
/
-- Should fail and roll back
BEGIN
    place_order_proc(p_customer_id => 1, p_product_id => 4, p_quantity => 10);
END;
/


-- here we will cancel an order and check whether our procedure is working or not
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Test 4: Order Cancellation (Cancelling Order 1) ---');
END;
/
-- Order 1 was for Product 3, Qty 3. Stock should be refunded.
BEGIN
    cancel_order_proc(p_order_id => 1);
END;
/


-- now we are printing the final state of product stock after order and cancelllations
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Final Table States ---');
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Orders Table ---');
END;
/
SELECT order_id, customer_id, status, sub_total, discount_applied, tax_amount, total_amount
FROM Orders
ORDER BY order_id;

BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- OrderItems Table ---');
END;
/
SELECT order_item_id, order_id, product_id, quantity
FROM OrderItems
ORDER BY order_item_id;

BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Final Product Stock ---');
END;
/
-- Product 3 stock should be back to 50
-- Product 1 stock should be 20 - 5 = 15
SELECT product_id, name, stock_quantity FROM Products ORDER BY product_id;

-- here we have created an example report using joins and aggregation
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Sales Report (Joins and Aggregation) ---');
END;
/
SELECT
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_id,
    o.order_date,
    o.status,
    o.total_amount,
    p.amount AS payment_amount
FROM
    Orders o
JOIN
    Customers c ON o.customer_id = c.customer_id
LEFT JOIN
    Payments p ON o.order_id = p.order_id
WHERE
    o.status != 'Cancelled'
ORDER BY
    o.order_date DESC;

COMMIT;
