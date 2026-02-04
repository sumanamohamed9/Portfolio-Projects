-- EDA

-- Here we are jsut going to explore the data and find trends or patterns or anything interesting like outliers

SELECT *
FROM layoffs_staging_2;

-- Max laid_off 
SELECT  MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging_2;
# this shows that the max laid off by companies were 100% of its employees

-- companies who had 100% lay offs
SELECT *
FROM layoffs_staging_2
WHERE percentage_laid_off = 1;
# here we can see the name of the companies who have laid off all there employees

-- if we order by funcs_raised_millions we can see how big some of these companies were
SELECT *
FROM layoffs_staging_2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- min and max date in the data
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging_2;

-- comapnies with the biggest single lay off
SELECT company, total_laid_off
FROM layoffs_staging_2
ORDER BY total_laid_off DESC; 

-- Companies with the most Total Layoffs
SELECT company, sum(total_laid_off)
FROM layoffs_staging_2
GROUP BY company
ORDER BY Sum(total_laid_off) DESC; 

-- By industry
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY industry
ORDER BY SUM(total_laid_off) DESC;

-- which country had the most laid off
SELECT country, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY country
ORDER BY SUM(total_laid_off) DESC;

-- total lay off in given years
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY  YEAR(`date`)
ORDER BY YEAR(`date`) DESC;
# 2023 had the highest laid off eventhoug the available data is for 3 months of th year.

SELECT country, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY country
ORDER BY SUM(total_laid_off) DESC;

-- Roling total lay off per month to show month-momth progression in layoff
SELECT substring(`date`, 1, 7) AS `month`, SUM(total_laid_off)
FROM layoffs_staging_2
WHERE substring(`date`, 1, 6)IS NOT NULL
GROUP BY `month`
ORDER BY `month` ASC;


WITH Rolling_total AS
(
SELECT substring(`date`, 1, 7) AS `month`, SUM(total_laid_off) AS total_off
FROM layoffs_staging_2
WHERE substring(`date`, 1, 6)IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC
)
SELECT `month`, total_off,
SUM(total_off) OVER(ORDER BY `month`) AS rolling_total
FROM Rolling_total;

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY company, YEAR(`date`)
ORDER BY 2 DESC;

WITH company_year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off) 
FROM layoffs_staging_2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(
SELECT *, 
DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM company_year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE ranking <= 5;