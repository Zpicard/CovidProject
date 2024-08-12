
/*
Select * 
From covidvaccinations
order by 3,4;
*/

-- Select Data that we are going to be using
USE PortfolioProject;

SELECT 
    Location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM
    coviddeaths
ORDER BY 1 , 2;

-- Change Data types for proper calculations

UPDATE PortfolioProject.coviddeaths 
SET 
    continent = NULL
WHERE
    continent = '';


UPDATE PortfolioProject.coviddeaths 
SET 
    total_cases = NULL
WHERE
    total_cases = '';

UPDATE PortfolioProject.coviddeaths 
SET 
    total_deaths = NULL
WHERE
    total_deaths = '';

UPDATE PortfolioProject.coviddeaths 
SET 
    Population = NULL
WHERE
    Population = '';

ALTER TABLE `PortfolioProject`.`coviddeaths` 
CHANGE COLUMN `total_cases` `total_cases` INT NULL DEFAULT NULL ,
CHANGE COLUMN `total_deaths` `total_deaths` INT NULL DEFAULT NULL ,
CHANGE COLUMN `Population` `Population` BIGINT NULL DEFAULT NULL;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT 
    Location,
    date,
    total_cases,
    total_deaths,
    (total_deaths / total_cases) * 100 AS DeathPercentage
FROM
    coviddeaths
WHERE
    location LIKE '%states%'
ORDER BY 1 , 2;

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT 
    Location,
    date,
    population,
    total_cases,
    (total_cases / population) * 100 AS PercentPopulationInfected
FROM
    coviddeaths
WHERE
    location LIKE '%states%'
ORDER BY 1 , 2;

-- Looking at Countries with Highest Infection Rate compared to Population

Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases / population)) * 100 as PercentPopulationInfected
From coviddeaths
Group by Location, population
-- Where location like '%states%'
order by PercentPopulationInfected desc;

-- Showing Countries with Highest Death Count per Population

Select Location, MAX(Total_deaths) as TotalDeathCount
From coviddeaths
Where continent is not null
Group by location
order by TotalDeathCount desc;

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

Select continent, MAX(Total_deaths) as TotalDeathCount
From coviddeaths
Where continent is not null
Group by continent
order by TotalDeathCount desc;


-- GLOBAL NUMBERS

SELECT 
     date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(New_Deaths) / SUM(New_Cases) * 100 as DeathPercentage
FROM
    coviddeaths
WHERE
    continent is not null
Group By date
ORDER BY 1 , 2;




SELECT 
     SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(New_Deaths) / SUM(New_Cases) * 100 as DeathPercentage
FROM
    coviddeaths
WHERE
    continent is not null
-- Group By date
ORDER BY 1 , 2;

-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) 
OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
, (RollingPeopleVaccinated/population) * 100
From coviddeaths dea
Join covidvaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2, 3;

-- USE CTE
with PopsvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) 
OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population) * 100
From coviddeaths dea
Join covidvaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--  order by 2, 3
)

Select *, (RollingPeopleVaccinated/population) * 100 
From PopsVsVac;

-- TEMP TABLE

-- Drop the temporary table if it exists
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

-- Create the temporary table
CREATE TEMPORARY TABLE PercentPopulationVaccinated 
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population DECIMAL(18,2),
    New_Vaccinations DECIMAL(18,2),
    RollingPeopleVaccinated DECIMAL(18,2)
);

-- Insert data into the temporary table, handling empty strings
INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    -- Convert empty strings to NULL or a default value (e.g., 0)
    NULLIF(vac.new_vaccinations, '') AS New_Vaccinations, 
    SUM(NULLIF(vac.new_vaccinations, 0)) 
        OVER (PARTITION BY dea.Location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    coviddeaths dea
JOIN 
    covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;
-- WHERE 
--    dea.continent IS NOT NULL;

-- Select data and calculate the percentage
SELECT 
    *, 
    (RollingPeopleVaccinated/population) * 100 AS PercentPopulationVaccinated
FROM 
    PercentPopulationVaccinated;
    
-- Creating View to store data for later visaulizations

Create View PercentPopulationVaccinated as
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    -- Convert empty strings to NULL or a default value (e.g., 0)
    NULLIF(vac.new_vaccinations, '') AS New_Vaccinations, 
    SUM(NULLIF(vac.new_vaccinations, 0)) 
        OVER (PARTITION BY dea.Location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    coviddeaths dea
JOIN 
    covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
	dea.continent IS NOT NULL;
-- order by 2,3

Create View CountriesInfectedRates as
Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases / population)) * 100 as PercentPopulationInfected
From coviddeaths
Group by Location, population
-- Where location like '%states%'
order by PercentPopulationInfected desc;

Create View DeathCountPerPopulation as
Select Location, MAX(Total_deaths) as TotalDeathCount
From coviddeaths
Where continent is not null
Group by location
order by TotalDeathCount desc;






