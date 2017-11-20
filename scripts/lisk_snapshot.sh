#!/bin/bash
# 
# LiskHQ/lisk-build
# Copyright (C) 2017 Lisk Foundation
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
######################################################################

### crontab example(s) ########################################################

# Production
#*/5 * * * * /usr/bin/bash /opt/lisk/client/lisk_snapshot.sh  -b /opt/lisk/backup -d 2 -g > /dev/null 2>&1

# Debug
#*/2 * * * * /usr/bin/bash /opt/lisk/client/lisk_snapshot.sh  -b /opt/lisk/backup -g  > /opt/lisk/client/logs/snapshot_cron."`date +\%Y\%m\%d_\%H\%M\%S`".log 2>&1


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
PM2_CONFIG="$(pwd)/etc/pm2-snapshot.json"
SOURCE_DB_NAME="$(grep "database" "$LISK_CONFIG" | cut -f 4 -d '"')"

BACKUP_LOCATION="$(pwd)/backups"

DAYS_TO_KEEP="7"

GENERIC_COPY="N"

PGSQL_VACUUM_DELAY="3"

# Not configurable via parameter(s).

STALL_THRESHOLD_PREVIOUS="20"
STALL_THRESHOLD_CURRENT="10"

LOCK_LOCATION="$(pwd)/locks"
LOCK_FILE="$LOCK_LOCATION/snapshot.lock"

### Function(s) ###############################################################

parse_option() {
	OPTIND=1
	while getopts :t:s:b:d:m:g OPT; do
		case "$OPT" in
			t)
				if [ -f "$OPTARG" ]; then
					SNAPSHOT_CONFIG="$OPTARG"
					TARGET_DB_NAME="$(grep "database" "$SNAPSHOT_CONFIG" | cut -f 4 -d '"')"
					LOG_LOCATION="$(grep "logFileName" "$SNAPSHOT_CONFIG" | cut -f 4 -d '"')"
				else
					echo "$(now) Config.json for snapshot not found. Please verify the file exists and try again."
					exit 1
				fi ;;

			s)
				if [ -f "$OPTARG" ]; then
					LISK_CONFIG="$OPTARG"
					SOURCE_DB_NAME="$(grep "database" "$LISK_CONFIG" | cut -f 4 -d '"')"
				else
					echo "$(now) Config.json not found. Please verify the file exists and try again."
					exit 1
				fi ;;

			b)
				mkdir -p "$OPTARG" &> /dev/null
				if [ -d "$OPTARG" ]; then
					BACKUP_LOCATION="$OPTARG"
				else
					echo "$(now) Backup location invalid. Please verify the folder exists and try again."
					exit 1
				fi ;;

			d)
				if [ "$OPTARG" -ge 0 ]; then
					DAYS_TO_KEEP="$OPTARG"
				else
					echo "Invalid number for days to keep."
					exit 1
				fi ;;

			m)
				if [ "$OPTARG" -ge 1 ]; then
					PGSQL_VACUUM_DELAY=$OPTARG
				else
					echo "$(now) Invalid number for vacuum delay in minute(s)."
					exit 1
				fi ;;

			g) GENERIC_COPY="Y" ;;

			?) usage; exit 1 ;;

			:) echo "$(now) Missing option argument for -$OPTARG" >&2; exit 1 ;;

			*) echo "$(now) Unimplemented option: -$OPTARG" >&2; exit 1 ;;

		esac
	done
}

usage() {
	echo -e "\nUsage: $0 [-t <snapshot.json>] [-s <config.json>] [-b <backup directory>] [-d <days to keep>] [-r <round>] [-g] [-m <vacuum delay>]\n"
	echo " -t <snapshot.json>        -- config.json to use for creating the snapshot"
	echo " -s <config.json>          -- config.json used by the target database"
	echo " -b <backup directory>     -- Backup directory to output into. Default is ./backups"
	echo " -d <days to keep>         -- Days to keep backups. Default is 7"
	echo " -m <vacuum delay>         -- Delay in minute(s) between each vacuum of mem_round table.  Default is 3"
	echo " -g                        -- Make a copy of backup file named blockchain.db.gz"
	echo ''
}

now() {
	date +'%Y-%m-%d %H:%M:%S'
}


### MAIN ######################################################################

parse_option "$@"

echo -e "\n$(now) Checking for existing snapshot operation"

if [ ! -f "$LOCK_FILE" ]; then
	echo "√ Previous snapshot is not runnning. Proceeding."
else
  if [ "$( stat --format=%Y "$LOG_LOCATION" )" -le $(( $(date +%s) - ( STALL_THRESHOLD_PREVIOUS * 60 ) )) ]; then
    echo "√ Previous snapshot is stalled for $STALL_THRESHOLD_PREVIOUS minutes, terminating and continuing with a new snapshot"
    bash lisk.sh stop_node -p "$PM2_CONFIG"
    rm -f "$LOCK_FILE" &> /dev/null
  else
    echo "X Previous snapshot is in progress, aborting."
    exit 1
  fi
