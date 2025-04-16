--- monday cofee-- data Analysis-----
select * from city;
select *from customers;
select *from sales;
select * from products;

-----repoert and Data Analysis--------
----Q1. coffee consumers count

--- how many people in each city  are estimate to consume coffe,given that 25% of population does?
select city_name,
round((population *0.25)/1000000,2),
city_rank
from city order by  2 desc;


--Q2 Total revenue from coffe sale 
-- what is is the total revenue generated from coffee sales across all cities in the last quater of 2023
select *, extract(year from sale_date)as year , extract(quarter from sale_date)as quater from  sales
where extract( year from sale_date)=2023 and extract( quarter  from sale_date)=4;


select 
    ci. city_name,
	Sum(s.total)as total_revenue from sales as s

join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id where extract(year from s. sale_date)=2023 and extract(quarter from s.sale_date)=4
group by 1
order by 2 desc

--Q.3
--sales count for Each products
--how many units of each coffe products have sold?
select   p.product_name,count(s.sale_id)as total_orders from products as p
left join sales as s on s.product_id=p.product_id group by 1 
order by 2 desc


--Q.4 
--Average sales Amount per City
--what is the average sales amount per customer in each city?

--city average total sale 
--no customer in each these city

select 
    ci. city_name, sum(s.total)as total_revenue ,
	count(s.customer_id) as total_customers,
	round(
	
---"::numeric "--type casting

	    sum(s.total)::numeric /count(distinct s.customer_id):: numeric,2) as avg_sale_per_customer
	
	from  sales as s
	join customers as c on s.customer_id=c.customer_id
	join city as ci  on ci.city_id=c.city_id
	 
	group by 1
	order by 2 desc



---Q.5 
----city population and coffe consumers(25%)
----provies a list of  cities along with  their populations and estimated coffe consumers.
---- return city_name,total current customers, estimated coffe consumers(25%)
with city_table as
(
   select
        city_name,
		round((population*0.25)/1000000,2)as coffe_consumers from city),

		customers_table as
		(

		  select ci.city_name,
		  count(distinct c.customer_id)as unique_customers
		  from sales as s
		  join customers as c
		  on c.customer_id=s.customer_id
		  join city as ci
		  on ci.city_id =c.city_id
		  group by 1
		)
		select 
		   customers_table.city_name,
		   city_table.coffe_consumers as coffee_consumers_in_millions,
		   customers_table.unique_customers 
		   from city_table
		   join customers_table
		   
		   on city_table.city_name= customers_table.city_name


---Q.6
---top Selling product by city
---what are the top 3 selling products in each city based on sales volume?

select  * from --table
(
select
  ci.city_name,
  p.product_name,
  count(s.sale_id) as total_orders,
  dense_rank()over(partition  by ci.city_name order by count(s.sale_id)desc)as rank
from sales as s
join products as p
on s.product_id =p.product_id
join customers as c
on c.customer_id= s.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1,2    ---1 means first column 2 means second column 
---order by 1,3 desc
) as t1
where rank <=3


--Q.7
--customer segmentation by city
--how many unique customers are there in each city who have purchased coffee product?

select 
      ci.city_name,
	  count(distinct c.customer_id)as unique_customers
	from city as ci
	left join 
	customers as c
	on c.city_id=ci.city_id
	join sales as s
	on s.customer_id =c.customer_id
	where  s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14) group by 1

---Q.8
--average sale vs Rent
---find each city and their average sale per customer and avg   rent per customer

--conclusion------
with city_table 
as( select
        ci.city_name,
		sum(s.total)as total_revenue,
		count(distinct s.customer_id)  as total_customers,
		round( 
		       sum(s.total)::numeric/count(distinct s.customer_id)::numeric,2) as avg_sale_per_customers
			   from sales as s
			   join customers as c
			   on s.customer_id=c.customer_id
			   join city as ci
			   on ci.city_id=c.city_id
			   group by 1
			   order by 2 desc
        
),
city_rent
as
(select
   city_name,
   estimated_rent
   from city
   
)
select
   cty_rent.city_name,
   cty_rent.estimated_rent,
   cty.total_customers,
   cty.avg_sale_per_customers,
  round (cty_rent.estimated_rent :: numeric/cty.total_customers ::numeric,2) as avg_rent_per_customers
  from city_rent as cty_rent
  join city_table as cty
  on cty_rent.city_name=cty.city_name
  order by 5 desc


 --monthly sales growth
 -- sales growth rate: calculate the percentage growth(or decline)in sales over diffrent time periods(monthly)
 --by each city
with monthly_sales as
      
	 (select 
	 ci.city_name,
	 extract(month from sale_date)as month,
	 extract(year from sale_date)as year,
	 sum(s.total)as total_sale
	
	from sales as s
	join customers as c
	on c.customer_id = s.customer_id
	join city as ci
	on ci.city_id= c.city_id
	group by 1,2,3
	
	order by 1,3,2
),
growth_ratio
as(
	select 
	   city_name,
	   month,
	   year,
	   total_sale as cr_month_sale ,
	    lag(total_sale,1)over(partition by city_name order by year, month) as last_month_sale from monthly_sales
 )
 select 
      city_name,
	  month,
	  year,
	  cr_month_sale,
	  last_month_sale,
	  round((cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric *100,2)
	  as growth_ratio
	  from growth_ratio
where last_month_sale is not null


--Q.10
--Maret potential Analysis
--Identify top 3 city based on highest sales, return city name,total sale, total rent,total customers,estimated coffee consumers

with city_table as
(
   select
      ci.city_name,
	  sum(s.total)as total_revenue,
	  count(distinct s.customer_id)as total_customers,
	  round( sum(s.total)::numeric/ count(distinct s.customer_id)::numeric ,2)as avg_sale_per_customers
	  from sales as s
	   join customers as c
	   on s.customer_id=c.customer_id
	   join city as ci
	   on ci.city_id =c.city_id
	   group by 1
	   order by 2 desc
	   ),
	   city_rent as
	   (select
	        city_name,
			estimated_rent ,
			round((population * 0.25)/1000000 ,3) as estimated_coffee_consumer_in_millions
			from city 
	   )

		select
		   cty_rent.city_name,
		   total_revenue,
		   cty_rent.estimated_rent as total_rent,
		   cty.total_customers,
		   estimated_coffee_consumer_in_millions,
		   cty.avg_sale_per_customers,
		   round(cty_rent.estimated_rent::numeric/ cty.total_customers::numeric ,2) as avg_rent_per_customers
		   from city_rent as cty_rent
		   join city_table as cty
		   on cty_rent.city_name = cty.city_name
		   order by 2 desc
			
	   
/*
----recommandation
city 1: pune
1.avg rent per customers is very less,
2. highest total revenue,
3.avg_sale per customers is also high


city 2:  delhi
  1.highest estimated coffee consumers which is 7.7M
  2.highest total customers which is  68
  3.avg rent per customers 330 (still under 500)


city 3.jaipur
     1.highest customers no which is 69
	 2.avg rent per customers is very less 156
	 3.avg sale per customers is better which at 11.6k


  

	  
   