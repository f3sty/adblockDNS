#!/bin/sh

DIR=$1
if ! [ -d $DIR ]; then
  echo "No directory $DIR"
  echo "Exiting."
  echo
  exit
fi

DESTADDR=$2
if [ -z $DESTADDR ]; then
	DESTADDR=127.0.0.1
fi

DB=adblockDNS
PASS=`pwgen -N 1 32` 2>/dev/null || PASS=`dd if=/dev/random bs=1 count=16 2>/dev/null | openssl md5 | awk '{print $2}'`

mysql -uroot -p <<MYSQL_SCRIPT
DROP DATABASE IF EXISTS $DB;
DROP USER IF EXISTS '$DB'@'localhost';
FLUSH PRIVILEGES;

CREATE DATABASE $DB;
CREATE USER '$DB'@'localhost' IDENTIFIED BY '$PASS';
GRANT ALL PRIVILEGES ON $DB.* TO '$DB'@'localhost';
FLUSH PRIVILEGES;
FLUSH TABLES;
USE $DB;
DROP TABLE IF EXISTS blocklist;
CREATE TABLE blocklist (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  domain varchar(150) DEFAULT NULL,
  timestamp timestamp NOT NULL DEFAULT "0000-00-00 00:00:00" ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY domain_unique (domain)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4;
MYSQL_SCRIPT

echo "Database $DB created."
echo "MySQL user created."
echo "Username:   $DB"
echo "Password:   $PASS"

# substitute the DB name and user credentials into the scripts
perl -pi.orig -e "s/<DB>/$DB/; s/<DBUSER>/$DB/; s/<DBPASS>/$PASS/" updateblockDB.pl generate_blocklist.pl
perl -pi.orig -e "s/<DESTADDR>/$DESTADDR/" null.zone.file

