#!/bin/bash

######################################################################
#  Name - mysqlExportCaptureFile.sh
#  Desc- runs a sql script to specified db
#  Param - l = login for mysql db default = mysql
#        - u = user default = mysql
#        - s = schema default = sofiatsaf 
#        - d = directory for file export (C://temp) 
#        - f = filename for file export (CAPTURE_QUANTITY)
#        - a = area
#        - m = monitored data by status and trends (1, 0)
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
  sqlFile="CAPTURE_QUANTITY.csv"
  area="37"
  monitoring="1"
  terminated=','
  enclosed='"'
  
  
  PARIN=1
  while getopts ":l:s:u:d:f:c:" opt
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
      m)  
        monitored="$OPTARG"
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
DROP TABLE IF EXISTS tmp_capture;

CREATE TEMPORARY TABLE tmp_capture(
  id int(11) unsigned NOT NULL AUTO_INCREMENT,
  cap_stock VARCHAR(200) DEFAULT NULL,
  cap_area VARCHAR(200) DEFAULT NULL,
  cap_year INT DEFAULT NULL,
  cap_value DOUBLE DEFAULT NULL,
  cap_measure VARCHAR(45) DEFAULT NULL,
  cap_qualifier VARCHAR(45) DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=295 DEFAULT CHARSET=utf8mb4;
LOAD DATA 
  LOCAL INFILE '"${filedir}"'
  INTO TABLE tmp_capture
       FIELDS TERMINATED BY '${terminated}' ENCLOSED BY '${enclosed}' LINES TERMINATED BY '\n'
       IGNORE 1 LINES
       (@UN_CODE,@ALPHA_3_CODE,@AREACODE,@MEASURE,@PERIOD,@VALUE,@STATUS)
       SET cap_stock = @ALPHA_3_CODE, cap_area = @AREACODE, cap_year = @PERIOD,
       cap_value = @VALUE, cap_measure = @MEASURE, cap_qualifier = @STATUS;
UPDATE tmp_capture set cap_area = CONCAT('0',cap_area) where length(cap_area)=1;
SELECT distinct cap_area from tmp_capture;

SELECT distinct tc.cap_stock
FROM tmp_capture tc
LEFT JOIN area ar on tc.cap_area = ar.ar_code
LEFT JOIN ((select distinct stock_id, st_code, stock_update_id
from (
select stock_id, fao_3code as st_code, id as stock_update_id
from stock_update 
UNION ALL 
select id as stock_id, st_code, NULL as stock_update_id
from stock) as p)) as st on tc.cap_stock = st.st_code
where st.stock_id is null;

INSERT INTO capture(area_id, stock_id, stock_update_id, year, biomass, unit, qualifier, reference_id)
SELECT ar.id, st.stock_id,st.stock_update_id, tc.cap_year, tc.cap_value, tc.cap_measure, tc.cap_qualifier, 445
FROM tmp_capture tc
LEFT JOIN area ar on tc.cap_area = ar.ar_code
LEFT JOIN (select stid.id as stock_id, case when stup.fao_3code is not null then stup.fao_3code else stid.st_code end as st_code, stup.id as stock_update_id
from stock stid
left join stock_update stup on stid.id = stup.stock_id
UNION ALL 
select st.id as stock_id, st.st_code, NULL as stock_update_id
from stock st
join stock_update stup on st.id = stup.stock_id and st.st_code <> fao_3code
group by st.id, st.st_code) as st on tc.cap_stock = st.st_code;

SET GLOBAL local_infile=OFF;
COMMIT;
"
charset=utf8mb4

executeCmds="mysql --login-path=${loginval} --local-infile=1 --default-character-set=${charset} \
             --skip-reconnect --unbuffered -v ${schema} -e "
log "Commands to execute: "${executeCmds}
log $(${executeCmds} "${sqlCmds}")

exit ${exitErr}
    