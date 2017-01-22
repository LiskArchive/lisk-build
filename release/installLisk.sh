#!/bin/bash
#############################################################
# Lisk Installation Script                                  #
# by: Isabella Dell                                         #
# Date: 03/08/2016                                          #
#                                                           #
#                                                           #
#                                                           #
#############################################################

# Variable Declaration
UNAME=$(uname)-$(uname -m)
defaultLiskLocation=$(pwd)
defaultRelease=main

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
    echo -e "Curl is installed.\t\t\t\t\t$(tput setaf 2)Passed$(tput sgr0)"
  else
    echo -e "\nCurl is not installed.\t\t\t\t\t$(tput setaf 1)Failed$(tput sgr0)"
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
  [ "$liskLocation" ] || read -r -p "Where do you want to install Lisk to? (Default $defaultLiskLocation): " liskLocation
  liskLocation=${liskLocation:-$defaultLiskLocation}
  if [[ ! -r "$liskLocation" ]]; then
    echo "$liskLocation is not valid, please check and re-execute"
    exit 2;
  fi

  [ "$release" ] || read -r -p "Would you like to install the Main or Test Client? (Default $defaultRelease): " release
  release=${release:-$defaultRelease}
  if [[ ! "$release" == "main" && ! "$release" == "test" ]]; then
    echo "$release is not valid, please check and re-execute"
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
        [ "$installNtp" ] || read -r -n 1 -p "Would like to install NTP? (y/n): " $REPLY
        if [[ "$installNtp" || $REPLY =~ ^[Yy]$ ]]; then
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
    elif [[ -f "/etc/redhat-release" &&  ! -f "/proc/user_beancounters" ]]; then
      if sudo pgrep -x "ntpd" > /dev/null; then
        echo "√ NTP is running"
      else
        if sudo pgrep -x "chronyd" > /dev/null; then
          echo "√ Chrony is running"
        else
          echo "X NTP and Chrony are not running"
          [ "$installNtp" ] || read -r -n 1 -p "Would like to install NTP? (y/n): " $REPLY
          if [[ "$installNtp" || $REPLY =~ ^[Yy]$ ]]; then
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
      [ "$installNtp" ] || read -r -n 1 -p "Would like to install NTP? (y/n): " $REPLY
      if [[ "$installNtp" || $REPLY =~ ^[Yy]$ ]]; then
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
  liskVersion=lisk-$UNAME.tar.gz

  liskDir=`echo $liskVersion | cut -d'.' -f1`

  echo -e "\nDownloading current Lisk binaries: "$liskVersion

  curl -s "https://downloads.lisk.io/lisk/$release/$liskVersion" -o $liskVersion

  curl -s "https://downloads.lisk.io/lisk/$release/$liskVersion.md5" -o $liskVersion.md5

  if [[ "$(uname)" == "Linux" ]]; then
    md5=`md5sum $liskVersion | awk '{print $1}'`
  elif [[ "$(uname)" == "FreeBSD" ]]; then
    md5=`md5 $liskVersion | awk '{print $1}'`
  elif [[ "$(uname)" == "Darwin" ]]; then
    md5=`md5 $liskVersion | awk '{print $4}'`
  fi

  md5_compare=`grep "$liskVersion" $liskVersion.md5 | awk '{print $1}'`

  if [[ "$md5" == "$md5_compare" ]]; then
    echo -e "\nChecksum Passed!"
  else
    echo -e "\nChecksum Failed, aborting installation"
    rm -f $liskVersion $liskVersion.md5
    exit 0
  fi

  echo -e "\nExtracting Lisk binaries to "$liskLocation/lisk-$release

  tar -xzf $liskVersion -C $liskLocation

  mv $liskLocation/$liskDir $liskLocation/lisk-$release

  echo -e "\nCleaning up downloaded files"
  rm -f $liskVersion $liskVersion.md5
}

configure_lisk() {
  cd $liskLocation/lisk-$release

  echo -e "\nColdstarting Lisk for the first time"
  bash lisk.sh coldstart -l $liskLocation/lisk-$release/etc/blockchain.db.gz

  sleep 5

  echo -e "\nStopping Lisk to perform database tuning"
  bash lisk.sh stop

  echo -e "\nExecuting database tuning operation"
  bash tune.sh

  log_rotate

  echo -e "\nStarting Lisk with all parameters in place"
  if [[ $url ]]; then
      bash lisk.sh rebuild -u $url
   else
      bash lisk.sh rebuild
   fi
}

