#!/bin/bash
#############################################################
# Postgres Memory Tuning for Lisk                           #
# by: Isabella Dell                                         #
# Date: 16/05/2016                                          #
#                                                           #
#                                                           #
#############################################################

#Copying template into pgsql/data folder
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

  if [[ "$(uname)" == "FreeBSD" ]]; then
    sed -I .temp "s#mc#$max_connections#g" ./pgsql/data/postgresql.conf
    sed -I .temp "s#sb#$shared_buffers#g" ./pgsql/data/postgresql.conf
    sed -I .temp "s#ecs#$effective_cache_size#g" ./pgsql/data/postgresql.conf
    sed -I .temp "s#wmem#$work_mem#g" ./pgsql/data/postgresql.conf
    sed -I .temp "s#mwm#$maintenance_work_mem#g" ./pgsql/data/postgresql.conf
    sed -I .temp "s#minws#$min_wal_size#g" ./pgsql/data/postgresql.conf
    sed -I .temp "s#maxws#$max_wal_size#g" ./pgsql/data/postgresql.conf
    sed -I .temp "s#cct#$checkpoint_completion_target#g" ./pgsql/data/postgresql.conf
    sed -I .temp "s#wb#$wal_buffers#g" ./pgsql/data/postgresql.conf
    sed -I .temp "s#dst#$default_statistics_target#g" ./pgsql/data/postgresql.conf
  fi

  #### UNTESTED
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
  fi
}

if [[ "$(uname)" == "Linux" ]]; then
  memoryBase=`cat /proc/meminfo | grep MemTotal | awk '{print $2 / 1024 }' | cut -f1 -d"."`
fi

if [[ "$(uname)" == "FreeBSD" ]]; then
  memoryBase=`sysctl hw.physmem | awk '{print $2 / 1024 / 1024}' |cut -f1 -d"."`
fi

### UNTESTED
if [[ "$(uname)" == "Darwin" ]]; then
  memoryBase=`top -l 1 | grep PhysMem: | awk '{print $10  / 1024  / 1024 }' |cut -f1 -d"."`
fi

if [[ "$memoryBase" -lt "1024" ]]; then
  max_connections=50
  shared_buffers=64MB
  effective_cache_size=256MB
  work_mem=10922kB
  maintenance_work_mem=64MB
  min_wal_size=100MB
  max_wal_size=100MB
  checkpoint_completion_target=0.7
  wal_buffers=2MB
  default_statistics_target=100
  update_config
  exit 0
fi

if [[ "$memoryBase" -lt "2048"  && "$memoryBase" -gt "1024" ]]; then
  max_connections=200
  shared_buffers=128MB
  effective_cache_size=512MB
  work_mem=21845kB
  maintenance_work_mem=128MB
  min_wal_size=100MB
  max_wal_size=100MB
  checkpoint_completion_target=0.7
  wal_buffers=4MB
  default_statistics_target=100
  update_config
  exit 0
fi

if [[ "$memoryBase" -lt "4096" && "$memoryBase" -gt "2048" ]]; then
  max_connections=200
  shared_buffers=512MB
  effective_cache_size=1GB
  work_mem=43690kB
  maintenance_work_mem=256MB
  min_wal_size=100MB
  max_wal_size=100MB
  checkpoint_completion_target=0.7
  wal_buffers=8MB
  default_statistics_target=100
  update_config
  exit 0
fi

if [[ "$memoryBase" -lt "8192" && "$memoryBase" -gt "4096" ]]; then
  max_connections=200
  shared_buffers=1GB
  effective_cache_size=2GB
  work_mem=87381kB
  maintenance_work_mem=512MB
  min_wal_size=100MB
  max_wal_size=100MB
  checkpoint_completion_target=0.7
  wal_buffers=16MB
  default_statistics_target=100
  update_config
  exit 0
fi

if [[ "$memoryBase" -gt "8192" ]]; then
  max_connections=200
  shared_buffers=2GB
  effective_cache_size=4GB
  work_mem=174762kB
  maintenance_work_mem=1GB
  min_wal_size=100MB
  max_wal_size=100MB
  checkpoint_completion_target=0.7
  wal_buffers=16MB
  default_statistics_target=100
  update_config
  exit 0
fi
