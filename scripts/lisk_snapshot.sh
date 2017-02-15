#!/bin/bash

### Init. Env. ################################################################

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2
# shellcheck disable=SC1090
. "$(pwd)/shared.sh"
# shellcheck disable=SC1090
. "$(pwd)/env.sh"


### Variables Definition ######################################################

SNAPSHOT_CONFIG="$(pwd)/etc/snapshot.json"
TARGET_DB_NAME="$(grep "database" "$SNAPSHOT_CONFIG" | cut -f 4 -d '"')"
LOG_LOCATION="$(grep "logFileName" "$SNAPSHOT_CONFIG" | cut -f 4 -d '"')"

LISK_CONFIG="config.json"
SOURCE_DB_NAME="$(grep "database" "$LISK_CONFIG" | cut -f 4 -d '"')"

BACKUP_LOCATION="$(pwd)/backups"

DAYS_TO_KEEP="7"

SNAPSHOT_ROUND="highest"

GENERIC_COPY="N"

PGSQL_VACUUM="N"
PGSQL_VACUUM_DELAY=5

STALL_THRESHOLD_PREVIOUS=20
STALL_THRESHOLD_CURRENT=10


### Function(s) ###############################################################

parse_option() {
  OPTIND=1
  while getopts :t:s:b:d:r:gvm: OPT; do
    case "$OPT" in
      t)
        if [ -f "$OPTARG" ]; then
          SNAPSHOT_CONFIG="$OPTARG"
          TARGET_DB_NAME="$(grep "database" "$SNAPSHOT_CONFIG" | cut -f 4 -d '"')"
          LOG_LOCATION="$(grep "logFileName" "$SNAPSHOT_CONFIG" | cut -f 4 -d '"')"
        else
          echo "$( date +'%Y-%m-%d %H:%M:%S' ) Config.json for snapshot not found. Please verify the file exists and try again."
          exit 1
        fi ;;

      s)
        if [ -f "$OPTARG" ]; then
          LISK_CONFIG="$OPTARG"
          SOURCE_DB_NAME="$(grep "database" "$LISK_CONFIG" | cut -f 4 -d '"')"
        else
          echo "$( date +'%Y-%m-%d %H:%M:%S' ) Config.json not found. Please verify the file exists and try again."
          exit 1
        fi ;;

      b)
        mkdir -p "$OPTARG" &> /dev/null
        if [ -d "$OPTARG" ]; then
          BACKUP_LOCATION="$OPTARG"
        else
          echo "$( date +'%Y-%m-%d %H:%M:%S' ) Backup Location invalid. Please verify the folder exists and try again."
          exit 1
        fi ;;

      d)
        if [ "$OPTARG" -ge 0 ]; then
          DAYS_TO_KEEP="$OPTARG"
        else
          echo "Invalid number for days to keep."
          exit 1
        fi ;;

		r)
        if [ "$OPTARG" -gt "0" ] 2> /dev/null; then
          SNAPSHOT_ROUND="$OPTARG"
        elif [ "$OPTARG" == "highest" ]; then
          SNAPSHOT_ROUND="$OPTARG"
        else
          echo "$( date +'%Y-%m-%d %H:%M:%S' ) Snapshot flag must be a greater than 0 or set to highest"
          exit 1
        fi ;;

      g) GENERIC_COPY="Y" ;;

      v) PGSQL_VACUUM="Y" ;;

      m)
        if [ "$OPTARG" -ge 1 ]; then
          PGSQL_VACUUM_DELAY=$OPTARG
        else
          echo "$( date +'%Y-%m-%d %H:%M:%S' ) Invalid number for vacuum delay in minute(s)."
          exit 1
        fi ;;

      ?) usage; exit 1 ;;

      :) echo "$( date +'%Y-%m-%d %H:%M:%S' ) Missing option argument for -$OPTARG" >&2; exit 1 ;;

      *) echo "$( date +'%Y-%m-%d %H:%M:%S' ) Unimplemented option: -$OPTARG" >&2; exit 1 ;;

    esac
  done
}

usage() {
  echo -e "\nUsage: $0 [-t <snapshot.json>] [-s <config.json>] [-b <backup directory>] [-d <days to keep>] [-r <round>] [-g] [-v] [-m <vacuum delay>]\n"
  echo " -t <snapshot.json>        -- config.json to use for creating the snapshot"
  echo " -s <config.json>          -- config.json used by the target database"
  echo " -b <backup directory>     -- Backup directory to output into. Default is ./backups"
  echo " -d <days to keep>         -- Days to keep backups. Default is 7"
  echo " -r <round>                -- Round to end the snapshot at. Default is highest"
  echo " -g                        -- Make a copy of backup file named blockchain.db.gz"
  echo " -v                        -- Use extra pgsql vacuum commands"
  echo " -m <vacuum delay>         -- Delay in minute(s) between each vacuum of mem_round table."
  echo ''
}


### MAIN ######################################################################

parse_option "$@"

echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Checking for existing snapshot operation"

bash lisk.sh status -c "$SNAPSHOT_CONFIG"

if [ $? == 1 ]; then
  echo "√ Previous snapshot is not runnning. Proceeding."
