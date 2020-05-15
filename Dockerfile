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

ENV MP_SPDZ_HOME /usr/src/MP-SPDZ
WORKDIR $MP_SPDZ_HOME

# mpir
COPY --from=mpir:55fe6a9 /usr/local/mpir ./local
RUN echo MY_CFLAGS += -I./local/include >> CONFIG.mine
RUN echo MY_LDLIBS += -Wl,-rpath -Wl,./local/lib -L./local/lib >> CONFIG.mine

COPY . .
# honest majority, malicious shamir
#RUN make -j 8 malicious-shamir-party.x
#RUN Scripts/setup-ssl.sh 3
#RUN mkdir -p Player-Data

# online
#RUN echo "MY_CFLAGS += -DINSECURE" >> CONFIG.mine
#RUN make -j 8 online
#RUN ./Scripts/setup-online.sh

# tldr
RUN make -j 2 tldr
#RUN echo ARCH = -march=native >> CONFIG.mine
#RUN make mascot-party.x
#RUN mkdir -p Player-Data \
#        && echo 1 2 3 4 > Player-Data/Input-P0-0 \
#        && echo 1 2 3 4 > Player-Data/Input-P1-0
#
#CMD Scripts/mascot.sh tutorial

# shamir
RUN make -j 2 shamir

# ring
RUN Scripts/setup-ssl.sh 3
RUN make -j 8 replicated-ring-party.x
RUN mkdir -p Player-Data \
        && echo 3 > Player-Data/Input-P0-0 \
        && echo 4 > Player-Data/Input-P1-0 \
        && echo 5 > Player-Data/Input-P2-0
CMD /bin/sh -c Scripts/ring.sh mult3
