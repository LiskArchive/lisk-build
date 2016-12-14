#!/bin/bash

# Variable Declaration
UNAME=$(uname)-$(uname -m)
DEFAULT_LISK_LOCATION=$(pwd)
DEFAULT_RELEASE=main
DEFAULT_SYNC=no
LOG_FILE=installLisk.out

#setup logging
exec > >(tee -ia $LOG_FILE)
exec 2>&1

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# Verification Checks
if [ "\$USER" == "root" ]; then
  echo "Error: Lisk should not be installed be as root. Exiting."
  exit 1
fi

prereq_checks() {
  echo -e "Checking prerequisites:"

  if [ -x "$(command -v curl)" ]; then
    echo -e "curl is installed.\t\t\t\t\t$(tput setaf 2)Passed$(tput sgr0)"
  else
    echo -e "\ncurl is not installed.\t\t\t\t\t$(tput setaf 1)Failed$(tput sgr0)"
      echo -e "\nPlease follow the Prerequisites at: https://lisk.io/documentation?i=lisk-docs/PrereqSetup"
    exit 2
  fi

  if [ -x "$(command -v tar)" ]; then
    echo -e "Tar is installed.\t\t\t\t\t$(tput setaf 2)Passed$(tput sgr0)"
  else
    echo -e "\ntar is not installed.\t\t\t\t\t$(tput setaf 1)Failed$(tput sgr0)"
      echo -e "\nPlease follow the Prerequisites at: https://lisk.io/documentation?i=lisk-docs/PrereqSetup"
    exit 2
  fi

  if [ -x "$(command -v wget)" ]; then
    echo -e "Wget is installed.\t\t\t\t\t$(tput setaf 2)Passed$(tput sgr0)"
  else
    echo -e "\nWget is not installed.\t\t\t\t\t$(tput setaf 1)Failed$(tput sgr0)"
    echo -e "\nPlease follow the Prerequisites at: https://lisk.io/documentation?i=lisk-docs/PrereqSetup"
    exit 2
  fi

  if sudo -n true 2>/dev/null; then
    echo -e "Sudo is installed and authenticated.\t\t\t$(tput setaf 2)Passed$(tput sgr0)"
  else
    echo -e "Sudo is installed.\t\t\t\t\t$(tput setaf 2)Passed$(tput sgr0)"
    echo "Please provide sudo password for validation"
    if sudo -Sv -p ''; then
      echo -e "Sudo authenticated.\t\t\t\t\t$(tput setaf 2)Passed$(tput sgr0)"
    else
      echo -e "Unable to authenticate Sudo.\t\t\t\t\t$(tput setaf 1)Failed$(tput sgr0)"
      echo -e "\nPlease follow the Prerequisites at: https://lisk.io/documentation?i=lisk-docs/PrereqSetup"
      exit 2
    fi
  fi

  echo -e "$(tput setaf 2)All preqrequisites passed!$(tput sgr0)"
}

# Adding LC_ALL LANG and LANGUAGE to user profile
if [[ -f ~/.profile && ! "$(grep "en_US.UTF-8" ~/.profile)" ]]; then
  echo "LC_ALL=en_US.UTF-8" >> ~/.profile
  echo "LANG=en_US.UTF-8"  >> ~/.profile
  echo "LANGUAGE=en_US.UTF-8"  >> ~/.profile
elif [[ -f ~/.bash_profile && ! "$(grep "en_US.UTF-8" ~/.bash_profile)" ]]; then
  echo "LC_ALL=en_US.UTF-8" >> ~/.bash_profile
  echo "LANG=en_US.UTF-8"  >> ~/.bash_profile
  echo "LANGUAGE=en_US.UTF-8"  >> ~/.bash_profile
fi

