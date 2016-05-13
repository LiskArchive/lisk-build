#!/bin/bash
####################################################
#Lisk Installation Script
# by Isabella D.
#
#
#
#
####################################################

#Variable Declaration
UNAME=$(uname)-$(uname -m)
defaultLiskLocation=~

#Verification Checks
if [ "$USER" == "root" ]; then
  echo "Error: Lisk should not be installed be as root. Exiting."
  exit 1
fi

user_prompts() {
read -r -p "Where do you want to install Lisk to? (Default $defaultLiskLocation):  " liskLocation
liskLocation=${liskLocation:-$defaultLiskLocation}
if [[ ! -r "$liskLocation" ]]
then
echo "$liskLocation is not valid, please check and re-excute"
exit 2;
fi
}

install_prereqs() {
if [[ -f "/etc/redhat-release" ]]; then
	sudo yum -yq install curl tar 
fi

if [[ -f "/etc/debian_version" ]]; then
	sudo apt-get update
	sudo apt-get install -yyq curl tar 
fi
if [[ "$(uname)" == "FreeBSD" ]]; then
	sudo pkg install curl tar 
fi

}
  
ntp_checks() {
#Install NTP or Chrony for Time Management - Physical Machines only
if [[ "$(uname)" == "Linux" ]]; then
 if [[ -f "/etc/debian_version" &&  ! -f "/proc/user_beancounters" ]]; then
   if pgrep -x "ntpd" > /dev/null
    then
      echo "√ NTP is running"
    else
      echo "X NTP is not running"
      read -r -n 1 -p "Would like to install NTP? (y/n): " $REPLY
	  if [[  $REPLY =~ ^[Yy]$ ]]
		then
		echo -e "\nInstalling NTP, please provide sudo password.\n"
        sudo apt-get install ntp -yyq
        sudo service ntp stop
        sudo ntpdate pool.ntp.org
        sudo service ntp start
			if pgrep -x "ntpd" > /dev/null
				then
					echo "√ NTP is running"
				else
					echo -e "\nLisk requires NTP running on Debian based systems. Please check /etc/ntp.conf and correct any issues."
					exit 0
			fi
		else
		echo -e "\nLisk requires NTP on Debian based systems, exiting."
		exit 0
	  fi
   fi #End Debian Checks
   
 elif [[ -f "/etc/redhat-release" &&  ! -f "/proc/user_beancounters" ]]; then
   if pgrep -x "ntpd" > /dev/null
   then
      echo "√ NTP is running"
   else
      if pgrep -x "chronyd" > /dev/null
      then
        echo "√ Chrony is running"
      else
        echo "X NTP and Chrony are not running"
        read -r -n 1 -p "Would like to install NTP? (y/n): " $REPLY
        if [[  $REPLY =~ ^[Yy]$ ]]
        then
        	echo -e "\nInstalling NTP, please provide sudo password.\n"
      		sudo yum -yq install ntp ntpdate ntp-doc
		sudo chkconfig ntpd on
		sudo service ntpd stop
		sudo ntpdate pool.ntp.org
		sudo service ntpd start
		if pgrep -x "ntpd" > /dev/null
			then
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
   fi #End Redhat Checks
   
 elif [[ -f "/proc/user_beancounters" ]]; then
   echo "_ Running OpenVZ VM, NTP and Chrony are not required"
 fi
elif [[ "$(uname)" == "FreeBSD" ]]; then
	if pgrep -x "ntpd" > /dev/null
	   then
		  echo "√ NTP is running"
	   else
		  echo "X NTP is not running"
		  read -r -n 1 -p "Would like to install NTP? (y/n): " $REPLY
		  if [[  $REPLY =~ ^[Yy]$ ]]
		  then
		  echo -e "\nInstalling NTP, please provide sudo password.\n"
		  sudo pkg install ntp
		  sudo sh -c "echo 'ntpd_enable=\"YES\"' >> /etc/rc.conf"
		  sudo ntpdate -u pool.ntp.org
		  sudo service ntpd start
			if pgrep -x "ntpd" > /dev/null
				then
					echo "√ NTP is running"
				else
					echo -e "\nLisk requires NTP running on FreeBSD based systems. Please check /etc/ntp.conf and correct any issues."
					exit 0
			fi
		  else
		  echo -e "\nLisk requires NTP FreeBSD based systems, exiting."
		  exit 0
	    fi
    fi #End FreeBSD Checks
elif [[ "$(uname)" == "Darwin" ]]; then
	if pgrep -x "ntpd" > /dev/null
	   then
		    echo "√ NTP is running"
	   else
			sudo launchctl load /System/Library/LaunchDaemons/org.ntp.ntpd.plist
			sleep 1
			if pgrep -x "ntpd" > /dev/null
				then
					echo "√ NTP is running"
				else
				echo -e "\nNTP did not start, Please verify its configured on your system"
				exit 0
			fi
	fi	#End Darwin Checks
fi #End NTP Checks
}

install_lisk() {
	
liskVersion=`curl -s https://downloads.lisk.io/lisk/test/ | grep $UNAME | cut -d'"' -f2`
liskDir=`echo $liskVersion | cut -d'.' -f1`

echo -e "\nDownloading current Lisk binaries: "$liskVersion

curl -s https://downloads.lisk.io/lisk/test/$liskVersion -o $liskVersion

#Disabled until file is present
#curl -s https://downloads.lisk.iso/lisk/test/lisk_checksum.md5 -o lisk_checksum.md5

#md5=`md5sum $liskVersion | awk '{print $1}'`
#md5_compare=`grep "$liskVersion" lisk_checksum.md5 | awk '{print $1}'`

#if [[ "$md5" == "$md5_compare" ]]; then
#echo "Checksum Passed!"
#else
#echo "Checksum Failed, aborting installation"
#rm -f $liskVersion lisk_checksum.md5
#exit 0
#fi

echo -e "Extracting Lisk binaries to "$liskLocation/lisk

tar -xzf $liskVersion -C $liskLocation 

mv $liskDir $liskLocation/lisk

echo -e "\nCleaning up downloaded files"
rm -f $liskVersion lisk_checksum.md5

cd $liskLocation/lisk

echo -e "\nColdstarting Lisk for the first time"
bash lisk.sh coldstart

echo -e "\nStopping Lisk to perform database tuning"
bash lisk.sh stop


rm -f $liskLocation/lisk/pgsql/data/postgresql.conf
cp ./postgresql.conf $liskLocation/lisk/pgsql/data/postgresql.conf

echo -e "\nExecuting database tuning operation"
bash $liskLocation/lisk/tune.sh

echo -e "\nStarting Lisk with all parameters in place."
bash lisk.sh start

sleep 5
blockHeight=`curl -s http://localhost:7000/api/loader/status/sync | cut -d: -f5 | cut -d} -f1`

echo -e "\nCurrent Block Height: " $blockHeight
}

upgrade_lisk() {
	echo "Not supported yet"
}

case $1 in
"install")
  user_prompts
  ntp_checks
  install_prereqs
  install_lisk
  ;;
  "upgrade")
  upgrade_lisk
  ;;
*)
  echo "Error: Unrecognized command."
  echo ""
  echo "Available commands are: install upgrade"
  ;;
esac


