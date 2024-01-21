######## Bixi Project - Part 1 - Data Analysis in SQL - by Mehrnoosh Behzadi ##########
########                            May 22nd-2023                            ##########

-- set default schema
use bixi;

-- -------------------------------------------------------------

-- Q1 : Overview of the volume of usage of Bixi Bikes and influential factors

-- 1-1: The total number of trips in 2016
select count(*) as total_trips_in_2016
from trips
where year(start_date) = 2016;

-- 1-2: The total number of trips in 2017
select count(*) as total_trips_in_2017
from trips
where year(start_date) = 2017;

-- 1-3: The total number of trips per month in 2016
select year(start_date) as year, month(start_date) as month, count(*) as total_trips_in_month
from trips
where year(start_date) = 2016
group by year(start_date), month(start_date);

-- 1-4: The total number of trips per month in 2017
select year(start_date) as year, month(start_date) as month, count(*) as total_trips_in_month
from trips
where year(start_date) = 2017
group by year(start_date), month(start_date);

-- 1-5: The average number of trips (rounded to avoid decimal) a day for each year-month
select year(start_date) as year, month(start_date) as month, round((count(*) / count(distinct date(start_date)))) as avg_daily_trips
from trips
group by year(start_date), month(start_date);

-- 1-6: Creating a table for the average number of trips (rounded to avoid decimal) a day for each year-month
-- First making sure the table doesn't exist in database
drop table if exists working_table1;
-- Now creating the table
create table working_table1 as
select year(start_date) as year, month(start_date) as month, round((count(*) / count(distinct date(start_date)))) as working_table1
from trips
group by year(start_date), month(start_date);

-- -------------------------------------------------------------

-- Q2 : Overview of membership status, (member/non-member) users behavior in the year 2017

-- 2-1: The total number of trips broken down by membership status
select 
-- Change membership status in result (1 to members and 0 to non-members)
	case is_member
		when 1 then 'members'
		else 'non-members'
		end as member_status,
-- Number of trips based on membership status
count(*) as total_trips_by_membership
from trips
where year(start_date) = 2017
group by is_member;

-- 2-2: The percentage (rounded to avoid decimal) of total trips by members per month
select year(start_date) as year, month(start_date) as month, round(100 * count(*) / (select count(*) from trips where year(start_date) = 2017)) as members_trips_percentage
from trips
where year(start_date) = 2017 and is_member = 1
group by year(start_date), month(start_date);

-- -------------------------------------------------------------

-- Q3 : based on above queries:

-- 3-1: At which time(s) of the year is the demand for Bixi bikes at its peak? Summer and fall, months 6-9, show the highst trip counts; it could be due to best weather condition to ride a bike.

-- 3-2: If you were to offer non-members a special promotion in an attempt to convert them to members, when would you do it? As seen in the results, summer would be the best time of year to attract new clients, by offering free trial periods, or discount on membership cost etc. to encourage non-members to buy membership.

-- -------------------------------------------------------------

-- Q4 :  Overview of individual stations usage, and station popularity

-- 4-1: The names of the 5 most popular starting stations - without using a subquery (Elapsed time on my pc 24s)
select stations.code, stations.name, count(trips.start_station_code) as num_trips
from stations
inner join trips
    on stations.code = trips.start_station_code
group by stations.code, stations.name
order by num_trips desc
LIMIT 5;

-- 4-2: The names of the 5 most popular starting stations - using a subquery (Elapsed time on my pc 2s!)
select stations.code, stations.name, num_trips
from stations
inner join (
select start_station_code, count(trips.start_station_code) as num_trips
from trips
group by start_station_code
order by num_trips desc
LIMIT 5) as trips on stations.code = trips.start_station_code;

-- -------------------------------------------------------------

-- Q5 : Overview of daily trips starting/ending @ the station Mackay/de Maisonneuve

-- 5-1: Daily distribution of number of trips starting/ending @ the station Mackay/de Maisonneuve
SELECT CASE
       WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
       WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
       WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
       ELSE "night"
END AS time_of_day,
sum(case when start_station_code = 6100 then 1 else 0 end) as start_trips,
sum(case when end_station_code = 6100 then 1 else 0 end) as end_trips
from trips
group by time_of_day;

-- 5-2: Why do you think these patterns in Bixi usage occur for this station? This station is situated in the downtown core of Montreal. Some reasons for pick usage in afternoon and evening could include exploring the downtown area, attending cultural events, shopping, or enjoying the vibrant urban atmosphere.

-- -------------------------------------------------------------

-- Q6 : List all stations for which at least 10% of trips are round trips, consider stations with at least 500 starting trips

-- 6-1: Number of starting trips per station
select stations.code, stations.name, num_start_trips
from stations
inner join (
select start_station_code, count(trips.start_station_code) as num_start_trips
from trips
group by start_station_code
) as trips on stations.code = trips.start_station_code
order by trips.num_start_trips desc;

-- 6-2: Number of round trips per station
select stations.code, stations.name, num_round_trips
from stations
inner join (
select start_station_code, end_station_code, count(trips.start_station_code) as num_round_trips
from trips
-- Condition for round trips
where start_station_code = end_station_code
group by start_station_code
) as trips on stations.code = trips.start_station_code
order by trips.num_round_trips desc;

-- 6-3: Fraction of round trips to the total number of starting trips for each station
select stations.code, stations.name, (trips.num_round_trips / trips.num_start_trips) as fraction_round_trips
from stations
inner join (
-- Count number of start trips
select start_station_code, count(trips.start_station_code) as num_start_trips,
-- Sum up number of round trips
sum(case when start_station_code = end_station_code then 1 else 0 end) as num_round_trips
from trips
group by start_station_code
) as trips on stations.code = trips.start_station_code
order by fraction_round_trips desc;

-- 6-4: Fraction of round trips to the total number of starting trips for each station with at least 500 trips & 10% round trips
select stations.code, stations.name, (trips.num_round_trips / trips.num_start_trips) as fraction_round_trips
from stations
inner join (
-- Count number of start trips
select start_station_code, count(trips.start_station_code) as num_start_trips,
-- Sum up number of round trips
sum(case when start_station_code = end_station_code then 1 else 0 end) as num_round_trips
from trips
group by start_station_code
) as trips on stations.code = trips.start_station_code
-- Condition of min 500 starting trips & 10% round trips
where num_start_trips >=500 and (num_round_trips / num_start_trips) >= 0.1
order by fraction_round_trips desc;

-- 6-5: Location of stations with a high fraction of round trips
select stations.name, stations.longitude, stations.latitude, (trips.num_round_trips / trips.num_start_trips) as fraction_round_trips
from stations
inner join (
-- Count number of start trips
select start_station_code, count(trips.start_station_code) as num_start_trips,
-- Sum up number of round trips
sum(case when start_station_code = end_station_code then 1 else 0 end) as num_round_trips
from trips
group by start_station_code
) as trips on stations.code = trips.start_station_code
-- Condition of min 500 starting trips & 10% round trips
where num_start_trips >=500 and (num_round_trips / num_start_trips) >= 0.1
order by fraction_round_trips desc;
