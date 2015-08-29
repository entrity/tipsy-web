#!/bin/bash

# This imports structure and data from the .sql and .txt files that result from
# mysqldump -T

DSTDB="tmp"
CHARSET="utf-8" #your current database charset
DATADIR="$1"

do_format_struct ()
{
	TMP=$(basename "$1")
	TABLE=${TMP%.*}
	echo tmp $TMP
	echo table $TABLE
	TMPFILE="/tmp/$( basename "$1" ).tmp"
	sed -r \
	-e 's/`/"/g' \
	-e 's/varchar\([0-9]+\)/text/g' \
	-e 's/int\(11\)/int/g' \
	-e '/^  KEY .*/d' \
	-e '/^  CONSTRAINT .*/d' \
	-e 's/^(  PRIMARY KEY \("[a-zA-Z0-9_]*"\)),/\1/' \
	-e '/^LOCK TABLES/d' \
	-e '/^UNLOCK TABLES/d' \
	-e "s/\\\'/''/g" \
	-e '/ENGINE=\w/d' \
	-e '/^\/\*.*\*\/;/d' \
	-e '/^--/d' \
	-e "s/(PRIMARY KEY .*)$/tmp int);\nALTER TABLE ONLY $TABLE ADD CONSTRAINT ""$TABLE""_pkey \1;\ALTER TABLE ONLY $TABLE DROP COLUMN tmp/g" \
	"$1" > $TMPFILE
	iconv -t $CHARSET -f $CHARSET -c < $TMPFILE > "$1.out"
}

do_load_struct ()
{
	OUT="$1.out"
	echo importing structure for $2 from $OUT
	psql $DSTDB < "$OUT"
}

do_load_data ()
{
	TABLE="$2"
	TMPFILE=/tmp/$TABLE.export.tmp.out
	iconv -t $CHARSET -f $CHARSET -c < "$1" > $TMPFILE
	echo "Loading data for $TABLE from $TMPFILE"
	psql $DSTDB -c "copy $TABLE from '$TMPFILE'"
}

for file in `ls "$DATADIR"/*.sql`; do
	TMP=$(basename $file)
	TABLE=${TMP%.*}
	do_format_struct 	"$file" "$TABLE"
	do_load_struct 		"$file" "$TABLE"
	datafile="$TABLE".txt
	do_load_data    "$datafile" "$TABLE"
done
