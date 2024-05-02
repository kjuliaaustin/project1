#World Life Expectancy Project

SELECT *
FROM world_life_expectancy;

SELECT * 
FROM world_life_expectancy
WHERE Country LIKE '%United%';

UPDATE world_life_expectancy
SET Country = 'United States'
WHERE Country = 'United States of America';

UPDATE world_life_expectancy
SET Country = 'United Kingdom'
WHERE Country = 'United Kingdom of Great Britain and Northern Ireland';

#Find duplicate rows by combining country and year
SELECT Country, 
Year, 
CONCAT(Country, Year), 
COUNT(CONCAT(Country, Year))
FROM world_life_expectancy
GROUP BY Country, Year, CONCAT(Country, Year)
HAVING COUNT(CONCAT(Country, Year)) > 1
;

#Creating a new column, Row_Num, to delete duplicate records
SELECT *
FROM(
	SELECT Row_ID,
	CONCAT(Country, Year),
	ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as Row_Num
	FROM world_life_expectancy) AS Row_table
WHERE Row_Num > 1
;

SET SQL_SAFE_UPDATES = 0;

#Delete duplicate records
DELETE FROM world_life_expectancy
WHERE
	Row_ID IN (
    SELECT Row_ID
FROM(
	SELECT Row_ID,
	CONCAT(Country, Year),
	ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as Row_Num
	FROM world_life_expectancy
    ) AS Row_table
WHERE Row_Num > 1
)
;

#Find empty records
SELECT *
FROM world_life_expectancy
WHERE Status = '';

#Find the unique strings within the Status column
SELECT DISTINCT(Status)
FROM world_life_expectancy
WHERE Status <> '';

#What countries have the 'Developing' Status?
SELECT DISTINCT(Country)
FROM world_life_expectancy
WHERE Status = 'Developing';

#Update all developing countries to include the status 'Developing'
#This will fill all null records
UPDATE world_life_expectancy
SET Status = 'Developing'
WHERE Country IN (SELECT DISTINCT(Country)
	FROM world_life_expectancy
	WHERE Status = 'Developing');
    
#This did not work, so a new method needs to be used
    
#Updating the table using a self-join for 'Developing' Countries to fill null records
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developing'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developing'
;

#Updating the table using a self-join for 'Developed' Countries to fill null records
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
SET t1.Status = 'Developed'
WHERE t1.Status = ''
AND t2.Status <> ''
AND t2.Status = 'Developed'
;

#Find empty records in 'Life expectancy' column
SELECT Country, Year, `Life expectancy`
FROM world_life_expectancy
WHERE `Life expectancy` = ''
;

#This resulted in two records having empty values

#Creating a self-join to find the average Life expectancy for +1 and -1 year to fill in blank records
SELECT t1.Country, t1.Year, t1.`Life expectancy`, 
t2.Country, t2.Year, t2.`Life expectancy`,
t3.Country, t3.Year, t3.`Life expectancy`,
ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
WHERE t1.`Life expectancy` = ''
;

#Update the records with missing values with the average life expectancy for +1 and -1 year
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.Country = t2.Country
    AND t1.Year = t2.Year - 1
JOIN world_life_expectancy t3
	ON t1.Country = t3.Country
    AND t1.Year = t3.Year + 1
SET t1.`Life expectancy` = ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
WHERE t1.`Life expectancy` = ''
;

