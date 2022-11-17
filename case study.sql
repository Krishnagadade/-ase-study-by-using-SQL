CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
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
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

create temporary table t1 as ( select s.customer_id,s.order_date,s.product_id,m.product_name,m.price,r.join_date
							 from sales s
							 left join menu m
							 on s.product_id=m.product_id
							 left join members r
							 on s.customer_id=r.customer_id)

1.What is the total amount each customer spent at the restaurant?
select * from t1
select distinct(customer_id),sum(price) over(partition by customer_id)
from t1
order by customer_id

2.How many days has each customer visited the restaurant?

select distinct(customer_id),count(order_date) over(partition by customer_id)
from t1
order by customer_id


3.What was the first item from the menu purchased by each customer?
select a.customer_id,a.product_name
from (select customer_id,product_name,row_number() over(partition by customer_id order by order_date) as row
from t1) as a
where a.row =1

4.What is the most purchased item on the menu and how many times was it purchased by all customers?

select b.customer_id,b.product_name
from (select a.customer_id,a.product_name,row_number() over(partition by a.customer_id order by a.count desc )
from (select customer_id,product_name,count(product_name)
from t1
group by customer_id,product_name
order by customer_id,count(product_name) desc) as a) as b
where b.row_number =1


5.Which item was purchased first by the customer after they became a member?
select a.customer_id,a.order_date,a.product_name,a.join_date 
from (select customer_id,order_date,product_name,join_date,count(product_id),row_number() over(partition by customer_id order by order_date)
from t1
where order_date > join_date
group by customer_id,order_date,product_name,join_date
order by customer_id,order_date) as a
where a.row_number = 1


6.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select distinct(a.customer_id), sum(a.points) over(partition by a.customer_id) as total_points
from (select customer_id,case when product_name ='sushi' then price*2 else price*1 end as points
from t1) as a
order by a.customer_id



7.In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
not just sushi 
- how many points do customer A and B have at the end of January?
select distinct(a.customer_id), sum(a.points) over(partition by a.customer_id) as total_points
from (select customer_id,order_date,(price*2)as points
from t1
where order_date > join_date and order_date < '2021-02-01') as a
order by a.customer_id





