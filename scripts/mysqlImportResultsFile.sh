#!/bin/bash

######################################################################
#  Name - mysqlExportCaptureFile.sh
#  Desc- runs a sql script to specified db
#  Param - l = login for mysql db default = mysql
#        - u = user default = mysql
#        - s = schema default = sofiatsaf 
#        - d = directory for file export (C://tmp) 
#        - f = filename for file export (fao_current_results.csv)
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
  sqlFile="fao_current_results.csv"
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
DROP TABLE IF EXISTS tmp_results;

CREATE TEMPORARY TABLE tmp_results(
  id int(11) unsigned NOT NULL AUTO_INCREMENT,
  cap_stock VARCHAR(200) DEFAULT NULL,
  cap_area VARCHAR(20) DEFAULT NULL,
  tier INT DEFAULT NULL,
  cap_year INT DEFAULT NULL,
  cap_group VARCHAR(200) DEFAULT NULL,
  bbmsy_value DOUBLE DEFAULT NULL,
  ffmsy_value DOUBLE DEFAULT NULL,
  cert_value DOUBLE DEFAULT NULL,
  status VARCHAR(20) DEFAULT NULL,
  reference INT DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=295 DEFAULT CHARSET=utf8mb4;
LOAD DATA 
  LOCAL INFILE '"${filedir}"'
  INTO TABLE tmp_results
       FIELDS TERMINATED BY '${terminated}' ENCLOSED BY '${enclosed}' LINES TERMINATED BY '\n'
       IGNORE 1 LINES
       (@area,@tier,@group,@species,@status,@ffmsy,@bbmsy,@uncert,@year,@reference)
       SET cap_area=@area,tier=@tier,cap_group=@group,cap_stock=@species,status=@status,ffmsy_value=@ffmsy,bbmsy_value=@bbmsy,cert_value=@uncert,cap_year=@year,reference=@reference;
UPDATE tmp_results set cap_area = CONCAT('0',cap_area) where length(cap_area)=1;
SELECT distinct cap_area from tmp_results;

SELECT tc.cap_stock FROM tmp_results tc
LEFT JOIN fao_group fg on tc.cap_group = fg.grp_name
LEFT JOIN (select stid.id as stock_id, stid.isscaap, case when stup.fao_scientific_name is not null then stup.fao_scientific_name else stid.scientific_name end as scientific_name, stup.id as stock_update_id
from stock stid
left join stock_update stup on stid.id = stup.stock_id
UNION ALL 
select st.id as stock_id, st.isscaap, st.scientific_name, NULL as stock_update_id
from stock st
join stock_update stup on st.id = stup.stock_id and st.scientific_name <> fao_scientific_name
group by st.id, st.scientific_name) as st on replace(replace(tc.cap_stock, ',', ''), '.', '') = replace(replace(st.scientific_name, ',', ''), '.', '') 
and fg.id = st.isscaap
where st.stock_id is null;


INSERT INTO output_timeseries
(area_id,
current_year,
reference_id,
stock_group,
bbmsy,
ffmsy,
result_flag,
status,
tier,
uncertainty,
stock_id,
stock_update_id)
SELECT ar.id, tc.cap_year, tc.reference, st.isscaap,tc.bbmsy_value, tc.ffmsy_value, 'current', tc.status, tc.tier, tc.cert_value, st.stock_id,st.stock_update_id
FROM tmp_results tc
LEFT JOIN area ar on tc.cap_area = ar.ar_code
LEFT JOIN fao_group fg on tc.cap_group = fg.grp_name
LEFT JOIN (select stid.id as stock_id, stid.isscaap, case when stup.fao_scientific_name is not null then stup.fao_scientific_name else stid.scientific_name end as scientific_name, stup.id as stock_update_id
from stock stid
left join stock_update stup on stid.id = stup.stock_id
UNION ALL 
select st.id as stock_id, st.isscaap, st.scientific_name, NULL as stock_update_id
from stock st
join stock_update stup on st.id = stup.stock_id and st.scientific_name <> fao_scientific_name
group by st.id, st.isscaap, st.scientific_name) as st on replace(replace(tc.cap_stock, ',', ''), '.', '') = replace(replace(st.scientific_name, ',', ''), '.', '') and fg.id = st.isscaap;

SET GLOBAL local_infile=OFF;
COMMIT;
"
charset=utf8mb4

executeCmds="mysql --login-path=${loginval} --local-infile=1 --default-character-set=${charset} \
             --skip-reconnect --unbuffered -v ${schema} -e "
log "Commands to execute: "${executeCmds}
log $(${executeCmds} "${sqlCmds}")

exit ${exitErr}
    