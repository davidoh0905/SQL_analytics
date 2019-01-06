"""
1. What is the average number of messages sent per sender yesterday?
2. What fraction of active users had contact with more than 5 people yesterday?
3. What fraction of messages get a response within a minute?

This is the actual question that I received during the VC

[DATA]
messaging:
  ds (STRING)            # date stamp, 'YYYY-MM-DD'
  ts (BIGINT)            # time stamp, in seconds
  sender_uid (BIGINT)    # userid of sender of message
  receiver_uid (BIGINT)  # userid of receiver of message

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
"""

1. What is the average number of messages sent per sender yesterday?

-- first of all, think about what each row represents
-- my first mistake was trying to generate the unique identifer for each message. but each record was representing a single message
-- therefore all I needed to do was to calculate number of rows per users
# First Shot --> Take this as a lesson. the most important thing is to understand the data itself first
select
  sender_uid
  ,count(concat(cast(receiver_uid as string),cast(ts as string)))
from messaging
where ds = date_sub(cast(ds as date),1)

group by sender_uid

# Second Shot
select
  avg(message_per_user.num_of_message)
from (
  select
    sender_uid
    ,count(1) as num_of_message
  from messaging
  where ds = date_sub(cast(ds as date),1) -- getting yesterday's data
  group by sender_uid
) message_per_user



2. What fraction of active users had contact with more than 5 people yesterday?

-- Define the metric!!
-- what does "had contact" mean? ==> whether received or sent, it counts as contact for both
-- This is bidirectional and has to be counted for both parties

-- constraint : yester
-- 5 distinct receiver_uid
-- additional group by 'num_mess_sent' 
-- having count(user) 

select
  count( if(t.num_of_interaction>5 , 1 , NULL ) ) / count(1) as percent_above_five_interaction
  -- each record represents a user and its interaction with others
  -- count total number of users
  -- count number of users who had interactions with more than 5 people
from (
  select
    interact.user1 as user
    ,count(distinct user2) as num_of_interaction
  from (
    select distinct -- distinct because we only care about whether there exists an interction. not the frequency.
      sender_uid as user1
      ,receiver_uid as user2
    from messaging 
    where ds = date_sub(cast(ds as date),1)
    union all
    select distinct
      receiver_uid as user1
      ,sender_uid as user2
    where ds = date_sub(cast(ds as date),1)
      ) interact
  group by interact.user1
) t


select count(0) from table
> 10
select count(NULL)
> 0
select sum(0)
> 0


3. What fraction of messages get a response within a minute?

