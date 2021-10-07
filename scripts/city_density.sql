SELECT COALESCE(city.city_fips, rc.GEOID) AS geoid,
       COALESCE(city.city, rc.name) as name,
       STATEFIP,
       COUNT(*) FILTER (
                        WHERE EARNWT > 0.0) AS observations,
       SUM(EARNWT/120) AS employment,
       COALESCE(SUM(EARNWT/120) FILTER (
                                        WHERE "UNION" = 2), 0) AS members,
       COALESCE(SUM(EARNWT/120) FILTER (
                                        WHERE "UNION" > 1), 0) AS covered,
       COALESCE(city.GEOMETRY, rc.GEOMETRY) AS GEOMETRY
FROM cps
INNER JOIN city_map USING (METFIPS, STATEFIP, COUNTY, INDIVIDCC)
LEFT JOIN us_principal_cities AS city USING (city_fips)
LEFT JOIN remaining_cities AS rc ON city_map.city_fips = rc.GEOID
WHERE
    ELIGORG = 1
    AND (city.GEOMETRY IS NOT NULL OR rc.GEOMETRY IS NOT NULL)
    AND YEAR  >= 2016 AND YEAR <= 2020
GROUP BY COALESCE(city.city_fips, rc.GEOID);
