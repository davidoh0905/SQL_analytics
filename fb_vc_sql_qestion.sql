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
  ds (STRING)            # date stamp, 'YYYY-MM-DD'
  ts (BIGINT)            # time stamp, in seconds
  sender_uid (BIGINT)    # userid of sender of message
  receiver_uid (BIGINT)  # userid of receiver of message

DROP TABLE IF EXISTS temp.messages ;
CREATE TABLE IF NOT EXISTS temp.messages (
    ds STRING
    ,ts BIGINT
    ,sender_uid STRING
    ,receiver_uid STRING
  )
  ;

insert overwrite table temp.rising_temperature
select * from 
(
select stack(
    10,                 
'2015-01-01',unix_timestamp(current_timestamp())+10,'A','B',
'2015-01-01',unix_timestamp(current_timestamp())+20,'A','B',
'2015-01-01',unix_timestamp(current_timestamp())+30,'C','B',
'2015-01-01',unix_timestamp(current_timestamp())+40,'B','C',
'2015-01-01',unix_timestamp(current_timestamp())+50,'C','D',
'2015-01-01',unix_timestamp(current_timestamp())+60, 'A','B',
'2015-01-01',unix_timestamp(current_timestamp())+70,'B','D',
'2015-01-01',unix_timestamp(current_timestamp())+80, 'B','A',
'2015-01-01',unix_timestamp(current_timestamp())+90,'A','B',
'2015-01-01',unix_timestamp(current_timestamp())+100 ,'B','A'

    ) 
) s;



# This is about finding interactions betweens rows where it is all stacked from
# define the "response"
# the first record after certain record that has sender_uid and receiver_uid order reversed.
# this is super interesting. so there is a way to create a interaction map between two people
# and order them
# and group them and calculate the min and max of each group and subtract group by group to get all interaction latency
# and get average wait time between two people

# STEP 1
# - self join the message table with 2 conceptual conditions
# -- reversed receiver and sender join condition in order to get response
# -- only join ts that is larger in the response table (also the same table just differnet alias)
# -- order by the entire table in order to get the result in order
select
    send.sender_uid
    ,send.receiver_uid
    ,send.ds
    ,send.ts
    ,row_number() over (
        partition by
            send.sender_uid
            ,send.receiver_uid
            ,send.ds
            ,send.ts
        order by
            send.ts asc
            ,response.ts asc
            ) order_of_response
    ,response.sender_uid
    ,response.receiver_uid
    ,response.ds
    ,response.ts
from (
    select 
        sender_uid
        ,receiver_uid
        ,ds
        ,ts
    from temp.messages
) send
left outer join (
    select 
        sender_uid
        ,receiver_uid
        ,ds
        ,ts
    from temp.messages
    ) response
on send.sender_uid = response.receiver_uid
    and send.receiver_uid = response.sender_uid
    and response.ts > send.ts
    and response.ds < date_add(cast(send.ds as date),1) -- assumption that real interactions should not go over a day
order by send.ts

# the resulting table will have all future responses within a day.
# but the responses are not guaranteed to be direct response to the specific send.

sender_uid  receiver_uid  ds  ts  order_of_response sender_uid  receiver_uid  ds  ts
A B 2015-01-01  1546755868  1 B A 2015-01-01  1546755938
A B 2015-01-01  1546755868  2 B A 2015-01-01  1546755958
A B 2015-01-01  1546755878  1 B A 2015-01-01  1546755938
A B 2015-01-01  1546755878  2 B A 2015-01-01  1546755958
C B 2015-01-01  1546755888  1 B C 2015-01-01  1546755898
B C 2015-01-01  1546755898  1       
C D 2015-01-01  1546755908  1       
A B 2015-01-01  1546755918  1 B A 2015-01-01  1546755938
A B 2015-01-01  1546755918  2 B A 2015-01-01  1546755958
B D 2015-01-01  1546755928  1       
B A 2015-01-01  1546755938  1 A B 2015-01-01  1546755948
A B 2015-01-01  1546755948  1 B A 2015-01-01  1546755958
B A 2015-01-01  1546755958  1       

# STEP 2 : select the earliest response to measure the time gap

select
    count(1) total_sent
    ,count(if ( t.response_time < 30 and t.response_time is not null, 1, null)) responded_under30
from (
    select
        send.sender_uid
        ,send.receiver_uid
        ,send.ds
        ,send.ts
        ,row_number() over (
            partition by
                send.sender_uid
                ,send.receiver_uid
                ,send.ds
                ,send.ts
            order by
                send.ts asc
                ,response.ts asc
                ) order_of_response
        ,response.sender_uid
        ,response.receiver_uid
        ,response.ds
        ,response.ts
        ,response.ts - send.ts as response_time
    from (
        select 
            sender_uid
            ,receiver_uid
            ,ds
            ,ts
        from temp.messages
        order by ts
    ) send
    left outer join (
        select 
            sender_uid
            ,receiver_uid
            ,ds
            ,ts
        from temp.messages
        ) response
    on send.sender_uid = response.receiver_uid
        and send.receiver_uid = response.sender_uid
        and response.ts > send.ts
        and response.ds < date_add(cast(send.ds as date),1) -- assumption that real interactions should not go over a day
    having order_of_response = 1
    order by send.ts
    ) t

## Study about timestamp !!

select
    unix_timestamp(current_timestamp())
    ,unix_timestamp(current_timestamp())+10
    ,unix_timestamp(date_add(current_date(),1))


