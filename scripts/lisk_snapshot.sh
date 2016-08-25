#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
. "$(pwd)/shared.sh"
. "$(pwd)/env.sh"

SNAPSHOT_CONFIG="snapshot.json"
LISK_CONFIG="config.json"
BACKUP_LOCATION="./backups/"
TIME_TO_KEEP="7"

echo -e "\nPreparing to take a snapshot of the blockchain."

mkdir -p $BACKUP_LOCATION  &> /dev/null
echo -e "\nClearing old snapshots on disk"
find $BACKUP_LOCATION -name lisk_backup* -mtime +$TIME_TO_KEEP -exec rm {} \;

if [ "$(grep "da3ed6a45429278bac2666961289ca17ad86595d33b31037615d4b8e8f158bba" $LISK_CONFIG )" ];then
  NETWORK="test"
elif [ "$(grep "ed14889723f24ecc54871d058d98ce91ff2f973192075c0155ba2b7b70ad2511" $LISK_CONFIG )" ];then
  NETWORK="main"
else
  NETWORK="local"
fi

DB_NAME="$(grep "database" $SNAPSHOT_CONFIG | cut -f 4 -d '"')"

echo -e "\nClearing old snapshot instance"

dropdb --if-exists "$DB_NAME" &> /dev/null
createdb "$DB_NAME" &> /dev/null

echo -e "\nExporting active database to snapshot instance"
pg_dump lisk_$NETWORK | psql "$DB_NAME" &> /dev/null

echo -e "\nClearing old log files"
cat /dev/null > ./logs/lisk_snapshot.log

echo -e "\nBeginning snapshot process at "$(date)""
bash lisk.sh snapshot -s 100000 -c snapshot.json

until tail -n10 ./logs/lisk_snapshot.log | grep -q "Cleaned up successfully"; do
  sleep 60
  ###TODO CHECK IF SNAPSHOT FAILS
done
echo -e "\nSnapshot process completed at "$(date)""
PID="$(bash lisk.sh status -c snapshot.json| grep PID| cut -d: -f 2)"
kill -9 $PID

echo -e "\nCleaning peers table"
psql -d lisk_snapshot -c 'delete from peers;'  &> /dev/null

HEIGHT="$(psql -d lisk_snapshot -t -c 'select height from blocks order by height desc limit 1;')"

echo -e "\nDumping snapshot"
pg_dump -O "$DB_NAME" | gzip > ./backups/lisk_backup-"$(echo $HEIGHT)".gz

echo "\nSnapshot Complete"
