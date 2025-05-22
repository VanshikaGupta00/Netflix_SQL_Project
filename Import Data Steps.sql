-- Netflix Project

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

SELECT 
 COUNT(*) AS Total_Content
 FROM netflix;
 
 SELECT * FROM netflix;
 
 