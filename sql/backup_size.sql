SELECT   SUM(data_length+index_length)/1024/1024 AS total_mb,
         SUM(data_length)/1024/1024 AS data_mb,
         SUM(index_length)/1024/1024 AS index_mb,
         COUNT(DISTINCT table_schema) AS schema_cnt,
         COUNT(*) AS tables,
         CURDATE() AS today, 
         VERSION()
FROM     information_schema.tables\G
