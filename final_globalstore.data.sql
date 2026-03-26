use global_store_dataglobal_store_datafinal_master_reportfinal_master_reportfinal_master_reportfinal_master_reportfinal_master_reportfinancial_record;
select count(*) from global_store_data;

-- Data integrity check --
select count(*) from global_store_data
where order_id is NULL;

-- data check --
select order_id, customer_name, sales, profit, order_date
from global_store_data
limit 10;


-- which category gives most of the profit--

select category,
sum(sales) AS Total_sales,     
sum(profit) AS Total_profit
from global_store_data
group by category
order by Total_profit DESC;

-- month se Year wise total sales--

select year(order_date) AS Sales_year,
sum(sales) AS yearly_total
from global_store_data 
Group by Sales_year
order by Sales_year;

-- top 10 order due to highest loss--

select order_id, customer_name, profit, country
from global_store_data
where profit <0
order by profit asc
limit 10;

-- top 5 most profitable countries --

select country,
sum(sales) as Total_sales,
sum(profit) AS Total_profit
from global_store_data
group by country
order by Total_profit DESC
limit 5;

-- Category-wise  PROFITABILITY CHECK --

Select category, 
sum(sales) as Total_sales,
sum(profit) as Total_profit,
(sum(profit))/(sum(sales))*100 AS profit_margin_percent
from global_store_data
group by category
order by profit_margin_percent desc;



-- Shipping cost analysis --

select ship_mode,
avg(shipping_cost) as avg_shipping_cost,
sum(profit) as Total_profit
from global_store_data
group by ship_mode;

-- Shipping delay analysis --

SELECT order_priority, 
       AVG(DATEDIFF(ship_date, order_date)) AS avg_delivery_days
FROM global_store_data
GROUP BY order_priority;

-- find out top 5 customers --

select customer_name,
sum(sales) AS lifetime_sales_value
from global_store_data
group by customer_name
order by lifetime_sales_value desc
limit 5;


-- Data integreity check (remove duplicates) --

select order_id, count(*)
from global_store_data 
group by order_id
having count(*) >1;

-- duplicate removal--  
CREATE TABLE global_store_data_clean AS 
SELECT DISTINCT * FROM global_store_data;

DROP TABLE global_store_data;
ALTER TABLE global_store_data_clean RENAME TO global_store_data;
SELECT order_id, COUNT(*) 
FROM global_store_data 
GROUP BY order_id 
HAVING COUNT(*) > 1;

-- Kya poori row duplicate hai?
SELECT order_id, product_id, COUNT(*) 
FROM global_store_data 
GROUP BY order_id, product_id 
HAVING COUNT(*) > 1;



SELECT order_id, product_id, COUNT(*) AS duplicate_count
FROM global_store_data 
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

-- Data integrity check --
select count(*) from global_store_data
where order_id is NULL;
select *from global_store_data;

-- 1. Purani table ko delete karna (Safety Step)
DROP TABLE IF EXISTS final_master_report;

-- 2. Nayi Master Table banana (Raw Data + Analysis)
CREATE TABLE final_master_report AS
SELECT 
    -- 'table_name.*' likhna safe hota hai taaki saare purane columns aa jayein
    g.*, 

    -- Delivery Days (Check karein: ship_date aur order_date DATE format mein hone chahiye)
    DATEDIFF(g.ship_date, g.order_date) AS delivery_days,
    
    -- Profit Margin % (NULLIF prevents 'Division by Zero' error)
    (g.profit / NULLIF(g.sales, 0)) * 100 AS profit_margin_percent,
    
    -- Shipping Cost Ratio
    (g.shipping_cost / NULLIF(g.sales, 0)) * 100 AS shipping_cost_ratio,
    
    -- Year & Month extraction
    YEAR(g.order_date) AS order_year,
    MONTH(g.order_date) AS order_month,

    -- Business Logic: Delivery Performance
    CASE 
        WHEN g.order_priority = 'Critical' AND DATEDIFF(g.ship_date, g.order_date) > 2 THEN 'Delayed Critical'
        WHEN g.order_priority = 'Critical' AND DATEDIFF(g.ship_date, g.order_date) <= 2 THEN 'On-Time Critical'
        ELSE 'Standard Delivery'
    END AS delivery_performance_status

FROM global_store_data g;

-- 3. Verify karne ke liye ki data aa gaya hai
SELECT * FROM final_master_report LIMIT 10;
SELECT count(*) AS total_rows FROM final_master_report;
SELECT * FROM final_master_report LIMIT 10;
SELECT * FROM final_master_report LIMIT 0;