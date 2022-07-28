DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
    runner_id INTEGER,
    registration_date DATE
)
DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
    order_id INTEGER,
    customer_id INTEGER,
    pizza_id INTEGER,
    exclusions VARCHAR(4),
    extras VARCHAR(4),
    order_time TIMESTAMP
)

DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
    order_id INTEGER,
    runner_id INTEGER,
    pickup_time VARCHAR(19),
    distance VARCHAR(7),
    duration VARCHAR(10),
    cancellation VARCHAR(23)
)


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
    pizza_id INTEGER,
    pizza_name TEXT
)

	
DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
    pizza_id INTEGER,
    toppings TEXT
)


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
    topping_id INTEGER,
    topping_name TEXT
)

/********************Inserting Data into Tables*******************/

INSERT INTO runners VALUES (1, '2021-01-01'),(2, '2021-01-03'),
    (3, '2021-01-08'),(4, '2021-01-15')

INSERT INTO customer_orders VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49')

INSERT INTO runner_orders VALUES 
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null')
  
INSERT INTO pizza_names VALUES (1, 'Meatlovers'),(2, 'Vegetarian')

INSERT INTO pizza_recipes VALUES (1, '1, 2, 3, 4, 5, 6, 8, 10'),
    (2, '4, 6, 7, 9, 11, 12')
	
INSERT INTO pizza_toppings VALUES 
	(1, 'Bacon'),(2, 'BBQ Sauce'),(3, 'Beef'),
    (4, 'Cheese'),(5, 'Chicken'),(6, 'Mushrooms'),
    (7, 'Onions'),(8, 'Pepperoni'),(9, 'Peppers'),
    (10, 'Salami'),(11, 'Tomatoes'),(12, 'Tomato Sauce')

------------------------------------------------------------------------------------------
/*****************************DATA CLEANING********************************/
------------------------------------------------------------------------------------------
--Cleaning customer_orders table Data --------
update customer_orders
set 
exclusions = case exclusions when 'null' then null else exclusions end,
extras = case extras when 'null' then null else extras end;
---Cleaning runner_orders table data----------------
-- Copying table and cleaning data
drop table if exists runner_orders1;
create table runner_orders1 as 
(select order_id, runner_id, pickup_time,
case
 when distance like '%km' then trim('km' from distance)
 else distance 
end as distance,
case
 when duration like '%minutes' then trim('minutes' from duration)
 when duration like '%mins' then trim('mins' from duration)
 when duration like '%minute' then trim('minute' from duration)
 else duration
end as duration, cancellation 
from runner_orders);
-- cleaning data
update runner_orders1
set 
pickup_time = case pickup_time when 'null' then null else pickup_time end,
distance = case distance when 'null' then null else distance end,
duration = case duration when 'null' then null else duration end,
cancellation = case cancellation when 'null' then null else cancellation end;
-------------------------------------------------------------------------------------------------------------------
--PART 1: PIZZA METRICS !
-------------------------------------------------------------------------------------------------------------------

--Q.1-->1) How many pizzas were ordered?
SELECT COUNT(pizza_id) AS number_of_pizza_ordered
FROM customer_orders_cleaned; 

--Q.2-->2) How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS distinct_orders
FROM customer_orders_cleaned; 

--Q.3-->3) How many successful orders were delivered by each runner?
SELECT COUNT(order_id) AS distinct_orders
FROM runner_orders_cleaned
WHERE cancellation IS NULL; 

--Q.4-->) How many of each type of pizza was delivered?
SELECT C.pizza_id,
    COUNT(C.pizza_id) as pizza_delivered
FROM customer_orders_cleaned AS C
    LEFT JOIN runner_orders_cleaned AS R ON C.order_id = R.order_id
WHERE R.cancellation IS NULL
GROUP BY pizza_id; 

--Q.5-->) How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id,
    SUM(
        CASE
            WHEN pizza_id = 1 THEN 1
            ELSE 0
        END
    ) as meatlovers,
    SUM(
        CASE
            WHEN pizza_id = 2 THEN 1
            ELSE 0
        END
    ) as vegetarians
FROM customer_orders_cleaned
GROUP BY customer_id
ORDER BY customer_id; 

