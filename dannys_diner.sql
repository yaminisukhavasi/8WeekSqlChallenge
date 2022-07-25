CREATE DATABASE dannys_diner_1;

/************Creating tables in database**************************/
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INT(5) PRIMARY KEY
)
CREATE TABLE menu (
  product_id INT(5),
  product_name VARCHAR(5),
  price INT(5) 
)
CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
)

/***********************Inserting data into tables ***********************/
INSERT INTO sales VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3')

INSERT INTO menu VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12')

INSERT INTO members VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09')
  
/****************CASE STUDY**************************/

--Q.1-->What is the total amount each customer spent at the restaurant?
Select S.customer_id, Sum(M.price) As TotalSpent
From Menu m
join Sales s
On m.product_id = s.product_id
group by S.customer_id

--Q.2-->How many days has each customer visited the restaurant?
Select customer_id, count(distinct(order_date)) AS Days_Visited
From Sales
Group by customer_id

--Q.3-->What was the first item from the menu purchased by each customer?
With Rank as
(
Select S.customer_id, 
       M.product_name, 
       S.order_date,
       DENSE_RANK() OVER (PARTITION BY S.Customer_ID Order by S.order_date) as Rank
From Menu m
join Sales s
On m.product_id = s.product_id
group by S.customer_id, M.product_name,S.order_date
)
Select Customer_id, product_name
From Rank
Where Rank = 1

--Q.4-->What is the most purchased item on the menu and how many times was it purchased by all customers?
Select TOP 1 m.product_name , COUNT(s.product_id)
From Menu m
join Sales s
On m.product_id = s.product_id
Group by m.product_name
Order by Count(s.product_id) desc

--Q.5-->Which item was the most popular for each customer?
With rank as
(
Select S.customer_ID ,
       M.product_name, 
       Count(S.product_id) as Count,
       Dense_rank()  Over (Partition by S.Customer_ID order by Count(S.product_id) DESC ) as Rank
From Menu m
join Sales s
On m.product_id = s.product_id
group by S.customer_id,S.product_id,M.product_name
)
Select Customer_id,Product_name,Count
From rank
where rank = 1

--Q.6-->Which item was purchased first by the customer after they became a member?
With Rank as
(
Select  S.customer_id,
        M.product_name,
	Dense_rank() OVER (Partition by S.Customer_id Order by S.Order_date) as Rank
From Sales S
Join Menu M
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date >= Mem.join_date  
)
Select *
From Rank
Where Rank = 1

--Q.7-->Which item was purchased just before the customer became a member?
With Rank as
(
Select  S.customer_id,
        M.product_name,
	Dense_rank() OVER (Partition by S.Customer_id Order by S.Order_date) as Rank
From Sales S
Join Menu M
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date < Mem.join_date  
)
Select customer_ID, Product_name
From Rank
Where Rank = 1

--Q.8-->What is the total items and amount spent for each member before they became a member?
Select s.customer_id,count(s.product_id ) as quantity ,Sum(m.price) as total_sales
From Sales s
Join Menu m
ON m.product_id = s.product_id
JOIN Members Mem
ON Mem.Customer_id = s.customer_id
Where s.order_date < Mem.join_date
Group by s.customer_id

--Q.9-->If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
With Points as
(
Select *,Case When product_id = 1 THEN price*20
               Else price*10
	         End as Points
From Menu
)
Select S.customer_id, Sum(P.points) as Points
From Sales S
Join Points p
On p.product_id = S.product_id
Group by S.customer_id

--Q.10-->In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH dates AS 
(
   SELECT *, 
      DATEADD(DAY, 6, join_date) AS valid_date, 
      EOMONTH('2021-01-31') AS last_date
   FROM members 
)
Select S.Customer_id, 
       SUM(
	   Case 
	  When M.product_ID = 1 THEN M.price*20
	  When S.order_date between D.join_date and D.valid_date Then M.price*20
	  Else M.price*10
	  END 
	  ) as Points
From Dates D
join Sales S
On D.customer_id = S.customer_id
Join Menu M
On M.product_id = S.product_id
Where S.order_date < D.last_date
Group by S.customer_id


  



  
