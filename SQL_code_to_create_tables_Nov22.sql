
-- Remove all of the duplicated movements (ie moves with the same animal, same destinations, same day, sometimes double births)

CREATE TABLE movement_without_dups_tbl AS
SELECT eartag,
movement_date, 
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
GROUP BY eartag, movement_date, off_cph, on_cph, birth, death, trans_cph, off_county_name, 
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
ORDER BY eartag, movement_date







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


-- Remove any moves that occured on the same day as a death, as most likely moved to slaughter
-- not used

CREATE TABLE moves_no_dups_no_self_no_deathday AS
SELECT * FROM public.moves_no_dups_with_sameday_death_tbl mv
WHERE  NOT EXISTS (
    SELECT 
    FROM public.deaths_no_dups_tbl
	WHERE eartag = mv.eartag AND movement_date = mv.movement_date
  )


-- TESTS --

-- Remove duplicate tests

CREATE TABLE tests_no_dups AS
SELECT cph, county_name, eartag, test_date, category, test_type, test_res, action, count(eartag) as num_duplicate_tests
     FROM tests_extended_tbl
     GROUP BY cph, county_name, eartag, test_date, category, test_type, test_res, action
     ORDER BY test_date, cph, test_type, test_res, action












