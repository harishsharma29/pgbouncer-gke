FROM ubuntu:20.04
ENV TZ=Asia/Kolkata \
    DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y make \
    autoconf \
    automake \
    libtool \
    pandoc \
    libevent-dev \
    pkg-config \
    openssl \
    libssl-dev \
    python3 \
    git
WORKDIR /usr/src
RUN git clone https://github.com/pgbouncer/pgbouncer.git
WORKDIR /usr/src/pgbouncer
RUN git submodule init
RUN git submodule update
RUN mkdir --mode=777 /var/log/postgresql
RUN mkdir --mode=777 /var/run/postgresql
RUN useradd -M postgres
RUN chown -R postgres:postgres /var/log/postgresql
RUN chown -R postgres:postgres /var/run/postgresql
COPY . .
RUN chmod +x entrypoint.sh
RUN ./autogen.sh && ./configure --prefix=/usr/local && make && make install
EXPOSE 6432
CMD ["./entrypoint.sh"]
