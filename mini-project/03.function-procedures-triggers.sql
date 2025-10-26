-- in this file i have bundled all the business logic in form of function/triggers/procedures

--list of functions
    --calculate_discount -> to calculate the discount or product according to price and quantity
    --calculate_tax --> to caluclate tax, here i have used fixed tax rate of 8%


--list of triggers
    --trg_update_inventory --> to update inventory after each order is placed


--list of procedures
    --place_order_proc --> procedure to place order
    --cancel_order_proc --> procedure to cancel order


-- Function to calculate discount
CREATE OR REPLACE FUNCTION calculate_discount (
    p_subtotal  IN NUMBER,
    p_quantity  IN NUMBER
)
RETURN NUMBER
IS
    v_discount_rate NUMBER(4, 2); -- 0.00 to 1.00
    v_discount_amount NUMBER(10, 2) := 0;
BEGIN
    -- Business Logic: 15% discount for bulk orders (quantity >=5) and (amount >=400)
    IF p_quantity >= 5 AND p_subtotal >= 400 THEN
        v_discount_rate := 0.15;
    -- Business Logic: 5% discount for any order item with quantity > 2
    ELSIF p_quantity > 2 THEN
        v_discount_rate := 0.05;
    ELSE
        v_discount_rate := 0.00;
    END IF;

    v_discount_amount := p_subtotal * v_discount_rate;

    RETURN v_discount_amount;
END;
/

-- Function to calculate taxes
CREATE OR REPLACE FUNCTION calculate_tax (
    p_taxable_amount IN NUMBER
)
RETURN NUMBER
IS
    c_tax_rate CONSTANT NUMBER(4, 2) := 0.08; -- Fixed 8% sales tax
BEGIN
    RETURN p_taxable_amount * c_tax_rate;
END;
/


-- Trigger to Update Inventory on Order Placement

CREATE OR REPLACE TRIGGER trg_update_inventory
AFTER INSERT ON OrderItems
FOR EACH ROW
BEGIN
    -- Decrement the stock quantity for the product
    UPDATE Products
    SET stock_quantity = stock_quantity - :NEW.quantity
    WHERE product_id = :NEW.product_id;
END;
/



-- Procedure for Placing Orders

CREATE OR REPLACE PROCEDURE place_order_proc (
    p_customer_id   IN NUMBER,
    p_product_id    IN NUMBER,
    p_quantity      IN NUMBER
)
IS
    v_product_price     Products.price%TYPE;
    v_stock_available   Products.stock_quantity%TYPE;
    v_sub_total         NUMBER(10, 2);
    v_discount          NUMBER(10, 2);
    v_tax_amount        NUMBER(10, 2);
    v_total_amount      NUMBER(10, 2);
    v_order_id          Orders.order_id%TYPE;

    -- Custom Exception for Stock Issues
    e_insufficient_stock EXCEPTION;

BEGIN
    -- 1. Check if the product exists and get price/stock in one query
    BEGIN
        SELECT price, stock_quantity
        INTO v_product_price, v_stock_available
        FROM Products
        WHERE product_id = p_product_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Product ID ' || p_product_id || ' not found.');
    END;

    -- 2. Stock Check and Exception Handling
    IF v_stock_available < p_quantity THEN
        RAISE e_insufficient_stock;
    END IF;

    -- 3. Calculations
    v_sub_total := v_product_price * p_quantity;
    v_discount := calculate_discount(v_sub_total, p_quantity);
    v_tax_amount := calculate_tax(v_sub_total - v_discount);
    v_total_amount := v_sub_total - v_discount + v_tax_amount;

    -- 4. Insert into Orders table
    v_order_id := order_seq.NEXTVAL;
    INSERT INTO Orders (
        order_id, customer_id, sub_total, discount_applied, tax_amount, total_amount, status
    ) VALUES (
        v_order_id, p_customer_id, v_sub_total, v_discount, v_tax_amount, v_total_amount, 'Pending'
    );

    -- 5. Insert into OrderItems table (Trigger trg_update_inventory fires here)
    INSERT INTO OrderItems (
        order_item_id, order_id, product_id, quantity, unit_price
    ) VALUES (
        item_seq.NEXTVAL, v_order_id, p_product_id, p_quantity, v_product_price
    );

    -- 6. Simulate Payment
    INSERT INTO Payments (
        payment_id, order_id, amount, method
    ) VALUES (
        pay_seq.NEXTVAL, v_order_id, v_total_amount, 'Credit Card'
    );

    -- 7. Update order status to confirm
    UPDATE Orders SET status = 'Confirmed' WHERE order_id = v_order_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Order ' || v_order_id || ' placed successfully for Customer ' || p_customer_id);

EXCEPTION
    WHEN e_insufficient_stock THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Insufficient stock for Product ID ' || p_product_id || '. Available: ' || v_stock_available || ', Requested: ' || p_quantity);
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: ' || SQLERRM);
        ROLLBACK;
END;
/


-- Procedure for Cancelling Orders

CREATE OR REPLACE PROCEDURE cancel_order_proc (
    p_order_id  IN NUMBER
)
IS
    v_current_status Orders.status%TYPE;
BEGIN
    -- 1. Check current status and existence
    BEGIN
        SELECT status INTO v_current_status
        FROM Orders
        WHERE order_id = p_order_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Order ID ' || p_order_id || ' not found.');
    END;

    -- 2. Prevent cancellation if already shipped or cancelled
    IF v_current_status IN ('Cancelled', 'Shipped') THEN
        RAISE_APPLICATION_ERROR(-20003, 'Order ' || p_order_id || ' cannot be cancelled because its status is ' || v_current_status || '.');
    END IF;

    -- 3. Update Order Status
    UPDATE Orders
    SET status = 'Cancelled'
    WHERE order_id = p_order_id;

    -- 4. Refund Inventory (iterate through all order items and add stock back)
    FOR item_rec IN (SELECT product_id, quantity FROM OrderItems WHERE order_id = p_order_id) LOOP
        UPDATE Products
        SET stock_quantity = stock_quantity + item_rec.quantity
        WHERE product_id = item_rec.product_id;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Order ' || p_order_id || ' successfully cancelled and inventory refunded.');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An unexpected error occurred during cancellation: ' || SQLERRM);
        ROLLBACK;
END;
/
