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
  schema="sofia_taf"
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
  reference_group_id int DEFAULT NULL,
  cap_year INT DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=295 DEFAULT CHARSET=utf8mb4;
LOAD DATA 
  LOCAL INFILE '"${csvfile}"'
  INTO TABLE tmp_tier1data
       FIELDS TERMINATED BY '${terminated}' ENCLOSED BY '${enclosed}' LINES TERMINATED BY '\n'
       (@isscaap,@cap_common,@cap_species,@location,@location_id,@status,@assessed,@reference_id,@cap_year)
       SET isscaap = @isscaap, cap_common=@cap_common, cap_species = @cap_species, location = @location, location_code = @location_id,
       status = @status, assessed = @assessed, reference_group_id = @reference_group_id, cap_year = @cap_year;

SELECT distinct tc.cap_species
FROM tmp_tier1data tc
LEFT JOIN ((select distinct species_id, st_code, english_name, species_update_id
from (
select species_id, fao_scientific_name as st_code, fao_common_name as english_name, id as species_update_id
from asfis_fao_species
UNION ALL 
select id as species_id, scientific_name as st_code,english_name, NULL as species_update_id
from asfis_species) as p)) as st on tc.cap_species = st.st_code or tc.cap_species = st.english_name
where st.species_id is null;

INSERT INTO `sofia_taf`.`output`
(`area_id`,
`current_year`,
`reference_group_id`,
`species_group`,
`status`,
`tier`,
`species_id`,
`species_update_id`,
`location_id`)
SELECT 305,
tc.cap_year,
rg.reference_group_id,
st.isscaap,
tc.status,
1,
st.species_id,
st.species_update_id,
loc.location_id
FROM tmp_tier1data tc
JOIN reference_group rg on tc.reference_id = rg.reference_group_id
JOIN location loc on tc.location_code = loc.location_id
LEFT JOIN ((select distinct species_id,isscaap, st_code, english_name, species_update_id
from (
select species_id, fao_scientific_name as st_code,isscaap, fao_common_name as english_name, id as species_update_id
from asfis_fao_species
UNION ALL 
select id as species_id, scientific_name as st_code,isscaap,english_name, NULL as species_update_id
from asfis_species) as p)) as st on tc.cap_species = st.st_code or tc.cap_species = st.english_name
group by tc.cap_year,
rg.reference_group_id,
st.isscaap,
tc.status,
st.species_id,
st.species_update_id,
loc.location_id;

 
SET GLOBAL local_infile=OFF;
COMMIT;
"
  charset=utf8mb4

  executeCmds="mysql --login-path=${loginval} --local-infile=1 --default-character-set=${charset} \
               --skip-reconnect --unbuffered -v -v -v ${schema} -e "
  log "Commands to execute: "${executeCmds}
  log $(${executeCmds} "${sqlCmds}")

exit ${exitErr}
    