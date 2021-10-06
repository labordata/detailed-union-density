SELECT geoid,
        GEOMETRY,
        COUNT(*) FILTER (WHERE EARNWT > 0.0) AS observations,
        SUM(EARNWT) / 60 AS employment,
        COALESCE(SUM(EARNWT / 60) FILTER (WHERE "UNION" = 2), 0) AS members,
        COALESCE(SUM(EARNWT / 60) FILTER (WHERE "UNION" > 1), 0) AS covered
from cps
inner join cps_geography
USING (METFIPS, STATEFIP, COUNTY, INDIVIDCC)
   WHERE
        ELIGORG = 1
        AND YEAR >= 2016
        AND YEAR <= 2020
GROUP BY METFIPS, STATEFIP, COUNTY, INDIVIDCC;
