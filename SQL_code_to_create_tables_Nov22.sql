
-- Clean the locations table to have only the most complete records for each (cph,  premises_type) pair

CREATE TABLE locations_unique_tbl AS
with cte2 AS (	
	WITH cte AS (
		SELECT cph_formatted, cph, map_x, map_y, premises_type, geom, uid, county, parish, holding,
			   (CASE WHEN cph_formatted IS NOT NULL THEN 1 ELSE 0 END) + 
			   (CASE WHEN cph IS NOT NULL THEN 1 ELSE 0 END) + 
			   (CASE WHEN map_x IS NOT NULL THEN 1 ELSE 0 END) + 
			   (CASE WHEN map_y IS NOT NULL THEN 1 ELSE 0 END) + 
			   (CASE WHEN premises_type IS NOT NULL THEN 1 ELSE 0 END) + 
			   (CASE WHEN geom IS NOT NULL THEN 1 ELSE 0 END) + 
			   (CASE WHEN uid IS NOT NULL THEN 1 ELSE 0 END) + 
			   (CASE WHEN county IS NOT NULL THEN 1 ELSE 0 END) + 
			   (CASE WHEN parish IS NOT NULL THEN 1 ELSE 0 END) + 
			   (CASE WHEN holding IS NOT NULL THEN 1 ELSE 0 END) AS completeness
		FROM locations_tbl
	)
	SELECT cph_formatted, cph, map_x, map_y, premises_type, geom, uid, county, parish, holding, 
	ROW_NUMBER() OVER (PARTITION BY cph, premises_type ORDER BY completeness DESC) as rn
	FROM cte)
SELECT cph_formatted, cph, map_x, map_y, premises_type, geom, uid, county, parish, holding
FROM cte2
WHERE rn = 1


-- Extract only the Agricultural holdings

CREATE TABLE locations_unique_AH_tbl AS
SELECT *
FROM locations_unique_tbl
WHERE premises_type = 'AH'

-- Add the county names

CREATE TABLE locations_unique_extended_tbl AS
SELECT * 
FROM locations_unique_tbl loc
LEFT JOIN apha_counties_tbl apha
ON (loc.county = apha.county_id)

CREATE TABLE locations_unique_extended_AH_tbl AS
SELECT *
FROM locations_unique_extended_tbl
WHERE premises_type = 'AH'

-- Add finer location detail to movements table

CREATE TABLE movement_extended_tbl AS
SELECT mov.eartag,
mov.movement_date,
mov.movement_id, 
mov.off_cph, 
mov.on_cph, 
mov.trans_cph, 
mov.birth, 
mov.death, 
loc2.county_name AS off_county_name, 
loc2.county AS off_county, 
loc2.parish AS off_parish, 
loc2.holding AS off_holding, 
loc2.premises_type AS off_premises_type, 
loc.county_name AS on_county_name, 
loc.county AS on_county, 
loc.parish AS on_parish, 
loc.holding AS on_holding, 
loc.premises_type AS on_premises_type,
tran.county_name AS trans_county_name, 
tran.county AS trans_county, 
tran.parish AS trans_parish, 
tran.holding AS trans_holding, 
mov.trans_prem_type, 
mov.movement_date_day, 
mov.movement_date_month, 
mov.movement_date_year, 
mov.movement_date_dow
FROM animal_movements_split_dates_tbl mov
LEFT JOIN locations_unique_extended_ah_tbl loc
	ON (loc.cph = mov.on_cph)
LEFT JOIN locations_unique_extended_ah_tbl loc2
	ON (loc2.cph = mov.off_cph)
LEFT JOIN locations_unique_extended_ah_tbl tran
	ON (tran.cph = mov.trans_cph)


-- Add finer location detail to testing table

CREATE TABLE tests_extended_tbl AS
SELECT test.cph,
test.test_date,
test.eartag,
test.age_at_test,
test.category,
test.test_type,
test.test_res,
test.test_res2,
test.action,
test.les_sh,
test.cult,
test.genotype,
test.avian_result,
test.bovine_result,
test.reactor_type,
loc.county_name,
loc.county,
loc.parish,
loc.holding,
loc.premises_type,
test.test_date_year,
test.test_date_month,
test.test_date_day,
test.test_date_dow,
loc.country
FROM animal_tests_split_dates_tbl test
LEFT JOIN (SELECT * FROM locations_unique_extended_ah_tbl) loc
ON (test.cph = loc.cph)


-- Remove all of the duplicated movements (ie moves with the same animal, same destinations, same day, sometimes double births)

CREATE TABLE movement_without_dups_tbl AS
SELECT eartag,
movement_date, 
movement_id,
off_cph, 
on_cph, 
trans_cph, 
birth, 
death, 
off_county_name, 
off_county, 
off_parish, 
off_holding, 
off_premises_type, 
on_county_name, 
on_county, 
on_parish, 
on_holding, 
on_premises_type,
trans_county_name, 
trans_county, 
trans_parish, 
trans_holding, 
trans_prem_type, 
movement_date_day, 
movement_date_month, 
movement_date_year, 
movement_date_dow,
count(eartag) AS num_duplicate_movements
FROM movement_extended_tbl
GROUP BY eartag, movement_date, movement_id, off_cph, on_cph, birth, death, trans_cph, off_county_name, 
off_county, 
off_parish, 
off_holding, 
off_premises_type, 
on_county_name, 
on_county, 
on_parish, 
on_holding, 
on_premises_type,
trans_county_name, 
trans_county, 
trans_parish, 
trans_holding, 
trans_prem_type, 
movement_date_day, 
movement_date_month, 
movement_date_year, 
movement_date_dow
ORDER BY eartag, movement_date, movement_id





-- Remove the movements that have the same on and off cph id (ie moves to self) from the no duplicated movements table

CREATE TABLE movement_no_dups_no_selfmoves_tbl AS
SELECT *
FROM movement_without_dups_tbl
EXCEPT
SELECT *
FROM movement_without_dups_tbl
WHERE off_cph = on_cph


-- Split the movements into 3 tables: births, deaths, and moves

CREATE TABLE births_no_dups_tbl AS
SELECT *
FROM movement_no_dups_no_selfmoves_tbl
WHERE birth = 'true'

CREATE TABLE deaths_no_dups_tbl AS
SELECT *
FROM movement_no_dups_no_selfmoves_tbl
WHERE death = 'true'

CREATE TABLE moves_no_dups_with_sameday_death_tbl AS
SELECT *
FROM movement_no_dups_no_selfmoves_tbl
WHERE death = 'false' AND birth = 'false'



-- TESTS --

-- Remove duplicate tests

CREATE TABLE tests_no_dups AS
SELECT cph, county_name, eartag, test_date, category, test_type, test_res, action, count(eartag) as num_duplicate_tests
     FROM tests_extended_tbl
     GROUP BY cph, county_name, eartag, test_date, category, test_type, test_res, action
     ORDER BY test_date, cph, test_type, test_res, action