SELECT Country, 
MIN(`Life expectancy`), 
MAX(`Life expectancy`),
ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`), 1) AS Life_Increase_15_Years
FROM world_life_expectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY Life_Increase_15_Years DESC;

#Haiti, Zimbabwe, Eritrea, and Uganda increased their life expectancy by 20 years in a 15 year timespan! That's incredible.

#Let's look at the average life expectancy by year
SELECT Year, 
ROUND(AVG(`Life expectancy`),2)
FROM world_life_expectancy
WHERE `Life expectancy` <> 0
GROUP BY Year
ORDER By Year;

#Our average life expectancy for 2007 was 66.75 years versus in 2022 was 71.62 years.
#That's an average increase of 4.87 years over a 15 year period!

SELECT ROUND(AVG(`Life expectancy`),2) AS World_Life_Expectancy
FROM world_life_expectancy;

#The average world life expectancy is 68.99

#Let's look at correlation between GDP and life expectancy and BMI and life expectancy
SELECT Country,
ROUND(AVG(`Life expectancy`),1) AS Life_Exp_Average,
ROUND(AVG(GDP),1) AS GDP_Average
FROM world_life_expectancy
GROUP BY Country
HAVING GDP_Average <> 0 AND Life_Exp_Average <> 0
ORDER BY GDP_Average ASC;

#The average life expectancy for High GDP versus the average life expectancy for Low GDP to see correlation
SELECT
SUM(CASE WHEN GDP >= 1500 THEN 1 ELSE 0 END) High_GDP_Count,
ROUND(AVG(CASE WHEN GDP >= 1500 THEN `Life expectancy` ELSE NULL END),2) High_GDP_Life_Expectancy,
SUM(CASE WHEN GDP < 1500 THEN 1 ELSE 0 END) Low_GDP_Count,
ROUND(AVG(CASE WHEN GDP < 1500 THEN `Life expectancy` ELSE NULL END),2) Low_GDP_Life_Expectancy
FROM world_life_expectancy;

#The life expectancy for high GDP is 74.20 versus for low GDP is 64.70

#Look at the average life expectancy for developing countries versus developed countries
SELECT Status, ROUND(AVG(`Life expectancy`),1)
FROM world_life_expectancy
GROUP BY Status;

#The life expectancy for developing countries is 66.8 versus developed countries is 79.2

#Let's see if the life expectancy by status is skewed based on the count of countries per status
SELECT Status, COUNT(DISTINCT Country), ROUND(AVG(`Life expectancy`),1)
FROM world_life_expectancy
GROUP BY Status;

#There are over 5 times more developing countries so the data is a bit skewed. Data should be broken down by country and not by status.

#Let's look at correlation between life expectancy and BMI
SELECT Country,
ROUND(AVG(`Life expectancy`),1) AS Life_Exp_Average,
ROUND(AVG(BMI),1) AS BMI_Average
FROM world_life_expectancy
GROUP BY Country
HAVING BMI_Average > 0 AND Life_Exp_Average <> 0
ORDER BY BMI_Average DESC;

#Rolling total of adult mortality by country
SELECT Country,
Year,
`Life expectancy`,
`Adult Mortality`,
SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) AS Rolling_Total
FROM world_life_expectancy;

SELECT *
FROM world_population;

#The average life expectancy by continent
SELECT Continent, ROUND(AVG(`Life expectancy`),2) AS Avg_Continent_Life_Expectancy
FROM world_life_expectancy wle
JOIN world_population wp
	ON wle.Country = wp.`Country/Territory`
GROUP BY wp.Continent
ORDER BY Avg_Continent_Life_Expectancy DESC;

#Europe has the highest life expectancy at 77.72
#South America has the second highest life expectancy at 73.46
#North America has the third highest life expectancy at 73.11
#Africa has the lowest life expectancy
    
SELECT Continent, ROUND(AVG(GDP),2) AS Avg_Continent_GDP
FROM world_life_expectancy wle
JOIN world_population wp
	ON wle.Country = wp.`Country/Territory`
GROUP BY wp.Continent
ORDER BY Avg_Continent_GDP DESC;

#Europe has the highest GDP at 17225.19
#Africa has the lowest GDP

SELECT Continent, ROUND(AVG(Schooling),2) AS Avg_Continent_Schooling
FROM world_life_expectancy wle
JOIN world_population wp
	ON wle.Country = wp.`Country/Territory`
GROUP BY wp.Continent
ORDER BY Avg_Continent_Schooling DESC;

#Europe again has the highest schooling at 15.25 years
#Africa again has the lowest schooling at 8.92 years

SELECT *
FROM world_data_2023;

#Let's look at Co2 emissions by country
SELECT wle.Country, 
ROUND(AVG(`Co2-Emissions`),2) AS Avg_CO2_Emissions, 
ROUND(AVG(wle.`Life expectancy`),2) AS Avg_Life_Expectancy
FROM world_life_expectancy wle
JOIN world_data_2023 wd
	ON wle.Country = wd.Country
GROUP BY wle.Country
HAVING Avg_Life_Expectancy <> 0
ORDER BY Avg_CO2_Emissions DESC;

#Let's look at Average out of pocket health expenditure by country
#Do countries with higher expenditures have lower life expectancy?
SELECT wle.Country, 
ROUND(AVG(`Out of pocket health expenditure`),2) AS Avg_OOP, 
ROUND(AVG(wle.`Life expectancy`),2) AS Avg_Life_Expectancy
FROM world_life_expectancy wle
JOIN world_data_2023 wd
	ON wle.Country = wd.Country
GROUP BY wle.Country
HAVING Avg_Life_Expectancy <> 0
ORDER BY Avg_Life_Expectancy DESC;

#Physicians per country
SELECT wle.Country, 
ROUND(AVG(`Physicians per Thousand`),2) AS Avg_Physicians, 
ROUND(AVG(wle.`Life expectancy`),2) AS Avg_Life_Expectancy
FROM world_life_expectancy wle
JOIN world_data_2023 wd
	ON wle.Country = wd.Country
GROUP BY wle.Country
HAVING Avg_Life_Expectancy <> 0
ORDER BY Avg_Life_Expectancy DESC;

#There is a strong correlation between life expectancy and physicians

#Let's take a look at the average physicians by continent and compare this to the life expectancy
SELECT Continent, 
ROUND(AVG(`Physicians per Thousand`),2) AS Avg_Physicians,
ROUND(AVG(wle.`Life expectancy`),2) AS Avg_World_Life_Expectancy
FROM world_life_expectancy wle
JOIN world_data_2023 wd
	ON wle.Country = wd.Country
JOIN world_population wp
	ON wd.Country = wp.`Country/Territory`
GROUP BY wp.Continent
ORDER BY Avg_Physicians DESC;

#Europe has the highest amount of physicians at 3.63 and highest life expectancy
#Africa has the lowest amount of physicians at 0.39

#Let's compare the physicians to the out of pocket expenses by continent
SELECT Continent, 
ROUND(AVG(`Physicians per Thousand`),2) AS Avg_Physicians,
ROUND(AVG(`Out of pocket health expenditure`),2) AS Avg_OOP,
ROUND(AVG(wle.`Life expectancy`),2) AS Avg_World_Life_Expectancy
FROM world_life_expectancy wle
JOIN world_data_2023 wd
	ON wle.Country = wd.Country
JOIN world_population wp
	ON wd.Country = wp.`Country/Territory`
GROUP BY wp.Continent
ORDER BY Avg_Physicians DESC;

SELECT *
FROM mental_health;

SELECT *
FROM mental_health
WHERE Entity LIKE '%United%';

SELECT wle.Country, 
ROUND(AVG(`Schizophrenia (%)`),2) AS Schizophrenia, 
ROUND(AVG(`Bipolar disorder (%)`),2) AS Bipolar_disorder, 
ROUND(AVG(`Eating disorders (%)`),2) AS Eating_disorder,
ROUND(AVG(`Anxiety disorders (%)`),2) AS Anxiety_disorder,
ROUND(AVG(`Drug use disorders (%)`),2) AS Drug_use_disorder,
ROUND(AVG(`Depression (%)`),2) AS Depression,
ROUND(AVG(`Alcohol use disorders (%)`),2) AS Alcohol_use_disorder,
ROUND(AVG(wle.`Life expectancy`),2) AS Avg_Life_Expectancy
FROM world_life_expectancy wle
JOIN mental_health mh
	ON wle.Country = mh.Entity
GROUP BY wle.Country
HAVING Avg_Life_Expectancy <> 0
ORDER BY Avg_Life_Expectancy DESC;