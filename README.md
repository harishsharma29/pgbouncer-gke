# PgBoucner

  Lightweight connection pooler for PostgreSQL

## Prerequisite
  
  - docker (can be downloaded from "https://docs.docker.com/engine/install")
  - gcloud cli (can be installed by following "https://cloud.google.com/sdk/docs/install")

## Create Dcoker build

  To Create docker build use following command

    docker run build -t tagname .

## Consume docker images on local machine

  check images hash using below command
    
    docker images

  To run pgbouncer in docker container need to pass two env variables. 

    docker run -it -e DB_HOST=localhot -e DB_PASS=admin imageshash

## Deployment in gcloud containers

  - Run gcloud-deploy.sh script, This will build and upload the container to google container registry.
    
    bash gcloud-deploy.sh

  - Once done you have create kubernetes cluster in Google Kubernetes Engine.

  - Then you have to dpeloy new workload, while deploying it will ask for for image path you can click on select and choose lastest images from `gcr.io/project-id/pgbouncer`.

  - Then you have to add two `Environment variables`, 

    DB_HOST=127.0.0.1 (host of you psql instance)
    DB_PASS=admin (password for you psql database)

  - After deployments go in workload section in GKE and open newely created conatainer, choose expose service from actions.

  - PgBoucner is running on port `6432` this has to be exposed, so fill `6432` in port and choose ip type as `Load balancer`.

  This will create on load balancer external IP, we need to chage this IP as interanl IP. For that:

  - Go in to `Services & Ingress` Section of GKE, select and edit load balancer service.
  - In edit YMAL add `​cloud.google.com/load-balancer-type: Internal` in `metodata > annotations` like this:
      

          apiVersion: v1
          kind: Service
          metadata:
            annotations:
              cloud.google.com/load-balancer-type: Internal
              cloud.google.com/neg: '{"ingress":true}'
          creationTimestamp: "2022-03-21T16:12:58Z"

  You have to create as many deployments as you have psql instances including replica instances.

  For example if you have 1 PSQL instance and with 2 replica instance then you have to deploy 3 (1 psql + 2 replica) workloads. For this you can use same image.

  > After deployments you have to changes db host in gcloud run services with the exposed service IP