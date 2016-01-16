#!/bin/bash

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
. "$(pwd)/shared.sh"

if [ ! -f "$(pwd)/app.js" ]; then
  echo "Error: Lisk installation was not found. Aborting."
  exit 1
fi

PATH="$(pwd)/bin:/usr/bin:/bin:/usr/local/bin"
LOG_FILE="$(pwd)/app.log"
PID_FILE="$(pwd)/app.pid"

CMDS=("curl" "node" "sqlite3" "unzip")
check_cmds CMDS[@]

################################################################################

start_forever() {
  (
    download_blockchain
    until node app.js; do
      echo "Lisk exited with code $?. Respawning..." >&2
      sleep 3
    done
  )
}

stop_forever() {
  local PID=$(cat "$PID_FILE")
  if [ ! -z "$PID" ]; then
    kill -- -$(ps -o pgid= "$PID" | grep -o '[0-9]\+') > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "Stopped process $PID"
    else
      echo "Failed to stop process $PID"
    fi
  fi
  rm -f "$PID_FILE"
}

start_lisk() {
  echo "Starting lisk..."
  if [ -f "$PID_FILE" ]; then
    stop_forever
  fi
  rm -f "$LOG_FILE" logs.log
  touch "$LOG_FILE" logs.log
  start_forever > "$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  echo "Started process $!"
}

download_blockchain() {
  if [ ! -f "blockchain.db" ]; then
    echo "Downloading blockchain snapshot..."
    curl -o blockchain.db.zip "http://downloads.liskchain.me/blockchain.db.zip"
    [ $? -eq 1 ] || unzip blockchain.db.zip
    [ $? -eq 0 ] || rm -f blockchain.db
    rm -f blockchain.db.zip
  fi
}

stop_lisk() {
  echo "Stopping lisk..."
  if [ -f "$PID_FILE" ]; then
    stop_forever
  else
    echo "Lisk is not running."
  fi
}

rebuild_lisk() {
  echo "Rebuilding lisk..."
  rm -f "$LOG_FILE" logs.log
  touch "$LOG_FILE" logs.log
  rm -f blockchain.db*
}

autostart_lisk() {
  autostart_cron
}

autostart_cron() {
  local cmd="crontab"

  command -v "$cmd" &> /dev/null

  if [ $? -eq 1 ]; then
    echo "Failed to execute crontab."
    return 1
  fi

  crontab=$($cmd -l 2> /dev/null | sed '/lisk\.sh start/d' 2> /dev/null)

  crontab=$(cat <<-EOF
	$crontab
	@reboot $(command -v "bash") $(pwd)/lisk.sh start > $(pwd)/cron.log 2>&1
	EOF
  )

  printf "$crontab\n" | $cmd - 2> /dev/null

  if [ $? -eq 0 ]; then
    echo "Crontab updated successfully."
    return 0
  else
    echo "Failed to update crontab."
    return 1
  fi
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
  if [ -f $PID_FILE ] && [ ! -z "$PID" ] && [ $STATUS -eq 0 ]; then
    echo "Lisk is running (as process $PID)."
  else
    echo "Lisk is not running."
  fi
}

tail_logs() {
  if [ -f "$LOG_FILE" ]; then
    tail -f "$LOG_FILE"
  fi
}

case $1 in
"start")
  start_lisk
  ;;
"stop")
  stop_lisk
  ;;
"restart")
  stop_lisk
  start_lisk
  ;;
"autostart")
  autostart_lisk
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
  echo "Available commands are: start stop restart autostart rebuild status logs"
  ;;
esac