backup_lisk() {
  echo -e "\nStopping Lisk to perform a backup"
  cd $liskLocation/lisk-$release
  bash lisk.sh stop

  echo -e "\nBacking up existing Lisk Folder"

  if [[ -d "$liskLocation/backup/lisk-$release" ]]; then
    echo -e "\nRemoving old backup folder"
    rm -rf $liskLocation/backup/lisk-$release &> /dev/null
  fi

  mkdir -p $liskLocation/backup/ &> /dev/null
  mv -f $liskLocation/lisk-$release $liskLocation/backup/ &> /dev/null
}

upgrade_lisk() {
  echo -e "\nRestoring Database to new Lisk Install"
  mkdir -p -m700 $liskLocation/lisk-$release/pgsql/data

  if [[ "$($liskLocation/backup/lisk-$release/pgsql/bin/postgres -V)" != "postgres (PostgreSQL) 9.6".* ]]; then
    echo -e "\nUpgrading database from PostgreSQL 9.5 to PostgreSQL 9.6"
    . "$liskLocation/lisk-$release/shared.sh"
    . "$liskLocation/lisk-$release/env.sh"
    pg_ctl initdb -D $liskLocation/lisk-$release/pgsql/data &> /dev/null
    $liskLocation/lisk-$release/pgsql/bin/pg_upgrade -b $liskLocation/backup/lisk-$release/pgsql/bin -B $liskLocation/lisk-$release/pgsql/bin -d $liskLocation/backup/lisk-$release/pgsql/data -D $liskLocation/lisk-$release/pgsql/data  &> /dev/null
    pgUpgrade=true
  else
    cp -rf $liskLocation/backup/lisk-$release/pgsql/data/* $liskLocation/lisk-$release/pgsql/data/
  fi

  echo -e "\nCopying config.json entries from previous installation"
  $liskLocation/lisk-$release/bin/node $liskLocation/lisk-$release/updateConfig.js -o $liskLocation/backup/lisk-$release/config.json -n $liskLocation/lisk-$release/config.json

  if [[ -e "$liskLocation/backup/lisk-$release/snapshot.json" ]]; then
    echo -e "\nCopying snapshot.json file from previous installation"
    cp $liskLocation/backup/lisk-$release/snapshot.json $liskLocation/lisk-$release/
	fi

  log_rotate

  if [[ $rebuild == true ]]; then
    if [[ $url ]]; then
      echo -e "\nStarting Lisk with snapshot"
      cd $liskLocation/lisk-$release
      bash lisk.sh rebuild -u $url 
    else
      echo -e "\nStarting Lisk with snapshot"
      cd $liskLocation/lisk-$release
      bash lisk.sh rebuild 
    fi
  else
   echo -e "\nStarting Lisk"
   cd $liskLocation/lisk-$release
   bash lisk.sh start
  fi

  if [[ $pgUpgrade == true ]]; then
    bash $liskLocation/lisk-$release/analyze_new_cluster.sh &> /dev/null
    rm -f $liskLocation/lisk-$release/*cluster*  &> /dev/null
  fi
}

log_rotate() {
  if [[ "$(uname)" == "Linux" ]]; then
    echo -e "\nConfiguring Logrotate for Lisk"
    sudo bash -c "cat > /etc/logrotate.d/lisk-$release-log << EOF_lisk-logrotate
    $liskLocation/lisk-$release/logs/*.log {
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
  echo "Usage: $0 <install|upgrade> [-d <directory] [-r <main|test>] [-n] [-h] [-u <url>]"
  echo "install         -- install Lisk"
  echo "upgrade         -- upgrade Lisk"
  echo " -d <directory> -- install location"
  echo " -r <release>   -- choose main or test"
  echo " -n             -- install ntp if not installed"
  echo " -h 	        -- rebuild instead of copying database"
  echo " -u <url>       -- URL to rebuild from"
}

parse_option() {
  OPTIND=2
  while getopts :d:r:u:hn opt; do
     case $opt in
       d) liskLocation=$OPTARG ;;
       r) release=$OPTARG ;;
       n) installNtp=1 ;;
       h) rebuild=true ;;
       u) url=$OPTARG ;;
     esac
   done

  if [ "$release" ]; then
    if [[ "$release" != test && "$release" != "main" ]]; then
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
  ;;
"upgrade")
  parse_option $@
  user_prompts
  backup_lisk
  install_lisk
  upgrade_lisk
  ;;
*)
  echo "Error: Unrecognized command."
  echo ""
  echo "Available commands are: install upgrade"
  usage
  exit 1
  ;;
esac