--Q.6-->) What was the maximum number of pizzas delivered in a single order?
SELECT order_id,
    COUNT(pizza_id) as pizzas_delivered
FROM customer_orders_cleaned
GROUP BY order_id
ORDER BY pizzas_delivered DESC; 

--Q.7-->) For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT customer_id,
    SUM(
        CASE
            WHEN (
                exclusions IS NOT NULL
                OR extras IS NOT NULL
            ) THEN 1
            ELSE 0
        END
    ) as changes_performed,
    SUM(
        CASE
            WHEN (
                exclusions IS NULL
                AND extras IS NULL
            ) THEN 1
            ELSE 0
        END
    ) as no_changes
FROM customer_orders_cleaned
GROUP BY customer_id
ORDER BY customer_id; 

--Q.8-->) How many pizzas were delivered that had both exclusions and extras?
SELECT SUM(
        CASE
            WHEN (
                exclusions IS NOT NULL
                AND extras IS NOT NULL
            ) THEN 1
            ELSE 0
        END
    ) as exclusions_and_extra
FROM customer_orders_cleaned; 

--Q.9-->) What was the total volume of pizzas ordered for each hour of the day?
SELECT extract(
        hour
        from order_time
    ) AS order_hour,
    COUNT(
        extract(
            hour
            from order_time
        )
    ) AS count_pizza_ordered,
    ROUND(
        100 * COUNT(
            extract(
                hour
                from order_time
            )
        ) / SUM(COUNT(*)) OVER (),
        2
    ) AS volume_pizza_ordered
FROM customer_orders_cleaned
GROUP BY order_hour
ORDER BY order_hour; 

--Q.10-->) What was the volume of orders for each day of the week?
SELECT to_char(order_time, 'Day') AS day_ordered,
    COUNT(to_char(order_time, 'Day')) AS count_pizza_ordered,
    ROUND(
        100 * COUNT(to_char(order_time, 'Day')) / SUM(COUNT(*)) OVER (),
        2
    ) AS volume_pizza_ordered
FROM customer_orders_cleaned
GROUP BY day_ordered
ORDER BY day_ordered; 

------------------------------------------------------------------------------------------
--PART 2: Runner and Customer Experience!
------------------------------------------------------------------------------------------

--Q.1)-->How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select week(registration_date) as RegistrationWeek, count(runner_id) as RunnerRegistrated
from runners
group by RegistrationWeek;

--Q.2)-->What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select runner_id,round(avg(timestampdiff(minute,order_time, pickup_time)),1) as AvgTime
from runner_orders1
inner join customer_orders1
on customer_orders1.order_id = runner_orders1.order_id
where distance != 0
group by runner_id
order by AvgTime;

--Q.3)-->Is there any relationship between the number of pizzas and how long the order takes to prepare?
with cte as(
select c.order_id, count(c.order_id) as PizzaCount, round((timestampdiff(minute, order_time, pickup_time))) as Avgtime
from customer_orders1 as c
inner join runner_orders1 as r
on c.order_id = r.order_id
where distance != 0 
group by c.order_id)
select PizzaCount, Avgtime
from cte
group by PizzaCount;

--Q.4)-->What was the average distance travelled for each customer?
with cte as (
select c.customer_id, round(avg(r.distance),1) as AvgDistance
from customer_orders1 as c
inner join runner_orders1 as r
on c.order_id = r.order_id
where r.distance != 0
group by c.customer_id)
select * from cte;

--Q.5)-->What was the difference between the longest and shortest delivery times for all orders?
with cte as(
select c.order_id, order_time, pickup_time, timestampdiff(minute, order_time,pickup_time) as TimeDiff1
from customer_orders1 as c
inner join runner_orders1 as r
on c.order_id = r.order_id
where distance != 0
group by c.order_id, order_time, pickup_time)
select max(TimeDiff1) - min(TimeDiff1) as DifferenceTime from cte;

--Q.6)-->What was the average speed for each runner for each delivery and do you notice any trend for these values?
with cte as (
select runner_id, order_id, round(distance *60/duration,1) as speedKMH
from runner_orders1
where distance != 0
group by runner_id, order_id)
select * from cte
order by runner_id;


