DROP TABLE IF EXISTS temp.pop_prop_ci ;
CREATE TABLE IF NOT EXISTS temp.pop_prop_ci (
    mon string
    ,user_id string
    ,convert boolean
  )
  

insert overwrite table temp.pop_prop_ci
select * from 
(
select stack(
    70,                 
'201801','1',true,
'201801','2',false,
'201801','3',false,
'201801','4',false,
'201801','5',false,
'201801','6',true,
'201801','7',false,
'201801','8',false,
'201801','9',false,
'201801','10',false,
'201801','11',false,
'201801','12',false,
'201801','13',false,
'201801','14',true,
'201801','15',false,
'201801','16',false,
'201801','17',false,
'201801','18',false,
'201801','19',false,
'201801','20',false,
'201801','21',false,
'201801','22',true,
'201801','23',false,
'201801','24',false,
'201801','25',false,
'201801','26',true,
'201801','27',false,
'201801','28',false,
'201801','29',false,
'201801','30',false,
'201801','31',true,
'201801','32',false,
'201801','33',false,
'201801','34',false,
'201801','35',false,
'201801','36',false,
'201801','37',false,
'201801','38',false,
'201801','39',false,
'201801','40',false,
'201802','1',true,
'201802','2',false,
'201802','3',false,
'201802','4',false,
'201802','5',false,
'201802','6',true,
'201802','7',false,
'201802','8',false,
'201802','9',false,
'201802','10',false,
'201802','11',false,
'201802','12',false,
'201802','13',false,
'201802','14',true,
'201802','15',false,
'201802','16',false,
'201802','17',false,
'201802','18',false,
'201802','19',false,
'201802','20',false,
'201802','21',false,
'201802','22',true,
'201802','23',false,
'201802','24',false,
'201802','25',false,
'201802','26',true,
'201802','27',false,
'201802','28',false,
'201802','29',false,
'201802','30',false
    ) 
) s;

select
    mon
    ,n as num_users
    ,'95% CI'  as confidence_interval
    ,converted-1.96*sqrt(p*(1-p)/n) as low
    ,converted as min
    ,converted+1.96*sqrt(p*(1-p)/n) as high
from (
    select
        mon
        ,count(1) as n
        ,sum(
            case when convert == True
                then 1
            else 0
            end
            ) as converted
        ,sum(
            case when convert == True
                then 1
            else 0
            end
            ) / count(1) as p
    from temp.pop_prop_ci
    group by mon
    ) conversion
