-- in this file i have inserted some sample data into the tables
-- no data is inserted manually in order table because we will do it with help of procedures
-- that thing would be done in the next file



-- Customers
INSERT INTO Customers VALUES (cust_seq.NEXTVAL, 'Anupam', 'Kumar', 'anupam@gmail.com', '0612-1234');
INSERT INTO Customers VALUES (cust_seq.NEXTVAL, 'Ankita', 'Kumari', 'ankita@example.com', '0612-5678');

-- Products
INSERT INTO Products VALUES (prod_seq.NEXTVAL, 'Laptop Pro X', 1200.00, 20); -- ID: 1
INSERT INTO Products VALUES (prod_seq.NEXTVAL, 'Wireless Mouse', 25.50, 150); -- ID: 2
INSERT INTO Products VALUES (prod_seq.NEXTVAL, 'Mechanical Keyboard', 95.00, 50); -- ID: 3
INSERT INTO Products VALUES (prod_seq.NEXTVAL, 'USB-C Hub', 45.00, 5); -- Low stock for testing -- ID: 4

COMMIT;
-- i am using commit so that we can have persistent data across the files and database.
