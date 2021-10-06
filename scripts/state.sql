SELECT STATECENSUS,
       State,
       YEAR,
       COUNT(*) FILTER (
                        WHERE EARNWT > 0.0) AS observations,
       SUM(EARNWT/12) AS employment,
       SUM(EARNWT/12) FILTER (
                              WHERE "UNION" = 2) AS members,
       SUM(EARNWT/12) FILTER (
                              WHERE "UNION" > 1) AS covered
FROM cps
INNER JOIN state_codes ON STATECENSUS = state_codes.Code
WHERE ELIGORG = 1
GROUP BY STATECENSUS,
         YEAR;
