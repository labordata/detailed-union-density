

WITH counties AS
  (SELECT geoid,
          substr('00' || STATEFIP, -2, 2) as state_geoid,
          GEOMETRY,
          COUNT(*) FILTER (
                           WHERE EARNWT > 0.0) AS observations,
          SUM(EARNWT)/60 AS employment,
          COALESCE(SUM(EARNWT/60) FILTER (
                                           WHERE "UNION" = 2), 0) AS members,
          COALESCE(SUM(EARNWT/60) FILTER (
                                           WHERE "UNION" > 1), 0) AS covered
   FROM cps
   INNER JOIN cb_2018_us_county_20m ON geoid = substr('00000' || COUNTY, -5, 5)
   WHERE ELIGORG = 1
     AND YEAR >= 2016
     AND YEAR <= 2020
   GROUP BY STATEFIP,
            COUNTY),
remaining_metro AS
  (select metro.geoid as geoid,
          CASE
              WHEN ST_UNION(counties.GEOMETRY) IS NOT NULL THEN ST_DIFFERENCE(metro.GEOMETRY, ST_UNION(counties.GEOMETRY))
              ELSE metro.GEOMETRY
          END AS GEOMETRY
   from cb_2018_us_cbsa_20m as metro
   LEFT JOIN counties ON St_Contains(metro.GEOMETRY, counties.GEOMETRY)
   GROUP BY metro.geoid,
            metro.GEOMETRY),
metros AS
  (SELECT remaining_metro.geoid,
          state.geoid,
          ST_CollectionExtract(ST_INTERSECTION(remaining_metro.GEOMETRY, state.GEOMETRY), 3) AS GEOMETRY,
          COUNT(*) FILTER (
                           WHERE EARNWT > 0.0) AS observations,
          SUM(EARNWT)/60 AS employment,
          COALESCE(SUM(EARNWT/60) FILTER (
                                           WHERE "UNION" = 2), 0) AS members,
          COALESCE(SUM(EARNWT/60) FILTER (
                                           WHERE "UNION" > 1), 0) AS covered
   FROM cps
   INNER JOIN remaining_metro on remaining_metro.geoid = METFIPS
   INNER JOIN cb_2018_us_state_20m as state ON state.geoid = substr('00' || STATEFIP, -2, 2)
   WHERE ELIGORG = 1
     AND YEAR >= 2016
     AND YEAR <= 2020
     AND COUNTY = 0
   GROUP BY METFIPS,
            STATEFIP),
subregion AS (
select *
from metros
UNION
select *
from counties),
remaining_state AS
  (select state.geoid as geoid,
          CASE
              WHEN ST_UNION(subregion.GEOMETRY) IS NOT NULL THEN ST_DIFFERENCE(state.GEOMETRY, ST_UNION(subregion.GEOMETRY))
              ELSE state.GEOMETRY
          END AS GEOMETRY
   from cb_2018_us_state_20m as state
   LEFT JOIN subregion ON St_Contains(state.GEOMETRY, subregion.GEOMETRY)
   GROUP BY state.geoid,
            state.GEOMETRY),
states AS (
select 
          remaining_state.geoid,
          remaining_state.geoid,
	  GEOMETRY,
          COUNT(*) FILTER (
                           WHERE EARNWT > 0.0) AS observations,
          SUM(EARNWT)/60 AS employment,
          COALESCE(SUM(EARNWT/60) FILTER (
                                           WHERE "UNION" = 2), 0) AS members,
          COALESCE(SUM(EARNWT/60) FILTER (
                                           WHERE "UNION" > 1), 0) AS covered
   FROM cps
   INNER JOIN remaining_state on remaining_state.geoid = substr('00' || STATEFIP, -2, 2)
     WHERE ELIGORG = 1
     AND YEAR >= 2016
     AND YEAR <= 2020
     AND COUNTY = 0
     AND METFIPS = '99998'
   GROUP BY STATEFIP)
select * from subregion
union
select * from states
