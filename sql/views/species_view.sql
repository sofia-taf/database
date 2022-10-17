CREATE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`localhost` 
    SQL SECURITY DEFINER
VIEW `tafp`.`species_view` AS
    SELECT 
        `stid`.`id` AS `species_id`,
        `stup`.`id` AS `species_update_id`,
        (CASE
            WHEN (`stup`.`fao_scientific_name` IS NOT NULL) THEN `stup`.`fao_scientific_name`
            ELSE `stid`.`scientific_name`
        END) AS `species_name`,
        (CASE
            WHEN (`stup`.`fao_common_name` IS NOT NULL) THEN `stup`.`fao_common_name`
            ELSE `stid`.`english_name`
        END) AS `common_name`,
        (CASE
            WHEN (`stup`.`fao_3code` IS NOT NULL) THEN `stup`.`fao_3code`
            ELSE `stid`.`st_code`
        END) AS `alphacode`
    FROM
        (`tafp`.`stock` `stid`
        LEFT JOIN `tafp`.`stock_update` `stup` ON ((`stid`.`id` = `stup`.`stock_id`))) 
    UNION ALL SELECT 
        `st`.`id` AS `species_id`,
        NULL AS `species_update_id`,
        `st`.`scientific_name` AS `species_name`,
        `stup`.`fao_common_name` AS `fao_common_name`,
        `stup`.`fao_3code` AS `alphacode`
    FROM
        (`tafp`.`stock` `st`
        JOIN `tafp`.`stock_update` `stup` ON (((`st`.`id` = `stup`.`stock_id`)
            AND (`st`.`st_code` <> `stup`.`fao_3code`))))
    GROUP BY `st`.`id` , `st`.`st_code` , `stup`.`fao_3code` , `stup`.`fao_common_name`