# Netflix Movies and TV Shows Data Analysis using SQL
![Netflix_Logo](https://github.com/VanshikaGupta00/Netflix_SQL_Project/blob/main/logo.png)
## Objective
- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema

```sql
Create database netflix_db;

USE netflix_db;
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix(
    show_id VARCHAR(6),
    category VARCHAR(10),
    title VARCHAR(150),
    director VARCHAR(210),	
    cast VARCHAR(1000),	
    release_in_country VARCHAR(150),
    date_added VARCHAR(50),
    release_year int,	
    rating VARCHAR(10),
    duration VARCHAR(15),
    listed_in VARCHAR(100),	
    descriptions VARCHAR(250)
);

SET GLOBAL LOCAL_INFILE=ON;

LOAD DATA LOCAL INFILE 'C:/Users/gupta/OneDrive/Documents/IITG COURSE/Intro To SQL/netflix_titles.csv/netflix_titles.csv'
 INTO TABLE netflix
 FIELDS TERMINATED BY ','
 ENCLOSED BY '"'
 LINES TERMINATED BY '\r\n'
 IGNORE 1 LINES;

```

## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
SELECT 
 category,
 COUNT(*) AS total_count
FROM netflix
GROUP BY category;
```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
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
```

**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
SELECT title,release_year
FROM netflix
WHERE 
category="Movie" 
AND
release_year=2020;
```

**Objective:** Retrieve all movies released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix

```sql

-- FIRST QUERY
SELECT 
TRIM(SUBSTRING_INDEX(release_in_country, ',', 1)) AS country,
COUNT(show_id)  as Total_content
FROM netflix
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- SECOND QUERY 
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
-- Final select from CTE
SELECT country, COUNT(show_id)  as Total_content
FROM split_cte
GROUP BY country;

```

**Objective:** Identify the top 5 countries with the highest number of content items.

### 5. Identify the Longest Movie

```sql
SELECT * FROM netflix
WHERE 
category="Movie"
AND
duration=(SELECT MAX(duration) FROM netflix);
```

**Objective:** Find the movie with the longest duration.

### 6. Find Content Added in the Last 5 Years

```sql
SELECT *
FROM netflix
WHERE 
str_to_date(date_added,'%M %d,%Y') >= current_date - interval 5 YEAR;
```

**Objective:** Retrieve content added to Netflix in the last 5 years.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
SELECT *
FROM netflix
WHERE director COLLATE utf8mb4_general_ci LIKE "%Rajiv Chilaka%";
/*used COLLATE 'utf8mb4_general_ci' to also get case-snsitive like 'rajiv' (not only 'Rajiv') in output ,
it is an alternative of ILIKE of PostgreSQL*/
```

**Objective:** List all content directed by 'Rajiv Chilaka'.

### 8. List All TV Shows with More Than 5 Seasons

```sql
SELECT *
FROM netflix
WHERE 
category= 'TV Show' AND 
CAST(SUBSTRING_INDEX(duration,' ',1)AS UNSIGNED) > 5;
```

**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre

```sql
-- FIRST QUERY
SELECT 
TRIM(SUBSTRING_INDEX(listed_in, ",", 1)) AS genre,
COUNT(show_id)  as Total_content
FROM netflix
GROUP BY 1;

-- SECOND QUERY
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
  
  -- Final select from CTE
  SELECT genre, COUNT(*) AS total_content
FROM split_cte
GROUP BY genre;
```

**Objective:** Count the number of content items in each genre.

### 10.Find each year and the average numbers of content release in India on netflix. 
return top 5 year with highest avg content release!

```sql
SELECT 
EXTRACT(YEAR FROM str_to_date(date_added,"%M %d,%Y")) AS year,
COUNT(*),
ROUND(CAST(COUNT(*) AS UNSIGNED)/CAST((SELECT COUNT(*) FROM netflix 
WHERE release_in_country COLLATE utf8mb4_general_ci LIKE "%India%" )AS unsigned)* 100 ,2)AS Avg_content
FROM netflix
WHERE release_in_country COLLATE utf8mb4_general_ci LIKE "%India%"
GROUP BY 1
order by 1 DESC;
```

**Objective:** Calculate and rank years by the average number of content releases by India.

### 11. List All Movies that are Documentaries

```sql
SELECT *
FROM netflix
WHERE 
 category='Movie'
AND 
 listed_in COLLATE utf8mb4_general_ci LIKE "%Documentaries%";
```

**Objective:** Retrieve all movies classified as documentaries.

### 12. Find All Content Without a Director

```sql
SELECT * FROM netflix
WHERE TRIM(director)='' ;    
-- NOTE:there is a difference between '' and ' ' ,cannot be equated
```

**Objective:** List content that does not have a director.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

```sql
SELECT *
FROM netflix
WHERE 
category='Movie'
   AND 
cast COLLATE utf8mb4_general_ci LIKE "%Salman Khan%"
   AND 
release_year >= EXTRACT(YEAR FROM current_date()) -10;
```

**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

```sql
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
```

**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

### 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

```sql
-- PART 1
select title,descriptions FROM netflix
where  descriptions COLLATE utf8mb4_general_ci LIKE '%kill%' or
 descriptions COLLATE utf8mb4_general_ci LIKE '%violence%';

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
```

**Objective:** Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusion

- **Content Distribution:** The dataset contains a diverse range of movies and TV shows with varying ratings and genres.
- **Common Ratings:** Insights into the most common ratings provide an understanding of the content's target audience.
- **Geographical Insights:** The top countries and the average content releases by India highlight regional content distribution.
- **Content Categorization:** Categorizing content based on specific keywords helps in understanding the nature of content available on Netflix.

This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.



## Author - Vanshika Gupta

This project is part of my portfolio, showcasing the SQL skills essential for data analyst roles. If you have any questions, feedback, or would like to collaborate, feel free to get in touch!

### Stay Updated and Join the Community

Thank you for your support, and I look forward to connecting with you!
