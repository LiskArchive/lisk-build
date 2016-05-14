#!/bin/bash
#############################################################
# Postgres Memory Tuning for Lisk                           #
# by: Isabella D.
#
#
#
#############################################################

update_config() {
  if [[ "$(uname)" == "Linux" ]]; then
    cp ./pgsql/data/postgresql.conf ./pgsql/data/postgresql.conf.bak
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
    cp ./pgsql/data/postgresql.conf ./pgsql/data/postgresql.conf.bak
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
    cp ./pgsql/data/postgresql.conf ./pgsql/data/postgresql.conf.bak
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

if [[ -f "./pgsql/data/postgresql.conf.bak" ]]; then
  cp -f ./pgsql/data/postgresql.conf.bak ./pgsql/data/postgresql.conf
fi

if [[ "$(uname)" == "Linux" ]]; then
  memoryBase=`cat /proc/meminfo | grep MemTotal | awk '{print $2 / 1024 /4}' | cut -f1 -d"."`
  echo $memoryBase
fi

if [[ "$(uname)" == "FreeBSD" ]]; then
  memoryBase=`sysctl hw.physmem | awk '{print $2 / 1024 / 1024/ 4}' |cut -f1 -d"."`
  echo $memoryBase
fi

### UNTESTED
if [[ "$(uname)" == "Darwin" ]]; then
  memoryBase=`top -l 1 | grep PhysMem: | awk '{print $10  / 1024  / 1024 /  4 }' |cut -f1 -d"."`
  echo $memoryBase
fi

if [[ "$memoryBase" -lt "1024" ]]; then
  max_connections=200
  shared_buffers=1GB
  effective_cache_size=3GB
  work_mem=5242kB
  maintenance_work_mem=256MB
  min_wal_size=1GB
  max_wal_size=2GB
  checkpoint_completion_target=0.7
  wal_buffers=16MB
  default_statistics_target=100
  update_config
  exit 0
fi

if [[ "$memoryBase" -lt "2048"  && "$memoryBase" -gt "1024" ]]; then
  max_connections=200
  shared_buffers=2GB
  effective_cache_size=6GB
  work_mem=10485kB
  maintenance_work_mem=512MB
  min_wal_size=1GB
  max_wal_size=2GB
  checkpoint_completion_target=0.7
  wal_buffers=16MB
  default_statistics_target=100
  update_config
  exit 0
fi

if [[ "$memoryBase" -lt "4096" && "$memoryBase" -gt "2048" ]]; then
  max_connections=200
  shared_buffers=4GB
  effective_cache_size=12GB
  work_mem=20971kB
  maintenance_work_mem=1GB
  min_wal_size=1GB
  max_wal_size=2GB
  checkpoint_completion_target=0.7
  wal_buffers=16MB
  default_statistics_target=100
  update_config
  exit 0
fi

if [[ "$memoryBase" -lt "8192" && "$memoryBase" -gt "4096" ]]; then
  max_connections=200
  shared_buffers=8GB
  effective_cache_size=24GB
  work_mem=41943kB
  maintenance_work_mem=2GB
  min_wal_size=1GB
  max_wal_size=2GB
  checkpoint_completion_target=0.7
  wal_buffers=16MB
  default_statistics_target=100
  update_config
  exit 0
fi

if [[ "$memoryBase" -gt "8192" ]]; then
  max_connections=200
  shared_buffers=16GB
  effective_cache_size=48GB
  work_mem=83886kB
  maintenance_work_mem=2GB
  min_wal_size=1GB
  max_wal_size=2GB
  checkpoint_completion_target=0.7
  wal_buffers=16MB
  default_statistics_target=100
  update_config
  exit 0
fi
