---------------- DATA QUERY LANGUAGE -----------------

-- Let's pretend that we're a manager of a store and it's the first day at the job. We need to get some basic orientation about how the shop operates. Let's dig right in! It's gonna be my SQL practice.

-- 1. Basic operations

-- Q: How many orders have been issued so far?

--select distinct count(orderid) from orders

-- Q: Which customers have placed more than 3 orders?

-- select customerid, count(orderid) from orders
-- group by customerid
-- having count(orderid) >3

-- Q: How many customers have placed more than 3 orders

-- select count(customer5) from
-- (select customerid AS customer5, count(orderid) from orders
-- group by customerid
-- having count(orderid) >3) AS subquery

-- Q: Whcih customer did pay the most tax?
-- select concat(c.firstname,' ', c.lastname) AS "Customer Name", o.customerid, sum(o.tax) as total_tax from orders AS o
-- join customers as c using(customerid)
-- group by o.customerid, c.firstname, c.lastname
-- order by total_tax DESC
-- limit 1

-- Q: Let's create a view which will neatly sum up each customer i.e. how much tax did he pay, how many orders etc.
-- drop view customer_summary

-- create view customer_summary AS
-- select customerid, count(orderid) AS numberorders, round(avg(netamount),2) as avgnetamount, round(avg(tax),2) as avgtax, round(avg(totalamount),2) as avgtotalamount, sum(totalamount) as sumtotalamount
-- from orders
-- group by customerid

-- Q: Great! Now let's use the view. Select the customer with the highest sum of orders. Let's figure out who is the fat fish.
-- select c.firstname, c.lastname, c.country from customer_summary as cs
-- join customers as c using(customerid)
-- where sumtotalamount = (select max(sumtotalamount) from customer_summary)

-- ** STRINGS
--Q: Filter all customers whose city begins with A and ends with D
-- select firstname, lastname, city from customers
-- where city like 'A%D'
--
--Q : Filter all customers who city name contains A
-- select firstname, lastname, city from customers
-- where city like '%A%'

--Q : Filter all customers who city name contains A and it's in the second position in the name
-- select firstname, lastname, city from customers
-- where city like '_A'

--Q: How much are worth big orders for the shop (over 100 euro) and what fraction of the total value they consitute?
-- select round((sum(
-- CASE
--     WHEN totalamount < 100
--     then 0
--     else totalamount
-- END
-- )) /sum(totalamount), 2) AS bigordersonly from orders

-- Q: Please describe how expensive are products by writing cheap/medium/expensive next to them
-- select common_prod_id, price, (
-- CASE
--     when price < 20 then 'cheap'
--     when price between 20 and 40 then 'medium'
--     ELSE 'expensive'
-- END) as price_cat from products

-- Q: A customer asked us about all the dates she placed orders on. Create a column which will list all the dates for each customer.
-- select customerid, array_agg(orderdate) from orders
-- group by customerid;

-- 2. JOINS
-- Q: What was the city name of a person who ordered the biggest amount of items in one order and what was the value of the order?
-- select ol.orderlineid AS "No of items", o.customerid, c.firstname, c.lastname, c.city, ta.sumtotalamount from orderlines AS ol
-- join orders as o using(orderid)
-- join customers as c using(customerid)
-- JOIN (select orderid, sum(totalamount) AS sumtotalamount from orders group by orderid) AS ta using(orderid)
-- where orderlineid = (select max(orderlineid) from orderlines)
-- order by ta.sumtotalamount DESC

-- Q: Are there any customers who haven't placed an order? Who are they?
-- select * from customers
-- LEFT OUTER JOIN orders using(customerid)
-- where orderid is null

-- Q: Write 0 next to these customers name
-- select customers.lastname, COALESCE(orders.orderid, 0) from customers
-- LEFT OUTER JOIN orders using(customerid)
-- where orderid is null

-- Q: Show sum of all products and sum of each product in one query

-- select NULL as "prod_id", sum(ol.quantity)
-- from orderlines as ol
-- UNION
-- select prod_id AS "prod_id", sum(ol.quantity)
-- from orderlines as ol
-- group by prod_id
-- order by prod_id DESC

-- Q: Order customers (name, last name) by the amount of orders they placed
-- with o as
-- (
-- select customerid, count(orderid) from orders
-- group by customerid
-- )
-- select c.firstname, c.lastname, o.count from customers as c
-- JOIN o using(customerid)
-- order by count DESC

-- 3. DATES

-- Q: When was the first order placed and how long ago it was? How many days ago it was?
-- select min(orderdate), extract(epoch from age(min(orderdate)))/(3600*24) as age_oldest from orders

-- Q: What was time difference between the first and the last order?
-- select age(max(orderdate), min(orderdate)) as diff from orders

-- Q: Select all orders from March 2004
-- select orderid, orderdate from orders
-- where date_trunc('month', orderdate) = '2004-03-01'::date

-- Q: Select all orders made on the 13th or 15th day of a month in year 2004
-- select orderid, orderdate from orders
-- where (extract(day from orderdate) = 13 or extract(day from orderdate) = 15) and extract(year from orderdate) = 2004

-- Q: Show number of orders in total, per year and per quarter
-- select date_trunc('year', orderdate)::date as year, date_trunc('quarter', orderdate)::date as month, count(orderid) from orders
-- group by grouping sets(
-- ()
-- date_trunc('year', orderdate)
-- date_trunc('quarter', orderdate)
-- )

