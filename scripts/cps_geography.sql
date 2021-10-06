BEGIN;

CREATE TEMPORARY TABLE unique_geographies AS SELECT DISTINCT
    METFIPS,
    STATEFIP,
    COUNTY,
    INDIVIDCC
FROM
    cps
WHERE
    YEAR >= 2016;

CREATE TABLE cps_geography (
    geoid text,
    metfips text,
    statefip text,
    county text,
    individcc text
);
SELECT
    AddGeometryColumn ('cps_geography', 'GEOMETRY', 4326, 'MULTIPOLYGON', 'XY');

-- add cities
INSERT INTO cps_geography
SELECT
    substr('00000' || COUNTY, -5, 5) || city_fips AS geoid,
    METFIPS,
    STATEFIP,
    COUNTY,
    INDIVIDCC,
    ST_MULTI (COALESCE(ST_CollectionExtract (ST_INTERSECTION (city.GEOMETRY, county.GEOMETRY), 3), city.GEOMETRY)) AS GEOMETRY
FROM
    city_map
    INNER JOIN us_principal_cities AS city USING (city_fips)
    LEFT JOIN cb_2018_us_county_20m AS county ON county.geoid = substr('00000' || COUNTY, -5, 5);

-- add counties
INSERT INTO cps_geography
SELECT
    county.geoid,
    METFIPS,
    STATEFIP,
    COUNTY,
    0 AS INDIVIDCC,
    ST_MULTI (COALESCE(ST_DIFFERENCE (county.GEOMETRY, ST_UNION (city.GEOMETRY)), county.GEOMETRY)) AS GEOMETRY
FROM
    unique_geographies
    INNER JOIN cb_2018_us_county_20m AS county ON county.geoid = substr('00000' || COUNTY, -5, 5)
    LEFT JOIN cps_geography AS city USING (METFIPS, STATEFIP, COUNTY, INDIVIDCC)
GROUP BY
    county.geoid;

-- add MSAs
INSERT INTO cps_geography
SELECT
    state.geoid || metro.geoid AS geoid,
    METFIPS,
    STATEFIP,
    0 AS COUNTY,
    0 AS INDIVIDCC,
    ST_Multi (ST_CollectionExtract (ST_INTERSECTION (state.GEOMETRY, COALESCE(ST_DIFFERENCE (metro.GEOMETRY, ST_UNION (subregion.GEOMETRY)), metro.GEOMETRY)), 3)) AS GEOMETRY
FROM
    unique_geographies AS ug
    INNER JOIN cb_2018_us_cbsa_20m AS metro ON metro.geoid = METFIPS
    INNER JOIN cb_2018_us_state_20m AS state ON state.geoid = substr('00' || STATEFIP, -2, 2)
    LEFT JOIN cps_geography AS subregion USING (METFIPS, STATEFIP, COUNTY, INDIVIDCC)
GROUP BY
    METFIPS,
    STATEFIP;

-- add states
INSERT INTO cps_geography
SELECT
    state.geoid,
    '99998' AS METFIPS,
    STATEFIP,
    0 AS COUNTY,
    0 AS INDIVIDCC,
    COALESCE(ST_MULTI (ST_DIFFERENCE (state.GEOMETRY, ST_UNION (subregion.GEOMETRY))), state.GEOMETRY) AS GEOMETRY
FROM
    unique_geographies
    INNER JOIN cb_2018_us_state_20m AS state ON state.geoid = substr('00' || STATEFIP, -2, 2)
    LEFT JOIN cps_geography AS subregion USING (METFIPS, STATEFIP, COUNTY, INDIVIDCC)
GROUP BY
    STATEFIP;

COMMIT;
