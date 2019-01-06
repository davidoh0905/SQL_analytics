-- # The Dreaded
-- # Actual Video Watch Time
-- # there are set of consecutive feature that I want to monitor
-- # But it is mixed up with other features
-- # Need to declutter somehow and extract information that I want
"""
I want to see how long a person watched videos uninterrupted.
-- the starting point is click_video_play
-- from then on I only want to see video_play_....
-- if anything happens in the middle, it means the end of the video watch
-- assume that one person is just wathing one video

-- find all the video_play consecutive 
-- partition by ID 
-- well they are going to see what assumptions I make as well
-- in the case I will have to make assumption that one person watches only one video
-- and thus I can make outputuser_id as unique identifier.

[DATA]
DROP TABLE IF EXISTS temp.video_watch ;
CREATE TABLE IF NOT EXISTS temp.video_watch (
    outputuser_id INT
    ,ts timestamp
    ,url string
    ,event_name string
  )
  ;


insert overwrite table temp.video_watch
select * from 
(
select stack(
    12,                 
12345,1473811200,'/home' , 'page_view',
 12345,1473811205,'/home', 'link_click',
 12345,1473811215,'/video' , 'page_view',
 12345,1473811220,'/video' , 'click_video_play',
 12345,1473811225,'/video' , 'video_play_5_pct',
 12345,1473811230,'/video' , 'video_play_10_pct',
 12345,1473811235,'/video' , 'video_play_15_pct',
 12345,1473811236,'/video' , 'scroll',
 12345,1473811240,'/video' , 'video_play_20_pct',
 12345,1473811245,'/video' , 'video_play_25_pct',
 12345,1473811247,'/video' , 'scroll',
 12345,1473811250,'/video' , 'video_play_30_pct'

    ) 
) s;
"""

# Step 1 : 
- row_number for all rows under certain user_id
- row_number with condition for common feature of fields that I want to monitor consecutiveness of

select 
    outputuser_id
    ,event_name
    ,ts
    ,if(event_name like '%video_play%', True, False) video_play
    -- """the commonality of the consecutive rows"""
    -- if I can legitimately make an assumption that one user watches one video,
    -- the first true will always be the click_video_play
    -- and can seperate all the video_play related actions by interruption.
    ,row_number() over ( -- This will become original row_numbering
        partition by outputuser_id
        order by ts asc
        ) row_num
    -- row number for userid
from temp.video_watch

# Step 2 : 
- subtract the original row_number and conditional row_number
- the gamp will become grouppings of consecutive video watches seperated by interruptions
- THis only works under the assumption that each user_id watched one video
select
    t1.outputuser_id
    ,t1.event_name
    ,t1.ts
    ,t1.video_play
    ,t1.row_num -- original row_number
    - row_number() over ( -- conditional row number with constraint given at the end WHERE clause
        partition by t1.outputuser_id
        order by t1.ts asc
        ) consecutive_group
from (
    select 
        outputuser_id
        ,event_name
        ,ts
        ,if(event_name like '%video_play%', True, False) video_play
        ,row_number() over (
            partition by outputuser_id
            order by ts asc
            ) row_num
    from temp.video_watch
    ) t1
where t1.video_play = true


# Step 3 : 
- From the result of step 2, I need to get the first chunk
- and among the first chunk I need to get the max


select
    t2.outputuser_id
    ,t2.event_name
    ,t2.ts
    ,t2.consecutive_group 
    ,min(t2.consecutive_group) over (
        partition by t2.outputuser_id
        ) as min_consecutive_group
     -- this is to select the first consecutive video play group.
     -- the consecutive group is seperated by interruption
    ,max(t2.ts) over (
        partition by t2.outputuser_id, t2.consecutive_group
        ) as consecutive_group_max_ts
     -- within each consecutive group, select the line with maximum timestamp which will give us the largest video_play_pct
from (
    select
        t1.outputuser_id
        ,t1.event_name
        ,t1.ts
        ,t1.video_play
        ,t1.row_num - row_number() over (
            partition by t1.outputuser_id
            order by t1.ts asc
            ) consecutive_group
        -- creating a consecutive group
    from (
        select 
            outputuser_id
            ,event_name
            ,ts
            ,if(event_name like '%video_play%', True, False) video_play
            ,row_number() over (
                partition by outputuser_id
                order by ts asc
                ) row_num
        from temp.video_watch
        ) t1
    where t1.video_play = true
) t2
having t2.consecutive_group = min_consecutive_group -- minimum group
    and t2.ts = consecutive_group_max_ts -- max of the minimum group



## STEP 4 : substring!
-- I don't know much about regular expression but this is doable!!
-- calculating with the result of sub-groupby with window function. 
-- seems like I have to come out of the subquery to do so

select 
    t3.outputuser_id
    ,if( split(t3.event_name,'_')[2] rlike '[^0-9]'   ,'0%', concat(split(t3.event_name,'_')[2],'%'))
from (
    select
        t2.outputuser_id
        ,t2.event_name
        ,t2.ts
        ,t2.consecutive_group 
        ,min(t2.consecutive_group) over (
            partition by t2.outputuser_id
            ) as min_consecutive_group
         -- this is to select the first consecutive video play group.
         -- the consecutive group is seperated by interruption
        ,max(t2.ts) over (
            partition by t2.outputuser_id, t2.consecutive_group
            ) as consecutive_group_max_ts
         -- within each consecutive group, select the line with maximum timestamp which will give us the largest video_play_pct
    from (
        select
            t1.outputuser_id
            ,t1.event_name
            ,t1.ts
            ,t1.video_play
            ,t1.row_num - row_number() over (
                partition by t1.outputuser_id
                order by t1.ts asc
                ) consecutive_group
            -- creating a consecutive group
        from (
            select 
                outputuser_id
                ,event_name
                ,ts
                ,if(event_name like '%video_play%', True, False) video_play
                ,row_number() over (
                    partition by outputuser_id
                    order by ts asc
                    ) row_num
            from temp.video_watch
            ) t1
        where t1.video_play = true
    ) t2
    having t2.consecutive_group = min_consecutive_group -- minimum group
        and t2.ts = consecutive_group_max_ts -- max of the minimum group
    )t3
