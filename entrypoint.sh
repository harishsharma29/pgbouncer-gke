#!/bin/bash

set -euo pipefail

# Function to update pgbouncer configurations
update_pgbouncer_config() {
    sed -i "s/$1/$2/g" /usr/src/pgbouncer/pgbouncer.ini
};

# Function to update user credentials
update_userlist() {
    sed -i "s/$1/$2/g" /usr/src/pgbouncer/userlist.txt
};

# Check and update Redis configurations
if [ -n "${REDIS_SERVER+x}" ]; then
    echo "Running with Redis Server"
    sed -i -e 's/bind 127.0.0.1 ::1/bind 0.0.0.0 ::1/g' \
           -e 's/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf
    [ -z "${REDIS_PORT+x}" ] && REDIS_PORT=6379
    sed -i "s/port 6379/port $REDIS_PORT/g" /etc/redis/redis.conf
    redis-server /etc/redis/redis.conf
else
    echo "Running without Redis server"
fi

# Set database connection variables if not passed then store default values
: ${DB_HOST:=localhost}
: ${DB_PORT:=5432}
: ${DB_USER:=postgres}
: ${MAX_CONNECTIONS:=500}
: ${LISTEN_PORT:=6432}

# Check and set database password
if [ -z "${DB_PASS+x}" ]; then
    echo "Database password is required, please set DB_PASS variable"
    exit 0
fi

# Update pgbouncer configurations
update_pgbouncer_config "_db_host" "$DB_HOST"
update_pgbouncer_config "_db_port" "$DB_PORT"
update_pgbouncer_config "_db_user" "$DB_USER"
update_pgbouncer_config "_max_client_conn" "$MAX_CONNECTIONS"
update_pgbouncer_config "_listen_port" "$LISTEN_PORT"

# update user list password and username
update_userlist "_db_user" "$DB_USER"
update_userlist "_password" "$DB_PASS"

# starting pg bouncer server
echo "Starting PG Bouncer Server: $(cat /usr/src/pgbouncer/pgbouncer.ini | grep *=host)"
echo "Starting PG Bouncer Server on Port: $(cat /usr/src/pgbouncer/pgbouncer.ini | grep listen_port)"
echo "User credentials are: $(cat /usr/src/pgbouncer/userlist.txt)"

# Setup replica server if REPLICA_DB_HOST is set
if [ -n "${REPLICA_DB_HOST+x}" ]; then
    pgbouncer -R /usr/src/pgbouncer/pgbouncer.ini -u postgres &
    # reset all files
    git checkout .

    : ${REPLICA_DB_PORT:=$DB_PORT}
    : ${REPLICA_DB_USER:=$DB_USER}
    : ${REPLICA_DB_PASS:=$DB_PASS}
    REPLICA_LISTEN_PORT=$((LISTEN_PORT + 1))

    # Update pgbouncer configurations
    update_pgbouncer_config "_db_host" "$REPLICA_DB_HOST"
    update_pgbouncer_config "_db_port" "$REPLICA_DB_PORT"
    update_pgbouncer_config "_db_user" "$REPLICA_DB_USER"
    update_pgbouncer_config "_max_client_conn" "$MAX_CONNECTIONS"
    update_pgbouncer_config "_listen_port" "$REPLICA_LISTEN_PORT"

    # update log file names
    sed -i "s/pgbouncer.log/pgbouncer_$REPLICA_LISTEN_PORT.log/g" /usr/src/pgbouncer/pgbouncer.ini
    sed -i "s/pgbouncer.pid/pgbouncer_$REPLICA_LISTEN_PORT.pid/g" /usr/src/pgbouncer/pgbouncer.ini
    
    # update user list password and username
    update_userlist "_db_user" "$REPLICA_DB_USER"
    update_userlist "_password" "$REPLICA_DB_PASS"

    echo "Starting Replica Server: $(cat /usr/src/pgbouncer/pgbouncer.ini | grep *=host)"
    echo "Starting Replica Server on Port: $(cat /usr/src/pgbouncer/pgbouncer.ini | grep listen_port)"
    echo "User credentials are: $(cat /usr/src/pgbouncer/userlist.txt)"
    pgbouncer -R /usr/src/pgbouncer/pgbouncer.ini -u postgres

    # if replica server is not needed then run main server only
    else
        pgbouncer -R /usr/src/pgbouncer/pgbouncer.ini -u postgres
fi
