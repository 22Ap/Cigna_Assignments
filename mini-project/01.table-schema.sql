

-- in this file i have created the schemas of the tables
-- aslo used sequences to elininate the need to assigning ids manually

-- Table: Customers
CREATE TABLE Customers (
    customer_id     NUMBER(10)      PRIMARY KEY,
    first_name      VARCHAR2(50)    NOT NULL,
    last_name       VARCHAR2(50)    NOT NULL,
    email           VARCHAR2(100)   UNIQUE NOT NULL,
    phone_number    VARCHAR2(20)
);

-- Table: Products
CREATE TABLE Products (
    product_id      NUMBER(10)      PRIMARY KEY,
    name            VARCHAR2(100)   NOT NULL,
    price           NUMBER(10, 2)   NOT NULL,
    stock_quantity  NUMBER(10)      NOT NULL CHECK (stock_quantity >= 0)
);

-- Table: Orders
CREATE TABLE Orders (
    order_id            NUMBER(10)      PRIMARY KEY,
    customer_id         NUMBER(10)      NOT NULL REFERENCES Customers(customer_id),
    order_date          DATE            DEFAULT SYSDATE NOT NULL,
    status              VARCHAR2(20)    DEFAULT 'Pending' NOT NULL, -- e.g., 'Pending', 'Shipped', 'Cancelled'
    sub_total           NUMBER(10, 2)   NOT NULL,
    discount_applied    NUMBER(10, 2)   DEFAULT 0,
    tax_amount          NUMBER(10, 2)   DEFAULT 0,
    total_amount        NUMBER(10, 2)   NOT NULL
);

-- Table: OrderItems (Detail of what was ordered)
CREATE TABLE OrderItems (
    order_item_id   NUMBER(10)      PRIMARY KEY,
    order_id        NUMBER(10)      NOT NULL REFERENCES Orders(order_id) ON DELETE CASCADE,
    product_id      NUMBER(10)      NOT NULL REFERENCES Products(product_id),
    quantity        NUMBER(5)       NOT NULL CHECK (quantity > 0),
    unit_price      NUMBER(10, 2)   NOT NULL, -- Price at the time of order
    CONSTRAINT unq_order_product UNIQUE (order_id, product_id)
);

-- Table: Payments
CREATE TABLE Payments (
    payment_id      NUMBER(10)      PRIMARY KEY,
    order_id        NUMBER(10)      NOT NULL REFERENCES Orders(order_id) ON DELETE CASCADE,
    payment_date    DATE            DEFAULT SYSDATE NOT NULL,
    amount          NUMBER(10, 2)   NOT NULL,
    method          VARCHAR2(50)    NOT NULL -- e.g., 'Cash', 'UPI', 'Wallet', 'Card'
);

-- Sequences for Primary Keys
CREATE SEQUENCE cust_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE prod_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE order_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE item_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE pay_seq START WITH 1 INCREMENT BY 1;
