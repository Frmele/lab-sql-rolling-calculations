#Get number of monthly active customers.
#Active users in the previous month.
#Percentage change in the number of active customers.
#Retained customers every month.


# 1) Get number of monthly active customers.

Use sakila;
# exploring the data
select customer_id, create_date, active, concat(first_name, ' ',  last_name) as 
customer_name from customer where active=1;

# create a view from the rental table based on rental date by month and rental date by year 
# showing the customer id and the activity date
create view rental_activity as
select customer_id,
convert(rental_date, date) as Activity_date,
date_format(convert(rental_date,date), '%m') as Activity_Month,
date_format(convert(rental_date,date), '%Y') as Activity_year
from sakila.rental;

#sanity check
select * from rental_activity;

# creating statement scoped views to avoid polluting the global namespace, this query reports the 
# total of the monthly active customers grouping the count for each customer by month
      with monthly_active_customers as (select
      customer_id,
      Activity_year, 
      Activity_month  
      from rental_activity) 
      select count(customer_id) as active_customers, Activity_year, Activity_Month 
      from monthly_active_customers 
      group by Activity_month
      order by Activity_year, Activity_month asc;
      
      
#Active users in the previous month.

#storing in a view monthly_active_customers because I need to reuse it 
drop view if exists monthly_active_customers;
create view monthly_active_customers as
select Activity_Month, Activity_year,  
count(customer_id) as Active_customers from rental_activity
group by Activity_year, Activity_Month
order by Activity_year asc, Activity_Month asc;


select * from monthly_active_customers;

select 
   Activity_year, 
   Activity_month,
   Active_customers, 
   lag(Active_customers,1) over (order by Activity_year, Activity_Month) as Last_month
from monthly_active_customers;

#Percentage change in the number of active customers.

# creating statement scoped views to avoid polluting the global namespace, this query reports
# the difference in percentage from the active customers per month on the active customers of the
# previous month
with cte_percentage as (
  select Activity_year, Activity_month, Active_customers, 
  lag(Active_customers,1) over (order by Activity_year) as Last_month
  from monthly_active_customers
)
select Activity_year, Activity_month, Active_customers, Last_month, 
round(((Active_customers - Last_month) / Active_customers) * 100, 2) AS per_diff 
from cte_percentage
where Last_month is not null;

#Retained customers every month.

# To calculate your employee retention rate, divide the number of employees on 
# the last day of the given period by the number of employees on the first day. 
# Then, multiply that number by 100 to convert it to a percentage.


with cte_percentage2 as (
  select Activity_year, Activity_month, Active_customers, 
  lag(Active_customers,1) over (order by Activity_year) as Last_month
  from monthly_active_customers
)
select Activity_year, Activity_month, Active_customers, Last_month, 
round((Active_customers/Last_month)*100,2) AS retention 
from cte_percentage2
where Last_month is not null;