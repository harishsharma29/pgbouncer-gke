# Running pgbouncer and Redis Instances in Docker Containers

This guide outlines the steps to set up pgbouncer (PostgreSQL connection pooler) and Redis instances inside Docker containers using a provided Bash script.

## Prerequisites

- Docker: Make sure you have Docker installed on your system. You can download and install Docker from [here](https://www.docker.com/get-started).

## Instructions

1. Clone the Repository:

    ```bash
    git clone <repository_url>
    cd <repository_directory>
    ```

2. Modify Environment Variables (Optional):

    Open the `run-pgbouncer.sh` script and modify the environment variables to suit your requirements. The script allows you to customize various settings such as Redis configuration, database connection details, and more.

3. Build Docker Images:

    Run the following commands to build Docker images for pgbouncer and Redis:

    ```bash
    docker build -t pgbouncer-redis .
    ```

4. Run Docker Containers:

    Use the following command to start the Docker containers:

    ```bash
    docker run -d --name pgbouncer-redis-container -e DB_PASS=admin pgbouncer-redis
    ```

    This will start both the pgbouncer and Redis containers.

5. Verify Containers:

    To verify that the containers are running, you can use the following commands:

    ```bash
    docker ps
    ```

    You should see both the pgbouncer and Redis containers listed.

6. Access pgbouncer and Redis:

    You can access pgbouncer and Redis using their respective ports. By default, pgbouncer is configured to listen on port 6432, and Redis is configured to listen on port 6379.

    - pgbouncer: `localhost:6432`
    - Redis: `localhost:6379`

7. Clean Up:

    To stop and remove the containers, you can use the following commands:

    ```bash
    docker stop pgbouncer-redis-container
    docker rm pgbouncer-redis-container
    ```

## Important Notes

- Make sure to review and adjust the environment variables in the `entrypoint.sh` script according to your setup and security requirements.

- This guide provides a basic setup for running pgbouncer and Redis in Docker containers. Depending on your use case and production requirements, additional configurations and security measures might be necessary
