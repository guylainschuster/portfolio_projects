SELECT *
FROM covid_deaths$
ORDER BY 3,4

--SELECT *
--FROM covid_deaths$
--ORDER BY 3,4

-- Select the data that we are going to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths$
ORDER BY 1,2

-- Looking at the total cases vs. the total deaths
-- Shows likelihood of dying if you contract COVID in the USA

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS DeathPercentage 
FROM covid_deaths$
WHERE location = 'France'
ORDER BY 1,2

-- Looking at the total cases vs. the population
-- Shows what percentage of the population got COVID

SELECT location, date, total_cases, population, (total_cases / population)*100 AS InfectionRate 
FROM covid_deaths$
-- WHERE location = 'France'
ORDER BY 1,2

-- Country with the highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectionRate
FROM covid_deaths$
-- WHERE location = 'France'
GROUP BY location, population
ORDER BY InfectionRate DESC

-- Country with the highest death count per population

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM covid_deaths$
WHERE continent IS NOT null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Continent with the highest death count per population

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM covid_deaths$
WHERE continent IS NOT null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global numbers

SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage 
FROM covid_deaths$
WHERE continent IS NOT null
ORDER BY 1,2

-- Total population vs. vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM covid_deaths$ AS dea
JOIN covid_vaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null AND dea.location = 'Canada'
ORDER BY 2,3

-- Total population vs. vaccination V2

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths$ AS dea
JOIN covid_vaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
ORDER BY 2,3

-- Use CTE

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths$ AS dea
JOIN covid_vaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- Use Temp table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths$ AS dea
JOIN covid_vaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM covid_deaths$ AS dea
JOIN covid_vaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null

-- The data can be queried from this view
SELECT *
FROM PercentPopulationVaccinated

