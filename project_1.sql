create database extra_project;
use extra_project;
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-04-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-02-09'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-09-11',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-10-11',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

#1)What is total amount each customer spent on Zomato
select s.userid,sum(p.price) as total_amount_spent from sales s inner join  product p
on p.product_id =s.product_id 
group by userid;

#2)How many days has each customer visited zomato?
select userid, count(distinct created_date) as distinct_days  from sales 
 group by userid;
 
 #3)Which was the first product purchase by each customer?
select *,
RANK() OVER (
    PARTITION BY userid order by created_date )  as rnk from sales a where rnk=1;
 
 #4)What is most purchased item on the menu and how many times was it purchased by all customers?
select userid,product_id from sales where product_id=
(select product_id from sales group by product_id order by count(product_id)desc limit 1)
group by userid;

#5)which item was most popular for each customer?
SELECT *
FROM(SELECT *,RANK() OVER (PARTITION BY userid ORDER BY cnt DESC) AS rnk
FROM(SELECT userid,product_id,COUNT(product_id) AS cnt FROM sales GROUP BY userid,product_id) a) b
WHERE rnk = 1;

#6)Which item was purchased first by the customer after they became a member?
select * from 
(select c.*,rank() over( partition by userid order by created_date )as rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b
 on a.userid=b.userid  and created_date>gold_signup_date) as c)d where rnk=1;
 
 #7)which item was purchased just before the customer became a member?
 select * from 
(select c.*,rank() over( partition by userid order by created_date desc )as rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b
 on a.userid=b.userid  and created_date<=gold_signup_date) as c)d where rnk=1;

#8)What is total amount and orders spent for each member before they became member?
select userid,count(created_date) as order_purchased,sum(price) as total_amt_spent from
(select c.*,d.price from 
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b
 on a.userid=b.userid  and created_date<=gold_signup_date) as c inner join product d on c.product_id=d.product_id) as e 
 group by userid;
 
 #9)If buying each product generates points for eg 5rs=2 zomato point and each product has different zomato points for eg 
 #for eg  for p1 5rs=1 zomato point ,for p2 10rs=5 zomato point and p3 5rs=1 zomato point 2 rs=1zomato point
 #calculate points  collected by each customers and for which product most points have been given till now
 select userid,sum(total_points)*2.5 as total_points_earned  from
 (select e.*,amt/points as total_points from 
 (select d.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from 
 (select c.userid,c.product_id,sum(price) as amt from 
 (select a.*,b.price from sales a inner join product b on a.product_id=b.product_id) as c
 group by userid,product_id) as d)as e)f group by userid;
 
select * from 
(select * ,rank() over(order by total_points_earned desc) as rnk from 
(select product_id,sum(total_points) as total_points_earned  from
 (select e.*,amt/points as total_points from 
 (select d.*,case when product_id=1 then 5 when product_id=2 then 2 when product_id=3 then 5 else 0 end as points from 
 (select c.userid,c.product_id,sum(price) as amt from 
 (select a.*,b.price from sales a inner join product b on a.product_id=b.product_id) as c
 group by userid,product_id) as d)as e)f group by product_id)f)g where rnk=1;
 
 #10)In the first one year after a customer joins the gold program (including their join date)irrespective 
 #of what customer has purchased they earn 5 zomato points for every 10 rs spent who earned more 1 or 3 
 #and what was their points earnings in their first yr?
 #1zp=2 rs
 #0.5z1rs
 
 select c.*,d.price*0.5 total_points_earned from
 (select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b
 on a.userid=b.userid  and created_date>gold_signup_date and created_date <=date_add(gold_signup_date,interval 365 day))as c inner join
 product d on c.product_id=d.product_id;
 
 #11)Rank all the transaction of customers
 select *,rank()over(partition by userid order by created_date ) rnk from sales;
 
 #12)rank all the transactions for each member whenever they are a zomato gold member for every non gold member
 #transaction mark as na
 select c.*,case when gold_signup_date is null then 'na'else rank()over(partition by userid order by created_date  desc)end as rnk from 
 (select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a left join goldusers_signup b
 on a.userid=b.userid  and created_date>gold_signup_date)as c;
 
# OR

 select e.*,case when rnk=0 then 'na'else rnk end  as rnk from 
 (select c.*,case when gold_signup_date is null then 'na'else rank()over(partition by userid order by created_date  desc)end as rnk from 
 (select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a left join goldusers_signup b
 on a.userid=b.userid  and created_date>gold_signup_date)as c)e;
 
 #ssert cast function for case function,after end put as varchar