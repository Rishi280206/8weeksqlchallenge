SELECT * FROM sales
SELECT * FROM menu
SELECT * FROM members

/****************************************************************************************************************/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT S.customer_id, 
       SUM(M.price)
 FROM sales S
   INNER JOIN menu M
   ON S.product_id = M.product_id
GROUP BY S.customer_id
ORDER BY S.customer_id;

/******************************************************************************************************************/
-- 2. How many days has each customer visited the restaurant?

SELECT S.customer_id, 
       COUNT(DISTINCT(order_date)) AS days_visited
 FROM sales S
 GROUP BY S.customer_id
ORDER BY S.customer_id;

/******************************************************************************************************************/

-- 3. What was the first item from the menu purchased by each customer?

WITH first_order
AS
(
SELECT S.customer_id,
       S.order_date,
       M.product_name,
       DENSE_RANK () OVER (PARTITION BY S.customer_id ORDER BY S.order_date) AS first_order
 FROM sales S
   INNER JOIN menu M
   ON S.product_id = M.product_id
)
SELECT f.customer_id,
       f.product_name
   FROM first_order f
   WHERE first_order = 1
   GROUP BY f.customer_id,
            f.product_name;

/******************************************************************************************************************/

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
 
SELECT TOP 1
       M.product_name,
       COUNT(S.product_id) AS count_of_item
 FROM sales S
   INNER JOIN menu M
   ON S.product_id = M.product_id
GROUP BY M.product_name
ORDER BY COUNT(S.product_id) DESC;

/******************************************************************************************************************/

-- 5. Which item was the most popular for each customer?

WITH popular_order
AS
(
SELECT S.customer_id,
       M.product_name,
	   COUNT(S.product_id) AS order_count,
       DENSE_RANK () OVER (PARTITION BY S.customer_id ORDER BY COUNT(S.product_id) DESC) AS popular_order
 FROM sales S
   INNER JOIN menu M
   ON S.product_id = M.product_id
   GROUP BY S.customer_id, M.product_name
)
SELECT p.customer_id,
       p.product_name,
	   p.order_count
   FROM popular_order p
   WHERE popular_order = 1;

/******************************************************************************************************************/	   

-- 6. Which item was purchased first by the customer after they became a member?
WITH first_order
AS
(
SELECT S.customer_id,
       M.product_name,
       DENSE_RANK () OVER (PARTITION BY S.customer_id ORDER BY COUNT(S.product_id) DESC) AS first_order_rank
FROM sales S
   INNER JOIN menu M
   ON S.product_id = M.product_id
   INNER JOIN members X
   ON S.customer_id = X.customer_id
   WHERE S.order_date > X.join_date
   GROUP BY S.customer_id, M.product_name
)
SELECT f.customer_id,
       f.product_name
FROM first_order f
WHERE first_order_rank = 1;

/******************************************************************************************************************/	   

--Which item was purchased just before the customer became a member?

WITH last_order
AS
(
SELECT S.customer_id,
       M.product_name,
	   S.order_date,
	   X.join_date,
       DENSE_RANK () OVER (PARTITION BY S.customer_id ORDER BY S.order_date) AS last_order_rank
FROM sales S
   INNER JOIN menu M
   ON S.product_id = M.product_id
   INNER JOIN members X
   ON S.customer_id = X.customer_id
   WHERE S.order_date < X.join_date
)
SELECT l.customer_id,
       l.product_name
FROM last_order l
WHERE 
L.last_order_rank = (SELECT MAX(last_order_rank)
       FROM last_order
	  WHERE customer_id = l.customer_id);

/******************************************************************************************************************/	   

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT S.customer_id,
	   COUNT(S.product_id) AS item_total,
	   SUM(M.price) AS amt_spent
FROM sales S
   INNER JOIN menu M
   ON S.product_id = M.product_id
   INNER JOIN members X
   ON S.customer_id = X.customer_id
   WHERE S.order_date < X.join_date
   GROUP BY S.customer_id;

/******************************************************************************************************************/	   

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH Points_table
AS
(
SELECT S.customer_id,
	   SUM(M.price) item_total_price,
	   SUM(CASE 
	   WHEN M.product_name = 'sushi' THEN M.price*20
	   ELSE M.price*10 
	   END) AS points
 FROM sales S
   INNER JOIN menu M
   ON S.product_id = M.product_id
 GROUP BY S.customer_id
)
SELECT P.customer_id,
	   SUM(P.points)
	   FROM Points_table P
	    GROUP BY P.customer_id

/******************************************************************************************************************/	   

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
--- how many points do customer A and B have at the end of January?

WITH Week_points AS
(
SELECT S.customer_id,
	   SUM(M.price) item_total_price,
	   SUM(CASE 
	   WHEN S.order_date >= DATEADD(DAY, 7, X.join_date) THEN M.price*10
	   ELSE M.price*20
	   END) AS Week1
 FROM sales S
   INNER JOIN menu M
   ON S.product_id = M.product_id
   INNER JOIN members X
   ON S.customer_id = X.customer_id
   WHERE S.order_date >= X.join_date AND S.order_date <= '2021-01-31'
 GROUP BY S.customer_id
)
SELECT WP.customer_id,
	   SUM(WP.week1) AS total_points
	 FROM Week_points WP
	 GROUP BY WP.customer_id

