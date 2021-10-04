omnibus.geojson : cps.db
	ogr2ogr -f GeoJSON $@ $< -sql @scripts/omnibus.sql -dialect sqlite

cps.db : cps.csv cb_2018_us_county_20m.shp cb_2018_us_cbsa_20m.shp cb_2018_us_necta_500k.shp cb_2018_us_state_20m.shp
	ogr2ogr -f SQLite -dsco SPATIALITE=YES $@ $(word 2,$^) -nlt PROMOTE_TO_MULTI
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -append $@ $(word 3,$^) -nlt PROMOTE_TO_MULTI
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -append $@ $(word 4,$^) -nlt PROMOTE_TO_MULTI
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -append $@ $(word 5,$^) -nlt PROMOTE_TO_MULTI
	csvs-to-sqlite $< $@

cps.csv : cps_00006.csv.gz
	gunzip -c $< > $@

cb_%.shp : cb_%.zip
	unzip $<

cb_%.zip :
	wget -O $@ "https://www2.census.gov/geo/tiger/GENZ2018/shp/$@"


