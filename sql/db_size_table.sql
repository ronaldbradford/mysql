DROP TABLE IF EXISTS db_size;
CREATE TABLE db_size(
  table_schema  VARCHAR(64) NOT NULL,
  table_name    VARCHAR(64) NOT NULL,
  engine        VARCHAR(64) NOT NULL,
  row_format    VARCHAR(10) NULL,
  table_rows    INT UNSIGNED NOT NULL,
  avg_row       INT UNSIGNED NOT NULL,
  total_mb      DECIMAL(7,2) NOT NULL,
  data_mb       DECIMAL(7,2) NOT NULL,
  index_mb      DECIMAL(7,2) NOT NULL,
  created_date  DATETIME NOT NULL,
  INDEX (created_date,table_name)
) ENGINE=InnoDB;
