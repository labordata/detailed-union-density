
counties.csv : cps.db
	sqlite3 -header -csv $< < scripts/county_density.sql > $@

cps.db : cps.csv 
	csvs-to-sqlite $^ $@ 

cps.csv : cps_00005.csv.gz
	gunzip -c $< > $@



