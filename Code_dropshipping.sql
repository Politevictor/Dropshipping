/*Sales Analysis - what is the total sales for each product
                 - how does sales perfomance vary over different
                   time period monthly and yearly*/
                   

SELECT P.product_name, SUM(O.quantity * P.price) AS amount
FROM products AS P
JOIN orders AS O
	ON O.product_id = P.product_id
GROUP BY P.product_name
ORDER BY amount DESC
 ;
 
 
SELECT 
	MONTHNAME(O.order_date) _month, 
	COUNT(MONTH(O.order_date)) AS no_orders, 
    SUM(O.quantity * P.price) AS amount
FROM products AS P
JOIN orders AS O
	ON O.product_id = P.product_id
GROUP BY MONTHNAME(O.order_date)
ORDER BY MONTHNAME(O.order_date)  DESC
 ;


SELECT 
	YEAR(O.order_date) yearly, 
	COUNT(YEAR(O.order_date)) AS no_orders, 
    SUM(O.quantity * P.price) AS amount
FROM products AS P
JOIN orders AS O
	ON O.product_id = P.product_id
GROUP BY YEAR(O.order_date)
ORDER BY no_orders DESC
 ;
 
SELECT 
	YEAR(O.order_date) yearly, 
    MONTHNAME(O.order_date) monthly, 
	COUNT(YEAR(O.order_date)) AS no_orders, 
    SUM(O.quantity * P.price) AS amount
FROM products AS P
JOIN orders AS O
	ON O.product_id = P.product_id
GROUP BY YEAR(O.order_date), MONTHNAME(O.order_date) 
ORDER BY no_orders  DESC;    
 
 SELECT COUNT(*) FROM orders 
 where YEAR(order_date) = '2022' AND MONTHNAME(order_date) = 'october';
 
 
 /* Customer Behaviour - loyal customers who made order every year.
					   - how many new customers were acquired/lost over the period yearly?
                       - what is the average order value per customer?*/
                         
 -- loyal customers who made order every year
SELECT  O.customer_id,  C.first_name,  C.last_name 
FROM orders O
JOIN customers C
	ON C.customer_id = O.customer_id 
GROUP BY  C.customer_id, C.first_name,  C.last_name 
HAVING COUNT(DISTINCT YEAR(order_date)) = (SELECT COUNT(DISTINCT YEAR(order_date))FROM orders); 
------------------
   
-- customer who bought in 2020 but did not buy 2021
  SELECT 
	DISTINCT customer_id
  FROM orders
  WHERE YEAR(order_date) = 2020;

    /* out of the 176 customers who placed orders in 2020, 
     59 customers made order the follow year, 
     while 117  customers did not place order in 2021 -- lack of atifaction*/
     
SELECT DISTINCT O.customer_id, C.first_name, C.last_name 
FROM orders O
JOIN customers C
	ON C.customer_id = O.customer_id 
WHERE 
	YEAR(order_date) = 2020 AND 
	 O.customer_id NOT IN (SELECT DISTINCT customer_id FROM orders WHERE 
	YEAR(order_date) IN (2021));
    --
    
SELECT DISTINCT O.customer_id, C.first_name, C.last_name 
FROM orders O
JOIN customers C
	ON C.customer_id = O.customer_id 
WHERE 
	YEAR(O.order_date) IN (2020) AND 
    C.customer_id NOT IN
		(SELECT DISTINCT C2.customer_id FROM customers C2
		JOIN orders as O2 ON C2.customer_id = O2.customer_id
		WHERE YEAR(O2.order_date)  = 2021 );
        
 -----------------
--  - what is the average order value per customer?

SELECT 
	DISTINCT O.customer_id, 
    C.first_name, C.last_name, 
    round(avg(O.quantity),0) as "avg qyt per customers", 
	(SELECT round(avg(quantity),0)  FROM orders) group_avg
FROM orders O
JOIN customers C
	ON C.customer_id = O.customer_id 
GROUP BY   O.customer_id, C.first_name, C.last_name
ORDER BY   round(avg(O.quantity),0)  desc;

------------

/*Inventory and Product Mgt - how many units of each product is sold
							- which products need to be restocked base on sales trends*/
                            
SELECT DISTINCT	p.product_name, o.quantity as qyt_sold 
FROM 	products as p
JOIN orders as o
	ON o.product_id = p.product_id;				
 
-- by products 
SELECT DISTINCT	p.product_name, SUM(o.quantity) as qyt_sold 
FROM 	products as p
JOIN orders as o
	ON o.product_id = p.product_id
