FROM python:3.8 as base

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

# ssl keys
ARG n=4
RUN ./Scripts/setup-ssl.sh $n

# DEBUG and configuration flags
RUN echo "MY_CFLAGS += -DDEBUG_NETWORKING" >> CONFIG.mine \
        && echo "MY_CFLAGS += -DVERBOSE" >> CONFIG.mine \
        && echo "MY_CFLAGS += -DDEBUG_MAC" >> CONFIG.mine \
        && echo "MY_CFLAGS += -DDEBUG_FILE" >> CONFIG.mine


FROM base

ARG program="malicious-shamir-party.x"

ARG mod="-DGFP_MOD_SZ=4"
ARG prep_dir="/opt/preprocessing-data"

RUN mkdir -p $prep_dir \
        && echo "PREP_DIR = '-DPREP_DIR=\"${prep_dir}\"'" >> CONFIG.mine \
        && echo "MOD = ${mod}" >> CONFIG.mine

RUN make clean && make ${program}
