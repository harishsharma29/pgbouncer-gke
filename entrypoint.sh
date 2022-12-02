#!/bin/bash

set -euo pipefail


if [ -z ${REDIS_SERVER+x} ]
    then
        echo "Running without redis server"
    else
        sed -i "s/bind 127.0.0.1 ::1/bind 0.0.0.0 ::1/g" /etc/redis/redis.conf
        sed -i "s/protected-mode yes/protected-mode no/g" /etc/redis/redis.conf
        if [ -z ${REDIS_PORT+x} ]
            then 
            REDIS_PORT=6379
        fi
        sed -i "s/port 6379/port $REDIS_PORT/g" /etc/redis/redis.conf
        redis-server /etc/redis/redis.conf
fi

# check env variables
if [ -z ${DB_HOST+x} ]
    then
        echo "Settings database host as localhost"
        DB_HOST=localhost
fi

if [ -z ${DB_PORT+x} ]
    then
        echo "Settings database port as 5432"
        DB_PORT=5432
fi

if [ -z ${DB_PASS+x} ]
    then
        echo "Database password is required, please set DB_PASS variable"
        exit 0
fi

if [ -z ${MAX_CONNECTIONS+x} ]
    then
        echo "Settings max client connections as 500"
        MAX_CONNECTIONS=500
fi

if [ -z ${LISTEN_PORT+x} ]
    then
        echo "Settings max listen port 6432"
        LISTEN_PORT=6432
fi

if [ -z ${DB_USER+x} ]
    then
        echo "Settings database user as postgres"
        DB_USER=postgres
fi

# changes in pgbouncer configuration file
cd /usr/src/pgbouncer
sed -i "s/_db_host/$DB_HOST/g" pgbouncer.ini
sed -i "s/_db_port/$DB_PORT/g" pgbouncer.ini
sed -i "s/_db_user/$DB_USER/g" pgbouncer.ini
sed -i "s/_max_client_conn/$MAX_CONNECTIONS/g" pgbouncer.ini
sed -i "s/_listen_port/$LISTEN_PORT/g" pgbouncer.ini
sed -i "s/_password/$DB_PASS/g" userlist.txt
sed -i "s/_db_user/$DB_USER/g" userlist.txt

# setup new pgbouncer server on another port for replica in move that in background
if [ -z ${REPLICA_DB_HOST+x} ]
    then
        pgbouncer -R pgbouncer.ini -u postgres
    else
        echo "USERS LIST $(cat userlist.txt)"
        echo "STARTING SERVER $(cat pgbouncer.ini | grep *=host)"
        echo "STARTING SERVER ON PORT $(cat pgbouncer.ini | grep listen_port)"
        pgbouncer -R pgbouncer.ini -u postgres &
        git checkout .

        sed -i "s/_db_host/$REPLICA_DB_HOST/g" pgbouncer.ini
        sed -i "s/_max_client_conn/$MAX_CONNECTIONS/g" pgbouncer.ini

        if [ -z ${REPLICA_DB_PORT+x} ]
            then
            echo "Using same port: $DB_PORT for replica server..."
            sed -i "s/_db_port/$DB_PORT/g" pgbouncer.ini
            else
            echo "setting up port: $REPLICA_DB_PORT"
            sed -i "s/_db_port/$REPLICA_DB_PORT/g" pgbouncer.ini
        fi

        if [ -z ${REPLICA_DB_USER+x} ]
            then
            echo "Using same user: $DB_USER for replica server..."
            sed -i "s/_db_user/$DB_USER/g" pgbouncer.ini
            sed -i "s/_db_user/$DB_USER/g" userlist.txt
            else
            echo "setting up user: $REPLICA_DB_USER"
            sed -i "s/_db_user/$REPLICA_DB_USER/g" pgbouncer.ini
            sed -i "s/_db_user/$REPLICA_DB_USER/g" userlist.txt
        fi

        if [ -z ${REPLICA_DB_PASS+x} ]
            then
            echo "Using same password: $DB_PASS for replica server..."
            sed -i "s/_password/$DB_PASS/g" userlist.txt
            else
            echo "setting up password: $REPLICA_DB_PASS"
            sed -i "s/_password/$REPLICA_DB_PASS/g" userlist.txt
        fi

        REPLICA_LISTEN_PORT=$(( $LISTEN_PORT + 1 ))
        sed -i "s/_listen_port/$REPLICA_LISTEN_PORT/g" pgbouncer.ini
        sed -i "s/pgbouncer.log/pgbouncer_$REPLICA_LISTEN_PORT.log/g" pgbouncer.ini
        sed -i "s/pgbouncer.pid/pgbouncer_$REPLICA_LISTEN_PORT.pid/g" pgbouncer.ini

        echo "USERS LIST $(cat userlist.txt)"
        echo "STARTING REPLICA SERVER $(cat pgbouncer.ini | grep *=host)"
        echo "STARTING REPLICA SERVER ON PORT $(cat pgbouncer.ini | grep listen_port)"
        pgbouncer -R pgbouncer.ini -u postgres
fi