GROUP BY p.product_name
;	
-- by category    
SELECT DISTINCT	p.category, SUM(o.quantity) as qyt_sold 
FROM 	products as p
JOIN orders as o
	ON o.product_id = p.product_id
GROUP BY p.category
;	


  -- reorder level @ 6000 qyt
 SELECT  product_name "products due for restocking"
FROM 
	(SELECT p.product_id, p.product_name, (p.total_stock - o.quantity) available 
    FROM products p JOIN orders as o ON o.product_id = p.product_id 
    WHERE (p.total_stock - o.quantity) < 6000 
    order by available desc ) 
products;

-- reorder @ >250 qyt-per product
SELECT  product_name "products due for restocking"
FROM 
	(
		SELECT DISTINCT	p.product_name, SUM(o.quantity) as qyt_sold 
		FROM 	products as p
		JOIN orders as o
			ON o.product_id = p.product_id
		GROUP BY p.product_name
		HAVING SUM(o.quantity)> 250
	)
products;

/*Profitability and Margins - what is the profit margins for each category
							- how much profit is made in year 2022*/
                                                   

SELECT 
	p.category,  
    format(sum((p.price - p.cost)* o.quantity),3) margins
FROM orders as o
join products as p
	on p.product_id = o.product_id
group by p.category
order by margins desc; 


---------
SELECT 
	if(p.category is null, 'Grand total', p.category) as category,  
    format(sum((p.price - p.cost)* o.quantity),3) as "2022 margins"
FROM orders as o
join products as p
	on p.product_id = o.product_id
where year(o.order_date) = 2022
group by p.category with rollup
order by "2022 margins" desc; 

/*Customer Segmentation and Patterns - segment customers base on their purchasing behaviour
									   creating a class base on order period and quantity purchased.alter
									 */
  
  
SELECT  
	distinct O.customer_id,  
    C.first_name,  
    C.last_name, 
    COUNT(O.quantity) order_count,
    COUNT(DISTINCT YEAR(O.order_date)) count_year,
	CASE
		WHEN COUNT(DISTINCT YEAR(O.order_date)) = 4 AND COUNT(O.quantity) > 4 THEN 'Premium loyal customer'
        WHEN COUNT(DISTINCT YEAR(O.order_date)) = 4 THEN ' 2nd class customer'
		WHEN COUNT(DISTINCT YEAR(O.order_date)) = 3 THEN '3rd  class customer'
        ELSE 'common class'
	END AS class
FROM orders O
JOIN customers C
ON C.customer_id = O.customer_id 
GROUP BY 	
    O.customer_id,  
    C.first_name,  
    C.last_name
ORDER BY 
    count_year desc, 
    order_count desc
 ;

/*update shipment_date to interval of two months for the following countries 
and where delivery status is not 'pending' 'Malaysia', 'Brazil', 'Albania', 'Bolivia', 'Austria' */


UPDATE orders
SET shipment_date = DATE_ADD(orders.order_date, INTERVAL 2 MONTH)
WHERE orders.order_id IN (
    SELECT o.order_id 
    FROM (
        SELECT orders.order_id 
        FROM orders 
        JOIN customers ON customers.customer_id = orders.customer_id 
        WHERE orders.status != 'pending' 
        AND customers.country IN ('Malaysia', 'Brazil', 'Albania', 'Bolivia', 'Austria')
    ) AS o
);


/*Operational Efficiency - what is the time period taken to 
 ship items to customers from order_date to each countries*/



SELECT 
	distinct c.country, 
    concat( 
		'it takes   ', TIMESTAMPDIFF(WEEK, o.order_date, o.shipment_date),' ', 'wk(s)'
        ) as shipment_date
FROM  orders AS o
JOIN customers AS c
ON o.customer_id = c.customer_id
WHERE status != 'pending'
ORDER BY c.country ;

/*all pending orders are to be sent out, fetch all necccessery detail*/

SELECT 
	O.order_id, O.order_date, P.product_id, S.supplier_id, 
    S.supplier_email, C.customer_id,  C.first_name, O.quantity, 
    FORMAT((O.quantity * P.price),3) AS amount, O.shipping_address, O.tracking_number   
FROM orders As O
JOIN products P ON O.product_id = P.Product_id
JOIN customers C ON O.customer_id = C.customer_id
JOIN suppliers S ON O.supplier_id = S.supplier_id
WHERE O.status = 'pending'
ORDER BY C.customer_id;
