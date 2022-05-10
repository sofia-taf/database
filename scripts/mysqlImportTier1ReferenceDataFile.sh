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
  sqlDir="C://Users/Nicole/Desktop/fish/rishi raw data/area 31"
  sqlFile="area31_tier1.csv"
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
csvfile="C://tmp/tier1referencedata.csv"

log "$(date) @ $(hostname)"
log "output saved here"${LOGFILE}
{
 read
    while IFS=, read -r field1 field2 field3 field4 field5 field6 field7
    do 
    	if [[ $field1 = ISSCAAP* ]]
      then
        ISSCAAP=$(echo $field1 | grep -o '[0-9:]*')
      else
        if [ ! -z "$field1" ]
        then
          common=${field1%(*}
          speciesplus=${field1#*\(}
          species=${speciesplus%)*}
        fi
        echo "$ISSCAAP","$common","$species","$field2","$field3","$field4","$field5","$field6","$field7" >> ${csvfile}
        
        
      fi
    done
} < "$filedir"

sqlCmds="USE ${schema};
SELECT CONCAT(CURRENT_USER(), ' connected to ', @@hostname, ' with schema ', 
COALESCE(CONCAT('set to ', SCHEMA()), 'not set')) as 'Connection Info';
SET @@sql_log_off = 1;
SET @@autocommit = 1;
SET GLOBAL local_infile=ON;
SET @area = '31';
SET @measure = 'total landings';
DROP TABLE IF EXISTS tmp_tier1data;

CREATE TABLE tmp_tier1data(
  id int(11) unsigned NOT NULL AUTO_INCREMENT,
  isscaap VARCHAR(200) DEFAULT NULL,
  cap_species VARCHAR(200) DEFAULT NULL,
  cap_common VARCHAR(200) DEFAULT NULL,
  location VARCHAR(200) DEFAULT NULL,
  location_code VARCHAR(200) DEFAULT NULL,
  status VARCHAR(200) DEFAULT NULL,
  assessed int DEFAULT NULL,
  reference_id int DEFAULT NULL,
  cap_year INT DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=295 DEFAULT CHARSET=utf8mb4;
LOAD DATA 
  LOCAL INFILE '"${csvfile}"'
  INTO TABLE tmp_tier1data
       FIELDS TERMINATED BY '${terminated}' ENCLOSED BY '${enclosed}' LINES TERMINATED BY '\n'
       (@isscaap,@cap_common,@cap_species,@location,@location_id,@status,@assessed,@reference_id,@cap_year)
       SET isscaap = @isscaap, cap_common=@cap_common, cap_species = @cap_species, location = @location, location_code = @location_id,
       status = @status, assessed = @assessed, reference_id = @reference_id, cap_year = @cap_year;

SELECT distinct tc.cap_stock
FROM tmp_tier1data tc
LEFT JOIN ((select distinct stock_id, st_code, stock_update_id
from (
select stock_id, fao_scientific_name as st_code, id as stock_update_id
from stock_update 
UNION ALL 
select id as stock_id, scientific_name as st_code, NULL as stock_update_id
from stock) as p)) as st on tc.cap_species = st.st_code
where st.stock_id is null;


 
SET GLOBAL local_infile=OFF;
COMMIT;
"
  charset=utf8mb4

  executeCmds="mysql --login-path=${loginval} --local-infile=1 --default-character-set=${charset} \
               --skip-reconnect --unbuffered -v -v -v ${schema} -e "
  log "Commands to execute: "${executeCmds}
  log $(${executeCmds} "${sqlCmds}")

exit ${exitErr}
    