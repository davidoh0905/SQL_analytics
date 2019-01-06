select current_timestamp();
-- 2019-01-05 07:41:43
select current_date();
-- 2019-01-05
select date_sub(current_date(),1);
-- 2019-01-04
select date_add(current_date(),1);
-- 2019-01-06
select add_months(current_date(),1);
-- 2019-02-05
select datediff(date_add(current_date(),10), current_date())
-- 10


select unix_timestamp('2018-06-01', 'yyyy-MM-dd');
-- 1527811200
select from_unixtime(unix_timestamp('2018-06-01', 'yyyy-MM-dd'));
-- 2018-06-01 00:00:00
select cast(to_date(from_unixtime(unix_timestamp('2018-06-01', 'yyyy-MM-dd'))) as date);
-- 2018-06-01
select cast('2018-06-01' as date)
-- 2018-06-01
select date_sub(cast('2018-06-01' as date),1)
--2018-05-31

-- string dt and date data type direct comparison available
select date_sub(cast('2018-06-01' as date),1)=='2018-05-31'
--true
