.PHONY: all
all : cps_geography.geojson union_density.geojson county_density.geojson \
      metro_density.geojson city_density.geojson county_density.csv \
      metro_density.csv city_density.csv

%.csv : %.geojson
	ogr2ogr -f csv $@ $<

%_density.geojson : cps.db
	ogr2ogr -f GeoJSON $@ $< -sql @scripts/$*_density.sql -dialect sqlite	

cps_geography.geojson : cps.db
	ogr2ogr -f GeoJSON $@ $< -sql 'select * from cps_geography' -dialect sqlite

union_density.geojson : cps.db
	ogr2ogr -f GeoJSON $@ $< -sql @scripts/omnibus.sql -dialect sqlite

cps.db : cb_2018_us_county_20m.shp cb_2018_us_cbsa_20m.shp cb_2018_us_state_20m.shp us_principal_cities.shp remaining_cities.geojson cps.csv city_map.csv
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -t_srs "EPSG:4326" $@ $(word 1,$^) -nlt PROMOTE_TO_MULTI
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -append -t_srs "EPSG:4326" $@ $(word 2,$^) -nlt PROMOTE_TO_MULTI
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -append -t_srs "EPSG:4326" $@ $(word 3,$^) -nlt PROMOTE_TO_MULTI
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -append -t_srs "EPSG:4326" $@ $(word 4,$^) -nlt PROMOTE_TO_MULTI
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -append -t_srs "EPSG:4326" $@ $(word 5,$^) -nlt PROMOTE_TO_MULTI
	csvs-to-sqlite $(filter %.csv,$^) $@
	spatialite $@ < scripts/cps_geography.sql

cps.csv : cps_00006.csv.gz
	gunzip -c $< > $@

remaining_cities.geojson :
	wget -O $@ "https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/tigerWMS_ACS2018/MapServer/26/query?where=%28NAME+like+%27Pomona%25%27+and+STATE%3D%2706%27%29+OR+%28NAME+like+%27Fremont%25%27+and+STATE%3D%2706%27%29+OR+%28NAME+like+%27Fullerton%25%27+and+STATE%3D%2706%27%29+OR+%28NAME+like+%27Joliet%25%27+and+STATE%3D%2717%27%29+OR+%28NAME+like+%27Glendale%25%27+AND+STATE%3D%2704%27%29+OR+%28NAME+like+%27Carrollton%25%27+and+STATE%3D%2748%27%29&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot&relationParam=&outFields=*&returnGeometry=true&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&outSR=&havingClause=&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&gdbVersion=&historicMoment=&returnDistinctValues=false&resultOffset=&resultRecordCount=&returnExtentOnly=false&datumTransformation=&parameterValues=&rangeValues=&quantizationParameters=&featureEncoding=esriDefault&f=geojson"

%.shp : %.zip
	unzip $<
	touch $@

cb_%.zip :
	wget -O $@ "https://www2.census.gov/geo/tiger/GENZ2018/shp/$@"

us_principal_cities.zip :
	wget -O $@ "https://github.com/andrewvanleuven/website/raw/master/static/files/data/shp/us_principal_cities.zip"
