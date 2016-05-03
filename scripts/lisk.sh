#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
. "$(pwd)/shared.sh"

if [ ! -f "$(pwd)/app.js" ]; then
  echo "Error: Lisk installation was not found. Aborting."
  exit 1
fi

if [ "$USER" == "root" ]; then
  echo "Error: Lisk cannot be run as root. Aborting."
  exit 1
fi

UNAME=$(uname)
NETWORK="test"

DB_NAME="lisk_$NETWORK"
DB_USER=$USER
DB_PASS="password"
DB_DATA="$(pwd)/pgsql/data"
DB_LOG_FILE="$(pwd)/pgsql.log"

export PATH="$(pwd)/bin:$(pwd)/pgsql/bin:/usr/bin:/bin:/usr/local/bin"
export LD_LIBRARY_PATH="$(pwd)/pgsql/lib"

LOG_FILE="$(pwd)/app.log"
PID_FILE="$(pwd)/app.pid"

CMDS=("curl" "forever" "gunzip" "node" "tar" "psql" "createdb" "createuser" "dropdb" "dropuser" "psql" "createdb" "createuser" "dropdb" "dropuser")
check_cmds CMDS[@]

################################################################################

create_user() {
  dropuser -U postgres --if-exists "$DB_USER" &> /dev/null
  createuser -U postgres --createdb "$DB_USER" &> /dev/null
  psql -U postgres -qd postgres -c "ALTER USER "$DB_USER" WITH PASSWORD '$DB_PASS';" &> /dev/null
  if [ $? != 0 ]; then
    echo "X Failed to create postgres user."
    exit 1
  else
    echo "√ Postgres user created successfully."
  fi
}

create_database() {
  dropdb --if-exists "$DB_NAME" &> /dev/null
  createdb "$DB_NAME" &> /dev/null
  if [ $? != 0 ]; then
    echo "X Failed to create postgres database."
    exit 1
  else
    echo "√ Postgres database created successfully."
  fi
}

populate_database() {
  psql -ltAq | grep -q "^$DB_NAME|" &> /dev/null
  if [ $? == 0 ]; then
    download_blockchain
    restore_blockchain
  fi
}

download_blockchain() {
  echo "Downloading blockchain snapshot..."
  curl -o blockchain.db.gz "https://downloads.lisk.io/lisk/$NETWORK/blockchain.db.gz" &> /dev/null
  if [ $? == 0 ] && [ -f blockchain.db.gz ]; then
    gunzip -q blockchain.db.gz &> /dev/null
  fi
  if [ $? != 0 ]; then
    rm -f blockchain.*
    echo "X Failed to download blockchain snapshot."
    exit 1
  else
    echo "√ Blockchain snapshot downloaded successfully."
  fi
}

restore_blockchain() {
  echo "Restoring blockchain..."
  if [ -f blockchain.db ]; then
    psql -qd "$DB_NAME" < blockchain.db &> /dev/null
  fi
  rm -f blockchain.*
  if [ $? != 0 ]; then
    echo "X Failed to restore blockchain."
    exit 1
  else
    echo "√ Blockchain restored successfully."
  fi
}

autostart_cron() {
  local cmd="crontab"

  command -v "$cmd" &> /dev/null

  if [ $? != 0 ]; then
    echo "X Failed to execute crontab."
    return 1
  fi

  crontab=$($cmd -l 2> /dev/null | sed '/lisk\.sh start/d' 2> /dev/null)

  crontab=$(cat <<-EOF
	$crontab
	@reboot $(command -v "bash") $(pwd)/lisk.sh start > $(pwd)/cron.log 2>&1
	EOF
  )

  printf "$crontab\n" | $cmd - &> /dev/null

  if [ $? != 0 ]; then
    echo "X Failed to update crontab."
    return 1
  else
    echo "√ Crontab updated successfully."
    return 0
  fi
}

coldstart_lisk() {
  stop_lisk &> /dev/null
  stop_postgresql &> /dev/null
  rm -rf $DB_DATA
  pg_ctl initdb -D $DB_DATA &> /dev/null
  start_postgresql
  sleep 1
  create_user
  create_database
  populate_database
  autostart_cron
  start_lisk
}

start_postgresql() {
  pg_ctl -D $DB_DATA -l $DB_LOG_FILE start &> /dev/null
  if [ $? != 0 ]; then
    echo "X Failed to start postgresql."
    exit 1
  fi
}

stop_postgresql() {
  pg_ctl -D $DB_DATA -l $DB_LOG_FILE stop &> /dev/null
}

start_lisk() {
  forever start -u lisk -a -l $LOG_FILE --pidFile $PID_FILE -m 1 app.js &> /dev/null
  if [ $? == 0 ]; then
    echo "√ Lisk started successfully."
  else
    echo "X Failed to start lisk."
  fi
}

stop_lisk() {
  forever stop lisk &> /dev/null
  if [ $? !=  0 ]; then
    echo "X Failed to stop lisk."
  else
    echo "√ Lisk stopped successfully."
  fi
}

rebuild_lisk() {
  create_database
  download_blockchain
  restore_blockchain
}

check_status() {
  if [ -f "$PID_FILE" ]; then
    local PID=$(cat "$PID_FILE")
  fi
  if [ ! -z "$PID" ]; then
    ps -p "$PID" > /dev/null 2>&1
    local STATUS=$?
  else
    local STATUS=1
  fi
  if [ -f $PID_FILE ] && [ ! -z "$PID" ] && [ $STATUS == 0 ]; then
    echo "√ Lisk is running (as process $PID)."
  else
    echo "X Lisk is not running."
  fi
}

tail_logs() {
  if [ -f "$LOG_FILE" ]; then
    tail -f "$LOG_FILE"
  fi
}

case $1 in
"coldstart")
  coldstart_lisk
  ;;
"start")
  start_postgresql
  sleep 1
  start_lisk
  ;;
"stop")
  stop_lisk
  stop_postgresql
  ;;
"restart")
  stop_lisk
  start_lisk
  ;;
"rebuild")
  stop_lisk
  rebuild_lisk
  start_lisk
  ;;
"status")
  check_status
  ;;
"logs")
  tail_logs
  ;;
*)
  echo "Error: Unrecognized command."
  echo ""
  echo "Available commands are: coldstart start stop restart rebuild status logs"
  ;;
esac