fi

mkdir -p "$LOCK_LOCATION" &> /dev/null
touch "$LOCK_FILE" &> /dev/null

echo -e "\n$(now) Cleaning old snapshot instance, database and logs"
bash lisk.sh stop_node -p "$PM2_CONFIG" &> /dev/null
cat /dev/null > "$LOG_LOCATION"
dropdb --if-exists "$TARGET_DB_NAME" &> /dev/null

echo -e "\n$(now) Deleting snapshots older then $DAYS_TO_KEEP day(s) in $BACKUP_LOCATION"
mkdir -p "$BACKUP_LOCATION" &> /dev/null
find "$BACKUP_LOCATION" -name "${SOURCE_DB_NAME}*.gz" -mtime +"$(( DAYS_TO_KEEP - 1 ))" -exec rm {} \;

echo -e "\n$(now) Executing vacuum on database '$SOURCE_DB_NAME' before copy"
vacuumdb --analyze --full "$SOURCE_DB_NAME" &> /dev/null

echo -e "\n$(now) Copying active database '$SOURCE_DB_NAME' to snapshot database '$TARGET_DB_NAME'"
createdb "$TARGET_DB_NAME" &> /dev/null
pg_dump "$SOURCE_DB_NAME" | psql "$TARGET_DB_NAME" &> /dev/null

echo -e "\n$(now) Beginning snapshot verification process"
bash lisk.sh start -p "$PM2_CONFIG"

MINUTES=0
until tail -n10 "$LOG_LOCATION" | (grep -q "Snapshot finished"); do
	sleep 60

	if [ "$( stat --format=%Y "$LOG_LOCATION" )" -le $(( $(date +%s) - ( STALL_THRESHOLD_CURRENT * 60 ) )) ]; then
		echo -e "\n$(now) Snapshot process is stalled for $STALL_THRESHOLD_CURRENT minutes, cleaning up and exiting"
		bash lisk.sh stop_node -p "$PM2_CONFIG" &> /dev/null
		dropdb --if-exists "$TARGET_DB_NAME" &> /dev/null
		rm -f "$LOCK_FILE" &> /dev/null
		exit 1
	fi

	MINUTES=$(( MINUTES + 1 ))
	if (( MINUTES % PGSQL_VACUUM_DELAY == 0 )) 2> /dev/null; then
		echo -e "\n$(now) Executing vacuum on table 'mem_round' of database '$TARGET_DB_NAME'"
		DBSIZE1=$(( $( ./pgsql/bin/psql -d "$TARGET_DB_NAME" -t -c "select pg_database_size('$TARGET_DB_NAME');" | xargs ) / 1024 / 1024 ))
		vacuumdb --analyze --full --table 'mem_round' "$TARGET_DB_NAME" &> /dev/null
		DBSIZE2=$(( $( ./pgsql/bin/psql -d "$TARGET_DB_NAME" -t -c "select pg_database_size('$TARGET_DB_NAME');" | xargs ) / 1024 / 1024 ))
		echo -e "$(now) Vacuum completed, database size: $DBSIZE1 MB => $DBSIZE2 MB"
	fi
done
echo -e "\n$(now) Snapshot verification process completed"

echo -e "\n$(now) Deleting data on table 'peers' of database '$TARGET_DB_NAME'"
psql -d "$TARGET_DB_NAME" -c 'delete from peers;' &> /dev/null

echo -e "\n$(now) Executing vacuum on database '$TARGET_DB_NAME' before dumping"
vacuumdb --analyze --full "$TARGET_DB_NAME" &> /dev/null

echo -e "\n$(now) Dumping snapshot database to gzip file"
HEIGHT="$(psql -d lisk_snapshot -t -c 'select height from blocks order by height desc limit 1;' | xargs)"
BACKUP_FULLPATH="${BACKUP_LOCATION}/${SOURCE_DB_NAME}_backup-${HEIGHT}.gz"
pg_dump -O "$TARGET_DB_NAME" | gzip > "$BACKUP_FULLPATH"

if [ "$GENERIC_COPY" == "Y" ] 2> /dev/null; then
	echo -e "\n$(now) Overwriting Generic Copy"
	cp -f "$BACKUP_FULLPATH" "$BACKUP_LOCATION"/blockchain.db.gz &> /dev/null
fi

echo -e "\n$(now) Cleaning up"
bash lisk.sh stop_node -p "$PM2_CONFIG" &> /dev/null
dropdb --if-exists "$TARGET_DB_NAME" &> /dev/null
rm -f "$LOCK_FILE" &> /dev/null

echo -e "\n$(now) Snapshot Complete"
exit 0
