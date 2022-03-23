#!/bin/bash

set -euo pipefail

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