SELECT STATEFIP,
       COUNTY,
       COUNT(*) FILTER (
                        WHERE EARNWT > 0.0) AS observations,
       SUM(EARNWT/120) AS employment,
       COALESCE(SUM(EARNWT/120) FILTER (
                                        WHERE "UNION" = 2), 0) AS members,
       COALESCE(SUM(EARNWT/120) FILTER (
                                        WHERE "UNION" > 1), 0) AS covered
FROM cps
WHERE ELIGORG = 1
AND YEAR  >= 2010 AND YEAR <= 2020
GROUP BY STATEFIP,
         COUNTY;
