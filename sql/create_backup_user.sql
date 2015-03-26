CREATE USER backup_user@localhost IDENTIFIED BY 'backup_password';
-- RELOAD is required for --master-data
-- LOCK TABLES is required when --single-transaction is not specified (because --opt than is default)
GRANT SELECT, SHOW VIEW, TRIGGER, LOCK TABLES, RELOAD ON *.* to backup_user@localhost;
