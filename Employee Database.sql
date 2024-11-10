CREATE TEMPORARY TABLE temp_table AS
SELECT * 
FROM salaries AS s 
LEFT JOIN companies AS c ON s.comp_name = c.company_name
LEFT JOIN functions AS f ON s.func_code = f.function_code
LEFT JOIN employees AS e ON s.employee_id = e.employee_code_emp
;

SELECT * FROM temp_table
;

CREATE TABLE dbs_employee AS   
SELECT 
    CONCAT(employee_id, CAST(STR_TO_DATE(`date`, '%d/%m/%Y %H:%i') AS DATE)) AS id,
    CAST(STR_TO_DATE(`date`, '%d/%m/%Y %H:%i') AS DATE) AS month_year, 
    employee_id, 
    employee_name,
    `GEN(M_F)`, 
    age,
    salary, 
    function_group, 
    company_name,
    company_city,
    company_state,
    company_type,
    const_site_category
FROM temp_table
;

SELECT * FROM dbs_employee
;

ALTER TABLE dbs_employee 
CHANGE COLUMN `GEN(M_F)` gender VARCHAR(255)
;

SET SQL_SAFE_UPDATES = 0;

UPDATE dbs_employee
SET    
    id = TRIM(id), 
    employee_id = TRIM(employee_id), 
    employee_name = TRIM(employee_name),
    gender = TRIM(gender),
    function_group = TRIM(function_group),
    company_name = TRIM(company_name),
    company_city = TRIM(company_city),
    company_state = TRIM(company_state),
    company_type = TRIM(company_type),
    const_site_category = TRIM(const_site_category);
    
SELECT * 
FROM dbs_employee
WHERE (id IS NULL OR TRIM(id) = '')
    OR (month_year IS NULL OR TRIM(month_year) = '')
    OR (employee_id IS NULL OR TRIM(employee_id) = '')
    OR (employee_name IS NULL OR TRIM(employee_name) = '')
    OR (gender IS NULL OR TRIM(gender) = '')
    OR (age IS NULL OR TRIM(age) = '')
    OR (salary IS NULL OR TRIM(salary) = '')
    OR (function_group IS NULL OR TRIM(function_group) = '')
    OR (company_name IS NULL OR TRIM(company_name) = '')
    OR (company_city IS NULL OR TRIM(company_city) = '')
    OR (company_state IS NULL OR TRIM(company_state) = '')
    OR (company_type IS NULL OR TRIM(company_type) = '')
    OR (const_site_category IS NULL OR TRIM(const_site_category) = '');    


-- Check for missing values in all columns 

-- id 

SELECT COUNT(id) AS count_missing_id
	FROM dbs_employee
	WHERE id = ''
    ;

-- month_year NOT WORKING 

SELECT COUNT(month_year) AS count_missing_month_year
FROM dbs_employee
WHERE month_year = '' OR month_year IS NULL
;

-- gender
SELECT COUNT(gender) AS count_missing_gender
FROM dbs_employee
WHERE TRIM(gender) = '' OR gender IS NULL
;

-- age
SELECT COUNT(age) AS count_missing_age
FROM dbs_employee
WHERE TRIM(age) = '' OR age IS NULL;

-- salary
SELECT COUNT(salary) AS count_missing_salary
FROM dbs_employee
WHERE TRIM(salary) = '' OR salary IS NULL
;

-- function_group
SELECT COUNT(function_group) AS count_missing_function_group
FROM dbs_employee
WHERE TRIM(function_group) = '' OR function_group IS NULL
;

-- company_name
SELECT COUNT(company_name) AS count_missing_company_name
FROM dbs_employee
WHERE TRIM(company_name) = '' OR company_name IS NULL
;

-- company_city
SELECT COUNT(company_city) AS count_missing_company_city
FROM dbs_employee
WHERE TRIM(company_city) = '' OR company_city IS NULL
;

-- company_state
SELECT COUNT(company_state) AS count_missing_company_state
FROM dbs_employee
WHERE TRIM(company_state) = '' OR company_state IS NULL
;

-- company_type
SELECT COUNT(company_type) AS count_missing_company_type
FROM dbs_employee
WHERE TRIM(company_type) = '' OR company_type IS NULL
;

-- const_site_category
SELECT COUNT(const_site_category) AS count_missing_const_site_category
FROM dbs_employee
WHERE TRIM(const_site_category) = '' OR const_site_category IS NULL
;

-- Deleting Missing Values 

-- salary

DELETE FROM dbs_employee
WHERE TRIM(salary) = '' OR salary IS NULL
;

-- const_site_category

DELETE FROM dbs_employee
WHERE TRIM(const_site_category) = '' OR const_site_category IS NULL
;

-- Checking Standardization 

-- ID (Might be a problem)

