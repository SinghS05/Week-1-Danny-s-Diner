USE dannys_diner;
-- 1. What is the total amount each customer spent at the restaurant?
SELECT p.customer_id,SUM(m.price) As amount_spent
FROM sales p 
INNER JOIN menu m 
	ON p.product_id = m.product_id
GROUP BY p.customer_id;
-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS no_days_visited
FROM sales
GROUP BY customer_id;
-- 3. What was the first item from the menu purchased by each customer?
-- First Visit>>FirstItem
WITH order_details AS
(
SELECT p.customer_id, p.order_date, p.product_id,
		m.product_name,
        dense_rank()
			OVER(Partition BY p.customer_id
					Order BY order_date asc) As order_rank,
		row_number()
			OVER(Partition BY p.customer_id
					Order By order_date asc) As seq_no
FROM sales p 
INNER JOIN menu m 
ON p.product_id = m.product_id
)
SELECT customer_id, product_name
FROM order_details
WHERE order_rank = 1 AND seq_no = 1;
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH purchased_prod AS
(
SELECT p.product_id, m.product_name, COUNT(p.product_id) AS prod_count
FROM sales p 
INNER JOIN menu m 
ON m.product_id = p.product_id
GROUP BY p.product_id, m.product_name),
max_purchased_prod AS
(
SELECT product_id
FROM purchased_prod
WHERE prod_count = (SELECT MAX(prod_count) FROM purchased_prod)
)
SELECT a.customer_id, p.product_name, COUNT(a.product_id) As no_of_times_purchased
FROM sales a 
INNER JOIN purchased_prod p 
ON a.product_id = p.product_id
WHERE a.product_id = (SELECT product_id FROM max_purchased_prod)
GROUP BY 1,2;

-- 5. Which item was the most popular for each customer?
WITH purchased_prod AS
(
SELECT p.product_id, m.product_name, COUNT(p.product_id) AS prod_count
FROM sales p 
INNER JOIN menu m 
ON m.product_id = p.product_id
GROUP BY p.product_id, m.product_name)
SELECT product_name As most_popular_prod
FROM purchased_prod
WHERE prod_count = (SELECT MAX(prod_count) FROM purchased_prod);
-- 6. Which item was purchased first by the customer after they became a member?
SELECT customer_id, first_order_after_membership
FROM(
	SELECT a.customer_id, a.order_date, 
		b.product_name As first_order_after_membership,
		dense_rank()
			Over(partition by a.customer_id
					order by order_date asc) As sequence
	FROM
		sales a 
		INNER JOIN menu b 
		ON a.product_id = b.product_id
		INNER JOIN members c 
		ON a.customer_id = c.customer_id
		WHERE order_date >= join_date) A 
    WHERE sequence = 1;
-- 7. Which item was purchased just before the customer became a member?
SELECT customer_id, last_order_before_membership
FROM(
	SELECT a.customer_id, a.order_date, 
		b.product_name As last_order_before_membership,
		dense_rank()
			Over(partition by a.customer_id
					order by order_date desc) As sequence
	FROM
		sales a 
		INNER JOIN menu b 
		ON a.product_id = b.product_id
		INNER JOIN members c 
		ON a.customer_id = c.customer_id
		WHERE order_date < join_date) A 
WHERE sequence =1;
-- 8. What is the total items and amount spent for each member before they became a member?
SELECT a.customer_id, COUNT(a.product_id) AS total_items,
	SUM(price) AS amount_spent
FROM
	sales a 
	INNER JOIN menu b 
	ON a.product_id = b.product_id
	INNER JOIN members c 
	ON a.customer_id = c.customer_id
	WHERE order_date < join_date
    GROUP BY 1;
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT a.customer_id, 
	SUM(CASE 
		WHEN b.product_name = "sushi" THEN b.price * 2
        ELSE b.price * 1 END) AS points
FROM sales a 
INNER JOIN menu b 
ON a.product_id = b.product_id
GROUP BY a.customer_id;
/* 10. In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi - how many points do customer 
A and B have at the end of January?*/
SELECT a.customer_id, 
	SUM(CASE
		WHEN order_date IN (join_date, join_date+7) THEN b.price*2
		WHEN b.product_name = "sushi" THEN b.price * 2
        ELSE b.price * 1 END) AS points
FROM sales a 
INNER JOIN menu b 
ON a.product_id = b.product_id
INNER JOIN members c
ON a.customer_id = c.customer_id
WHERE MONTH(Order_date) = 1
GROUP BY a.customer_id;