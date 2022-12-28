use PortfolioProject;

update coviddeaths
set date = STR_TO_DATE(date, '%d.%m.%Y');

update covidvaccinations
set date = STR_TO_DATE(date, '%d.%m.%Y');

/*Looking at Total Death vs Total Cases in Turkey*/
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from coviddeaths where location like '%turkey%'
order by 1,2;

/*Looking at Total Cases vs Population in Turkey*/
select location, date, total_cases, population, (total_cases/population)*100 as population_percentage
from coviddeaths where location like '%turkey%' and continent is not null
order by 1,2;

/*Looking at Countries with High İnfection Rate Compared to Population*/
select location, population, max(total_cases) as highest_infection, max((total_cases/population))*100 as population_infection_percentage
from coviddeaths
where continent is not null
group by population, location
order by population_infection_percentage desc;


/*Showing Countries with Highest Death Count per Population */
select location, MAX(CAST(total_deaths as signed)) as total_death_count 
from coviddeaths
where continent != ''
group by location
order by total_death_count desc;

/* Showing continents with the highest death count per population */
select continent, MAX(CAST(total_deaths as signed)) as total_death_count 
from coviddeaths
where continent != ''
group by continent
order by total_death_count desc;

/* Global Numbers by Date */
select STR_TO_DATE(date, '%d.%m.%Y'), sum(new_cases) as total_cases_global
from coviddeaths
where continent != ''
group by date
order by 1;

/* Global Numbers by Date */
select date, sum(new_cases) as total_cases_global, sum(cast(new_deaths as signed)) as total_deaths_global, (sum(cast(new_deaths as signed))/sum(new_cases))*100 as death_percentage 
from coviddeaths
where continent != ''
group by date
order by 1;

/* Total cases vs total deaths */
select sum(new_cases) as total_cases_global, sum(cast(new_deaths as signed)) as total_deaths_global, (sum(cast(new_deaths as signed))/sum(new_cases))*100 as death_percentage 
from coviddeaths
where continent != ''
order by 1;

/* using cte */

WITH pop_vs_vac(continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, sum(cast(cv.new_vaccinations as signed)) over (partition by cd.location order by cd.location, cd.date) as rolling_people_vaccinated
from coviddeaths cd
join covidvaccinations cv
on cd.location = cv.location
and cd.date = cv.date
where cd.continent != ''
order by 2,3)
select * from pop_vs_vac;

/* Temp Table */

drop table percent_population_vaccinated;
create temporary table percent_population_vaccinated
(
continent varchar(255),
location varchar(255),
date datetime,
population int,
new_vaccinations int,
rolling_people_vaccinated int
);
insert into percent_population_vaccinated
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, sum(cast(cv.new_vaccinations as unsigned)) over (partition by cd.location order by cd.location, cd.date) as rolling_people_vaccinated
from coviddeaths cd
join covidvaccinations cv
on cd.location = cv.location
and cd.date = cv.date
where cv.new_vaccinations != '';
select *, (rolling_people_vaccinated/population)*100
from percent_population_vaccinated;

drop view percent_population_vaccinated;
create view percent_population_vaccinated as
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, sum(cast(cv.new_vaccinations as unsigned)) over (partition by cd.location order by cd.location, cd.date) as rolling_people_vaccinated
from coviddeaths cd
join covidvaccinations cv
on cd.location = cv.location
and cd.date = cv.date
where cd.continent != '' and cv.new_vaccinations != '';
