""" calculating a mutual friend is a no easy task 
Approbach any complex SQL questions with relational algebra in mind
Getting a mutual friend between two designated people can be calculated by
{user A's friend} intersect {user B's friend}
and in order to extend this to all users, it will have to be a cartesian join
"""
[DATA]

DROP TABLE IF EXISTS temp.tuple ;
CREATE TABLE IF NOT EXISTS temp.tuple (
    user1 STRING
    ,user2 STRING
  )
  

insert overwrite table temp.tuple
select * from 
(
select stack(
    16,                 
'a','b',
'b','a',
'a','e',
'e','a',
'a','f',
'f','a',
'b','c',
'c','b',
'b','e',
'e','b',
'b','f',
'f','b',
'c','d',
'd','c',
'd','e',
'e','d'
    ) 
) s;

select * from temp.tuple


## Getting mutual friend regardless of whether user A and user B are friends or not
## Step 1
## - user2 column of the base table refers to friend of user1
## - left outer join with t1.user2 = t2.user1 will give us user2's friend as well
## - by removing t1.user1 = t2.user2, t1.user2 column will become two distinct friends of user2 on its left and right.
## - which in turn means, t1.user1 and t2.user2 has mutual friend of t1.user2

select
    t1.user1
    ,t1.user2 as shared_friend
    ,t2.user2
from temp.tuple t1
left outer join temp.tuple t2
on t1.user2 = t2.user1
where t1.user1 != t2.user2


## STEP 2

select
    tt.user1
    ,tt.user2
    ,if(t3.user1 is not null, 'yes','no') 
    ,tt.shared_friend
from (
    select
        t1.user1
        ,t1.user2 as shared_friend
        ,t2.user2
    from temp.tuple t1
    left outer join temp.tuple t2 on t1.user2 = t2.user1
    where t1.user1 != t2.user2
    ) tt
left outer join temp.tuple t3 on tt.user1 = t3.user1 and tt.user2 = t3.user2

## continuous left join did not work.
why!!! why !!! why !!!

================================================================================================================================================
================================================================================================================================================
## whatever in below is not exactly correct
## unnecessary cartesian
## --> I did not have to get entire list of user1's friend
## --> I just needed to identify whether they are already friends or not.
# --> by doing this, I will just get for a,b it's friend list. 
# think step by step.
# think what I have and think 

## STEP 1 
# We need to compare user 1 and user 2's friends and get the intersect 
# < First Left Join >
# will self join with user2 from original table as left table
#  and bring in extra column of user2's friends
#  with constraint of user2's friend != user1
# < Second Left Join >
# will self join with user1 from original table as left table
#  and bring in extra column of user1's friends
#  with constraint of user1's friend != user2
# < at this point >
# the original user1 and usre2 column only becomes an index
# and user2_friend and user1_friend becomes a cartesian join

# Limitation : This method give you mutual friend for only two friends who are already friends
# this does not give two non-friend's share(mutual) friend

user1	user2	user2_friend	user1_friend
a	      b	      c	                  e
a	      b	      c	                  f
a	      b	      e	                  e
a	      b	      e	                  f
a	      b	      f	                  e
a	      b	      f	                  f


select
    t1.user1
    ,t1.user2
    ,t2.user2 as user2_friend
    ,t3.user2 as user1_friend
from (
    select
        user1
        ,user2
    from temp.tuple
order by user1
) t1
left outer join (
    select
        user1
        ,user2
    from temp.tuple
    ) t2
left outer join (
    select
        user1
        ,user2
    from temp.tuple
    ) t3
on t1.user2 = t2.user1
and t1.user1 = t3.user1
where t1.user1 != t2.user2
    and t1.user2 != t3.user2
    

## Step 2
- As have initially been discussed, it's time to get just the common friends of user1 and user 2
select
    t1.user1
    ,t1.user2
    ,t2.user2 as user2_friend
    ,t3.user2 as user1_friend
from (
    select
        user1
        ,user2
    from temp.tuple
order by user1
) t1
left outer join (
    select
        user1
        ,user2
    from temp.tuple
    ) t2
left outer join (
    select
        user1
        ,user2
    from temp.tuple
    ) t3
on t1.user2 = t2.user1
and t1.user1 = t3.user1
where t1.user1 != t2.user2
    and t1.user2 != t3.user2
having user2_friend = user1_friend
    
    
STEP 3 : Deduplication is on you!!

================================================================================================================
================================================================================================================
## This gives you a mutual friend regardless of whether user1 and user2 are friends or not
## I guess this is better(?)
select
    t1.user1
    ,t1.user2 as shared_friend
    ,t2.user2
from temp.tuple t1
left outer join temp.tuple t2
on t1.user2 = t2.user1
where t1.user1 != t2.user2
## THis is good enough for now

select
    distinct dupped.*
from (
    select
        greatest(mutual.L_user1, mutual.R_user1) as user1
        ,least(mutual.L_user1, mutual.R_user1) as user2
        ,mutual.mutual_friend
    from (
        select
            string(L.user1) as L_user1
            ,string(R.user1) as R_user1
            ,string(L.user2) as mutual_friend --  the join key
        from temp.tuple L
        left outer join temp.tuple R
        on L.user2 = R.user2
            where L.user1 != R.user1 -- this filters out no join & row level self join
            ) mutual
     ) dupped
--could I have done inner join? 
-- when you are joining two tables on the same column (when there is no null), it has 100% referential integrity. inner join and left join will be the same
-- it is when there is no 100% referential intergrity that you choose between left join or right join
-- think about why I use certain join when I do this.

-------- Deduplication
-- they said dedupling is also one of the questions that they get but I think **distinct** is something that you can do as well

-- feature engineering
-- question. create a column that indicates that there has been certain activity.
-- type of possible customer engagements.

select * from temp.tuple
show create table temp.tuple


select distinct entitlement_id, owner_id from entitlement_optimized.entitlement_edp_optimized limit 12

-- Chris
select d.friend_1, d.friend_2, d.mutual_friend 
from (
    SELECT 
        a.user1 as friend_1,
        b.user2 as friend_2,
        b.user1 as mutual_friend,
        ROW_NUMBER() OVER (
            PARTITION BY a.user1 + b.user2 
            -- I like the row_number approach!
            -- but quesion! in this specific case, sum of friend1 and friend2 ( numerical sum ) are all distinct. 
            -- but will this work when the sum is not unique or if the friend identifier is character?
            -- I was also trying to find a unordered pair data type for hive but couldn't figure it out yet.
            ) AS rn
    FROM temp.tuple2 a 
join (select * from temp.tuple2) b 
on b.user1 = a.user2 -- my friend's other friend
    and b.user2 != a.user1 -- removing self join
) d
where d.rn = 1



==================================================================================================
==================================================================================================

select * from temp.tuple2
CREATE TABLE students (name VARCHAR(64), age INT, gpa DECIMAL(3, 2));
INSERT INTO TABLE students
  VALUES ('fred flintstone', 35, 1.28), ('barney rubble', 32, 2.32);

INSERT INTO TABLE temp.testbucket select '2','3' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '4','7' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '5','8' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '1','3' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '4','9' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '2','9' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '1','5' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '6','7' from temp.abc limit 1;


INSERT INTO TABLE temp.tuple select '3','2' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '7','4' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '8','5' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '3','1' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '9','4' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '9','2' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '5','1' from temp.abc limit 1;
INSERT INTO TABLE temp.tuple select '7','6' from temp.abc limit 1;

select * from temp.testbucket
show create table temp.testbucket
expected outcome : 
- 1,2 has mutual friend of 3
- 6 does not have mutual friend with anyone
