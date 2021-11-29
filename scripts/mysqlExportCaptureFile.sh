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
  sqlFile="extract_$(date +'%y%m%d%H%MS').csv"
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
filedir="'${sqlDir}/${sqlFile}'"

log "$(date) @ $(hostname)"
log "output saved here"${filedir}

sqlCmds="USE ${schema};
SELECT CONCAT(CURRENT_USER(), ' connected to ', @@hostname, ' with schema ', 
COALESCE(CONCAT('set to ', SCHEMA()), 'not set')) as 'Connection Info';
SELECT 'area', 'year', 'stock', 'capture'
UNION ALL
SELECT ar_code, c.year, scientific_name as stock, biomass as capture
FROM capture c
join area_stock arst on c.stock_id = arst.stock_id and c.area_id = arst.area_id
left join stock st on c.stock_id = st.id
left join area ar on c.area_id = ar.id
left join stock_update stup on stup.id = c.stock_update_id 
where ar.ar_code=${area} AND arst.monitoring=${monitoring} 
INTO OUTFILE "${filedir}" FIELDS TERMINATED BY '${terminated}' ENCLOSED BY '${enclosed}' LINES TERMINATED BY '\n';"
charset=utf8mb4

executeCmds="mysql --login-path=${loginval} --default-character-set=${charset} \
             --skip-reconnect --unbuffered -v ${schema} -e "
log "Commands to execute: "${executeCmds}
log $(${executeCmds} "${sqlCmds}")

exit ${exitErr}
    