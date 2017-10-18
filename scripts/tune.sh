#!/bin/bash
#############################################################
# Postgres Memory Tuning for Lisk                           #
# by: Isabella Dell                                         #
# Date: 16/05/2016                                          #
#                                                           #
#                                                           #
#############################################################

if [[ "$(uname)" == "Linux" ]]; then
	# shellcheck disable=SC2002
	# Erreoneous assumption about meminfo as a script
	MEMORY_BASE=$(cat /proc/meminfo | grep MemTotal | awk '{print $2 }' | cut -f1 -d".")
fi

if [[ "$(uname)" == "Darwin" ]]; then
	MEMORY_BASE=$(top -l 1 | grep PhysMem: | awk '{print $10}' |cut -f1 -d".")
fi

if [[ "$MEMORY_BASE" -lt "1310720" ]]; then
echo "Not enough ram, taking defaults."
exit 0
fi

# Copying template into pgsql/data folder
rm -f ./pgsql/data/postgresql.conf
cp ./etc/postgresql.conf ./pgsql/data/postgresql.conf

if [ ! -d ./pgsql/data ]; then
	echo "Failed to open ./pgsql/data folder"
	exit 1
elif [ ! -f ./pgsql/data/postgresql.conf ]; then
	echo "Failed to open ./pgsql/data/postgresql.conf"
	exit 1
fi

update_config() {
	if [[ "$(uname)" == "Linux" ]]; then
		sed -i "s#mc#$max_connections#g" ./pgsql/data/postgresql.conf
		sed -i "s#sb#$shared_buffers#g" ./pgsql/data/postgresql.conf
		sed -i "s#ecs#$effective_cache_size#g" ./pgsql/data/postgresql.conf
		sed -i "s#wmem#$work_mem#g" ./pgsql/data/postgresql.conf
		sed -i "s#mwm#$maintenance_work_mem#g" ./pgsql/data/postgresql.conf
		sed -i "s#minws#$min_wal_size#g" ./pgsql/data/postgresql.conf
		sed -i "s#maxws#$max_wal_size#g" ./pgsql/data/postgresql.conf
		sed -i "s#cct#$checkpoint_completion_target#g" ./pgsql/data/postgresql.conf
		sed -i "s#wb#$wal_buffers#g" ./pgsql/data/postgresql.conf
		sed -i "s#dst#$default_statistics_target#g" ./pgsql/data/postgresql.conf
		echo "Updates completed"
	fi

	if [[ "$(uname)" == "Darwin" ]]; then
		sed -i "s#mc#$max_connections#g" ./pgsql/data/postgresql.conf
		sed -i "s#sb#$shared_buffers#g" ./pgsql/data/postgresql.conf
		sed -i "s#ecs#$effective_cache_size#g" ./pgsql/data/postgresql.conf
		sed -i "s#wmem#$work_mem#g" ./pgsql/data/postgresql.conf
		sed -i "s#mwm#$maintenance_work_mem#g" ./pgsql/data/postgresql.conf
		sed -i "s#minws#$min_wal_size#g" ./pgsql/data/postgresql.conf
		sed -i "s#maxws#$max_wal_size#g" ./pgsql/data/postgresql.conf
		sed -i "s#cct#$checkpoint_completion_target#g" ./pgsql/data/postgresql.conf
		sed -i "s#wb#$wal_buffers#g" ./pgsql/data/postgresql.conf
		sed -i "s#dst#$default_statistics_target#g" ./pgsql/data/postgresql.conf
		echo "Updates completed"
	fi
}


# Hard code memory limit for systems above 16gb
if [[ "$MEMORY_BASE" -gt 16777216 ]]; then
	MEMORY_BASE=16777216
fi

max_connections=200
shared_buffers=$(( MEMORY_BASE / 4))'kB'
effective_cache_size=$(( MEMORY_BASE  / 4))'kB'
work_mem=$(( (MEMORY_BASE - ( MEMORY_BASE / 4 ))/ (max_connections * 3  )))'kB'
maintenance_work_mem=$(( MEMORY_BASE / 16 ))'kB'
min_wal_size=1GB
max_wal_size=2GB
checkpoint_completion_target=0.9
wal_buffers=16MB
default_statistics_target=100

update_config
