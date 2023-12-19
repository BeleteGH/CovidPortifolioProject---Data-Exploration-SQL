	/*

	Data Exploration using Covid 19 Data downloaded from https://ourworldindata.org/covid-deaths
	I have downloaded covid death and covid vaccination data. 

	Skils applied: Aggregate functions, Window functions, CTE, Joins, Temp Tables, Converting data types, Creating Views, 

	*/
		
	-- Checking the CovdDeath Table 
	SELECT *
	FROM CovidProject ..CovdDeath$
	where continent is not null 
	order by 3,4
		
	-- Checking the CovidVaccination Table 
	SELECT *
	FROM CovidProject .. ['CovidVaccination)$']
	order by 3,4
		
	-- Select the data we are going to use 
	Select location, date, total_cases, new_cases, total_deaths, population
	From CovidProject ..CovdDeath$
	order by 1,2

	-- looking at total cases vs total deaths 
	-- this shows the percentage of people died from total cases.
	Select location, date, total_cases, total_deaths,(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 as DeathPercentage
	From CovidProject ..CovdDeath$
	order by 1,2

	-- Checking death percentage in the United States 
	Select location, date, total_cases, total_deaths,(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 as DeathPercentage
	From CovidProject ..CovdDeath$
	Where location like '%states%'
	and continent is not null 
	order by 1,2

	-- Checking total cases vs total population 
	-- it shows percent of population who got covid 
	Select location, date, total_cases, population, (CONVERT(float, total_cases)/population)*100 as TotalCasesPercentage
	From CovidProject ..CovdDeath$
	Where location like '%states%'
	order by 1,2

	-- Looking at countries with highest infection rate compared to population 

	select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
	From CovidProject ..CovdDeath$
	Group by location, population
	order by PercentPopulationInfected desc

	-- Looking at countries with highest death count per population

	select location, MAX(cast(total_deaths as int)) as TotalDeathCount
	from CovidProject ..CovdDeath$
	where continent is not null
	Group by location
	order by TotalDeathCount desc

	-- Lets analyze it by continent 
	Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
	from CovidProject ..CovdDeath$
	where continent is not null
	Group by continent
	order by TotalDeathCount desc


	-- Global Numbers 
	Select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
	from CovidProject ..CovdDeath$
	where continent is not null
	--Group by date
	Order by 1,2


	-- Checking total population vs total vaccination 

	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	From CovidProject ..CovdDeath$ dea
	Join CovidProject ..['CovidVaccination)$'] vac
	On dea.location = vac.location 
		and dea.date = vac.date
	where dea.continent is not null
	order by 1,2,3


	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
	From CovidProject ..CovdDeath$ dea
	Join CovidProject ..['CovidVaccination)$'] vac
	On dea.location = vac.location 
		and dea.date = vac.date
	where dea.continent is not null
	order by 2,3

	-- Use CTE 
	With PopVsVac(Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
	as
	(
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CAST(vac.new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
	From CovidProject ..CovdDeath$ dea
	Join CovidProject ..['CovidVaccination)$'] vac
		On dea.location = vac.location 
		and dea.date = vac.date
	where dea.continent is not null
	--order by 2,3
	)
	select *, (RollingPeopleVaccinated/population)*100 
	from PopVsVac

	
	-- Temp Table 
	
	Drop Table if exists #PercentPopulationVaccinated
	Create Table #PercentPopulationVaccinated
	(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric, 
	RollingPeopleVaccinated numeric
	)

	Insert into #PercentPopulationVaccinated
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
	From CovidProject ..CovdDeath$ dea
	Join CovidProject ..['CovidVaccination)$'] vac
		On dea.location = vac.location 
		and dea.date = vac.date
	-- where dea.continent is not null
	-- order by 2,3
	select *, (RollingPeopleVaccinated/population)*100
	from #PercentPopulationVaccinated

	

	-- Creating View to store data and use it later for visualization 

	Create View PercentPopulationVaccinated as
	Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(int, vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
	From CovidProject ..CovdDeath$ dea
	Join CovidProject ..['CovidVaccination)$'] vac
		On dea.location = vac.location 
		and dea.date = vac.date
	where dea.continent is not null


	select * 
	from PercentPopulationVaccinated