CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_year`()
BEGIN
DECLARE i INT DEFAULT 1945; 
WHILE (i <= 2040) DO
    INSERT INTO `star_year` (star_year) values (i);
    SET i = i+1;
END WHILE;
END