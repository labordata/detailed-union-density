SELECT metro.geoid,
       metro.name,
       COUNT(*) FILTER (
                        WHERE EARNWT > 0.0) AS observations,
       SUM(EARNWT/120) AS employment,
       COALESCE(SUM(EARNWT/120) FILTER (
                                        WHERE "UNION" = 2), 0) AS members,
       COALESCE(SUM(EARNWT/120) FILTER (
                                        WHERE "UNION" > 1), 0) AS covered,
       GEOMETRY
FROM cps
INNER JOIN cb_2018_us_cbsa_20m AS metro ON metro.geoid = METFIPS
WHERE ELIGORG = 1
AND YEAR  >= 2016 AND YEAR <= 2020
GROUP BY METFIPS;