--Q.7)-->What is the successful delivery percentage for each runner?
with cte as(
select runner_id, sum(case
when distance != 0 then 1
else 0
end) as percsucc, count(order_id) as TotalOrders
from runner_orders1
group by runner_id)
select runner_id,round((percsucc/TotalOrders)*100) as Successfulpercentage 
from cte
order by runner_id;

---------------------------------------------------------------------------------------------------------------
--PART 3: Ingredient Optimisation ! 
---------------------------------------------------------------------------------------------------------------
--Q.1-->. What are the standard ingredients for each pizza?
WITH cte AS (SELECT topping_name as meat_lovers, topping_id
		FROM pizza_toppings
		WHERE topping_id != 7 AND topping_id !=9 AND topping_id !=11 AND topping_id != 12),
testing AS ( SELECT topping_name as vegeterian, topping_id
		FROM pizza_toppings
		WHERE topping_id != 1 AND topping_id !=2 AND topping_id !=3 AND topping_id!= 5 AND topping_id != 8 AND topping_id !=10)
SELECT c.meat_lovers, t.vegeterian
FROM cte c
LEFT JOIN testing t ON c.topping_id=t.topping_id
UNION
SELECT c.meat_lovers, t.vegeterian
FROM cte c
RIGHT JOIN testing t ON c.topping_id=t.topping_id;

--Q.2-->. What was the most commonly added extra?
WITH cte AS (SELECT COUNT(extras) AS no_bacon
		FROM customer_orders
		WHERE extras NOT LIKE '1%' 
),
testing AS (SELECT COUNT(extras) as orders_with_bacon
		FROM customer_orders
		WHERE extras LIKE '1%')
SELECT no_bacon,orders_with_bacon
FROM cte, testing;

--Q.3-->. What was the most common exclusion?
WITH cte AS (SELECT COUNT(exclusions) AS exclusions_without_cheese
		FROM customer_orders
		WHERE exclusions NOT LIKE '4%' 
),
testing AS (SELECT COUNT(exclusions) AS exclusions_with_cheese
		FROM customer_orders
		WHERE exclusions LIKE '4%')
SELECT exclusions_without_cheese,exclusions_with_cheese
FROM cte, testing;

/* Q.4--> Generate an order item for each record in the customers_orders table in the format of one of the following: 
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers*/

SELECT *, 
	CASE WHEN pizza_id=1 AND exclusions IS NULL AND extras IS NULL THEN 'Meat Lovers'
	WHEN  pizza_id=2 AND exclusions IS NULL AND extras IS NULL THEN 'Vegeterian'
	WHEN pizza_id=1 AND exclusions='4' AND extras IS NULL THEN 'Meat Lovers-Exclude Cheese'
	WHEN pizza_id=2 AND exclusions='4'AND extras IS NULL THEN 'Vegeterian-Exclude Cheese'
	WHEN pizza_id=1 AND extras='1, 5' AND exclusions='4' THEN 'Meat Lovers-Exclude Cheese - Extra Bacon,Chicken'
	WHEN pizza_id=1 AND extras='1, 4' AND exclusions='2, 6' THEN 'Meat Lovers-Exclude BBQ Sauce,Mushrooms - Extra Bacon,Cheese'
	WHEN pizza_id=1 AND extras='1' AND exclusions IS NULL THEN 'Meat Lovers-Extra Bacon'
	WHEN pizza_id=2 AND extras='1' AND exclusions IS NULL THEN 'Vegeterian-Extra Bacon'
		END AS orders
FROM customer_orders;
            
/*Q.5--> Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"*/
SELECT *, 
	CASE WHEN pizza_id=1 AND exclusions IS NULL AND extras IS NULL THEN 'Meat Lovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami'
	WHEN  pizza_id=2 AND exclusions IS NULL AND extras IS NULL THEN 'Vegeterian: Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce'
	WHEN pizza_id=1 AND exclusions='4' AND extras IS NULL THEN 'Meat Lovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami'
	WHEN pizza_id=2 AND exclusions='4'AND extras IS NULL THEN 'Vegeterian: Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce'
	WHEN pizza_id=1 AND extras='1, 5' AND exclusions='4' THEN 'Meat Lovers: 2xBacon, BBQ Sauce, Beef, 2xChicken, Mushrooms, Pepperoni, Salami'
	WHEN pizza_id=1 AND extras='1, 4' AND exclusions='2, 6' THEN 'Meat Lovers: 2xBacon, Beef, 2xCheese, Chicken, Pepperoni, Salami'
	WHEN pizza_id=1 AND extras='1' AND exclusions IS NULL THEN 'Meat Lovers: 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami'
	WHEN pizza_id=2 AND extras='1' AND exclusions IS NULL THEN 'Vegeterian: Bacon, Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce'
		END AS orders