user_prompts() {
  [ "$LISK_LOCATION" ] || read -r -p "Where do you want to install Lisk to? (Default $DEFAULT_LISK_LOCATION): " LISK_LOCATION
  LISK_LOCATION=${LISK_LOCATION:-$DEFAULT_LISK_LOCATION}
  if [[ ! -r "$LISK_LOCATION" ]]; then
    echo "$LISK_LOCATION is not valid, please check and re-execute"
    exit 2;
  fi

  [ "$RELEASE" ] || read -r -p "Would you like to install the Main or Test Client? (Default $DEFAULT_RELEASE): " RELEASE
  RELEASE=${RELEASE:-$DEFAULT_RELEASE}
  if [[ ! "$RELEASE" == "main" && ! "$RELEASE" == "test" ]]; then
    echo "$RELEASE is not valid, please check and re-execute"
    exit 2;
  fi

  [ "$SYNC" ] || read -r -p "Would you like to synchronize from the Genesis Block? (Default $DEFAULT_SYNC): " SYNC
  SYNC=${SYNC:-$DEFAULT_SYNC}
  if [[ ! "$SYNC" == "no" && ! "$SYNC" == "yes" ]]; then
    echo "$SYNC is not valid, please check and re-execute"
    exit 2;
  fi
}

ntp_checks() {
  # Install NTP or Chrony for Time Management - Physical Machines only
  if [[ "$(uname)" == "Linux" ]]; then
    if [[ -f "/etc/debian_version" &&  ! -f "/proc/user_beancounters" ]]; then
      if sudo pgrep -x "ntpd" > /dev/null; then
        echo "√ NTP is running"
      else
        echo "X NTP is not running"
        [ "$INSTALL_NTP" ] || read -r -n 1 -p "Would like to install NTP? (y/n): " $REPLY
        if [[ "$INSTALL_NTP" || $REPLY =~ ^[Yy]$ ]]; then
          echo -e "\nInstalling NTP, please provide sudo password.\n"
          sudo apt-get install ntp -yyq
          sudo service ntp stop
          sudo ntpdate pool.ntp.org
          sudo service ntp start
          if sudo pgrep -x "ntpd" > /dev/null; then
            echo "√ NTP is running"
          else
            echo -e "\nLisk requires NTP running on Debian based systems. Please check /etc/ntp.conf and correct any issues."
            exit 0
          fi
        else
          echo -e "\nLisk requires NTP on Debian based systems, exiting."
          exit 0
        fi
      fi # End Debian Checks
    elif [[ -f "/etc/redhat-RELEASE" &&  ! -f "/proc/user_beancounters" ]]; then
      if sudo pgrep -x "ntpd" > /dev/null; then
        echo "√ NTP is running"
      else
        if sudo pgrep -x "chronyd" > /dev/null; then
          echo "√ Chrony is running"
        else
          echo "X NTP and Chrony are not running"
          [ "$INSTALL_NTP" ] || read -r -n 1 -p "Would like to install NTP? (y/n): " $REPLY
          if [[ "$INSTALL_NTP" || $REPLY =~ ^[Yy]$ ]]; then
            echo -e "\nInstalling NTP, please provide sudo password.\n"
            sudo yum -yq install ntp ntpdate ntp-doc
            sudo chkconfig ntpd on
            sudo service ntpd stop
            sudo ntpdate pool.ntp.org
            sudo service ntpd start
            if pgrep -x "ntpd" > /dev/null; then
              echo "√ NTP is running"
              else
              echo -e "\nLisk requires NTP running on Debian based systems. Please check /etc/ntp.conf and correct any issues."
              exit 0
            fi
          else
            echo -e "\nLisk requires NTP or Chrony on RHEL based systems, exiting."
            exit 0
          fi
        fi
      fi # End Redhat Checks
    elif [[ -f "/proc/user_beancounters" ]]; then
      echo "_ Running OpenVZ VM, NTP and Chrony are not required"
    fi
  elif [[ "$(uname)" == "FreeBSD" ]]; then
    if sudo pgrep -x "ntpd" > /dev/null; then
      echo "√ NTP is running"
    else
      echo "X NTP is not running"
      [ "$INSTALL_NTP" ] || read -r -n 1 -p "Would like to install NTP? (y/n): " $REPLY
      if [[ "$INSTALL_NTP" || $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\nInstalling NTP, please provide sudo password.\n"
        sudo pkg install ntp
        sudo sh -c "echo 'ntpd_enable=\"YES\"' >> /etc/rc.conf"
        sudo ntpdate -u pool.ntp.org
        sudo service ntpd start
        if pgrep -x "ntpd" > /dev/null; then
          echo "v NTP is running"
        else
          echo -e "\nLisk requires NTP running on FreeBSD based systems. Please check /etc/ntp.conf and correct any issues."
          exit 0
        fi
      else
        echo -e "\nLisk requires NTP FreeBSD based systems, exiting."
        exit 0
      fi
    fi # End FreeBSD Checks
  elif [[ "$(uname)" == "Darwin" ]]; then
    if pgrep -x "ntpd" > /dev/null; then
      echo "√ NTP is running"
    else
      sudo launchctl load /System/Library/LaunchDaemons/org.ntp.ntpd.plist
      sleep 1
      if pgrep -x "ntpd" > /dev/null; then
        echo "√ NTP is running"
      else
        echo -e "\nNTP did not start, Please verify its configured on your system"
        exit 0
      fi
    fi  # End Darwin Checks
  fi # End NTP Checks
}

install_lisk() {
  LISK_VERSION=lisk-$UNAME.tar.gz

  liskDir=`echo $LISK_VERSION | cut -d'.' -f1`

  echo -e "\nDownloading current Lisk binaries: "$LISK_VERSION

  curl --progress-bar -o $LISK_VERSION "https://downloads.lisk.io/lisk/$RELEASE/$LISK_VERSION"

  curl -s "https://downloads.lisk.io/lisk/$RELEASE/$LISK_VERSION.md5" -o $LISK_VERSION.md5

  if [[ "$(uname)" == "Linux" ]]; then
    md5=`md5sum $LISK_VERSION | awk '{print $1}'`
  elif [[ "$(uname)" == "FreeBSD" ]]; then
    md5=`md5 $LISK_VERSION | awk '{print $1}'`
  elif [[ "$(uname)" == "Darwin" ]]; then
    md5=`md5 $LISK_VERSION | awk '{print $4}'`
  fi

  md5_compare=`grep "$LISK_VERSION" $LISK_VERSION.md5 | awk '{print $1}'`

  if [[ "$md5" == "$md5_compare" ]]; then
    echo -e "\nChecksum Passed!"
  else
    echo -e "\nChecksum Failed, aborting installation"
    rm -f $LISK_VERSION $LISK_VERSION.md5
    exit 0
  fi

  echo -e "\nExtracting Lisk binaries to "$LISK_LOCATION/lisk-$RELEASE

  tar -xzf $LISK_VERSION -C $LISK_LOCATION

  mv $LISK_LOCATION/$liskDir $LISK_LOCATION/lisk-$RELEASE

  echo -e "\nCleaning up downloaded files"
  rm -f $LISK_VERSION $LISK_VERSION.md5
}

configure_lisk() {
  cd $LISK_LOCATION/lisk-$RELEASE

  echo -e "\nColdstarting Lisk for the first time"
  bash lisk.sh coldstart -l $LISK_LOCATION/lisk-$RELEASE/etc/blockchain.db.gz

  sleep 5 #we sleep here to allow the DAPP password to generate and write back to the config.json

  echo -e "\nStopping Lisk to perform database tuning"
  bash lisk.sh stop

  echo -e "\nExecuting database tuning operation"
  bash tune.sh
}

backup_lisk() {
  echo -e "\nStopping Lisk to perform a backup"
  cd $LISK_LOCATION/lisk-$RELEASE
  bash lisk.sh stop

  echo -e "\nBacking up existing Lisk Folder"

  if [[ -d "$LISK_LOCATION/backup/lisk-$RELEASE" ]]; then
    echo -e "\nRemoving old backup folder"
    rm -rf $LISK_LOCATION/backup/lisk-$RELEASE &> /dev/null
  fi

  mkdir -p $LISK_LOCATION/backup/ &> /dev/null
  mv -f $LISK_LOCATION/lisk-$RELEASE $LISK_LOCATION/backup/ &> /dev/null
}

start_lisk() { #Here we parse the various startup flags
  if [[ $REBUILD == true ]]; then
    if [[ $URL ]]; then
      echo -e "\nStarting Lisk with specified snapshot"
      cd $LISK_LOCATION/lisk-$RELEASE
      bash lisk.sh rebuild -u $URL
    else
      echo -e "\nStarting Lisk with official snapshot"
      cd $LISK_LOCATION/lisk-$RELEASE
      bash lisk.sh rebuild
    fi
  else
    if [[ "$SYNC" == "yes" ]]; then
        echo -e "\nStarting Lisk from genesis"
        bash lisk.sh rebuild -l etc/blockchain.db.gz
     else
       echo -e "\nStarting Lisk with current blockchain"
       cd $LISK_LOCATION/lisk-$RELEASE
       bash lisk.sh start
    fi
  fi
}

upgrade_lisk() {
  echo -e "\nRestoring Database to new Lisk Install"
  mkdir -p -m700 $LISK_LOCATION/lisk-$RELEASE/pgsql/data

  if [[ "$($LISK_LOCATION/backup/lisk-$RELEASE/pgsql/bin/postgres -V)" != "postgres (PostgreSQL) 9.6".* ]]; then
    echo -e "\nUpgrading database from PostgreSQL 9.5 to PostgreSQL 9.6"
    . "$LISK_LOCATION/lisk-$RELEASE/shared.sh"
    . "$LISK_LOCATION/lisk-$RELEASE/env.sh"
    pg_ctl initdb -D $LISK_LOCATION/lisk-$RELEASE/pgsql/data &>> $LOG_FILE
    $LISK_LOCATION/lisk-$RELEASE/pgsql/bin/pg_upgrade -b $LISK_LOCATION/backup/lisk-$RELEASE/pgsql/bin -B $LISK_LOCATION/lisk-$RELEASE/pgsql/bin -d $LISK_LOCATION/backup/lisk-$RELEASE/pgsql/data -D $LISK_LOCATION/lisk-$RELEASE/pgsql/data &>> $LOG_FILE
    bash $LISK_LOCATION/lisk-$RELEASE/lisk.sh start_db &>> $LOG_FILE
    bash $LISK_LOCATION/lisk-$RELEASE/analyze_new_cluster.sh &>> $LOG_FILE
    rm -f $LISK_LOCATION/lisk-$RELEASE/*cluster*
  else
    cp -rf $LISK_LOCATION/backup/lisk-$RELEASE/pgsql/data/* $LISK_LOCATION/lisk-$RELEASE/pgsql/data/
  fi

  echo -e "\nCopying config.json entries from previous installation"
  $LISK_LOCATION/lisk-$RELEASE/bin/node $LISK_LOCATION/lisk-$RELEASE/updateConfig.js -o $LISK_LOCATION/backup/lisk-$RELEASE/config.json -n $LISK_LOCATION/lisk-$RELEASE/config.json
}

log_rotate() {
  if [[ "$(uname)" == "Linux" ]]; then
    echo -e "\nConfiguring Logrotate for Lisk"
    sudo bash -c "cat > /etc/logrotate.d/lisk-$RELEASE-log << EOF_lisk-logrotate
    $LISK_LOCATION/lisk-$RELEASE/logs/*.log {
    create 666 $USER $USER
    weekly
    size=100M
    dateext
    copytruncate
    missingok
    rotate 2
    compress
    delaycompress
    notifempty
    }
EOF_lisk-logrotate" &> /dev/null
    fi
}

usage() {
  echo "Usage: $0 <install|upgrade> [-d <directory] [-r <main|test>] [-n] [-h [-u <URL>] ] "
  echo "install         -- install Lisk"
  echo "upgrade         -- upgrade Lisk"
  echo " -d <DIRECTORY> -- install location"
  echo " -r <RELEASE>   -- choose main or test"
  echo " -n             -- install ntp if not installed"
  echo " -h 	          -- rebuild instead of copying database"
  echo " -u <URL>       -- URL to rebuild from - Requires -h"
  echo " -0             -- Forces sync from 0"
}

parse_option() {
  OPTIND=2
  while getopts :d:r:u:hn0 opt; do
     case $opt in
       d) LISK_LOCATION=$OPTARG ;;
       r) RELEASE=$OPTARG ;;
       n) INSTALL_NTP=1 ;;
       h) REBUILD=true ;;
       u) URL=$OPTARG ;;
       0) SYNC=yes ;;
     esac
   done

  if [ "$RELEASE" ]; then
    if [[ "$RELEASE" != test && "$RELEASE" != "main" ]]; then
      echo "-r <test|main>"
      usage
      exit 1
    fi
  fi
}

case $1 in
"install")
  parse_option $@
  prereq_checks
  user_prompts
  ntp_checks
  install_lisk
  configure_lisk
  log_rotate
  start_lisk
  ;;
"upgrade")
  parse_option $@
  user_prompts
  backup_lisk
  install_lisk
  upgrade_lisk
  start_lisk
  ;;
*)
  echo "Error: Unrecognized command."
  echo ""
  echo "Available commands are: install upgrade"
  usage
  exit 1
  ;;
esac
