FROM python:3.8

RUN apt-get update && apt-get install -y --no-install-recommends \
                automake \
                build-essential \
                git \
                libboost-dev \
                libboost-thread-dev \
                libntl-dev \
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

RUN echo "USE_NTL = 1" >> CONFIG.mine

RUN pip install --upgrade pip ipython

COPY . .

# mpir
RUN make mpir

RUN make clean

#RUN mkdir -p PreProcessing-Data \
#        && echo "PREP_DIR = '-DPREP_DIR=\"PreProcessing-Data/\"'" >> CONFIG.mine

# DEBUG and configuration flags
RUN echo "MY_CFLAGS += -DDEBUG_NETWORKING" >> CONFIG.mine \
        && echo "MY_CFLAGS += -DVERBOSE" >> CONFIG.mine \
        && echo "MY_CFLAGS += -DDEBUG_MAC" >> CONFIG.mine \
        && echo "MY_CFLAGS += -DDEBUG_FILE" >> CONFIG.mine \
        && echo "MOD = -DGFP_MOD_SZ=4" >> CONFIG.mine

#RUN make malicious-shamir-party.x
RUN make random-shamir.x

RUN ./Scripts/setup-ssl.sh 4
