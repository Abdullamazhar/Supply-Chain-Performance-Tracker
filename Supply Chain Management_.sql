-- Total Sales (MTD, QTD, YTD):
WITH temp_table AS (
    SELECT
        s.date,
        p.`Sales Amount`
    FROM sales s
    JOIN pos p ON s.`Order Number` = p.`Order Number`
)
SELECT 
    YEAR(date) AS year_col,
    MONTH(date) AS month_col,
    DATE(date) AS date_col,
    
    -- Month-to-date sales
    SUM(CASE
            WHEN YEAR(date) = YEAR('2023-04-06') 
             AND MONTH(date) = MONTH('2023-04-06') 
             AND DATE(date) <= '2023-04-06'
            THEN `Sales Amount`
            ELSE 0
        END) AS MTD_Sales,

    -- Quarter-to-date sales
    SUM(CASE
            WHEN YEAR(date) = YEAR('2023-04-06') 
             AND QUARTER(date) = QUARTER('2023-04-06') 
             AND DATE(date) <= '2023-04-06'
            THEN `Sales Amount`
            ELSE 0
        END) AS QTD_Sales,

    -- Year-to-date sales
    SUM(CASE
            WHEN YEAR(date) = YEAR('2023-04-06') 
             AND DATE(date) <= '2023-04-06'
            THEN `Sales Amount`
            ELSE 0
        END) AS YTD_Sales

FROM temp_table
GROUP BY YEAR(date), MONTH(date), DATE(date)
ORDER BY date_col;

-- Product Wise Sales
with temp_table as (
select
i.`product type`,
p. `sales Amount`
from inventory_adjusted i join pos p on i.`Product Key` = p.`Product Key`)
select `product type`, concat('$',round(sum(`sales Amount`))) as Total_sales 
from temp_table
group by 1;

-- Sales Growth:
with Temp_table as (
select
s.date,
p.`Sales Amount`
from sales s join pos p on s.`Order Number` = p.`Order Number`)
select
 YEAR(Date) AS year_col, sum(`Sales Amount`) as total_sales,
    CONCAT(ROUND(((SUM(`Sales amount`) - LAG(SUM(`Sales amount`)) OVER (ORDER BY YEAR(Date))) / LAG(SUM(`sales amount`)) OVER (ORDER BY YEAR(Date))) * 100, 2),"%") AS yoy_growth
    from temp_table
    group by 1;

-- Daily Sales Trend:
with temp_table as (
select 
s.date,
p.`sales amount`
from sales s join pos p on s.`Order Number` = p.`Order Number`)
select
year(Date) year_col, concat('$',round(sum(`Sales Amount`))) total_sales
from temp_table
group by 1
order by 1;

-- State Wise Sales:
with temp_table as (
select
s.`store key`,
p. `sales amount`
from sales s join pos p on s.`Order Number` = p.`Order Number`),
temp_table2 as (
select
st.`store state`,
tt. `sales amount`
from temp_table tt join stores st on st.`store key` = tt.`store key`)
select 
`store state`,
concat('$',round(sum(`sales amount`))) Total_sales
from temp_table2
group by 1;

-- Top 5 Store Wise Sales:
with temp_table as (
select
s.`store key`,
p. `sales amount`
from sales s join pos p on s.`Order Number` = p.`Order Number`),
temp_table2 as (
select
st.`store Name`,
tt. `sales amount`
from temp_table tt join stores st on st.`store key` = tt.`store key`)
select 
`store Name`,
sum(`sales amount`) Total_sales
from temp_table2
group by 1
order by 2 desc
limit 5;

-- Region Wise Sales:
with temp_table as (
select
s.`store key`,
p. `sales amount`
from sales s join pos p on s.`Order Number` = p.`Order Number`),
temp_table2 as (
select
st.`store Region`,
tt. `sales amount`
from temp_table tt join stores st on st.`store key` = tt.`store key`)
select 
`store region`,
concat('$',sum(`sales amount`)) Total_sales
from temp_table2
group by 1;


-- Total Inventory:
select sum(`quantity on hand`) as Total_inventory 
from inventory_adjusted;

-- Inventory Value
with avg_cost_per_product as (
select
`product key`,
sum(`cost amount`)/sum(`sales quantity`) as avg_unit_cost         -- since cost-AMOUNT in the pos table is total cost for every transaction. 1st avg unit cost per transaction.
from pos
group by 1),
inventory_value as(
select
ia.`product key`,
ia.`quantity on hand`,
ac.avg_unit_cost,
ia.`quantity on hand` * ac.avg_unit_cost as product_inventory_value
from inventory_adjusted ia join avg_cost_per_product ac on ia.`Product Key` = ac.`product key`)
select 
concat('$',round(sum(product_inventory_value))) as Total_inventory_values
from inventory_value;

-- Overstock, Out-of-stock, Under-stock
select 
`product key`,`product name`,`quantity on hand`,min_quantity,
case
when `quantity on hand` <=0 then 'out-of-stock'
when `quantity on hand` < min_quantity then 'under-stock'
else 'in-stock'
end as inventory_stock
from inventory_adjusted;

-- purchase method vs sales
with temp_table as (
select 
s.`Purchase MEthod`,
p. `Sales Amount`
from sales s join pos p on s.`Order Number` = p.`Order Number`)
select `purchase Method`, concat('$',sum(`sales amount`)) as Total_sales
from temp_table
group by 1;