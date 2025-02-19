Q1 - High Freq Customers

with order_count as 
(
    select 
        month(date(order_date)) as month,
        year(date(order_date)) as year,
        customer_id,
        count(distinct order_id) as cnt_order,
        case when cnt_order >= 30 then 1 else 0 END as high_freq_customer
    FROM table
    where year(date(order_date))  = 2023
    group by 1,2,3
    order by 4 desc
),

high_freq_count as 
(
    select month, year,
    count(distinct cutomer_id) as cnt_cust_total,
    count(distinct case when high_freq_cutomer = 1 then customer_id end) as cnt_high_freq_cust
    from order_count
    group by 1,2
)

select month,year, 
    round(cnt_high_freq_cust / cnt_cust_total *100, 3) as perct_high_freq
FROM high_freq_count
order by 1,2


Q2 - Highest Non-Freq Customers

with order_count as 
(
    select 
        month(date(order_date)) as month,
        year(date(order_date)) as year,
        customer_id,
        count(distinct order_id) as cnt_order,
        case when cnt_order >= 30 then 1 else 0 END as high_freq_customer
    FROM table
    where year(date(order_date))  = 2023
    group by 1,2,3
    order by 4 desc
),

 high_freq_rank as 
(
    select *, 
        rank() over (partition by high_freq_customer, month, year ORDER BY cnt_order desc) end as rank_high_freq
    FROM order_count
    where year(date(order_date))  = 2023
    group by 1,2,3
    order by 4 desc
),

high_freq_rank_all AS 
(
SELECT
    customer_id,
    order_mth,
    RANK() OVER (ORDER BY cnt_order DESC) AS overall_rank
    FROM order_count
    WHERE high_freq_customer = 1
)


high_freq_count as 
(
    select month, year,
    count(distinct cutomer_id) as cnt_cust_total,
    count(distinct case when high_freq_cutomer = 0 and rank_high_freq = 1 then customer_id end) 
        as cnt_high_freq_cust
    from order_count
    group by 1,2
)

select month,year, 
    round(cnt_high_freq_cust / cnt_cust_total *100, 3) as perct_high_freq
FROM high_freq_count
order by 1,2


Q3 - Resturant Sales

with rest_sales as
(
    select 
        month(date(order_date)) as month,
        year(date(order_date)) as year,
        restu_id,
        SUM(order_value) AS sales_total
        --case when cnt_order >= 30 then 1 else 0 END as high_freq_customer
    FROM table
    where year(date(order_date))  = 2023
    group by 1,2,3
    order by 4 desc
),

rest_sales_months as (
    SELECT
        month, 
        year, 
        restu_id, 
        total_sales,
        lag(total_sales,1) over (partition by restu_id ORDER BY month ASC) as sales_last_month,
        lead(total_sales,1) over (partition by restu_id ORDER BY month ASC) as sales_next_month
    FROM rest_sales
    ORDER BY
        restaurant_id, month
        
)

select month, year, restu_id,
    total_sales - sales_last_month as MoM
FROM rest_sales_months
WHERE Year = 2023 and month > 1 and restu_id = XXX
order by month, year


Q4 -- Quartile

with rest_sales as
(
    select 
        month(date(order_date)) as month,
        year(date(order_date)) as year,
        restu_id,
        SUM(order_value) AS sales_total
        --case when cnt_order >= 30 then 1 else 0 END as high_freq_customer
    FROM table
    where year(date(order_date))  = 2023
    group by 1,2,3
    order by 4 desc
),

rest_sales_quartile as (
    select *,
        ntile(4) over (partition by month order by sales_total) as quartile
    FROM rest_sales
),


cust_rest_status as 
(
    select 
        month,
        year,
        count(distinct cutomer_id) as cnt_cust_total,
        count(distinct case when rq.quartile = 4 then customer_id end) as cnt_low_q_c
        from customer_table as a
            left join rest_sales_quartile as b on
                a.resturant_id = b.resturant_id
)

select month, year
    round(cnt_low_q_c / cnt_cust_total,2) as perct_low_q
    from cust_rest_status
    group by 1,2
