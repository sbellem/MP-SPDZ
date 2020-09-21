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
        && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/MP-SPDZ
COPY . .

# mpir
RUN make mpir
COPY --from=mpir:55fe6a9 /usr/local/mpir ./local
RUN echo MY_CFLAGS += -I./local/include >> CONFIG.mine
RUN echo MY_LDLIBS += -Wl,-rpath -Wl,./local/lib -L./local/lib >> CONFIG.mine

# honest majority, malicious shamir
#RUN make -j 8 malicious-shamir-party.x
#RUN Scripts/setup-ssl.sh 3
#RUN mkdir -p Player-Data

# online
RUN echo "MY_CFLAGS += -DINSECURE" >> CONFIG.mine
#RUN make -j 8 online
#RUN ./Scripts/setup-online.sh
