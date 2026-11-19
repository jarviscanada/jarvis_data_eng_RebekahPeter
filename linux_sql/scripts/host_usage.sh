#!/bin/sh
# Script will collect hardware usage data and insert the data into psql instance
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
vmstat_mb=$(vmstat --unit M)

# Get and store usage info on host
memory_free=$(echo "$vmstat_mb" | tail -n1 | awk '{print $4}')
cpu_idle=$(echo "$vmstat_mb"  | tail -n1 | awk '{print $15}')
cpu_kernel=$(echo "$vmstat_mb" | tail -n1 | awk '{print $14}')
disk_io=$(vmstat -d | tail -n1 | awk '{print $10}')
disk_available=$(df -BM / | tail -n1 | awk '{print $4}'| sed 's/M// ')
timestamp=$(date +"%F %T")
host_id="(SELECT id FROM host_info WHERE hostname='$hostname')"

# Create statement and insert data into host_usage table
export PGPASSWORD=$psql_password
insert_stmt="INSERT INTO host_usage (timestamp, host_id, memory_free, cpu_idle, cpu_kernel, disk_io, disk_available)
            VALUES('$timestamp', $host_id, '$memory_free', '$cpu_idle', '$cpu_kernel', '$disk_io', '$disk_available');"
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"

exit $?