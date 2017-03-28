#!/bin/bash

# shellcheck disable=SC2129

cd "$(cd -P -- "$(dirname -- "$0")" && pwd -P)" || exit 2
# shellcheck disable=SC1090
. "$(pwd)/shared.sh"
# shellcheck disable=SC1090
. "$(pwd)/env.sh"

if [ ! -f "$(pwd)/app.js" ]; then
  echo "Error: Lisk installation was not found. Exiting."
  exit 1
fi

if [ "$USER" == "root" ]; then
  echo "Error: Lisk should not be run be as root. Exiting."
  exit 1
fi

LISK_CONFIG="config.json"
PM2_CONFIG="$(pwd)/etc/pm2-lisk.json"
PM2_APP="$(grep "name" "$PM2_CONFIG" | cut -d'"' -f4)" >> /dev/null

LOGS_DIR="$(pwd)/logs"

DB_NAME="$(grep "database" "$LISK_CONFIG" | cut -f 4 -d '"')"
DB_USER="$USER"
DB_PASS="password"
DB_DATA="$(pwd)/pgsql/data"
DB_LOG_FILE="$LOGS_DIR/pgsql.log"
DB_SNAPSHOT="blockchain.db.gz"
DB_DOWNLOAD=Y

SH_LOG_FILE="$LOGS_DIR/lisk.out"

# Setup logging
exec > >(tee -ia "$SH_LOG_FILE")
exec 2>&1

################################################################################

blockheight() {
  DB_HEIGHT="$(psql -d "$DB_NAME" -t -c 'select height from blocks order by height desc limit 1;')"
  HEIGHT="${DB_HEIGHT:- Unavailable}"
  echo -e "Current Block Height:" "$HEIGHT"
}

network() {
  # shellcheck disable=SC2143
  if [ "$(grep "da3ed6a45429278bac2666961289ca17ad86595d33b31037615d4b8e8f158bba" "$LISK_CONFIG" )" ];then
    NETWORK="test"
  elif [ "$(grep "ed14889723f24ecc54871d058d98ce91ff2f973192075c0155ba2b7b70ad2511" "$LISK_CONFIG")" ];then
    NETWORK="main"
  else
    NETWORK="local"
  fi
  echo -e 'Lisk configured for '"$NETWORK"' network\n' >> "$SH_LOG_FILE" 2>&1
}

create_user() {
  # shellcheck disable=SC2129
  dropuser --if-exists "$DB_USER" >> "$SH_LOG_FILE" 2>&1
  createuser --createdb "$DB_USER" >> "$SH_LOG_FILE" 2>&1
  psql -qd postgres -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASS';" >> "$SH_LOG_FILE" 2>&1
  if [ $? != 0 ]; then
    echo "X Failed to create Postgresql user."
    exit 1
  else
    echo "√ Postgresql user created successfully."
  fi
}

create_database() {
  # shellcheck disable=SC2129
  dropdb --if-exists "$DB_NAME" >> "$SH_LOG_FILE" 2>&1
  createdb "$DB_NAME" >> "$SH_LOG_FILE" 2>&1
  if [ $? != 0 ]; then
    echo "X Failed to create Postgresql database."
    exit 1
  else
    echo "√ Postgresql database created successfully."
  fi
}

populate_database() {
  psql -ltAq | grep -q "^$DB_NAME|" >> "$SH_LOG_FILE" 2>&1
  if [ $? == 0 ]; then
    download_blockchain
    restore_blockchain
  fi
}

download_blockchain() {
  if [ "$DB_DOWNLOAD" = "Y" ]; then
    rm -f "$DB_SNAPSHOT"
    if [ "$BLOCKCHAIN_URL" = "" ]; then
      BLOCKCHAIN_URL="https://downloads.lisk.io/lisk/$NETWORK"
    fi
    echo '√ Downloading '"$DB_SNAPSHOT"' from '"$BLOCKCHAIN_URL"
    curl --progress-bar -o "$DB_SNAPSHOT" "$BLOCKCHAIN_URL/$DB_SNAPSHOT"
    # Required to clean up ugly curl output in the logs
    sed -i -e '/[#]/d' "$SH_LOG_FILE"
    if [ $? != 0 ]; then
      rm -f "$DB_SNAPSHOT"
      echo "X Failed to download blockchain snapshot."
      exit 1
    else
      echo "√ Blockchain snapshot downloaded successfully."
    fi
  else
    echo -e "√ Using Local Snapshot."
  fi
}

