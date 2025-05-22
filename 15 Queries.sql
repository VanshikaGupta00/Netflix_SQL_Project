-- 1.Count the no. of movies VS TV shows?
SELECT 
 category,COUNT(*) AS total_count
 FROM netflix
 GROUP BY category;
 
 -- 2.Find the most common rating for movies and TV shows?
 SELECT 
 category,
 rating
 FROM
 (SELECT 
 category,
 rating,
 COUNT(*),
 RANK() OVER (PARTITION BY category order by COUNT(*) DESC) AS ranking 
 FROM netflix
 GROUP BY 1,2
 -- ORDER BY 1, 3 DESC;
 ) as t1
WHERE ranking=1;


-- 3.List all the movies released in a specific year(eg.2020)?
SELECT title,release_year
FROM netflix
WHERE 
category="Movie" 
AND
release_year=2020;

-- 4.Find the top 5 countries with the most content on netflix?
-- SELECT * FROM netflix;
SELECT 
TRIM(SUBSTRING_INDEX(release_in_country, ',', 1)) AS country,
COUNT(show_id)  as Total_content
FROM netflix
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;
/*SELECT 
  UNNEST(string_to_array(release_in_country, ',')) AS country
  FROM netflix;*/
  
  WITH RECURSIVE split_cte AS (
  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(release_in_country, ',', 1)) AS country,
    SUBSTRING(release_in_country, LENGTH(SUBSTRING_INDEX(release_in_country, ',', 1)) + 2) AS remaining,
    1 AS depth
  FROM netflix

  UNION ALL

  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
    SUBSTRING(remaining, LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2),
    depth + 1
  FROM split_cte
  WHERE TRIM(remaining)!= ''
)
-- final select from CTE
SELECT country, COUNT(show_id)  as Total_content
FROM split_cte
GROUP BY country;

-- SELECT show_id,country FROM split_cte;


-- 5.Identify the longest movie?
SELECT * FROM netflix
WHERE 
category="Movie"
AND
duration=(SELECT MAX(duration) FROM netflix);

-- 6.Find content added in the last 5 year?
SELECT *
FROM netflix
WHERE 
str_to_date(date_added,'%M %d,%Y') >= current_date - interval 5 YEAR;

-- 7.Find all the movies/TV shows by director Rajiv Chilaka!
SELECT *
FROM netflix
WHERE director COLLATE utf8mb4_general_ci LIKE "%Rajiv Chilaka%";
-- used COLLATE 'utf8mb4_general_ci' to also get case-snsitive like 'rajiv' (not only 'Rajiv') in output ,it is an alternative of ILIKE of PostgreSQL


-- 8.List all TV shows with more than 5 seasons!

SELECT *
-- SUBSTRING_INDEX(duration,' ',1) as sessions
FROM netflix
WHERE 
category= 'TV Show' AND 
CAST(SUBSTRING_INDEX(duration,' ',1)AS UNSIGNED) > 5;

/*SELECT
SUBSTRING_INDEX('Apple Banana Grapes',' ',1);*/


--  9.Count the no. of content items in each genre(listed_in column)!
-- SELECT * FROM netflix;
SELECT 
TRIM(SUBSTRING_INDEX(listed_in, ",", 1)) AS genre,
COUNT(show_id)  as Total_content
FROM netflix
GROUP BY 1;

WITH RECURSIVE split_cte AS (
  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(listed_in,",", 1)) AS genre,
    SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ",", 1)) + 2) AS remaining,
    1 AS depth   -- used it to avoid infinte looping beyond mysql limit
  FROM netflix

  UNION ALL

  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(remaining, ",", 1)),
    SUBSTRING(remaining, LENGTH(SUBSTRING_INDEX(remaining, ",", 1)) + 2),
    depth + 1   -- used it to avoid infinte looping beyond mysql limit
  FROM split_cte
  WHERE TRIM(remaining)!= " " AND depth < 20)  -- used it to avoid infinte looping beyond mysql limit
  
  -- final select from CTE
  SELECT genre, COUNT(*) AS total_content
