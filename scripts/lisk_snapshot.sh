#!/bin/bash

# Begin Variable Declaration and argument parsing
###############################################################################

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
. "$(pwd)/shared.sh"
. "$(pwd)/env.sh"

SNAPSHOT_CONFIG="$(pwd)/etc/snapshot.json"
TARGET_DB_NAME="$(grep "database" $SNAPSHOT_CONFIG | cut -f 4 -d '"')"
LOG_LOCATION="$(grep "logFileName" $SNAPSHOT_CONFIG | cut -f 4 -d '"')"

LISK_CONFIG="config.json"
SOURCE_DB_NAME="$(grep "database" $LISK_CONFIG | cut -f 4 -d '"')"

BACKUP_LOCATION="$(pwd)/backups"

DAYS_TO_KEEP="7"

SNAPSHOT_ROUND="highest"

GENERIC_COPY="N"

parse_option() {
  OPTIND=1
  while getopts :s:t:b:d:r:g opt; do
    case $opt in
      t)
        if [ -f $OPTARG ]; then
          SNAPSHOT_CONFIG=$OPTARG
          TARGET_DB_NAME="$(grep "database" $SNAPSHOT_CONFIG | cut -f 4 -d '"')"
          LOG_LOCATION="$(grep "logFileName" $SNAPSHOT_CONFIG | cut -f 4 -d '"')"
        else
          echo "Config.json for snapshot not found. Please verify the file exists and try again."
          exit 1
        fi ;;

      s)
        if [ -f $OPTARG ]; then
          LISK_CONFIG=$OPTARG
          SOURCE_DB_NAME="$(grep "database" $LISK_CONFIG | cut -f 4 -d '"')"
        else
          echo "Config.json not found. Please verify the file exists and try again."
          exit 1
        fi ;;

      b)
        mkdir -p $OPTARG &> /dev/null
        if [ -d $OPTARG ]; then
          BACKUP_LOCATION=$OPTARG
        else
          echo "Backup Location invalid. Please verify the folder exists and try again."
          exit 1
        fi ;;

      d)
        if [ $OPTARG -ge 0 ]; then
          DAYS_TO_KEEP=$OPTARG
        else
          echo "Invalid number for days to keep."
          exit 1
        fi ;;

      r)
        if [ "$OPTARG" -gt "0" ] 2> /dev/null; then
          SNAPSHOT=$OPTARG
        elif [ "$OPTARG" == "highest" ]; then
          SNAPSHOT=$OPTARG
        else
          echo "Snapshot flag must be a greater than 0 or set to highest"
          exit 1
        fi ;;

      g) GENERIC_COPY="Y" ;;

      ?) usage; exit 1 ;;

      :) echo "Missing option argument for -$OPTARG" >&2; exit 1 ;;

      *) echo "Unimplemented option: -$OPTARG" >&2; exit 1 ;;
    esac
  done
}

usage() {
  echo "Usage: $0 [-t <snapshot.json>] [-s <config.json>] [-b <backup directory>] [-d <days to keep>] [-r <round>] [-g]"
  echo " -t <snapshot.json>        -- config.json to use for validation"
  echo " -s <config.json>          -- config.json to create target database"
  echo " -b <backup directory>     -- Backup direcory"
  echo " -d <days to keep>         -- Days to keep backups"
  echo " -r <round>                -- Round height to snapshot at"
  echo " -g                        -- Make a copy of backup file named blockchain.db.gz"
}

parse_option "$@"

# Begin Main Process
###############################################################################

echo -e "\nPreparing to take a snapshot of the blockchain."

mkdir -p $BACKUP_LOCATION  &> /dev/null
echo -e "\nClearing old snapshots on disk"
find $BACKUP_LOCATION -name "${TARGET_DB_NAME}*.gz" -mtime +$DAYS_TO_KEEP -exec rm {} \;

echo -e "\nClearing old snapshot instance"
bash lisk.sh stop_node -c $SNAPSHOT_CONFIG &> /dev/null
dropdb --if-exists "$TARGET_DB_NAME" &> /dev/null
createdb "$TARGET_DB_NAME" &> /dev/null

echo -e "\nExporting active database to snapshot instance"
pg_dump $SOURCE_DB_NAME | psql "$TARGET_DB_NAME" &> /dev/null

echo -e "\nClearing old log files"
cat /dev/null > $LOG_LOCATION

echo -e "\nBeginning snapshot verification process at "$(date)""
bash lisk.sh snapshot -s $SNAPSHOT_ROUND -c $SNAPSHOT_CONFIG

until tail -n10 $LOG_LOCATION | grep -q "Cleaned up successfully"; do
  sleep 60
  # TODO: Check if snapshot fails
done
echo -e "\nSnapshot verification process completed at "$(date)""

echo -e "\nCleaning peers table"
psql -d $TARGET_DB_NAME -c 'delete from peers;'  &> /dev/null

HEIGHT="$(psql -d lisk_snapshot -t -c 'select height from blocks order by height desc limit 1;' | xargs)"

BACKUP_FULLPATH="${BACKUP_LOCATION}/${TARGET_DB_NAME}_backup-${HEIGHT}.gz"

echo -e "\nDumping snapshot"
pg_dump -O "$TARGET_DB_NAME" | gzip > $BACKUP_FULLPATH

if [ "$GENERIC_COPY" == "Y" ] 2> /dev/null; then
  echo -e "\nOverwriting Generic Copy"
  cp -f $BACKUP_FULLPATH $BACKUP_LOCATION/blockchain.db.gz &> /dev/null
fi

echo -e "\nSnapshot Complete"