restore_blockchain() {
  echo 'Restoring blockchain with '"$DB_SNAPSHOT"
  gunzip -fcq "$DB_SNAPSHOT" | psql -q -U "$DB_USER" -d "$DB_NAME" >> "$SH_LOG_FILE" 2>&1
  if [ $? != 0 ]; then
    echo "X Failed to restore blockchain."
    exit 1
  else
    echo "√ Blockchain restored successfully."
  fi
}

autostart_cron() {
  local cmd="crontab"

  command -v "$cmd" > /dev/null 2>&1

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

  printf "%s\n" "$crontab" | $cmd - >> "$SH_LOG_FILE" 2>&1

  if [ $? != 0 ]; then
    echo "X Failed to update crontab."
    return 1
  else
    echo "√ Crontab updated successfully."
    return 0
  fi
}

coldstart_lisk() {
  stop_lisk >> "$SH_LOG_FILE" 2>&1
  stop_postgresql >> "$SH_LOG_FILE" 2>&1
  rm -rf "$DB_DATA"
  pg_ctl initdb -D "$DB_DATA" >> "$SH_LOG_FILE" 2>&1
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
  if pgrep -x "postgres" > /dev/null 2>&1; then
    echo "√ Postgresql is running."
  else
    pg_ctl -D "$DB_DATA" -l "$DB_LOG_FILE" start >> "$SH_LOG_FILE" 2>&1
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
  STOP_PG=0
  if ! pgrep -x "postgres" > /dev/null 2>&1; then
    echo "√ Postgresql is not running."
  else
   while [[ $STOP_PG -lt 5 ]] >> "$SH_LOG_FILE" 2>&1; do
      pg_ctl -D "$DB_DATA" -l "$DB_LOG_FILE" stop >> "$SH_LOG_FILE" 2>&1
      if [ $? == 0 ]; then
        echo "√ Postgresql stopped successfully."
        break
      else
        echo "X Postgresql failed to stop."
      fi
      sleep 1
      STOP_PG=$((STOP_PG+1))
    done
    if pgrep -x "postgres" >> "$SH_LOG_FILE" 2>&1; then
      pkill -x postgres -9 >> "$SH_LOG_FILE" 2>&1;
      echo "√ Postgresql Killed."
    fi
  fi
}

start_lisk() {
  pm2 start "$PM2_CONFIG"  >> "$SH_LOG_FILE"
  if [ $? == 0 ]; then
    echo "√ Lisk started successfully."
    check_status
  else
    echo "X Failed to start Lisk."
  fi
  
 if [ -f /etc/debian_version &&  ! -f /proc/user_beancounters]; then
   if pgrep -x "ntpd" > /dev/null
   then
      echo "√ ntp is running"
   else
      echo "X ntp is not running"
      read -r -n 1 -p "Would like to install ntp? (y/n): " $REPLY
      if [[  $REPLY =~ ^[Yy]$ ]]
      then
        sudo apt-get update
        sudo apt-get install ntp -y
        sudo service ntp stop
        sudo ntpdate pool.ntp.org
        sudo service ntp start
      fi
   fi
 elif [ -f /etc/redhat-release &&  ! -f /proc/user_beancounters]; then
   if pgrep -x "ntpd" > /dev/null
   then
      echo "√ ntp is running"
   else
      if pgrep -x "chronyd" > /dev/null
      then
      	echo "√ chrony is running"
      else
      	echo "X ntp and chrony are not running"
      	read -r -n 1 -p "Would like to install ntp? (y/n): " $REPLY
      	if [[  $REPLY =~ ^[Yy]$ ]]
      	then
	  yum install ntp ntpdate ntp-doc
	  chkconfig ntpd on
	  ntpdate pool.ntp.org
	  /etc/init.d/ntpd start
      	fi
      fi
   fi
 elif [ -f /proc/user_beancounters]; then
   echo "_ Running OpenVZ VM"
 fi
}

