"""
swap the adjacent two students
This question is about using lead and lag.
not so fun.
but it's worth 
"""

|   id   | student |
+---------+---------+
|    1    | Abbot   |
|    2    | Doris   |
|    3    | Emerson |
|    4    | Green   |
|    5    | Jeames 

DROP TABLE IF EXISTS temp.swap_seats ;
CREATE TABLE IF NOT EXISTS temp.swap_seats (
    id INT
    ,student string
  )
  ;
insert overwrite table temp.swap_seats
select * from 
(
select stack(
    5,                 
1,'Abbot' ,
2,'Doris'  ,
3,'Emerson'  ,
4,'Green'  ,
5,'Jeames'  
    ) 
) s;

# STEP 1

select
    id
    ,student
    ,case when id%2==1  -- if you are an odd number
            then lead(student) over ( -- me the one below me
                order by id asc)
        when id%2==0  -- if you are an even number
            then lag(student) over ( -- get me the one above me
                order by id)
    end as swapped
    -- but if the total number of rows are not even, we will not be able to get any swapped value for the last guy
from temp.swap_seats;


# STEP 3 : use coalesce to resolve the above issue

select
    t.id
    ,coalesce(t.swapped, t.student) as new_seat_arrangement
from (
    select
        id
        ,student
        ,case when id%2==1
                then lead(student,1) over (
                    order by id)
            when id%2==0
                then lag(student,1) over (
                    order by id)
        end as swapped
    from temp.swap_seats
    ) t
