-- Data Cleaning

SELECT *
FROM layoffs;

-- Creating a duplicated table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens 
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- DATA CLEANING STEPS
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values 
-- 4. remove any columns and rows that are not necessary 

-- 1. Removing Duplicates

# checking for duplicates

SELECT *
FROM layoffs_staging;

# row_num created because the rows dont have a unique value

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- checking if the row_num have 2 or more values which will be the duplicates. first will be creating a CTE

WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

# checking to confirm the duplicates in company oda

SELECT *
FROM layoffs_staging
WHERE company = "oda";

# it looks like these are all legitimate entries and shouldn't be deleted. We need to really look at every single row to be accurate

-- checking to confirm the duplicates in company Casper
SELECT *
FROM layoffs_staging
WHERE company = "Casper";
# this one has duplicates and therefore the duplicated row need to be deleted 

-- creating a table and deleting the actual column
CREATE TABLE `layoffs_staging_2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL, 
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging_2
WHERE row_num > 1;

INSERT INTO layoffs_staging_2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, 
total_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- deleting the duplicated rows
DELETE
FROM layoffs_staging_2
WHERE row_num > 1;

-- Standardizing Data

# trimming the company list to remove the unwanted white spaces

SELECT company, TRIM(company)
FROM layoffs_staging_2;

#updating the 
UPDATE layoffs_staging_2
SET company = TRIM(company);

-- if we look at industry it looks like we have some null and empty rows, let's take a look at these
SELECT DISTINCT industry
FROM layoffs_staging_2
ORDER BY industry;

-- I also noticed the Crypto has different variations. We need to standardize that - let's say all to Crypto

SELECT DISTINCT industry
FROM layoffs_staging_2
ORDER BY industry;

UPDATE layoffs_staging_2
SET industry = "Crypto"
WHERE industry LIKE "Crypto%";

-- Checking whether all the rows got standardized
SELECT *
FROM layoffs_staging_2
WHERE industry LIKE "Crypto%";
# it can be seen that all the entries are now changed as crypto

-- everything looks good except we have some "United States" and some "United States." with a period at the end. Let's standardize this.
SELECT *
FROM layoffs_staging_2
WHERE country LIKE "United States%";

UPDATE layoffs_staging_2
SET country = "United States"
WHERE country LIKE "United States%";

-- now if we run this again it will be fixed
SELECT DISTINCT country
FROM layoffs_staging_2
ORDER BY country;

-- we need to fix the datec colum. currently it is in text format and it needed to be converted into date format
SELECT `date`,
STR_TO_DATE(`date`, "%m/%d/%Y")
FROM layoffs_staging_2;

UPDATE layoffs_staging_2
SET `date` = STR_TO_DATE(`date`, "%m/%d/%Y");

-- now we can convert the data type properly
ALTER TABLE layoffs_staging_2
MODIFY COLUMN `date` DATE;


-- looking and removing nulls

SELECT *
FROM layoffs_staging_2;

# the null values in total_laid_off, percentage_laid_off and funds_raised_millions looks normal and will be helpful for calculations during EDA phase. therefore i wont be removing that

-- checking for null values in industry
SELECT *
FROM layoffs_staging_2
WHERE industry IS NULL
OR industry = '';


SELECT *
FROM layoffs_staging_2
WHERE company = "Airbnb";
-- -- it looks like airbnb is a travel, but this one just isn't populated.
-- write a query that if there is another row with the same company name, it will update it to the non-null industry values


-- we should set the blanks to nulls since those are typically easier to work with

UPDATE layoffs_staging_2
SET industry = NULL
WHERE industry = '';

-- now if we check those are all null

SELECT *
FROM layoffs_staging_2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- now we need to populate these 

UPDATE layoffs_staging_2 AS t1
JOIN layoffs_staging_2  AS t2	
	ON t1.company = t2.company
SET t1.industry= t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- there was only one without a populated row to populate the null value in Bally's interactive
SELECT *
FROM layoffs_staging_2
WHERE company LIKE "Bally%";

-- 4. remove any columns and rows that are not necessary 

SELECT *
FROM layoffs_staging_2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- DELETE useless data 
DELETE FROM layoffs_staging_2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging_2
DROP COLUMN row_num;

SELECT*
FROM layoffs_staging_2;