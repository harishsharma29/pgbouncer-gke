#!/bin/bash

set -euo pipefail

# changes in pgbouncer configuration file
cd /usr/src/pgbouncer
sed -i "s/host=localhost/host=$DB_HOST/g" pgbouncer.ini
sed -i "s/_password/$DB_PASS/g" userlist.txt

pgbouncer -R pgbouncer.ini -u postgres