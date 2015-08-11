SELECT   FORMAT(SUM(data_length+index_length)/1024/1024,2) AS total_mb,
         FORMAT(SUM(data_length)/1024/1024,2) AS data_mb,
         FORMAT(SUM(index_length)/1024/1024,2) AS index_mb,
         COUNT(DISTINCT table_schema) AS schema_cnt,
         COUNT(*) AS tables,
         CURDATE() AS today, 
         VERSION()
FROM     information_schema.tables\G
