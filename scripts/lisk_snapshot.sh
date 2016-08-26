#!/bin/bash

#Begin Variable Declaration and argument parsing
###############################################################################

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
. "$(pwd)/shared.sh"
. "$(pwd)/env.sh"

SNAPSHOT_CONFIG="snapshot.json"
TARGET_DB_NAME="$(grep "database" $SNAPSHOT_CONFIG | cut -f 4 -d '"')"
LOG_LOCATION="$(grep "logFileName" $SNAPSHOT_CONFIG | cut -f 4 -d '"')"

LISK_CONFIG="config.json"
SOURCE_DB_NAME="$(grep "database" $LISK_CONFIG | cut -f 4 -d '"')"

BACKUP_LOCATION="./backups"

DAYS_TO_KEEP="7"

parse_option() {

 OPTIND=1
 while getopts :s:t:b:d: opt;
 do
   case $opt in
   t) if [ -f $OPTARG ]; then
          SNAPSHOT_CONFIG=$OPTARG
          TARGET_DB_NAME="$(grep "database" $SNAPSHOT_CONFIG | cut -f 4 -d '"')"
          LOG_LOCATION="$(grep "logFileName" $SNAPSHOT_CONFIG | cut -f 4 -d '"')"
      else
          echo "Config.json for snapshot not found. Please verify the file exists and try again."
          exit 1
      fi ;;

   s) if [ -f $OPTARG ]; then
          LISK_CONFIG=$OPTARG
          SOURCE_DB_NAME="$(grep "database" $LISK_CONFIG | cut -f 4 -d '"')"
      else
          echo "Config.json not found. Please verify the file exists and try again."
          exit 1
      fi ;;

    b) mkdir -p $OPTARG  &> /dev/null
       if [ -d $OPTARG ]; then
         BACKUP_LOCATION=$OPTARG
       else
         echo "Backup Location invalid. Please verify the folder exists and try again."
         exit 1
       fi ;;

    d) if [ $OPTARG -ge 0 ]; then
        DAYS_TO_KEEP=$OPTARG
       else
        echo "Invalid number for days to keep."
        exit 1
       fi ;;
    ?) usage; exit 1 ;;

   :) echo "Missing option argument for -$OPTARG" >&2; exit 1 ;;

   *) echo "Unimplemented option: -$OPTARG" >&2; exit 1 ;;

   esac
 done

}

usage() {

  echo "Usage: $0 [-s <config.json>] [-t <snapshot.json>] [-b <backup directory>] [-d <days to keep>]"
  echo " -t <snapshot.json>        -- config.json to use for validation"
  echo " -s <config.json>          -- config.json to create target database"
  echo " -b <backup directory>     -- backup direcory"
  echo " -d <days to keep>         -- Days to keep backups"

}

parse_option "$@"

#Begin Main Process
###############################################################################

echo -e "\nPreparing to take a snapshot of the blockchain."



mkdir -p $BACKUP_LOCATION  &> /dev/null
echo -e "\nClearing old snapshots on disk"
find $BACKUP_LOCATION -name lisk_backup* -mtime +$DAYS_TO_KEEP -exec rm {} \;

echo -e "\nClearing old snapshot instance"
bash lisk.sh stop_node -c $SNAPSHOT_CONFIG &> /dev/null
dropdb --if-exists "$TARGET_DB_NAME" &> /dev/null
createdb "$TARGET_DB_NAME" &> /dev/null

echo -e "\nExporting active database to snapshot instance"
pg_dump $SOURCE_DB_NAME | psql "$TARGET_DB_NAME" &> /dev/null

echo -e "\nClearing old log files"
cat /dev/null > $LOG_LOCATION

echo -e "\nBeginning snapshot verification process at "$(date)""
bash lisk.sh snapshot -s 100000 -c $SNAPSHOT_CONFIG

until tail -n10 $LOG_LOCATION | grep -q "Cleaned up successfully"; do
  sleep 60
  ###TODO CHECK IF SNAPSHOT FAILS
done
echo -e "\nSnapshot verification process completed at "$(date)""

echo -e "\nCleaning peers table"
psql -d lisk_snapshot -c 'delete from peers;'  &> /dev/null

HEIGHT="$(psql -d lisk_snapshot -t -c 'select height from blocks order by height desc limit 1;')"

echo -e "\nDumping snapshot"
pg_dump -O "$TARGET_DB_NAME" | gzip > $BACKUP_LOCATION/lisk_backup-"$(echo $HEIGHT)".gz

echo -e "\nSnapshot Complete"
