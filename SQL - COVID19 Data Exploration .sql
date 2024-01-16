/* Covid 19 Data Exploration 

In this SQL project, I've conducted data exploration and analysis using various SQL techniques and functions on two related tables: 
CovidDeaths and CovidVaccinations. These SQL queries and operations are aimed at providing insights into COVID-19 data, particularly 
focusing on infection rates, death rates, and vaccination progress. 

Skills Used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/ 

SELECT * 
FROM [CovidDeaths]
Where continent is NOT NULL 
Order by 3,4

/*SELECT * 
FROM [CovidVaccinations]
Order by 3,4
*/

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [CovidDeaths]
Order by 1,2


-- Total Cases vs. Total Deaths
-- The percentage of dying if you contract COVID in your Country 

SELECT location, date, total_cases, total_deaths, 100.0*total_deaths/total_cases AS Death_Percentage
FROM [CovidDeaths]
Where location like 'philippines' 
Order by 1,2

-- Total Cases vs. Population 
-- The percentage of the population that's infected in your country

SELECT location, date, population, total_cases, 100.0*total_cases/population AS Percent_Population_Infected
FROM [CovidDeaths]
Where location like 'philippines' 
Order by 1,2


-- Countries with the Highest Infection Rate compared to the Population 
-- Shows the count and percentage of the population infected 

SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, 100.0*MAX(total_cases)/population AS Percent_Population_Infected
FROM [CovidDeaths]
Group by location, population
Order by Percent_Population_Infected DESC


-- Countries with the Highest Death Count per Population 

SELECT location, MAX(cast(total_deaths as int)) AS Total_Death_Count
FROM [CovidDeaths]
Where continent is NOT NULL 
Group by location
Order by Total_Death_Count DESC



-- Continent with the Highest Death Count per Population 

/*SELECT continent, MAX(cast(total_deaths as int)) AS Total_Death_Count
FROM [CovidDeaths]
Where continent is NOT NULL 
Group by continent
Order by Total_Death_Count DESC*/ 

-- This shows the accurate numbers per continent but has extra rows of info 
SELECT location, MAX(cast(total_deaths as int)) AS Total_Death_Count
FROM [CovidDeaths]
Where continent is null 
Group by location 
Order by Total_Death_Count DESC



-- Global Numbers 
-- Shows the total cases, total deaths and death percentage in the world 

SELECT SUM(new_cases) as TotalCases, SUM(new_deaths) TotalDeaths, 100.0*SUM(new_deaths)/SUM(new_cases) AS Death_Percentage
FROM [CovidDeaths]
where continent is not null 
Order by 1,2



-- Total Population vs. Vaccinations 

-- Shows the rolling count of Vaccinated people per country 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location order by dea.location, dea.date) AS Rolling_Vaccination_Count 
FROM [CovidDeaths]as dea 
Join [CovidVaccinations]as vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
where dea.continent is not null 
Order by 2, 3


-- Using CTE to calculate the percentage of vaccinations per population
-- Show the percentage of the population that are vaccinated per country 

WITH PopvsVac (continent, location, date, population, new_vaccinations, Rolling_Vaccination_Count)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location order by dea.location, dea.date) AS Rolling_Vaccination_Count 
FROM [CovidDeaths]as dea 
Join [CovidVaccinations]as vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
where dea.continent is not null 
-- Order by 2, 3
)

SELECT *, MAX(Rolling_Vaccination_Count) AS Total_Vaccinations, 100.0*Rolling_Vaccination_Count/population As Perc_Pop_Vaccinated 
FROM PopvsVac
Group by Location 


-- Using Temp Table to calculate the percentage of vaccinations per population 
-- Show the percentage of the population that are vaccinated per country 

-- Drop table if exists PercPopVac
Create TEMP Table PercPopVac
(
Continent text,
Location text,
Date text,
Population integer,
New_vaccinations integer,
Rolling_Vaccination_Count integer
)

Insert into PercPopVac
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location order by dea.location, dea.date) AS Rolling_Vaccination_Count 
FROM [CovidDeaths]as dea 
Join [CovidVaccinations]as vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
where dea.continent is not null 
-- Order by 2, 3

SELECT *, MAX(Rolling_Vaccination_Count) AS Total_Vaccinations, 100.0*Rolling_Vaccination_Count/population As Perc_Pop_Vaccinated 
FROM PercPopVac
Group by Location 



-- Creating view to store data for later visualizations 

CREATE View PercPopVac as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location order by dea.location, dea.date) AS Rolling_Vaccination_Count 
FROM [CovidDeaths]as dea 
Join [CovidVaccinations]as vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
where dea.continent is not null 
--Order by 2, 3

SELECT * 
FROM PercPopVac 
