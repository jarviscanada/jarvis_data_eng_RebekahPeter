#!/bin/sh

# Capture CLI arguments
cmd=$1
db_username=$2
db_password=$3

# Start docker
# check to see the docker status, if it returns not a success (meaning it's not started yet, then
# run cmd on right of pipe, starting the docker
sudo systemctl status docker || sudo systemctl start docker

# Check container status
# to reduce the output in inspect, I piped inspect to display
# just the line with the id, if there was no container created, then error
docker container inspect jrvs-psql | grep Id
container_status=$?

# User switch case to handle create|stop|start operations
# if cmd given was create
case $cmd in
  create)

  # Check if the container is already created
  if [ $container_status -eq 0 ]; then
		echo 'Container already exists'
		exit 1
	fi

  # Check # of CLI arguments
  if [ $# -ne 3 ]; then
    echo 'Create requires username and password'
    exit 1
  fi

  # checks have all passed, so
	# create a new volume if not exist
  docker volume create pgdata

  # Create container
  docker run --name jrvs-psql -e POSTGRES_USER="$db_username" -e POSTGRES_PASSWORD="$db_password" -d -v pgdata:/var/lib/postgresql/data -p 5432:5432 postgres:9.6-alpine

  # $? pulls the exit status from the last run command, 0 indicating that starting container succeeded
  # non zero indicating failure
	exit $?
	;;

  start|stop)
  # Check instance status; exit 1 if container has not been created
  if [ $container_status -eq 1 ]; then
    echo 'Container has not been created'
  	exit 1
  fi

  # Start or stop the container
	docker container $cmd jrvs-psql
	exit $?
	;;

  *)
	echo 'Illegal command'
	echo 'Commands: start|stop|create'
	exit 1
	;;
esac