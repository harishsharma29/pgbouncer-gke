#!/bin/bash

set -euo pipefail

res=$(echo `gcloud --version`)

if [ -z "${res}" ]
    then
        echo "Gcloud is not installed. Exiting..."
        exit 0
fi

res=$(echo `docker version`)

if [ -z "${res}" ]
    then
        echo "docker is not installed. Exiting..."
        exit 0
fi

# getting gcloud project id
gcloudproject=$(gcloud config list --format 'value(core.project)')
oldimages=$(docker images --filter=reference="gcr.io/$gcloudproject/pgbouncer" -q)

# deleting old images if exists
if [ "${oldimages}" ]
    then
        echo "Deleting old images..."
        docker rmi -f $oldimages
fi

# creaing docker build and push image into into gcr
docker build -t gcr.io/$gcloudproject/pgbouncer .
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://gcr.io
docker push gcr.io/$gcloudproject/pgbouncer