FROM split_cte
GROUP BY genre;





-- 10. Find each year and the average numbers of content release in India on netflix
-- avg content for 2021=98/total content count
SELECT 
EXTRACT(YEAR FROM str_to_date(date_added,"%M %d,%Y")) AS year,
COUNT(*),
ROUND(CAST(COUNT(*) AS UNSIGNED)/CAST((SELECT COUNT(*) FROM netflix 
WHERE release_in_country COLLATE utf8mb4_general_ci LIKE "%India%" )AS unsigned)* 100 ,2)AS Avg_content
FROM netflix
WHERE release_in_country COLLATE utf8mb4_general_ci LIKE "%India%"
GROUP BY 1
order by 1 DESC;


-- 11.List all the movies that are documentaries
-- select * from netflix;
SELECT *
FROM netflix
WHERE 
 category='Movie'
AND 
 listed_in COLLATE utf8mb4_general_ci LIKE "%Documentaries%";


-- 12.Find all content without a director
SELECT * FROM netflix
WHERE TRIM(director)='' ;    
-- NOTE:there is a difference between '' and ' ' ,cannot be equated


-- 13.Find how many movies actor 'Salman khan' appeared in last 10 years!

-- select * FROM netflix;
SELECT *
FROM netflix
WHERE 
category='Movie'
   AND 
cast COLLATE utf8mb4_general_ci LIKE "%Salman Khan%"
   AND 
release_year >= EXTRACT(YEAR FROM current_date()) -10;
-- Error solved:put =sign also along with > 



-- 14.Find top 10 actors who have appeared in the highest number of movies produced in India
-- SELECT * from netflix;

-- FIRST QUERY
SELECT 
TRIM(SUBSTRING_INDEX(cast, ',', 1)) AS actors,
COUNT(*) as total_content
FROM netflix
WHERE category='Movie'
 AND
 release_in_country COLLATE utf8mb4_general_ci LIKE "%India%"
 GROUP BY 1
;

-- SECOND QUERY
WITH RECURSIVE split_cte AS (
  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(cast, ',', 1)) AS actors,
    SUBSTRING(cast, LENGTH(SUBSTRING_INDEX(cast, ',', 1)) + 2) AS remaining,
    1 AS depth
  FROM netflix

  UNION ALL

  SELECT 
    show_id,
    TRIM(SUBSTRING_INDEX(remaining, ',', 1)),
    SUBSTRING(remaining, LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2),
    depth + 1
  FROM split_cte
  WHERE TRIM(remaining)!= ''
)
-- final select from CTE
SELECT actors, COUNT(show_id)  as total_content
FROM split_cte
GROUP BY actors
ORDER BY 2 DESC
LIMIT 10;


-- 15. Categorize the content based on the presence of the keywords 'kill' and 'violence' in th description field
-- Label content containing these keywords as 'Bad' and all other content as 'Good'
-- count how many items fall into each category

-- PART 1
select title,descriptions FROM netflix
where  descriptions COLLATE utf8mb4_general_ci LIKE '%kill%' or
 descriptions COLLATE utf8mb4_general_ci LIKE '%violence%';    
 
 /* select title,descriptions FROM netflix
where  descriptions COLLATE utf8mb4_general_ci LIKE "%kill%" or "%violence%";
This code gave wrong number of rows/not all answer rows
*/
-- PART 2 
WITH new_table
AS
(
SELECT *,
 CASE
 WHEN descriptions COLLATE utf8mb4_general_ci LIKE '%kill%' or
 descriptions COLLATE utf8mb4_general_ci LIKE '%violence%' THEN 'Bad Content'
 ELSE
 'Good Content'
 END Content_type
 FROM netflix
 )
 
 -- PART 3
 SELECT Content_type,
 COUNT(*) AS total_content
 FROM new_table
 GROUP BY 1;
 









