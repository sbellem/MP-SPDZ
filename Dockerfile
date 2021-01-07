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
                lsof \
                libmpfr-dev \
                libmpc-dev \
        && rm -rf /var/lib/apt/lists/*

# Go & Ethereum
COPY --from=golang:1.15.6-buster /usr/local/go /usr/local/go
ENV PATH /usr/local/go/bin:$PATH
ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# ethereum
RUN go get -d -v github.com/ethereum/go-ethereum
WORKDIR $GOPATH/src/github.com/ethereum/go-ethereum
RUN git checkout cfbb969da

# geth - to run a (private) node
RUN make geth
RUN cp build/bin/geth /usr/local/bin/

RUN mkdir -p /go/src/github.com/initc3/MP-SPDZ/Scripts/
COPY Scripts/hbswap /go/src/github.com/initc3/MP-SPDZ/Scripts/hbswap
WORKDIR /go/src/github.com/initc3/MP-SPDZ/Scripts/hbswap
RUN go get -d -v ./...

#ENV GOPATH $HOME/gopath
#RUN mkdir -p $GOPATH/src/github.com/ethereum
#WORKDIR $GOPATH/src/github.com/ethereum
#RUN git clone https://github.com/ethereum/go-ethereum.git
#WORKDIR $GOPATH/src/github.com/ethereum/go-ethereum
#RUN git checkout cfbb969da
#RUN make geth
#RUN go get github.com/syndtr/goleveldb/leveldb

ENV MP_SPDZ_HOME /usr/src/MP-SPDZ
WORKDIR $MP_SPDZ_HOME

# mpir
ENV LD_LIBRARY_PATH /usr/local/lib
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

# ntl
COPY --from=initc3/ntl:10.5 /usr/local/include/NTL /usr/local/include/NTL
COPY --from=initc3/ntl:10.5 /usr/local/lib/libntl.a /usr/local/lib/libntl.a
RUN echo "USE_NTL = 1" >> CONFIG.mine

# pip, ipython
RUN pip install --upgrade pip ipython

# install compiler (console script mpspdz-compile)
#COPY Compiler Compiler
#RUN pip install --editable Compiler/

COPY . .

RUN make clean

#RUN mkdir -p PreProcessing-Data \
#        && echo "PREP_DIR = '-DPREP_DIR=\"PreProcessing-Data/\"'" >> CONFIG.mine

# DEBUG and configuration flags
RUN echo "MY_CFLAGS += -DDEBUG_NETWORKING" >> CONFIG.mine \
        && echo "MY_CFLAGS += -DVERBOSE" >> CONFIG.mine \
        && echo "MY_CFLAGS += -DDEBUG_MAC" >> CONFIG.mine \
        && echo "MY_CFLAGS += -DDEBUG_FILE" >> CONFIG.mine \
        && echo "MOD = -DGFP_MOD_SZ=4" >> CONFIG.mine

RUN make malicious-shamir-party.x \
        && make paper-example-shamir.x \
        && make random-shamir.x

RUN ./Scripts/setup-ssl.sh 4

RUN pip3 install gmpy2
RUN pip3 install gmpy
RUN pip3 install toml
RUN pip3 install leveldb
RUN pip3 install aiohttp
ENV LD_LIBRARY_PATH /usr/local/lib
