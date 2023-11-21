SELECT *
	FROM PortfolioProject1..CovidDeaths
	ORDER BY 3,4
	
--------------------------------------------------
-- Deathrate Amongst Infected by Country over Time

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
	FROM PortfolioProject1..CovidDeaths
	ORDER BY 1,2

-------------------------------------------------------
-- Creating View to Store Data for Later Visualizations

CREATE VIEW DeathRateByCountry AS 
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
	FROM PortfolioProject1..CovidDeaths

----------------------------------------------
-- Deathrate Amongst Infected in United States

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
	FROM PortfolioProject1..CovidDeaths
	WHERE Location LIKE '%states'
	ORDER BY 1,2

-----------------------------------------------------
-- Total Infections Relative to Population, over Time

SELECT Location, date, population, total_cases, (total_cases/population)*100 AS PopPercentInfected
	FROM PortfolioProject1..CovidDeaths
	ORDER BY 1,2

-------------------------------------------------------
-- Creating View to Store Data for Later Visualizations

CREATE VIEW InfectionVsPop AS 
SELECT Location, date, population, total_cases, (total_cases/population)*100 AS PopPercentInfected
	FROM PortfolioProject1..CovidDeaths

-----------------------------------------------------------------------
-- Total Infections Relative to Population, over Time for United States

SELECT Location, date, population, total_cases, (total_cases/population)*100 AS PopPercentInfected
	FROM PortfolioProject1..CovidDeaths
	ORDER BY 1,2

------------------------------------------------
-- Country Infection Rate Relative to Population

SELECT Location, population, MAX(cast(total_cases as int)) AS highestInfectionCount, MAX((cast(total_cases as int)/population))*100 AS PopPercentInfected
	FROM PortfolioProject1..CovidDeaths
	WHERE population > 100000
	GROUP BY location, population
	ORDER BY PopPercentInfected DESC

---------------------------
-- Countries by Death Rates

SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
	FROM PortfolioProject1..CovidDeaths
	--WHERE population > 1000000
	GROUP BY location
	ORDER BY TotalDeathCount DESC

SELECT Location, MAX(cast(total_deaths as int))/MAX(population)*100 AS DeathRate
	FROM PortfolioProject1..CovidDeaths
	--WHERE population > 1000000
	GROUP BY location
	ORDER BY DeathRate DESC

-------------------------
-- Breakdown by Continent

-------------------------------------------------------------
-- Showing Continents with Highest Death Count per Population

SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
	FROM PortfolioProject1..CovidDeaths
	--WHERE population > 1000000
	GROUP BY continent
	ORDER BY TotalDeathCount DESC


CREATE VIEW ContinentDeathCounts AS
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
	FROM PortfolioProject1..CovidDeaths
	--WHERE population > 1000000
	GROUP BY continent

---------------------------------------
-- Global Daily Cases/Deaths/Death Rate

SELECT date, SUM(new_cases) as new_cases, SUM(new_deaths) as new_deaths, (SUM(new_deaths)/NULLIF(SUM(new_cases),0))*100  AS DeathPercentage
	FROM PortfolioProject1..CovidDeaths
	WHERE new_cases IS NOT NULL
	GROUP BY date
	ORDER BY 1,2

--------------------------------
-- Total Global Deaths/Death Rate

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(new_deaths)/NULLIF(SUM(new_cases),0))*100  AS DeathPercentage
	FROM PortfolioProject1..CovidDeaths
	WHERE new_cases IS NOT NULL
	ORDER BY 1,2

----------------------------------------------
-- Looking at Total Population vs Vaccinations

SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations 
FROM PortfolioProject1..CovidDeaths death
JOIN PortfolioProject1..CovidVax vax
	ON death.location = vax.location
	AND death.date = vax.date
ORDER BY 2,3

------------------------
-- Rolling Vaccine Total

SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations
, SUM(CAST(vax.new_vaccinations as bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date)
  AS RollingVaxTotal
FROM PortfolioProject1..CovidDeaths death
JOIN PortfolioProject1..CovidVax vax
	ON death.location = vax.location
	AND death.date = vax.date
ORDER BY 2,3

-----------------------------
--Vaccination Peak by Country

-------------
--Using a CTE

With PopVsVax (continent, location, date, population, new_vaccinations, RollingVaxTotal)
AS
(
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations
, SUM(CAST(vax.new_vaccinations as bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date)
  AS RollingVaxTotal
FROM PortfolioProject1..CovidDeaths death
JOIN PortfolioProject1..CovidVax vax
	ON death.location = vax.location
	AND death.date = vax.date
--ORDER BY 2,3
)
Select *, RollingVaxTotal/population*100  
FROM PopVsVax

---------------------------------
--Same Process Using a Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaxxed
CREATE TABLE #PercentPopulationVaxxed
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaxTotal numeric
)

INSERT INTO #PercentPopulationVaxxed
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations
, SUM(CAST(vax.new_vaccinations as bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date)
  AS RollingVaxTotal
FROM PortfolioProject1..CovidDeaths death
JOIN PortfolioProject1..CovidVax vax
	ON death.location = vax.location
	AND death.date = vax.date
--ORDER BY 2,3

Select *, RollingVaxTotal/population*100 AS VaxRate
FROM #PercentPopulationVaxxed
ORDER BY 2,3

-------------------------------------------------------
-- Creating View to Store Data for Later Visualizations

CREATE VIEW PercentPopulationVaxxed AS
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations
, SUM(CAST(vax.new_vaccinations as bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date)
  AS RollingVaxTotal
FROM PortfolioProject1..CovidDeaths death
JOIN PortfolioProject1..CovidVax vax
	ON death.location = vax.location
	AND death.date = vax.date
--ORDER BY 2,3
