select * from credit_card_transactions;

select min(transaction_date), max(transaction_date) from credit_card_transactions;-----2013-10-04 to 2015-05-26

select distinct card_type from credit_card_transactions;---Silver, Signature, Gold, Platinum

select distinct exp_type from credit_card_transactions;---- Entertainment, Food, Bills, Fuel, Travel, Grocery

--1-write a query to print top 5 cities with highest spends 
--and their percentage contribution of total credit card spends 


with city_wise_table as
(select city, sum(amount) as spend
from credit_card_transactions
group by city)

,rank_spend_table as
(select *,
row_number() over(order by spend desc) as rn,
sum(spend) over(order by city rows between unbounded preceding and unbounded following) as total_spend
from city_wise_table)

select city,round((spend*1.0/total_spend)*100,2) as per
from rank_spend_table
where rn<=5

---below is the solution using Join

with cte1 as
(select city, sum(amount) as spend
from credit_card_transactions
group by city)

,cte2 as
(select sum(amount) as total_spend from credit_card_transactions)

select top 5 city,(spend*1.0/total_spend)*100 as per
from cte1 c1
inner join cte2 c2 on 1=1
order by spend desc


--2- write a query to print highest spend month and amount spent in that month for each card type

with card_yr_mo_table as
(select card_type,year(transaction_date) as yr, month( transaction_date) as mo, sum(amount) as ts
from credit_card_transactions
group by card_type,year(transaction_date), month( transaction_date))

,rank_table as
(select *, row_number() over(partition by card_type order by ts desc) as rn
from card_yr_mo_table)

select * from rank_table
where rn=1

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of  1,000,000 total spends(We should have 4 rows in the o/p one for each card type)

with running_sal_tab as
(select *, sum(amount) over (partition by card_type order by transaction_date,transaction_id) as running_sal
from credit_card_transactions)

,rank_tab as 
(select *, row_number() over( partition by card_type order by running_sal) as rn
  from running_sal_tab
  where running_sal>=1000000)

  select * from 
  rank_tab
  where rn=1

  --4- write a query to find city which had lowest percentage spend for gold card type
     with city_card_wise as
	 (select city, card_type, sum(amount) as spend
	 from credit_card_transactions
	 group by city, card_type)

	 ,total_spend as
	 (select *, sum(spend) over( partition by city order by card_type rows between unbounded preceding and unbounded following) as ts
	 from city_card_wise)

	 select top 1 *, round((spend*1.0/ts)*100,2) as per
	 from total_spend
	 where card_type = 'Gold'
	 order by per;

	 ---below is the solution using case when
	 with city_card_tab as
	 (select city,card_type, sum(amount) as spend, sum(case when card_type= 'Gold' then amount end) as gold_amount
	 from credit_card_transactions
	 group by city, card_type)

	 select top 1 city, sum(gold_amount)*1.0/sum(spend) as per
	 from city_card_tab
	 group by city
	 having sum(gold_amount) is not null
	 order by per asc

	 

  ---5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

  with city_exp_tab as
   (select city, exp_type, sum(amount) as spend
	from credit_card_transactions
	group by city, exp_type)

	,rank_tab as
	(select *, row_number() over(partition by city order by spend desc) as dern
	,row_number() over(partition by city order by spend asc) as arn
	from city_exp_tab)
	
	select city ,min(case when dern = 1 then exp_type end) as highest_exp_type, min(case when arn=1 then exp_type end) as lowest_expense_type
	from rank_tab 
	group by city;


 ----6- write a query to find percentage contribution of spends by females for each expense type

 with exp_gen_tab as
    (select exp_type,gender, sum(amount) as spend
	from credit_card_transactions
	group by exp_type,gender)

	,total_spend_tab as
	(select *, sum(spend) over(partition by exp_type order by spend rows between unbounded preceding and unbounded following) as ts 
	from exp_gen_tab)

	select exp_type, round((spend*1.0/ts)*100,2) as per
	from total_spend_tab
    where gender = 'F';

	 ---below is the solution using case when

	 select exp_type, sum(case when gender = 'F' then amount else 0 end)*1.0/sum(amount) as per
	 from credit_card_transactions
	 group by exp_type
	 order by per desc


 -----7- which card and expense type combination saw highest month over month growth in Jan-2014

      with combo_tab as
      (select card_type,exp_type,datepart(year,transaction_date) as yt,datepart(month,transaction_date) as mt, sum(amount) as spend
	  from credit_card_transactions
	  group by card_type,exp_type,datepart(year,transaction_date),datepart(month,transaction_date))

	  ,lag_spend_tab as
	  (select *, lag(spend,1) over(partition by card_type,exp_type order by yt,mt) as Pre_month_spend
	  from combo_tab)

	  select top 1  *, (spend*1.0/Pre_month_spend)-1 as mom_growth
	  from lag_spend_tab
	  where yt=2014 and mt=01
	  order by mom_growth desc;

 -----8- During weekends which city has highest total spend to total no of transcations ratio 
  
   select top 1 city, sum(amount)*1.0/count(*) as ratio
   from credit_card_transactions
   where datepart(weekday,transaction_date) = '1' or datepart(weekday,transaction_date) = '7'
   group by city
   order by ratio desc

-----9- which city took least number of days to reach its 500th transaction after the first transaction in that city

  with rank_tab as
  (select *, row_number() over(partition by city order by transaction_date, transaction_id) as running_days
  from credit_card_transactions)

  ,trans_tab as
  (select city, min(case when running_days = 1 then transaction_date end )as first_trans,min(case when running_days = 500 then transaction_date end )as last_trans
  from rank_tab
  group by city
  having count(running_days) >=500)

  select city, datediff(day,first_trans,last_trans) as diff_in_days
  from trans_tab
  order by diff_in_days



   








