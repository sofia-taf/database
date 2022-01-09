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
  sqlFile="ASFIS_sp_2021.txt"
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

LOAD DATA 
  LOCAL INFILE '"${filedir}"'
  IGNORE INTO TABLE stock
       FIELDS TERMINATED BY '${terminated}' ENCLOSED BY '${enclosed}' LINES TERMINATED BY '\n'
       IGNORE 1 LINES
       (ISSCAAP, @txocode, 3A_CODE, Scientific_name, English_name, 
       @french_name, @spanish_name, @arabic_name,
       @chinese_name, @russian_name, @author, Family, @order, @stat)
       SET isscaap = ISSCAAP, 3a_code = 3A_CODE, scientific_name = Scientific_name, 
       english_name = English_name, family = Family, reference_id = 446;
SET GLOBAL local_infile=OFF;
COMMIT;
"
charset=utf8mb4

executeCmds="mysql --login-path=${loginval} --local-infile=1 --default-character-set=${charset} \
             --skip-reconnect --unbuffered -v ${schema} -e "
log "Commands to execute: "${executeCmds}
log $(${executeCmds} "${sqlCmds}")

exit ${exitErr}
    