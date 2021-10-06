.PHONY: all
all : cps_geography.geojson union_density.geojson

cps_geography.geojson : cps.db
	ogr2ogr -f GeoJSON $@ $< -sql 'select * from cps_geography' -dialect sqlite

union_density.geojson : cps.db
	ogr2ogr -f GeoJSON $@ $< -sql @scripts/omnibus.sql -dialect sqlite

cps.db : cb_2018_us_county_20m.shp cb_2018_us_cbsa_20m.shp cb_2018_us_state_20m.shp us_principal_cities.shp cps.csv city_map.csv 
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -t_srs "EPSG:4326" $@ $(word 1,$^) -nlt PROMOTE_TO_MULTI
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -append -t_srs "EPSG:4326" $@ $(word 2,$^) -nlt PROMOTE_TO_MULTI
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -append -t_srs "EPSG:4326" $@ $(word 3,$^) -nlt PROMOTE_TO_MULTI
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -append -t_srs "EPSG:4326" $@ $(word 4,$^) -nlt PROMOTE_TO_MULTI
	csvs-to-sqlite $(filter-out %.shp,$^) $@
	spatialite $@ < scripts/cps_geography.sql


cps.csv : cps_00006.csv.gz
	gunzip -c $< > $@

%.shp : %.zip
	unzip $<
	touch $@

cb_%.zip :
	wget -O $@ "https://www2.census.gov/geo/tiger/GENZ2018/shp/$@"

us_principal_cities.zip :
	wget -O $@ "https://github.com/andrewvanleuven/website/raw/master/static/files/data/shp/us_principal_cities.zip"
