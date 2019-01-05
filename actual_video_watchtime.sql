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
        ,t1.row_num
        - row_number() over (
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
            -- if I can legitimately make an assumption that one user watches one video,
            -- the first true will always be the click_video_play
            -- and can seperate all the video_play related actions by interruption.
            ,row_number() over (
                partition by outputuser_id
                order by ts asc
                ) row_num
            -- row number for userid
        from temp.video_watch
        ) t1
    where t1.video_play = true
) t2
having t2.consecutive_group = min_consecutive_group -- minimum group
    and t2.ts = consecutive_group_max_ts -- max of the minimum group
