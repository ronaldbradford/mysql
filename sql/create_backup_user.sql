CREATE USER backup_user@localhost IDENTIFIED BY 'backup_password';
GRANT SELECT, SHOW VIEW, TRIGGER, LOCK TABLES ON *.* to backup_user@localhost;
