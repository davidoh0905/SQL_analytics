DROP TABLE IF EXISTS temp.running_avg ;
CREATE TABLE IF NOT EXISTS temp.running_avg (
    dt string
    ,x int
  )
  

insert overwrite table temp.running_avg
select * from 
(
select stack(
    10,                 
'20180101',7,
'20180102',6,
'20180103',9,
'20180104',10,
'20180105',9,
'20180106',8,
'20180107',11,
'20180108',12,
'20180109',13,
'20180110',11

    ) 
) s;

## Running Average
## Running x number of most recent rows

select
    dt
    ,x
    ,avg(x) over (
        order by dt asc
        rows between 6 preceding and current row)
     -- window function gives you running avg
     -- This is freaking awesome.
     -- This gives running average of current and six preceeding row's average
from temp.running_avg

-- avg(count(distinct user_id)) is our basic operation. count(distinct user_id) is the DAU, and avg averages the DAUs.
-- order by d tells the window function in what order to look at the data, which is important because:
-- rows between 7 preceding and current row tells the window function which rows to average. In this case we want the 7 rows before the current row.
