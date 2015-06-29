#!/bin/bash
CAMERON_SCRAPE=db/Dump20150525.sql
INTERMEDIATE_DUMP=tmp/scrape.sql
INTERMEDIATE_DUMP_2=tmp/utf8_scrape.sql
MYSQL_TMP=tt
PSQL_DST=$1
mysql -e "drop database if exists $MYSQL_TMP;"
mysql -e "create database $MYSQL_TMP;"
mysql $MYSQL_TMP < $CAMERON_SCRAPE
echo -e "SET standard_conforming_strings = 'off';\nSET backslash_quote = 'on';" > $INTERMEDIATE_DUMP
mysqldump --compatible=postgresql $MYSQL_TMP \
| sed -r \
	-e 's/varchar\([0-9]+\)/text/g' \
	-e 's/int\(11\)/int/g' \
	-e '/^  KEY .*/d' \
	-e '/^  CONSTRAINT .*/d' \
	-e 's/^(  PRIMARY KEY \("[a-zA-Z0-9_]*"\)),/\1/' \
	-e '/^LOCK TABLES/d' \
	-e '/^UNLOCK TABLES/d' \
	-e "s/\\\'/''/g" \
>> $INTERMEDIATE_DUMP
iconv -f CP1250 -t UTF-8 <$INTERMEDIATE_DUMP >$INTERMEDIATE_DUMP_2

psql $PSQL_DST < $INTERMEDIATE_DUMP_2 2> >(tee tmp/err.log >&2)
