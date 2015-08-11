DELIMITER $$
DROP PROCEDURE IF EXISTS generate_db_size$$
CREATE PROCEDURE generate_db_size()
BEGIN
  DECLARE l_created_date DATETIME;
  SET l_created_date := NOW();

  INSERT INTO db_size(table_schema, table_name, engine, row_format,
                      table_rows, avg_row, total_mb, data_mb, index_mb,
                      created_date)
  SELECT table_schema,
         table_name,
         engine,
         row_format,
         table_rows,
         avg_row_length AS avg_row,
         ROUND((data_length+index_length)/1024/1024,2) AS total_mb,
         ROUND((data_length)/1024/1024,2) AS data_mb,
         ROUND((index_length)/1024/1024,2) AS index_mb,
         l_created_date
  FROM   information_schema.tables
  WHERE  table_schema=DATABASE()
  AND    table_type='BASE TABLE'
  ORDER BY 6 DESC;
  
  SELECT l_created_date AS created_date, 
         DATABASE() AS table_schema, 
         COUNT(*) AS tables,
         FORMAT(SUM(total_mb),2) AS total_mb,
         FORMAT(SUM(data_mb),2) AS data_mb,
         FORMAT(SUM(index_mb),2) AS index_mb
  FROM   db_size
  WHERE  created_date = l_created_date;

END$$
DELIMITER ;
