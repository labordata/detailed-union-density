SELECT county.geoid,
       county.name,
       STATEFIP,
       COUNT(*) FILTER (
                        WHERE EARNWT > 0.0) AS observations,
       SUM(EARNWT/120) AS employment,
       COALESCE(SUM(EARNWT/120) FILTER (
                                        WHERE "UNION" = 2), 0) AS members,
       COALESCE(SUM(EARNWT/120) FILTER (
                                        WHERE "UNION" > 1), 0) AS covered,
       GEOMETRY
FROM cps
INNER JOIN cb_2018_us_county_20m AS county ON county.geoid = substr('00000' || COUNTY, -5, 5)
WHERE ELIGORG = 1
AND YEAR  >= 2016 AND YEAR <= 2020
GROUP BY COUNTY;
