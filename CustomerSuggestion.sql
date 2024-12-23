CREATE TABLE Users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    email TEXT,
    age INTEGER,
    gender TEXT
);

CREATE TABLE Products (
    product_id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_name TEXT,
    category TEXT,
    price REAL
);

CREATE TABLE Orders (
    order_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    order_date DATE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Order_Items (
    order_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    price REAL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

/* User info */
INSERT INTO Users (name, email, age, gender) VALUES
('Marie', 'marie@gmail.com', 24, 'F'),
('Jean', 'jean@gmail.com', 25, 'M'),
('Charlie', 'charlie@gmail.com', 35, 'M'),
('Diana', 'diana@gmail.com', 28, 'F');

/* Available products */
INSERT INTO Products (product_name, category, price) VALUES
('Laptop', 'Electronics', 1200.00),
('Headphones', 'Electronics', 150.00),
('Coffee Maker', 'Home Appliances', 80.00),
('Sneakers', 'Footwear', 90.00);

/* Date of purchase */
INSERT INTO Orders (user_id, order_date) VALUES
(1, '2024-08-21'),
(2, '2024-08-22'),
(3, '2024-08-23'),
(4, '2024-08-24');

/* Items */
INSERT INTO Order_Items (order_id, product_id, quantity, price) VALUES
(1, 1, 1, 1200.00),
(1, 2, 2, 300.00),
(2, 3, 1, 80.00),
(3, 1, 1, 1200.00),
(3, 4, 1, 90.00),
(4, 2, 1, 150.00);

/* Analyze product pairs */
WITH product_pairs AS (
    SELECT 
        oi1.product_id AS product_id_1, 
        oi2.product_id AS product_id_2, 
        COUNT(*) AS times_bought_together
    FROM 
        Order_Items oi1
    JOIN 
        Order_Items oi2 ON oi1.order_id = oi2.order_id
    WHERE 
        oi1.product_id < oi2.product_id
    GROUP BY 
        oi1.product_id, oi2.product_id
    ORDER BY 
        times_bought_together DESC
)
SELECT 
    p1.product_name AS Product_1, 
    p2.product_name AS Product_2, 
    pp.times_bought_together
FROM 
    product_pairs pp
JOIN 
    Products p1 ON pp.product_id_1 = p1.product_id
JOIN 
    Products p2 ON pp.product_id_2 = p2.product_id
LIMIT 10;

/* Query for recommendations */
WITH user_purchases AS (
    SELECT 
        user_id, 
        product_id, 
        COUNT(*) AS purchase_count
    FROM 
        Orders o
    JOIN 
        Order_Items oi ON o.order_id = oi.order_id
    GROUP BY 
        user_id, product_id
), 

similar_users AS (
    SELECT 
        up1.user_id AS user_1, 
        up2.user_id AS user_2, 
        COUNT(*) AS common_products
    FROM 
        user_purchases up1
    JOIN 
        user_purchases up2 
        ON up1.product_id = up2.product_id 
        AND up1.user_id <> up2.user_id
    GROUP BY 
        up1.user_id, up2.user_id
    HAVING 
        common_products > 2
),

recommendations AS (
    SELECT 
        su.user_1 AS user_id,
        p.product_name
    FROM 
        similar_users su
    JOIN 
        user_purchases up ON su.user_2 = up.user_id
    JOIN 
        Products p ON up.product_id = p.product_id
    WHERE 
        up.product_id NOT IN (
            SELECT product_id FROM user_purchases WHERE user_id = su.user_1
        )
    GROUP BY 
        su.user_1, p.product_name
    ORDER BY 
        COUNT(*) DESC
    LIMIT 1
)

SELECT 
    'User ' || u.name || ' is recommended to buy ' || r.product_name || '.' AS recommendation_sentence
FROM 
    Users u
JOIN 
    recommendations r ON u.user_id = r.user_id;
