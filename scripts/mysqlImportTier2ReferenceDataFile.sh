#!/bin/bash

######################################################################
#  Name - mysqlImportAreaFile.sh
#  Desc- runs a sql script to specified db
#  Param - l = login for mysql db default = mysql
#        - u = user default = mysql
#        - s = schema default = sofiatsaf 
#        - d = directory for file export (C://temp) 
#        - f = filename for file export (CAPTURE_QUANTITY)
#        - a = area
#####################################################################
LOGFILE="C://tmp/logs$(date +'%y%m%d%H%MS').txt"
# log message
log(){
	local m="$@"
	printf "" 1>>"${LOGFILE}"
	printf  "*** ${m} ***" 1>>"${LOGFILE}"
	printf "" 1>>"${LOGFILE}"
}
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>${LOGFILE} 2>&1
exitErr(){
	local m="$@"
  printf "%b/n" "*** ${m} ***" >&2
}

function validateInput {
# set defaults
  loginval="mysql_rw"
  user="mysql"
  schema="tafp"
  sqlDir="C://Users/Nicole/Desktop/fish/rishi raw data/area 31/Data_files_Area_31_3"
  sqlFile="Yellowtail_snapper_Venezuela.csv"
  area="31"
  terminated=','
  enclosed='"'
  
  
  PARIN=1
  while getopts ":l:s:u:d:f:a:" opt
  do 
    case "${opt}" in
      l)
        loginval="$OPTARG"
        ;;
      s)
        schema="$OPTARG"
        ;;
      u)
        user="$OPTARG"
        ;;
      d)
        sqlDir="$OPTARG"
        ;;
      f)  
        sqlFile="$OPTARG"
        ;;
      a)  
        area="$OPTARG"
        ;;
      :)
        returnMsg= "mysqlExecute Requires: -- $OPTARG"
        usage
        exitErr 2
        ;;
      *)
        if ["$OPTARG"="?"]
        then 
          usage
          exitErr 1
        else
          returnMsg= "mysqlExecute Invalid param: -- $OPTARG"
          usage
          exitErr 2
        fi
        ;;
    esac
  done
  echo ${returnMsg}
}


# main
validateInput
filedir="${sqlDir}/${sqlFile}"

log "$(date) @ $(hostname)"
log "output saved here"${filedir}

sqlCmds="USE ${schema};
SELECT CONCAT(CURRENT_USER(), ' connected to ', @@hostname, ' with schema ', 
COALESCE(CONCAT('set to ', SCHEMA()), 'not set')) as 'Connection Info';
SET @@sql_log_off = 1;
SET @@autocommit = 1;
SET GLOBAL local_infile=ON;
SET @area = '31';
SET @measure = 'total landings';
DROP TABLE IF EXISTS tmp_capture;

CREATE TABLE tmp_capture(
  id int(11) unsigned NOT NULL AUTO_INCREMENT,
  cap_stock VARCHAR(200) DEFAULT NULL,
  cap_common VARCHAR(200) DEFAULT NULL,
  cap_year INT DEFAULT NULL,
  catch DOUBLE DEFAULT NULL,
  best_index DOUBLE DEFAULT NULL,
  best_effort DOUBLE DEFAULT NULL,
  cap_measure VARCHAR(45) DEFAULT NULL,
  stocklong VARCHAR(200) DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=295 DEFAULT CHARSET=utf8mb4;
LOAD DATA 
  LOCAL INFILE '"${filedir}"'
  INTO TABLE tmp_capture
       FIELDS TERMINATED BY '${terminated}' ENCLOSED BY '${enclosed}' LINES TERMINATED BY '\n'
       IGNORE 1 LINES
       (@stockid,@scientificname,@commonname,@year,@catch,@stocklong)
       SET cap_stock = @scientificname,cap_common=@commonname, cap_year = @year, catch = @catch,
       stocklong = @stocklong;

SELECT distinct tc.cap_common, tc.cap_species
FROM tmp_tier1data tc
LEFT JOIN ((select distinct stock_id, st_code, stock_update_id
from (
select stock_id, fao_scientific_name as st_code, id as stock_update_id
from stock_update 
UNION ALL 
select id as stock_id, scientific_name as st_code, NULL as stock_update_id
from stock) as p)) as st on tc.cap_species = st.st_code
where st.stock_id is null;

INSERT INTO location(english_name, location_name, location_code, area_id)
SELECT tc.cap_common,tc.location,concat('Area31_',replace(tc.cap_common,' ','_'),'_',replace(tc.location,' ','_')),305
FROM tmp_tier1data tc
left join location loc on tc.cap_common = loc.english_name and tc.location = loc.location_name
where loc.location_id is null;

INSERT INTO output_timeseries(area_id, location_id, stock_id, stock_update_id, current_year, status, reference_id)
SELECT ar.id, loc.location_id, st.stock_id,st.stock_update_id, tc.cap_year, tc.status,  454
 FROM tmp_tier1data tc
 JOIN location loc on tc.location= loc.location_name and tc.cap_common = loc.english_name
 LEFT JOIN area ar on ar.ar_code =31
 LEFT JOIN ((select distinct stock_id, st_code, stock_update_id
from (
select stock_id, fao_scientific_name as st_code, id as stock_update_id
from stock_update 
UNION ALL 
select id as stock_id, scientific_name as st_code, NULL as stock_update_id
from stock) as p)) as st on tc.cap_species = st.st_code;
 
SET GLOBAL local_infile=OFF;
COMMIT;
"
  charset=utf8mb4

  executeCmds="mysql --login-path=${loginval} --local-infile=1 --default-character-set=${charset} \
               --skip-reconnect --unbuffered -v -v -v ${schema} -e "
  log "Commands to execute: "${executeCmds}
  log $(${executeCmds} "${sqlCmds}")

exit ${exitErr}
    