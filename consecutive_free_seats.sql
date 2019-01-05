-- # Row Operation
-- # Original consecutive row numbering
-- # conditional row_numbering
-- # the difference becomes consecutive continuation of desired properties
-- # How far can it go?
-- # make sure to provide order by every single time!
-- # Original row_number - filtered_row_number is just one way to resolve this kind of question
-- # Try remembering the other way!!

-- # another food for thought!
-- # there could be more than one condition to qualify for being consecutive!
"""
Calculate the number of consecutive free seats
Row Operation is important
filtering for consecutive rows with similar properties have wide application

[Data]

| seat_id | free |
|---------|------|
| 1       | 1    |
| 2       | 0    |
| 3       | 1    |
| 4       | 1    |
| 5       | 1    |

DROP TABLE IF EXISTS temp.consecutive_free_seats ;
CREATE TABLE IF NOT EXISTS temp.consecutive_free_seats (
    id INT
    ,free INT
  )
  ;


insert overwrite table temp.consecutive_free_seats
select * from 
(
select stack(
    5,                 
1,1,
2,0,
3,1,
4,1,
5,1
    ) 
) s;

"""

-- # Step 1
select
    id -- Original Row Numbering // with filter there will start being gap in consecutive number
    ,row_number() over (
        order by id asc
        )  -- with filter, new row_number() will not have gap
    ,id - row_number() over (
        order by id asc) 
    -- row numbering over nothing is same numbering as doing it for the entire table
    -- But if you give condition!! you are only row_numbering things that are filtered
    -- ## which induces gap in original row_numbering
from temp.consecutive_free_seats
where free = 1
order by id asc

-- # Step 2 : add aditional column that gives the number of intended consecutive rows 
-- this will require sub-group bys with window function

select
    id
    ,id - row_number() over (order by id asc) as num_group
    ,count(1) over(
        partition by -- partition by the grouppings by the number generated by above
            id - row_number() over (order by id asc)
        ) consecutive
from temp.consecutive_free_seats
where free = 1
order by id asc

-- # Step 3 : add condition to filter for the information needed
select
    id
    ,id - row_number() over (order by id asc) as num_group
    ,count(1) over(
        partition by -- partition by the grouppings by the number generated by above
            id - row_number() over (order by id asc)
        ) consecutive_num
from temp.consecutive_free_seats
where free = 1
having consecutive_num >=3
order by id asc

-- There are cases where you have to reverse the count and entity but this is not the case
-- There are many different ways to figure out consecutive number question




-- Short Version
select
    id -- Original Row Numbering
    ,count(id - row_number() over ()) over (
        partition by id - row_number() over ()
        ) as consecutive_count
from temp.consecutive_free_seats
where free = 1
having consecutive_count >=3
