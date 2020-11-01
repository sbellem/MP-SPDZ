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
                golang \
        && rm -rf /var/lib/apt/lists/*

#RUN wget https://dl.google.com/go/go1.13.12.linux-amd64.tar.gz
#RUN tar xf go1.13.12.linux-amd64.tar.gz
#RUN mv go /usr/local/go
#RUN echo 'export GOROOT=/usr/local/go' >> ~/.profile
#RUN echo 'export GOPATH=$HOME/gopath' >> ~/.profile
#RUN echo 'export GOBIN=$GOPATH/bin' >> ~/.profile
#RUN echo 'export PATH=$GOPATH:$GOBIN:$GOROOT/bin:$PATH' >> ~/.profile
#RUN rm /bin/sh && ln -s /bin/bash /bin/sh
#RUN /bin/bash -c "source ~/.profile"
#RUN /bin/bash -c "source /usr/local/bin/virtualenvwrapper.sh"

#RUN go get github.com/ethereum/go-ethereum
#RUN cd $GOPATH/src/github.com/ethereum/go-ethereum
ENV GOPATH $HOME/gopath
RUN mkdir -p $GOPATH/src/github.com/ethereum
WORKDIR $GOPATH/src/github.com/ethereum
RUN git clone https://github.com/ethereum/go-ethereum.git
WORKDIR $GOPATH/src/github.com/ethereum/go-ethereum
RUN git checkout cfbb969da
RUN make geth

RUN go get github.com/syndtr/goleveldb/leveldb

ENV MP_SPDZ_HOME /usr/src/MP-SPDZ
WORKDIR $MP_SPDZ_HOME

# mpir
COPY --from=initc3/mpir:55fe6a9 /usr/local/mpir ./local
RUN echo "MY_CFLAGS += -I./local/include" >> CONFIG.mine \
        && echo "MY_LDLIBS += -Wl,-rpath -Wl,./local/lib -L./local/lib" >> CONFIG.mine

# ntl
COPY --from=ntl:10.5 /usr/local/include/NTL /usr/local/include/NTL
COPY --from=ntl:10.5 /usr/local/lib/libntl.a /usr/local/lib/libntl.a
RUN echo "USE_NTL = 1" >> CONFIG.mine \
        && echo "MY_CFLAGS += -I/usr/local/include/NTL" >> CONFIG.mine \
        && echo "MY_LDLIBS += -Wl,-rpath -Wl,/usr/local/lib -L/usr/local/lib" >> CONFIG.mine

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
        && echo "MY_CFLAGS += -DDEBUG_FILE" >> CONFIG.mine

RUN make malicious-shamir-party.x \
        && make paper-example.x

RUN ./Scripts/setup-ssl.sh 4

RUN pip install gmpy2 \
                gmpy \
                toml \
                leveldb \
                aiohttp