FROM customer_orders;

-- Q.6-->What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH cte AS (SELECT c.*, 
			CASE WHEN pizza_id=1 AND exclusions IS NULL AND extras IS NULL THEN 'Meat Lovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami'
				WHEN  pizza_id=2 AND exclusions IS NULL AND extras IS NULL THEN 'Vegeterian: Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce'
				WHEN pizza_id=1 AND exclusions='4' AND extras IS NULL THEN 'Meat Lovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami'
				WHEN pizza_id=2 AND exclusions='4'AND extras IS NULL THEN 'Vegeterian: Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce'
				WHEN pizza_id=1 AND extras='1, 5' AND exclusions='4' THEN 'Meat Lovers: 2xBacon, BBQ Sauce, Beef, 2xChicken, Mushrooms, Pepperoni, Salami'
				WHEN pizza_id=1 AND extras='1, 4' AND exclusions='2, 6' THEN 'Meat Lovers: 2xBacon, Beef, 2xCheese, Chicken, Pepperoni, Salami'
				WHEN pizza_id=1 AND extras='1' AND exclusions IS NULL THEN 'Meat Lovers: 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami'
				WHEN pizza_id=2 AND extras='1' AND exclusions IS NULL THEN 'Vegeterian: Bacon, Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce'
                END AS orders
	FROM customer_orders c
	JOIN runner_orders r ON c.order_id=r.order_id
	WHERE cancellation IS NULL),
 testing AS (
SELECT *,
	CASE WHEN orders LIKE '%2xBacon%' THEN (COUNT(pizza_id)+1)
	     WHEN orders LIKE '%Bacon%' THEN COUNT(pizza_id) END AS bacon,
	CASE WHEN orders LIKE '%BBQ Sauce%' THEN COUNT(pizza_id) END AS bbq_sauce,
	CASE WHEN orders LIKE '%Beef%' THEN COUNT(pizza_id) END AS beef,
	CASE WHEN orders LIKE '%2xCheese%' THEN COUNT(pizza_id)+1
	     WHEN orders LIKE '%Cheese%' THEN COUNT(pizza_id) END AS cheese,
	CASE WHEN orders LIKE '%Chicken%' THEN COUNT(pizza_id) END AS chicken,
	CASE WHEN orders LIKE '%Mushrooms%' THEN COUNT(pizza_id) END AS mushrooms,
	CASE WHEN orders LIKE '%Onions%' THEN COUNT(pizza_id) END AS onions,
	CASE WHEN orders LIKE '%Pepperoni%' THEN COUNT(pizza_id) END AS pepperoni,
	CASE WHEN orders LIKE '%Peppers%' THEN COUNT(pizza_id) END AS peppers,
	CASE WHEN orders LIKE '%Salami%' THEN COUNT(pizza_id) END AS salami,
	CASE WHEN orders LIKE '%Tomatoes%' THEN COUNT(pizza_id) END AS tomatoes,
	CASE WHEN orders LIKE '%Tomato Sauce%' THEN COUNT(pizza_id) end as tomato_sauce
FROM cte
GROUP BY unique_id)
SELECT 'bacon' ingredients, SUM(bacon) no_of_ingredients FROM testing
UNION ALL 
SELECT 'bbq_sauce' ingredients, SUM(bbq_sauce) no_of_ingredients FROM testing
UNION ALL
SELECT 'beef' ingredients, SUM(beef) no_of_ingredients FROM testing
UNION ALL
SELECT 'cheese' ingredients, SUM(cheese) no_of_ingredients FROM testing
UNION ALL
SELECT 'chicken' ingredients, SUM(chicken) no_of_ingredients FROM testing
UNION ALL
SELECT 'mushrooms' ingredients, SUM(mushrooms) no_of_ingredients FROM testing
UNION ALL
SELECT 'onions' ingredients, SUM(onions) no_of_ingredients FROM testing
UNION ALL
SELECT 'pepperoni' ingredients, SUM(pepperoni) no_of_ingredients FROM testing
UNION ALL
SELECT 'peppers' ingredients, SUM(peppers) no_of_ingredients FROM testing
UNION ALL
SELECT 'salami' ingredients, SUM(salami) no_of_ingredients FROM testing
UNION ALL
SELECT 'tomatoes' ingredients, SUM(tomatoes) no_of_ingredients FROM testing
UNION ALL
SELECT 'tomato_sauce' ingredients, SUM(tomato_sauce) no_of_ingredients FROM testing
ORDER BY no_of_ingredients DESC;
 
