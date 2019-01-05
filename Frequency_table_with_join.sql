# Frequency Table # Hierarchical relationship between two tables # calculate before or after join
"""
Write a SQL query to compute a frequency table of a certain attribute involving two joins. 
What if you want to GROUP or ORDER BY some attribute?
What changes would you need to make? 
How would you account for NULLs?

frequency table is about count(1) and group by of what you are interested in

you have a table Submissions with the 
| submission_id | the body | parent_id |
Submissions can be posts, or comments to a post. 

In posts, parent_id is null, 
and in comments, the parent_id is the post the comment is commenting about. 
How would you go and make a histogram of number of posts per comment_count?'

post1		body		null
post2		body		null
comment1	body		post1
comment2	body		post2

"""
# What I need is number of comments per post
# 1 get list of post id and join later?
# 2. do it all at the same time?
select
	post.post_id as post_id
	,comment.comment_count 
		-- if there is any value, it will give you some value
		-- if it fails to join, it will be null
from (
	select distinct
		submission_id as post_id
	where parent_id is null 
	) post
	-- This way you will get all of the post_id whether they have comments or not
	left outer join ( -- because you want to keep all of the post_id
		select
			parent_id
			,count(distinct submission_id) comment_count
		where parent_id is not null
		) comment
	on post.post_id = comment.parent_id