-- Q: Show all orders which were less than 30 days older from the newest order
-- select orderid, orderdate from orders
-- where orderdate > (select max(orderdate) from orders) - interval '30 days'
-- order by orderdate desc

-- Q: Show the last order of each customer. 
-- select customerid, orderid, totalamount, orderdate from orders as o
-- JOIN (select customerid, max(orderdate) as max from orders group by customerid) as lo using(customerid)
-- where lo.max = o.orderdate
-- order by customerid;

-- 4. Advanced SQL
-- Windows

-- Q: Show how much each product price deviates from the average price of a product in its category
-- select category, prod_id, price, (AVG(price) OVER (partition by category) - price) as price_cat_avg_diff
-- from products

-- Q: Show how much each product contributed to the whole value of an order
-- select orderid, prod_id, quantity*price as value, round((quantity*price/ sum(quantity*price) over(partition by orderid)),2) as share_in_order
-- from orderlines join products using(prod_id)

-- Q: Show how much each product (quantity * price) contributed to the whole value  of an order
-- select orderid, prod_id, quantity*price as value, round((quantity*price/ sum(quantity*price) over(partition by orderid)),2) as share_in_order
-- from orderlines join products using(prod_id)

-- Q: Rank products within each order by their contribution to the whole value of an order
-- select orderid, prod_id, quantity*price as value, rank() over(partition by orderid order by quantity*price DESC) as rank_in_order
-- from orderlines join products using(prod_id)

-- Q: Show percentage change for each customer for order (total value) for the consecutive orders
-- select customerid, orderid, orderdate, totalamount, (-LAG(totalamount,1) OVER(partition by customerid order by orderdate) + totalamount)*100/totalamount AS pct_change
-- from orders
-- order by customerid, orderdate ASC

-- Q: For each customer-order show the average of the last 3 orders.
-- select customerid, orderid, orderdate, totalamount, avg(totalamount) over(partition by customerid order by orderdate rows between 2 preceding and current row)
-- from orders
-- order by customerid, orderdate

-- Q: Show how much each order (for each customer) contributes to the quarterly value of orders by a customer
-- select customerid, orderid, orderdate, totalamount/ (sum(totalamount) over(partition by customerid, date_trunc('quarter', orderdate))) as quarterly_share
-- from orders
-- order by customerid, orderdate

-- Q: Show how much each order contributes to the value of orders from the last 60 days by a customer
-- select customerid, orderid, orderdate, totalamount, (sum(totalamount) over(partition by customerid order by orderdate RANGE between interval '60' DAY preceding and CURRENT row)) as last_60_days_share
-- from orders
-- order by customerid, orderdate

-- Q: Show value of orders for each customer between the last order and 90 days before.
-- with c as
-- (select customerid, max(orderdate) as max_date, (max(orderdate) - interval '90 days')::date AS min_date from orders group by customerid)
-- select customerid, sum(totalamount), max(orderdate) AS last_order from orders as o
-- join c using(customerid)
-- where o.orderdate > c.min_date
-- group by customerid
-- order by sum DESC

-- Q: Show the last 2 orders for each customer
-- with c as 
-- (
-- select customerid, orderid, orderdate, totalamount, rank() over(partition by customerid order by orderdate DESC range between unbounded preceding and unbounded following) as rank from orders
-- )
-- select * from c
-- where rank <3;

---------------- DATA MANIPULATION LANGUAGE -----------------

-- naming convention
-- Super important to follow common standards.
-- Naming conventions:
-- - table names must be singular (so student not students)
-- - columns must be lowercase with underscores
-- - columns with mixed case are acceptable (better student_id than StudentID)
-- - columns with uppercase are unacceptable
-- - be consistent! write down your rules!

-- Q: Create a table which will show a chemical composition of a product (very basic)
-- DROP TABLE IF EXISTS composition;
--CREATE TYPE quality_prod AS ENUM ('bad', 'ok', 'good');
-- create table composition(
-- prod_id int unique,
-- CONSTRAINT fk_prod foreign key(prod_id) references products(prod_id),
-- quality quality_prod, -- 3 categories of product quality, please be honest!!!
-- coal_share float NOT NULL, check (coal_share >= 0 AND coal_share <= 100), -- percentage share of coal in product
-- description VARCHAR(1000)
-- );
-- 
-- Q: Add a column that will contain info about how much water there is in the product
-- alter table composition
-- add water_share float not null check (water_share >= 0 AND water_share <= 100);
-- select * from composition;
-- 
-- Q: In the hindsight, we can say that water_share column is not necessary. Let's drop it.
-- alter table composition
-- drop water_share;
-- 
-- Q: Insert 3 rows of data into the table
-- insert into composition (prod_id, quality, coal_share, description) values
-- (1, 'good', 1.23, 'Some funny product description'),
-- (2, 'bad', 7.7777777, 'What is a description?'),
-- (8, 'ok', 2.22, 'Desc lala ');
-- 
-- Q: Add 2 rows of data but add only these columns which are necessary
-- insert into composition (prod_id, coal_share) values
-- (3, 8.233),
-- (4,55.5);
-- 
-- Q: Add descriptions to rows where it's missing.
-- update composition
-- set description='We wait for a good description'
-- where description IS NULL;