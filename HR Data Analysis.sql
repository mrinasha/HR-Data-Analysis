use [HR data]
select * from [HR data]

--cleaning data and handling missing values

update [HR data]
set termdate=format(CONVERT(datetime, left(termdate,19),102),'yyyy-mm-dd')

--converting the termdate to date datatype

ALTER TABLE [HR data]
add new_termdate date;

update [HR data]
set new_termdate= case 
when termdate IS NOT NULL AND ISDATE(termdate)=1 then cast(termdate as datetime) else null end;

--- AGE DISTRIBUTION IN THE COMPANY
with cte as(
select id,birthdate,new_termdate, DATEDIFF(year, birthdate,getdate()) as age
from [HR data]
where  new_termdate IS NULL
)

SELECT
    SUM(CASE WHEN cte.age >= 20 AND cte.age < 30 THEN 1 END) AS twenties,
    SUM(CASE WHEN cte.age >= 30 AND cte.age < 40 THEN 1 END) AS thirties,
    SUM(CASE WHEN cte.age >= 40 AND cte.age < 50 THEN 1 END) AS forties,
    SUM(CASE WHEN cte.age >= 50 THEN 1 END) AS fifties,
    COUNT(*) AS total_employees,
    ROUND((SUM(CASE WHEN cte.age >= 20 AND cte.age < 30 THEN 1 END) * 100.0 / COUNT(*)), 2) AS twenties_percentage,
    ROUND((SUM(CASE WHEN cte.age >= 30 AND cte.age < 40 THEN 1 END) * 100.0 / COUNT(*)), 2) AS thirties_percentage,
    ROUND((SUM(CASE WHEN cte.age >= 40 AND cte.age < 50 THEN 1 END) * 100.0/ COUNT(*)), 2) AS forties_percentage,
    ROUND((SUM(CASE WHEN cte.age >= 50 THEN 1 END) * 100.0/ COUNT(*)), 2) AS fifties_percentage
FROM 
    cte
	where  new_termdate IS NULL


---GENDER BREAKDOWN

SELECT 
    SUM(CASE WHEN gender = 'Male' THEN 1 END) AS MALE_COUNT,
    SUM(CASE WHEN gender = 'Female' THEN 1 END) AS FEMALE_COUNT,
	SUM(CASE WHEN gender = 'Non-Conforming' THEN 1 END) AS non_conforming,
    COUNT(*) AS total_count,
    ROUND((SUM(CASE WHEN gender = 'Male' THEN 1 END) * 100.0 / COUNT(*)), 2) AS male_percent,
    ROUND((SUM(CASE WHEN gender = 'Female' THEN 1 END) * 100.0 / COUNT(*)), 2) AS female_percent,
	ROUND((SUM(CASE WHEN gender = 'non-conforming' THEN 1 END) * 100.0 / COUNT(*)), 2) AS nc_percent
FROM 
    [HR data]
WHERE 
    new_termdate IS NULL;



--GENDER BREAKDOWN ACROSS DEPARTMENT 
SELECT 
    department,
    SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) AS Female,
    SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) AS Male,
	SUM(CASE WHEN gender = 'non-conforming' THEN 1 ELSE 0 END) AS non_confirming,
	COUNT(*) AS total_count
FROM 
    [HR data]
	where new_termdate is null
GROUP BY 
    department
	order by department ;



--RACE DISTRIBUTION IN THE COMPANY
select race, count(*) as race_count from [HR data]
where new_termdate is null
group by race
order by race DESC



----AVERAGE EMPLOYMENT LENGTH
SELECT
 avg( DATEDIFF(YEAR, hire_date, new_termdate)) as tenure
FROM
    [HR data]
	WHERE
    new_termdate IS not NULL and new_termdate<=getdate()




--DEPARTMENT TURNOVER
select department,
total_count,
terminated_count, 
ROUND((terminated_count*100.0/total_count),2) as turnover_percent

from

(
select department,
count(*) as total_count,
sum(case 
when new_termdate is not null and new_termdate<=getdate()  then 1 end) as terminated_count
from  [HR data]
group by department
) as subquery
order by turnover_percent DESC



--TURNOVER RATE BASED ON GENDER 
select gender,
total_count,
terminated_count, 
ROUND((terminated_count*100.0/total_count),2) as turnover_percent

from

(
select gender,
count(*) as total_count,
sum(case 
when new_termdate is not null and new_termdate<=getdate()  then 1 end) as terminated_count
from  [HR data]
group by gender
) as subquery
order by turnover_percent DESC



--TURNOVER RATE BASED ON AGE
SELECT 
    Age_Group,
    COUNT(*) AS total_count,
    SUM(CASE WHEN new_termdate IS NOT NULL THEN 1 ELSE 0 END) AS terminated_count,
    ROUND((SUM(CASE WHEN new_termdate IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) AS turnover_percent
FROM (
    SELECT 
        id,
        birthdate,
        new_termdate,
        DATEDIFF(year, birthdate, GETDATE()) AS age,
        CASE
            WHEN DATEDIFF(year, birthdate, GETDATE()) BETWEEN 20 AND 29 THEN 'twenties'
            WHEN DATEDIFF(year, birthdate, GETDATE()) BETWEEN 30 AND 39 THEN 'thirties'
            WHEN DATEDIFF(year, birthdate, GETDATE()) BETWEEN 40 AND 49 THEN 'forties'
            WHEN DATEDIFF(year, birthdate, GETDATE()) >= 50 THEN 'fifties'
        END AS Age_Group
    FROM 
        [HR data]
) AS subquery
GROUP BY 
    Age_Group;





---TENURE DISTRIBUTION OVER DEPARTMENT
SELECT
department,
 avg( DATEDIFF(YEAR, hire_date, new_termdate)) as tenure
FROM
    [HR data]
	WHERE
    new_termdate IS not null  and new_termdate<=getdate()
group by department




--REMOTE WORKERS DISTRIBUTION
select
department,
sum(case when location='Headquarters' then 1 end) as wfo,
sum( case when location='remote' then 1 end ) as remote,
count(*) as total_count
from   [HR data]
where new_termdate is null
group by department



--DISTRIBUTION OF EMPLOYEES ACROSS STATES AND CITY
SELECT
location_state,
location_city,
COUNT(*) AS COUNT
from   [HR data]
where new_termdate is null
GROUP BY location_state, location_city
ORDER BY location_state



--JOB TITLE DISTRIBUTION ACROSS COMPANY(GENDER)
SELECT
jobtitle,
COUNT(*) AS COUNT,
sum(CASE WHEN gender='Male' then 1 end) as Male,
sum(CASE WHEN gender='Female' then 1 end) as Female,
sum(CASE WHEN gender='non-conforming' then 1 end) as nc
FROM [HR data]
where new_termdate is null
GROUP BY jobtitle


--VARIATION OF EMPLOYEE HIRE

SELECT 
    HIRE_YEAR,
    hire_number,
    termination,
    ROUND((hire_number - termination) * 100.0 / hire_number, 2) AS hire_percentage
FROM (
    SELECT 
        YEAR(hire_date) AS HIRE_YEAR,
        COUNT(*) AS hire_number,
        SUM(CASE WHEN new_termdate IS NOT NULL AND new_termdate <= GETDATE() THEN 1 ELSE 0 END) AS termination
    FROM 
        [HR data]
    GROUP BY 
        YEAR(hire_date)
) AS subquery
order by HIRE_YEAR
