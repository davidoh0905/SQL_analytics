
DROP TABLE IF EXISTS temp.messages ;
CREATE TABLE IF NOT EXISTS temp.messages (
    ds STRING
    ,ts BIGINT
    ,sender_uid STRING
    ,receiver_uid STRING
  )
  ;

insert overwrite table temp.messages
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

select
    unix_timestamp(current_timestamp())
    ,unix_timestamp(current_timestamp())+10
    


select * from temp.messages
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
