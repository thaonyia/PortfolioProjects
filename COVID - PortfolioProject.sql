/*********************************************************************************************************************************

COVID Portfolio Project - Nyia Thao

*********************************************************************************************************************************/


select * from PortfolioProject..CovidDeaths (nolock)
order by 1,2

select * from PortfolioProject..CovidVaccines (nolock)
order by 1,2

select Country, [date], total_cases, new_cases, total_deaths, [population]
from PortfolioProject..CovidDeaths (nolock)
order by 1,2

/*********************************************************************************************************************************

Covid Deaths

*********************************************************************************************************************************/
-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if a person contracts Covid in their country

select Country, [date], total_cases, total_deaths, 
case when total_cases = 0 then null else (cast(total_deaths as float)/cast(total_cases as float))*100 end as DeathPercentage
from PortfolioProject..CovidDeaths (nolock)
where country not in (select country from dbo.Continent)
order by 1,2

-- Looking at the Total Cases vs Population
-- Shows what percentage of the population got Covid

select Country, cast([date] as date) as [date], total_cases, [population], 
case when total_cases = 0 then null else (cast(total_cases as float)/cast([population] as float))*100 end as InfectedPercentage
from PortfolioProject..CovidDeaths (nolock)
where country not in (select country from dbo.Continent)
order by 1,2

--Looking at Countries with Highest Infection Rate compared to Population

select Country, [population], MAX(total_cases) as HighestInfectionCount
,MAX((total_cases/[population]))*100 as PercentageOfPopulationInfected
from PortfolioProject..CovidDeaths (nolock)
where country not in (select country from dbo.Continent)
group by Country, [population]
order by PercentageOfPopulationInfected desc

-- Showing Countries with the Highest Death Count per Population

select Country, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths (nolock)
where country not in (select country from dbo.Continent)
group by Country 
order by TotalDeathCount desc

-- Showing Continents with the Highest Death Count per Population

select Country as Continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths (nolock)
where country in (select country from dbo.Continent)
group by Country 
order by TotalDeathCount desc

-- Global Numbers of New Cases and New Deaths per Day

select cast([date] as date) as [date], SUM(new_cases) as TotalNewCases, SUM(cast(new_deaths as int)) as TotalNewDeaths
,	SUM(cast(new_deaths as int))/nullif(SUM(new_cases),0) * 100 as DeathPercentage
from PortfolioProject..CovidDeaths (nolock)
where country not in (select country from dbo.Continent)
group by date--, new_cases--, new_deaths
order by 1,2

-- Global Numbers of New Cases and New Deaths Overall

select SUM(new_cases) as TotalNewCases, SUM(cast(new_deaths as int)) as TotalNewDeaths
,	SUM(cast(new_deaths as int))/nullif(SUM(new_cases),0) * 100 as DeathPercentage
from PortfolioProject..CovidDeaths (nolock)
where country not in (select country from dbo.Continent)


/**************************************************************************************************************

Covid Death join Covid Vaccinations

***************************************************************************************************************/

Select *
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccines vac on dea.country = vac.country and dea.date = vac.date

-- Looking at Total Population vs Vaccinations

Select dea.country, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccines vac on dea.country = vac.country and dea.date = vac.date
where dea.country not in (select country from dbo.Continent)
order by 1,2

	Select dea.country, cast(dea.date as date) as [date], dea.population, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.country order by dea.country, cast(dea.date as date)) as RollingPeopleVaccinated
	from PortfolioProject..CovidDeaths dea
	join PortfolioProject..CovidVaccines vac on dea.country = vac.country and dea.date = vac.date
	where dea.country not in (select country from dbo.Continent)
	order by 1,2

-- Option 1: CTE
With PopVSVac (Country, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as 
(
Select dea.country, cast(dea.date as date) as [date], dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.country order by dea.country, cast(dea.date as date)) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccines vac on dea.country = vac.country and dea.date = vac.date
where dea.country not in (select country from dbo.Continent)
)
Select *, (RollingPeopleVaccinated/Population) * 100 as RollingPercentofPeopleVaccinated
from PopVSVac
order by 1,2

-- Option 2: Temp Table

DROP Table if exists #TMP_PercentPopulationVaccinated
Create table #TMP_PercentPopulationVaccinated
(
Country nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #TMP_PercentPopulationVaccinated
Select dea.country, cast(dea.date as date) as [date], dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.country order by dea.country, cast(dea.date as date)) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccines vac on dea.country = vac.country and dea.date = vac.date
where dea.country not in (select country from dbo.Continent)

Select *, (RollingPeopleVaccinated/Population)*100 as RollingPercentPeopleVaccinated
from #TMP_PercentPopulationVaccinated
order by 1,2

-- Create View to store data for later visualations

Create View PercentPopulationVaccinated as
Select dea.country, cast(dea.date as date) as [date], dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.country order by dea.country, cast(dea.date as date)) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccines vac on dea.country = vac.country and dea.date = vac.date
where dea.country not in (select country from dbo.Continent)

select *
from dbo.PercentPopulationVaccinated (nolock)
order by 1,2


/**************************************************************************************************************

	select distinct country from PortfolioProject..CovidDeaths (nolock) order by country
	/*
	Continent
	---------
	'Africa'
	,'Asia'
	,'Asia excl. China'
	,'Europe'
	,'European Union (27)'
	,'High-income countries'
	,'Lower-middle-income countries'
	,'Low-income countries'
	,'North America'
	,'Oceania'
	,'South America'
	,'Summer Olympics 2020'
	,'Upper-middle-income countries'
	,'Winter Olympics 2022'
	,'World'
	,'World excl. China'
	,'World excl. China and South Korea'
	,'World excl. China, South Korea, Japan and Singapore'
	*/

	select distinct country 
	into dbo.Continent
	from PortfolioProject..CovidDeaths where country in ('Africa'
	,'Asia'
	,'Asia excl. China'
	,'Europe'
	,'European Union (27)'
	,'High-income countries'
	,'Lower-middle-income countries'
	,'Low-income countries'
	,'North America'
	,'Oceania'
	,'South America'
	,'Summer Olympics 2020'
	,'Upper-middle-income countries'
	,'Winter Olympics 2022'
	,'World'
	,'World excl. China'
	,'World excl. China and South Korea'
	,'World excl. China, South Korea, Japan and Singapore')

***********************************************************************************************/