-----------------------------------------------------------------------------------------------------
-- PART 4--PRICING AND RATINGS!
-----------------------------------------------------------------------------------------------------

--Q.1-->If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees? */
WITH cte AS (SELECT
	CASE WHEN pizza_id=1 THEN (count(pizza_id)*12)
		WHEN pizza_id=2 THEN (count(pizza_id)*10)
        END AS prices_per_pizza
FROM customer_orders
GROUP BY pizza_id)
SELECT SUM(prices_per_pizza) AS total_sales
FROM cte;

--Q.2-->What if there was an additional $1 charge for any pizza extras?
SELECT *,
	CASE WHEN pizza_id=1 AND extras IS NULL THEN (count(pizza_id)*12)
		WHEN pizza_id=1 AND extras LIKE '%,%' THEN ((count(pizza_id)*12)+2)
		WHEN pizza_id=1 AND extras NOT LIKE '%,%' THEN ((count(pizza_id)*12)+1)
		WHEN pizza_id=2 AND extras IS NULL THEN (count(pizza_id)*10)
		WHEN pizza_id=2 AND extras LIKE '%,%' THEN ((count(pizza_id)*10)+2)
		WHEN pizza_id=2 AND extras NOT LIKE '%,%' THEN ((count(pizza_id)*10)+1)
        END AS prices_per_pizza
FROM customer_orders
GROUP BY unique_id;

--Q.3-->The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
	order_id INT AUTO_INCREMENT,
	runner_id INT,
	ratings INT,
	PRIMARY KEY(order_id),
	FOREIGN KEY (runner_id) REFERENCES runners(runner_id) ON DELETE SET NULL);
INSERT INTO runner_ratings (runner_id, ratings)   
VALUES
(1,3),(1,2),(1,4),(2,5),(3,2),
(3,NULL),(2,3),(2,2),(2,NULL),
(1,5);
SELECT *
FROM runner_ratings;

/*Q.4-->Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id, order_id, runner_id, rating, order_time, pickup_time, Time between order and pickup, Delivery duration, Average speed, Total number of pizzas*/
SELECT customer_id, r.*, order_time, pickup_time, timediff(pickup_time,order_time) as time_arrival_runner, duration as delivery_duration, CAST(((distance_KM*1000)/time_to_sec(duration))AS DECIMAL(4,2)) as avg_speed, COUNT(pizza_id) as total_pizza_ordered
FROM customer_orders c 
JOIN runner_ratings r ON c.order_id=r.order_id
JOIN runner_orders o ON c.order_id=o.order_id
WHERE pickup_time IS NOT NULL
GROUP BY r.order_id;

/*Q.5-->If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled.
 How much money does Pizza Runner have left over after these deliveries?*/
 WITH cte AS (
	 SELECT distance_KM*0.3 AS distance_cost,
					CASE WHEN pizza_id=1 THEN COUNT(pizza_id)*12
					ELSE COUNT(pizza_id)*10
					END AS total_sales
	FROM customer_orders c 
	JOIN runner_orders o ON c.order_id=o.order_id
	WHERE distance_KM IS NOT NULL
	GROUP BY c.order_id)
 SELECT CAST(SUM(total_sales)-SUM(distance_cost) AS FLOAT4) AS gross_profit
 FROM cte;