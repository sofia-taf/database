#!/bin/bash

######################################################################
#  Name - mysqlExportCaptureFile.sh
#  Desc- runs a sql script to specified db
#  Param - l = login for mysql db default = mysql
#        - u = user default = mysql
#        - s = schema default = sofiatsaf 
#        - d = directory for file export (C://temp) 
#        - f = filename for file export (CL_FI_WATERAREA_GROUPS)
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
  sqlDir="C:/tmp"
  sqlFile="area_stocks_monitoring_byFAO.csv"
  area="37"
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

TRUNCATE TABLE area_stock;

insert into area_stock(area_id, stock_id, isscaap, tier, stock_update_id)
select ar.id, st.id, st.isscaap, 2, su.id
from capture cap
join area ar on cap.area_id = ar.id
join stock st on cap.stock_id = st.id
join stock_update su on st.id = su.stock_id and su.fao_area_code = ar.ar_code
group by ar.id, su.id, st.isscaap, su.id;

 DROP TABLE IF EXISTS tmp_area_stocks;
 
 CREATE TEMPORARY TABLE tmp_area_stocks(
 id int(11) unsigned NOT NULL AUTO_INCREMENT,
  temp_area VARCHAR(45) DEFAULT NULL,
  temp_species VARCHAR(200) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=295 DEFAULT CHARSET=utf8mb4;
LOAD DATA 
  LOCAL INFILE '"${filedir}"'
  INTO TABLE tmp_area_stocks
       FIELDS TERMINATED BY '${terminated}' ENCLOSED BY '${enclosed}' LINES TERMINATED BY '\n'
       IGNORE 1 LINES
       (@temp_area,@temp_species)
       SET temp_area = @temp_area, temp_species = @temp_species;

UPDATE area_stock as a
join area ar on a.area_id = ar.id
join stock st on st.id = a.stock_id
join tafp.tmp_area_stocks tas on tas.temp_area = ar.ar_code and tas.temp_species = st.scientific_name
set a.monitoring = true;

SET GLOBAL local_infile=OFF;
COMMIT;
"
charset=utf8mb4

executeCmds="mysql --login-path=${loginval} --local-infile=1 --default-character-set=${charset} \
             --skip-reconnect --unbuffered -v ${schema} -e "
log "Commands to execute: "${executeCmds}
log $(${executeCmds} "${sqlCmds}")

exit ${exitErr}
    