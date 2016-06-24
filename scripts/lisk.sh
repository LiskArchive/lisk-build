#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
. "$(pwd)/shared.sh"
. "$(pwd)/env.sh"

if [ ! -f "$(pwd)/app.js" ]; then
  echo "Error: Lisk installation was not found. Exiting."
  exit 1
fi

if [ "$USER" == "root" ]; then
  echo "Error: Lisk should not be run be as root. Exiting."
  exit 1
fi

UNAME=$(uname)
NETWORK="test"
LISK_CONFIG=${2:-config.json}
CONFIG_NAME=`echo $LISK_CONFIG | cut -f 1 -d '.'`

DB_NAME=`grep "database" $LISK_CONFIG | awk --field-separator='"' '{print $2}'| cut -f 2 -d '"'`
DB_USER=$USER
DB_PASS="password"
DB_DATA="$(pwd)/pgsql/data"
DB_LOG_FILE="$(pwd)/log/pgsql.log"

LOG_FILE="$(pwd)/log/$CONFIG_NAME.app.log"
PID_FILE="$(pwd)/pid/$CONFIG_NAME.pid"

CMDS=("curl" "forever" "gunzip" "node" "tar" "psql" "createdb" "createuser" "dropdb" "dropuser")
check_cmds CMDS[@]

################################################################################

create_user() {
  dropuser --if-exists "$DB_USER" &> /dev/null
  createuser --createdb "$DB_USER" &> /dev/null
  psql -qd postgres -c "ALTER USER "$DB_USER" WITH PASSWORD '$DB_PASS';" &> /dev/null
  if [ $? != 0 ]; then
    echo "X Failed to create Postgresql user."
    exit 1
  else
    echo "√ Postgresql user created successfully."
  fi
}

create_database() {
  dropdb --if-exists "$DB_NAME" &> /dev/null
  createdb "$DB_NAME" &> /dev/null
  if [ $? != 0 ]; then
    echo "X Failed to create Postgresql database."
    exit 1
  else
    echo "√ Postgresql database created successfully."
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
  sleep 2
  start_postgresql
  sleep 1
  create_user
  create_database
  populate_database
  autostart_cron
  start_lisk
}

start_postgresql() {
  if pgrep -x "postgres" &> /dev/null; then
    echo "√ Postgresql is running."
  else
    pg_ctl -D $DB_DATA -l $DB_LOG_FILE start &> /dev/null
    sleep 1
    if [ $? != 0 ]; then
      echo "X Failed to start Postgresql."
      exit 1
    else
      echo "√ Postgresql started successfully."
    fi
  fi
}

stop_postgresql() {
  stopPg=0
  if ! pgrep -x "postgres" &> /dev/null; then
    echo "√ Postgresql is not running."
  else
   while [[ $stopPg < 5 ]] &> /dev/null; do
      pg_ctl -D $DB_DATA -l $DB_LOG_FILE stop &> /dev/null
      if [ $? == 0 ]; then
        echo "√ Postgresql stopped successfully."
        break
      else
        echo "X Postgresql failed to stop."
      fi
      sleep .5
      stopPg=$[$stopPg+1]
    done
    if pgrep -x "postgres" &> /dev/null; then
      pkill -x postgres -9  &> /dev/null;
      echo "√ Postgresql Killed."
    fi
  fi
}

start_lisk() {
  if check_status == 1 &> /dev/null; then
    check_status
    exit 1
  else
    forever start -u lisk -a -l $LOG_FILE --pidFile $PID_FILE -m 1 app.js -c $LISK_CONFIG &> /dev/null
    if [ $? == 0 ]; then
      echo "√ Lisk started successfully."
    else
      echo "X Failed to start lisk."
    fi
  fi
}

stop_lisk() {
  if check_status != 1 &> /dev/null; then
    stopLisk=0
    while [[ $stopLisk < 5 ]] &> /dev/null; do
      forever stop -t $PID  &> /dev/null
      if [ $? !=  0 ]; then
        echo "X Failed to stop lisk."
      else
        echo "√ Lisk stopped successfully."
        break
      fi
      sleep .5
      stopLisk=$[$stopLisk+1]
    done
  else
    echo "√ Lisk is not running."
  fi
}

rebuild_lisk() {
  create_database
  download_blockchain
  restore_blockchain
}

check_status() {
  if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
  fi
  if [ ! -z "$PID" ]; then
    ps -p "$PID" > /dev/null 2>&1
    STATUS=$?
  else
    STATUS=1
  fi
  if [ -f $PID_FILE ] && [ ! -z "$PID" ] && [ $STATUS == 0 ]; then
    echo "√ Lisk is running (as process $PID)."
    return 0
  else
    echo "X Lisk is not running."
    return 1
  fi
}

tail_logs() {
  if [ -f "$LOG_FILE" ]; then
    tail -f "$LOG_FILE"
  fi
}

help() {
  echo -e "\nCommand Options for Lisk.sh"
  echo -e "\nstart_node <config.json>\t\t\tStarts the Nodejs process for Lisk"
  echo -e "start <config.json>\t\t\tStarts the Nodejs process and PostgreSQL Database for Lisk"
  echo -e "stop_node <config.json>\t\t\tStops the Nodejs process for Lisk"
  echo -e "stop <config.json>\t\t\tStop the Nodejs process and PostgreSQL Database for Lisk"
  echo -e "reload <config.json>\t\t\tRestarts the Nodejs process for Lisk"
  echo -e "rebuild <config.json>\t\t\tRebuilds the PostgreSQL database"
  echo -e "start_db <config.json>\t\t\tStarts the PostgreSQL database"
  echo -e "stop_db <config.json>\t\t\tStops the PostgreSQL database"
  echo -e "coldstart\t\t\t\tCreates the PostgreSQL database and configures config.json for Lisk"
  echo -e "logs <config.json>\t\t\tTails the log file for the supplied config.json"
  echo -e "status <config.json>\t\t\tDisplays the status for the supplied config.json"
  echo -e "help\t\t\t\t\tDisplays this message"
}


case $1 in
"coldstart")
  coldstart_lisk
  ;;
"start_node")
  start_lisk
  ;;
"start")
  start_postgresql
  sleep 2
  start_lisk
  ;;
"stop_node")
  stop_lisk
  ;;
"stop")
  stop_lisk
  stop_postgresql
  ;;
"reload")
  stop_lisk
  start_lisk
  ;;
"rebuild")
  stop_lisk
  sleep 1
  start_postgresql
  sleep 1
  rebuild_lisk
  start_lisk
  ;;
"start_db")
  start_postgresql
  ;;
"stop_db")
  stop_postgresql
  ;;
"status")
  check_status
  ;;
"logs")
  tail_logs
  ;;
"help")
  help
  ;;
*)
  echo "Error: Unrecognized command."
  echo ""
  echo "Available commands are: start stop start_node stop_node start_db stop_db reload rebuild coldstart logs status help"
  help
  ;;
esac