stop_lisk() {
  pm2 delete "$PM2_CONFIG" >> "$SH_LOG_FILE"
  echo "√ Lisk stopped successfully."
}

reload_lisk() {
  echo "Stopping Lisk to reload PM2 config"
  pm2 delete "$PM2_CONFIG" >> "$SH_LOG_FILE"
  start_lisk
}

rebuild_lisk() {
  create_database
  download_blockchain
  restore_blockchain
}

check_status() {
  PM2_PID="$(pm2 describe "$PM2_APP" | grep "pid path" | cut -d' ' -f14)" >> "$SH_LOG_FILE" 2>&1> /dev/null

  pm2 describe "$PM2_APP" >> "$SH_LOG_FILE"

  check_pid
  if [ "$STATUS" -eq 0  ]; then
    echo "√ Lisk is running as PID: $PID"
    blockheight
  else
    echo "X Lisk is not running"
    exit 1
  fi
}

check_pid() {
  if [ -f "$PM2_PID" ]; then
  read -r PID < "$PM2_PID" 2>&1 > /dev/null
  fi
  if [ ! -z "$PID" ]; then
    ps -p "$PID" > /dev/null 2>&1
    STATUS=$?
  else
    STATUS=1
  fi
}

tail_logs() {
  pm2 logs "$PM2_APP"
}

help() {
  echo -e "\nCommand Options for Lisk.sh"
  echo -e "\nAll options may be passed [-p <PM2-config.json>]"
  echo -e "\nstart_node                            Starts a Nodejs process for Lisk"
  echo -e "start                                 Starts the Nodejs process and PostgreSQL Database for Lisk"
  echo -e "stop_node                             Stops a Nodejs process for Lisk"
  echo -e "stop                                  Stop the Nodejs process and PostgreSQL Database for Lisk"
  echo -e "reload                                Restarts the Nodejs process for Lisk"
  echo -e "rebuild [-u URL] [-f file.db.gz] [-0] Rebuilds the PostgreSQL database"
  echo -e "start_db                              Starts the PostgreSQL database"
  echo -e "stop_db                               Stops the PostgreSQL database"
  echo -e "coldstart                             Creates the PostgreSQL database and configures config.json for Lisk"
  echo -e "logs                                  Displays and tails logs for Lisk"
  echo -e "status                                Displays the status of the PID associated with Lisk"
  echo -e "help                                  Displays this message"
}


parse_option() {
  OPTIND=2
  while getopts ":p:f:u:l:0" OPT; do
    case "$OPT" in
      p)
        if [ -f "$OPTARG" ]; then
          PM2_CONFIG="$OPTARG"
          PM2_APP="$(grep "name" "$PM2_CONFIG" | cut -d'"' -f4)"
        else
          echo "PM2-config.json not found. Please verify the file exists and try again."
          exit 1
        fi ;;

      u)
        BLOCKCHAIN_URL="$OPTARG"
        ;;

      f)
        DB_SNAPSHOT="$OPTARG"
        if [ -f "$OPTARG" ]; then
          DB_DOWNLOAD=N
        fi ;;

      0)
        DB_SNAPSHOT="$(pwd)/etc/blockchain.db.gz"
        DB_DOWNLOAD=N
        ;;

       :) echo 'Missing option argument for -'"$OPTARG" >&2; exit 1;;

       *) echo 'Unimplemented option: -'"$OPTARG" >&2; exit 1;;
    esac
  done
}

parse_option "$@"
network

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
  reload_lisk
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

# Required to clean up colour characters that don't translate well from tee
sed -i -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g" "$SH_LOG_FILE"