SELECT DISTINCT id
FROM dbs_employee
GROUP BY id
;

-- month year [Create Pay Month without day] ---- FIX And Delete the rest

ALTER TABLE dbs_employee
ADD pay_month VARCHAR(7) GENERATED ALWAYS AS (LEFT(month_year, 7)) VIRTUAL
;


-- Gender 

UPDATE dbs_employee
SET gender = CASE gender
                 WHEN 'M' THEN 'Male'
                 WHEN 'F' THEN 'Female'
                 ELSE gender
             END
;

-- Salary (Delete Test Runs by HR)

DELETE FROM dbs_employee
WHERE salary = 1000000
;

-- Employee Name (Delete Test Runs by HR)

DELETE FROM dbs_employee
WHERE employee_name = "Name Good"
;

-- company_city [Fix Typos]

UPDATE dbs_employee
SET company_city = 'Goiania'
WHERE company_city = 'Goianiaa'
;

-- company_state [Correct Casing]

UPDATE dbs_employee
SET company_state = 'Goias'
WHERE company_state = 'GOIAS'
;

-- company_type [correct typing]

UPDATE dbs_employee
SET company_type = 'Construction Site'
WHERE company_type = 'Construction Sites'
;

-- const_site_category [correct typing]

UPDATE dbs_employee
SET const_site_category = 'Commercial'
WHERE const_site_category = 'Commerciall'
;

-- Check for duplicated rows in 'id' column.

SELECT DISTINCT id ,COUNT(id) as duplicated
FROM dbs_employee
GROUP BY id
HAVING COUNT(id) > 1
;

WITH duplicates AS 
(
SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY pay_month, employee_id 
        ORDER BY employee_id) AS row_num
FROM dbs_employee
)
DELETE FROM dbs_employee
WHERE employee_id IN (
	SELECT employee_id
    FROM duplicates
    WHERE row_num > 1
)
;
    
SELECT * FROM dbs_employee;

-- Analysis -----------------------------------------------------------

-- How many employees do the companies have today? 

SELECT COUNT(DISTINCT employee_id) AS employee_count 
FROM dbs_employee
WHERE pay_month = (SELECT MAX(pay_month) FROM dbs_employee)
;

-- Employees per company 

SELECT 
	company_name, 
    COUNT(DISTINCT employee_id) AS employee_count
FROM dbs_employee
WHERE pay_month = (SELECT MAX(pay_month) FROM dbs_employee)
GROUP BY company_name
ORDER BY employee_count DESC
;

-- What is the total number of employees each city? Add a percentage column

SELECT company_city, 
	   COUNT(employee_id) AS employee_count,
	   ROUND(COUNT(employee_id) * 100 / SUM(COUNT(employee_id)) OVER (),2) AS percentage
FROM dbs_employee
WHERE pay_month = (SELECT MAX(pay_month) FROM dbs_employee)
GROUP BY company_city
ORDER BY employee_count DESC
;

-- What is the total number of employees each month?

SELECT pay_month, COUNT(DISTINCT employee_id) AS employee_count 
FROM dbs_employee
GROUP BY pay_month
ORDER BY pay_month ASC
;

-- Which month had the highest amount of employees 

SELECT pay_month, COUNT(employee_id) AS count_employees_per_month
FROM dbs_employee
GROUP BY pay_month
ORDER BY count_employees_per_month ASC
LIMIT 1
;

-- What is the annual average salary?

SELECT LEFT(pay_month, 4) AS year, ROUND(AVG(salary),2) AS average_salary
FROM dbs_employee
GROUP BY LEFT(pay_month, 4)
ORDER BY year
;

-- What is the monthly average salary?

SELECT 
	pay_month, 
	ROUND(AVG(salary),2) AS average_salary
FROM dbs_employee
GROUP BY pay_month
ORDER BY pay_month
;

-- What is the average salary by city?

SELECT company_city, 
	   ROUND(AVG(salary),2) AS average_salary
FROM dbs_employee
GROUP BY company_city
ORDER BY average_salary DESC
;

-- What is the average salary by state?

SELECT 
	company_state, 
	ROUND(AVG(salary),2) AS average_salary
FROM dbs_employee
GROUP BY company_state
ORDER BY average_salary DESC
;

-- What is the  average salary by function group?

SELECT 
	function_group, 
    ROUND(AVG(salary),2) AS average_salary
FROM dbs_employee
GROUP BY function_group
ORDER BY average_salary DESC
;

-- What are the employees with the top 10 highest salaries in average?

SELECT 
	employee_name, 
    ROUND(AVG(salary),2) AS average_salary
FROM dbs_employee
WHERE pay_month = (SELECT MAX(pay_month) FROM dbs_employee)
GROUP BY employee_name
ORDER BY average_salary DESC
LIMIT 10
;






