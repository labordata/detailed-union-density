WITH counties AS (
    SELECT
        geoid,
        substr('00' || STATEFIP, -2, 2) AS state_geoid,
        GEOMETRY,
        COUNT(*) FILTER (WHERE EARNWT > 0.0) AS observations,
        SUM(EARNWT) / 60 AS employment,
        COALESCE(SUM(EARNWT / 60) FILTER (WHERE "UNION" = 2), 0) AS members,
        COALESCE(SUM(EARNWT / 60) FILTER (WHERE "UNION" > 1), 0) AS covered
    FROM
        cps
        INNER JOIN cb_2018_us_county_20m ON geoid = substr('00000' || COUNTY, -5, 5)
    WHERE
        ELIGORG = 1
        AND YEAR >= 2016
        AND YEAR <= 2020
    GROUP BY
        STATEFIP,
        COUNTY
),
remaining_metro AS (
    SELECT
        metro.geoid AS geoid,
        CASE WHEN ST_UNION (counties.GEOMETRY) IS NOT NULL THEN
            ST_DIFFERENCE (metro.GEOMETRY, ST_UNION (counties.GEOMETRY))
        ELSE
            metro.GEOMETRY
        END AS GEOMETRY
    FROM
        cb_2018_us_cbsa_20m AS metro
        LEFT JOIN counties ON St_Contains (metro.GEOMETRY, counties.GEOMETRY)
    GROUP BY
        metro.geoid,
        metro.GEOMETRY
),
metros AS (
    SELECT
        remaining_metro.geoid,
        state.geoid,
        ST_CollectionExtract (ST_INTERSECTION (remaining_metro.GEOMETRY, state.GEOMETRY), 3) AS GEOMETRY,
    COUNT(*) FILTER (WHERE EARNWT > 0.0) AS observations,
    SUM(EARNWT) / 60 AS employment,
    COALESCE(SUM(EARNWT / 60) FILTER (WHERE "UNION" = 2), 0) AS members,
    COALESCE(SUM(EARNWT / 60) FILTER (WHERE "UNION" > 1), 0) AS covered
FROM
    cps
    INNER JOIN remaining_metro ON remaining_metro.geoid = METFIPS
    INNER JOIN cb_2018_us_state_20m AS state ON state.geoid = substr('00' || STATEFIP, -2, 2)
    WHERE
        ELIGORG = 1
        AND YEAR >= 2016
        AND YEAR <= 2020
        AND COUNTY = 0
    GROUP BY
        METFIPS,
        STATEFIP
),
subregion AS (
    SELECT
        *
    FROM
        metros
    UNION
    SELECT
        *
    FROM
        counties
),
remaining_state AS (
    SELECT
        state.geoid AS geoid,
        CASE WHEN ST_UNION (subregion.GEOMETRY) IS NOT NULL THEN
            ST_DIFFERENCE (state.GEOMETRY, ST_UNION (subregion.GEOMETRY))
        ELSE
            state.GEOMETRY
        END AS GEOMETRY
    FROM
        cb_2018_us_state_20m AS state
        LEFT JOIN subregion ON St_Contains (state.GEOMETRY, subregion.GEOMETRY)
    GROUP BY
        state.geoid,
        state.GEOMETRY
),
states AS (
    SELECT
        remaining_state.geoid,
        remaining_state.geoid,
        GEOMETRY,
        COUNT(*) FILTER (WHERE EARNWT > 0.0) AS observations,
        SUM(EARNWT) / 60 AS employment,
        COALESCE(SUM(EARNWT / 60) FILTER (WHERE "UNION" = 2), 0) AS members,
    COALESCE(SUM(EARNWT / 60) FILTER (WHERE "UNION" > 1), 0) AS covered
FROM
    cps
    INNER JOIN remaining_state ON remaining_state.geoid = substr('00' || STATEFIP, -2, 2)
    WHERE
        ELIGORG = 1
        AND YEAR >= 2016
        AND YEAR <= 2020
        AND COUNTY = 0
        AND METFIPS = '99998'
    GROUP BY
        STATEFIP
)
SELECT
    *
FROM
    subregion
UNION
SELECT
    *
FROM
    states
