#!/bin/bash

set -euo pipefail

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
        echo "Settings max client connections as 500"
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
if [ ${REPLICA_DB_HOST+x} ]
    then
        sed -i "s/$DB_HOST/$REPLICA_DB_HOST/g" pgbouncer.ini
        REPLICA_LISTEN_PORT=$(( $LISTEN_PORT + 1 ))
        sed -i "s/$LISTEN_PORT/$REPLICA_LISTEN_PORT/g" pgbouncer.ini
        echo "STARTING REPLICA SERVER FOR DATABASE HOST $DB_HOST..."
        pgbouncer -R pgbouncer.ini -u postgres &
        echo "REPLICA SERVER STARTED ON PORT $REPLICA_LISTEN_PORT..."
fi

sed -i "s/$REPLICA_DB_HOST/$DB_HOST/g" pgbouncer.ini
sed -i "s/$REPLICA_LISTEN_PORT/$LISTEN_PORT/g" pgbouncer.ini
pgbouncer -R pgbouncer.ini -u postgres