else
  if [ "$( stat --format=%Y "$LOG_LOCATION" )" -le $(( $(date +%s) - ( STALL_THRESHOLD_PREVIOUS * 60 ) )) ]; then
    echo "√ Previous snapshot is stalled for $STALL_THRESHOLD_PREVIOUS minutes, terminating and continuing with a new snapshot"
    bash lisk.sh stop_node -c "$SNAPSHOT_CONFIG"
  else
    echo "X Previous snapshot is in progress, aborting."
    exit 1
  fi
fi

mkdir -p "$BACKUP_LOCATION" &> /dev/null
echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Deleting snapshots older then $DAYS_TO_KEEP day(s) in $BACKUP_LOCATION"
find "$BACKUP_LOCATION" -name "${SOURCE_DB_NAME}*.gz" -mtime +"$DAYS_TO_KEEP" -exec rm {} \;

if [ "$PGSQL_VACUUM" == "Y" ] 2> /dev/null; then
  echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Executing vacuum on database '$SOURCE_DB_NAME' before copy"
  vacuumdb --analyze --full "$SOURCE_DB_NAME" &> /dev/null
fi

echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Cleaning old snapshot instance, database and logs"
bash lisk.sh stop_node -c "$SNAPSHOT_CONFIG" &> /dev/null
dropdb --if-exists "$TARGET_DB_NAME" &> /dev/null
cat /dev/null > "$LOG_LOCATION"

echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Copying active database '$SOURCE_DB_NAME' to snapshot database '$TARGET_DB_NAME'"
createdb "$TARGET_DB_NAME" &> /dev/null
pg_dump "$SOURCE_DB_NAME" | psql "$TARGET_DB_NAME" &> /dev/null

echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Beginning snapshot verification process"
bash lisk.sh snapshot -s "$SNAPSHOT_ROUND" -c "$SNAPSHOT_CONFIG"

MINUTES=0
until tail -n10 "$LOG_LOCATION" | (grep -q "Snapshot finished"); do
  sleep 60
  
  if [ "$( stat --format=%Y "$LOG_LOCATION" )" -le $(( $(date +%s) - ( STALL_THRESHOLD_CURRENT * 60 ) )) ]; then
    echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Snapshot process is stalled for $STALL_THRESHOLD_CURRENT minutes, cleaning up and exiting"
    bash lisk.sh stop_node -c "$SNAPSHOT_CONFIG" &> /dev/null
    dropdb --if-exists "$TARGET_DB_NAME" &> /dev/null
    exit 1
  fi
  
  MINUTES=$(( MINUTES + 1 ))
  if [ "$PGSQL_VACUUM" == "Y" ] 2> /dev/null; then
    if (( MINUTES % PGSQL_VACUUM_DELAY == 0 )) 2> /dev/null; then
      echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Executing vacuum on table 'mem_round' of database '$TARGET_DB_NAME'"
      DBSIZE1=$(( $( ./pgsql/bin/psql -d "$TARGET_DB_NAME" -t -c "select pg_database_size('$TARGET_DB_NAME');" | xargs ) / 1024 / 1024 ))
      vacuumdb --analyze --full --table 'mem_round' "$TARGET_DB_NAME" &> /dev/null
      DBSIZE2=$(( $( ./pgsql/bin/psql -d "$TARGET_DB_NAME" -t -c "select pg_database_size('$TARGET_DB_NAME');" | xargs ) / 1024 / 1024 ))
      echo -e "$( date +'%Y-%m-%d %H:%M:%S' ) Vacuum completed, database size: $DBSIZE1 MB => $DBSIZE2 MB"
    fi
  fi
done
echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Snapshot verification process completed"

echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Deleting data on table 'peers' of database '$TARGET_DB_NAME'"
psql -d "$TARGET_DB_NAME" -c 'delete from peers;' &> /dev/null

if [ "$PGSQL_VACUUM" == "Y" ] 2> /dev/null; then
  echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Executing vacuum on database '$TARGET_DB_NAME' before dumping"
  vacuumdb --analyze --full "$TARGET_DB_NAME" &> /dev/null
fi

echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Dumping snapshot database to gzip file"
HEIGHT="$(psql -d lisk_snapshot -t -c 'select height from blocks order by height desc limit 1;' | xargs)"
BACKUP_FULLPATH="${BACKUP_LOCATION}/${SOURCE_DB_NAME}_backup-${HEIGHT}.gz"
pg_dump -O "$TARGET_DB_NAME" | gzip > "$BACKUP_FULLPATH"

if [ "$GENERIC_COPY" == "Y" ] 2> /dev/null; then
  echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Overwriting Generic Copy"
  cp -f "$BACKUP_FULLPATH" "$BACKUP_LOCATION"/blockchain.db.gz &> /dev/null
fi

echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Cleaning up"
bash lisk.sh stop_node -c "$SNAPSHOT_CONFIG" &> /dev/null
dropdb --if-exists "$TARGET_DB_NAME" &> /dev/null

echo -e "\n$( date +'%Y-%m-%d %H:%M:%S' ) Snapshot Complete"
exit 0
