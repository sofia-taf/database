CREATE DEFINER=`root`@`localhost` PROCEDURE `sproc_get_captures`(IN area_code varchar(10), IN monitoring int, IN output_dir varchar(200))
BEGIN
set session internal_tmp_mem_storage_engine=Memory;
SET GLOBAL temptable_use_mmap=0;
set @monitoring = monitoring;
set @area_code = area_code;
Drop table if exists cap_tmp;
CREATE temporary Table cap_tmp 
SELECT ar.ar_code, 
     st.isscaap, 
     arst.monitoring,
     coalesce(stup.fao_common_name,st.english_name) as english_name, 
     coalesce(stup.fao_scientific_name,st.scientific_name) as scientific_name, 
     year, biomass, qualifier
FROM tafp.capture c
join tafp.area_stock arst on c.stock_id = arst.stock_id and c.area_id = arst.area_id
left join tafp.stock st on c.stock_id = st.id
left join tafp.area ar on c.area_id = ar.id
left join tafp.stock_update stup on c.stock_update_id = stup.id 
where (@area_code IS NULL or ar.ar_code=@area_code) AND (@monitoring IS NULL OR arst.monitoring=@monitoring);

SET @output_dir  := IF( output_dir IS NULL, "D://mysql/tmp", output_dir );
SET @arCode := IF(@area_code IS NULL, "comp", @area_code);
SET @flag := IF(monitoring =1,"flagged","all");
SET @output_file := CONCAT( "cap", @flag, @arCode, DATE_FORMAT( NOW(), "%Y-%m-%d_%k%i%s" ) );
SET @csv_enclose_char         := '"';
SET @csv_field_terminate_char := ',';
SET @csv_line_terminate_char  := '\n';

SET @bioyr_list = NULL;
SET @@group_concat_max_len = 32000;
SELECT
  GROUP_CONCAT(
    CONCAT('CONCAT(sum(case when `year`= ''',
           `year`,
           ''' then CONCAT(biomass) else 0 end)) AS `',
           `year`, '`'
           )
  ) INTO @bioyr_list
from
(
  select `year`
  from cap_tmp 
  group by `year`
  order by `year`
) d;
SELECT @bioyr_list;
SET @yr_list= NULL;
SELECT
  GROUP_CONCAT(CONCAT("'",`year`,"'")) INTO @yr_list
from
(
  select `year`
  from cap_tmp 
  group by `year`
  order by `year`
) d;
set @header := CONCAT("SELECT 'ar_code', 'isscaap', 'monitoring', 'english_name', 'scientific_name',", @yr_list);

SELECT @yr_list;

SET @final := CONCAT(  "SELECT * FROM (",
    "(", @header, ")",
     "UNION ALL",
    "(", "SELECT ar_code, isscaap, monitoring, english_name, scientific_name,", @bioyr_list, "
FROM cap_tmp
group by ar_code, isscaap, monitoring, english_name, scientific_name ", ")",
  ") `result_set_alias__anything_will_do` ",
  "INTO OUTFILE '", @output_dir, "/", @output_file, ".csv' ",
  "FIELDS TERMINATED BY '", @csv_field_terminate_char, "' ",
  "ENCLOSED BY '", @csv_enclose_char, "' ",
  "LINES TERMINATED BY '", @csv_line_terminate_char, "';"
);


PREPARE statement FROM @final;
EXECUTE statement;
Drop table if exists cap_tmp;
END$$
DELIMITER ;
