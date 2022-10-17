CREATE DEFINER=`root`@`localhost` PROCEDURE `extract_output_summary`(IN area_code varchar(10), IN tier1adjustment decimal(10,2), IN tier2adjustment decimal(10,2), IN output_dir varchar(200))
BEGIN
SET session internal_tmp_mem_storage_engine=Memory;
SET GLOBAL temptable_use_mmap=0;
SET @area_code := area_code;
SET @AdjTier1 := IF( tier1adjustment IS NULL, 1,tier1adjustment);
SET @AdjTier2 := IF( tier2adjustment IS NULL, 1,tier2adjustment);
SET @output_dir  := IF( output_dir IS NULL, "C://tmp", output_dir );
SET @output_file := CONCAT( "overall_results_", @area_code, DATE_FORMAT( NOW(), "%Y-%m-%d_%k%i%s" ) );
SET @csv_enclose_char         := '"';
SET @csv_field_terminate_char := ',';
SET @csv_line_terminate_char  := '\n';
Drop table if exists output_tmp;
CREATE Table output_tmp
select @area_code as area_code,
(sum(case when status = 'U' and tier = 1 then 1.0 when status like '%U%' and length(replace(status,'-','')) =2 and tier = 1 then 0.5 when status like '%U%' and length(replace(status,'-','')) =3 and tier = 1 then 0.3333 else 0 end)*@AdjTier1 
+ sum(case when status = 'U' and tier = 2 then 1.0 when status like '%U%' and length(replace(status,'-','')) =2 and tier = 2 then 0.5 when status like '%U%' and length(replace(status,'-','')) =3 and tier = 2 then 0.3333 else 0 end)*@AdjTier2)
/count(status)*100 as underfished,
(sum(case when status = 'F' and tier = 1 then 1.0 when status like '%F%' and length(replace(status,'-','')) =2 and tier = 1 then 0.5 when status like '%F%' and length(replace(status,'-','')) =3 and tier = 1 then 0.3333 else 0 end)*@AdjTier1
 + sum(case when status = 'F' and tier = 2 then 1.0 when status like '%F%' and length(replace(status,'-','')) =2 and tier = 2 then 0.5 when status like '%F%' and length(replace(status,'-','')) =3 and tier = 2 then 0.3333 else 0 end)*@AdjTier2)
 /count(status)*100 as FullyFished,
(sum(case when status = 'O' and tier = 1 then 1.0 when status like '%O%' and length(replace(status,'-','')) =2 and tier = 1 then 0.5 when status like '%O%' and length(replace(status,'-','')) =3 and tier = 1 then 0.3333 else 0 end)*@AdjTier1
 + sum(case when status = 'O' and tier = 2 then 1.0 when status like '%O%' and length(replace(status,'-','')) =2 and tier = 2 then 0.5 when status like '%O%' and length(replace(status,'-','')) =3 and tier = 2 then 0.3333 else 0 end)*@AdjTier2)
 /count(status)*100 as Overfished, 
 count(status) as totals
from output_timeseries ot join area ar on ar.id = ot.area_id 
where ar.ar_code = @area_code and stock_id <> 8140;
set @header := CONCAT("SELECT 'area_code', 'underfished', 'fullyfished', 'overfished', 'totals'");

SET @final := CONCAT( "SELECT * FROM (",
    "(", @header, ")",
     "UNION ALL",
    "(", "select area_code, underfished, fullyfished, overfished, totals from output_tmp ", ")",
  ") `result_set_alias_output` ",
  "INTO OUTFILE '", @output_dir, "/", @output_file, ".csv' ",
  "FIELDS TERMINATED BY '", @csv_field_terminate_char, "' ",
  "ENCLOSED BY '", @csv_enclose_char, "' ",
  "LINES TERMINATED BY '", @csv_line_terminate_char, "';"
);


PREPARE statement FROM @final;
EXECUTE statement;
END