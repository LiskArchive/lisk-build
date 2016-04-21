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

CMDS=("curl" "node" "psql" "unzip")
check_cmds CMDS[@]

################################################################################

start_forever() {
  forever start -u lisk -a -l $LOG_FILE --pidFile $PID_FILE -m 1 app.js
}

stop_forever() {
  forever stop lisk
}

start_lisk() {
  echo "Starting lisk..."
  rm -f "$LOG_FILE" logs.log
  touch "$LOG_FILE" logs.log
  start_forever
}

stop_lisk() {
  echo "Stopping lisk..."
  stop_forever
}

rebuild_lisk() {
  echo "Rebuilding lisk..."
  rm -f "$LOG_FILE" logs.log
  touch "$LOG_FILE" logs.log
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
