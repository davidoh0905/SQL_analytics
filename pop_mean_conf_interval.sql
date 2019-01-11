DROP TABLE IF EXISTS temp.std ;
CREATE TABLE IF NOT EXISTS temp.std (
    x int
  )
  

insert overwrite table temp.std
select * from 
(
select stack(
    10,                 
'1','2',
'3','4',
'5','6',
'7','8',
'9','10'

    ) 
) s;

# There are few things we need to estimate population mean from sample
# Sample
# 1. sample size
# 2. Standard Error of sampling distribution
# 3. Sample Mean
# 4. Significance Level

# If I were to just calculate the number then below would be sufficient
# but below is not efficient since it will continously have to calcuate over and over again for the entire rows

select
    avg(x) over () - 1.96*sqrt(sum(power(x-avg(x) over (),2)) over () / count(1) over ()) /sqrt(count(1) over ())
    ,avg(x) over () + 1.96*sqrt(sum(power(x-avg(x) over (),2)) over () / count(1) over ()) /sqrt(count(1) over ())
from temp.std
limit 1

<<Result as Below>>
3.719741591790675	7.280258408209325
3.719741591790675	7.280258408209325
3.719741591790675	7.280258408209325
3.719741591790675	7.280258408209325
3.719741591790675	7.280258408209325
3.719741591790675	7.280258408209325
3.719741591790675	7.280258408209325
3.719741591790675	7.280258408209325
3.719741591790675	7.280258408209325
3.719741591790675	7.280258408209325



select
avg(x) over () - 1.96* sqrt( power((x-avg(x) over ()),2)/count(1) over () ) /sqrt(count(1) over ())
from temp.std

## up until now, I absolutely just have to use window function
## because I need both original number and average to calculate variance
    
    
select
    count(1) as n
    ,'95% CI' as confidence_interval
    ,t.sample_mean - 1.96*sqrt(sum(t.var) / count(1)) as low
    ,t.sample_mean as mid
    ,t.sample_mean + 1.96*sqrt(sum(t.var) / count(1)) as high
from (
    select
        x
        ,avg(x) over () as sample_mean
        ,x-avg(x) over ()
        ,power(x-avg(x) over (),2) as var
    from temp.std
    ) t
-- Though exactly the same, sample_mean here is the line item from the previous table
group by t.sample_mean

