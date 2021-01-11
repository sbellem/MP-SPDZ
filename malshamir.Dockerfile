FROM python:3.8

RUN apt-get update && apt-get install -y --no-install-recommends \
                automake \
                build-essential \
                git \
                libboost-dev \
                libboost-thread-dev \
                libsodium-dev \
                libssl-dev \
                libtool \
                m4 \
                texinfo \
                yasm \
                vim \
                gdb \
                valgrind \
        && rm -rf /var/lib/apt/lists/*

ENV MP_SPDZ_HOME /usr/src/MP-SPDZ
WORKDIR $MP_SPDZ_HOME

# mpir
RUN mkdir -p /usr/local/share/info
COPY --from=initc3/mpir:55fe6a9 /usr/local/mpir/lib/libmpir*.*a /usr/local/lib/
COPY --from=initc3/mpir:55fe6a9 /usr/local/mpir/lib/libmpir.so.23.0.3 /usr/local/lib/
COPY --from=initc3/mpir:55fe6a9 /usr/local/mpir/lib/libmpirxx.so.8.4.3 /usr/local/lib/
COPY --from=initc3/mpir:55fe6a9 /usr/local/mpir/include/mpir*.h /usr/local/include/
COPY --from=initc3/mpir:55fe6a9 /usr/local/mpir/share/info/* /usr/local/share/info/
RUN set -ex \
    && cd /usr/local/lib \
    && ln -s libmpir.so.23.0.3 libmpir.so \
    && ln -s libmpir.so.23.0.3 libmpir.so.23 \
    && ln -s libmpirxx.so.8.4.3 libmpirxx.so \
    && ln -s libmpirxx.so.8.4.3 libmpirxx.so.8

COPY Makefile .
COPY CONFIG .
COPY BMR BMR
#COPY ECDSA ECDSA
COPY Exceptions Exceptions
#COPY ExternalIO ExternalIO
#COPY FHE FHE
#COPY FHEOffline FHEOffline
COPY GC GC
COPY Machines Machines
COPY Math Math
COPY Networking Networking
COPY OT OT
COPY Processor Processor
COPY Protocols Protocols
COPY SimpleOT SimpleOT
COPY Tools Tools
#COPY Utils Utils
#COPY Yao Yao

RUN make clean

# DEBUG and configuration flags
RUN echo "MY_CFLAGS += -DDEBUG_NETWORKING" >> CONFIG.mine \
        && echo "MY_CFLAGS += -DVERBOSE" >> CONFIG.mine \
        && echo "MY_CFLAGS += -DDEBUG_MAC" >> CONFIG.mine \
        && echo "MY_CFLAGS += -DDEBUG_FILE" >> CONFIG.mine \
        && echo "MOD = -DGFP_MOD_SZ=4" >> CONFIG.mine

RUN make malicious-shamir-party.x

ENV PRIME 52435875175126190479447740508185965837690552500527637822603658699938581184513
ENV N_PARTIES 4
ENV THRESHOLD 1
ENV LD_LIBRARY_PATH /usr/local/lib

## Python (HTTP server) dependencies for HTTP server
#RUN apt-get update && apt-get install -y --no-install-recommends \
#                lsof \
#                libmpfr-dev \
#                libmpc-dev \
#        && rm -rf /var/lib/apt/lists/*
#RUN pip install gmpy2 gmpy toml leveldb aiohttp
#
## GO (server) dependencies
#COPY --from=golang:1.15.6-buster /usr/local/go /usr/local/go
#ENV GOPATH /go
#ENV PATH $GOPATH/bin:$PATH
#RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
#
#RUN go get -d -v github.com/ethereum/go-ethereum
#
#WORKDIR $GOPATH/src/github.com/ethereum/go-ethereum
#RUN git checkout cfbb969da
#
#COPY Scripts/hbswap /go/src/github.com/initc3/MP-SPDZ/Scripts/hbswap
#
#WORKDIR /go/src/github.com/initc3/MP-SPDZ/Scripts/hbswap
#
#RUN go get -d -v ./...
#
##WORKDIR /go/src/github.com/initc3/MP-SPDZ/Scripts/hbswap/go
