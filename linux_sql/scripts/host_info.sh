#!/bin/sh
# Script will collect hardware specification data and insert the data into psql instance
# Setup arguments
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# Validate # of parameters
  if [ "$#" -ne 5 ]; then
    echo 'Illegal number of parameters, 5 are needed: Host, port, database name, psql user, and psql password.'
    exit 1
  fi

# Save hostname and cpu info to variables
hostname=$(hostname -f)
specs=`lscpu`
vmstat_mb=$(vmstat --unit M)

# Get and store hardware info on host
cpu_number=$(echo "$specs" | egrep "^CPU\(s\):" | awk '{print $2}' | xargs)
cpu_architecture=$(echo "$specs" | egrep "^Architecture:" | awk '{print $2}' | xargs)
cpu_model=$(echo "$specs" | egrep "Model name:" | awk -F':' '{print $2}' | xargs)
cpu_mhz=$(echo "$specs" | egrep "Model name:" | awk '{printf "%.2f",$NF*1000}' | sed 's/GHz//'| xargs)
l2_cache=$(echo "$specs" | egrep "L2" | awk -F':' '{print $2}' | awk '{print $1}' | xargs)
timestamp=$(date +"%F %T")
total_mem=$(echo "$vmstat_mb" | tail -1 | awk '{print $4}')

# Create statement and insert data into host_info table
export PGPASSWORD=$psql_password
insert_stmt="INSERT INTO host_info (hostname, cpu_number, cpu_architecture, cpu_model, cpu_mhz, l2_cache, timestamp, total_mem) VALUES('$hostname', '$cpu_number', '$cpu_architecture', '$cpu_model', '$cpu_mhz', '$l2_cache', '$timestamp', '$total_mem');"
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"

exit $?