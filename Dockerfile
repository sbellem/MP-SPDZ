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

#ENV LIBRARY_PATH /usr/local/lib
#ENV LIBRARY_INCLUDE_PATH /usr/local/include

# mpir
COPY --from=initc3/mpir:55fe6a9 /usr/local/mpir ./local
RUN echo MY_CFLAGS += -I./local/include >> CONFIG.mine
RUN echo MY_LDLIBS += -Wl,-rpath -Wl,./local/lib -L./local/lib >> CONFIG.mine

# ntl
COPY --from=ntl:10.5 /usr/local/include/NTL /usr/local/include/NTL
COPY --from=ntl:10.5 /usr/local/lib/libntl.a /usr/local/lib/libntl.a
RUN echo USE_NTL = 1 >> CONFIG.mine
RUN echo MY_CFLAGS += -I/usr/local/include/NTL >> CONFIG.mine
RUN echo MY_LDLIBS += -Wl,-rpath -Wl,/usr/local/lib -L/usr/local/lib >> CONFIG.mine

# pip, ipython
RUN pip install --upgrade pip ipython

# install compiler (console script mpspdz-compile)
COPY Compiler Compiler
RUN pip install --editable Compiler/

COPY . .

RUN make clean

RUN mkdir PreProcessing-Data \
        && echo "PREP_DIR = '-DPREP_DIR=\"PreProcessing-Data/\"'" >> CONFIG.mine
#PREP_DIR = '-DPREP_DIR="Player-Data/"'
#RUN echo "MY_CFLAGS += -DINSECURE" >> CONFIG.mine

# honest majority, malicious shamir
#RUN make -j 2 malicious-shamir-party.x
#RUN Scripts/setup-ssl.sh 3
#RUN mkdir -p Player-Data

# tldr
#RUN make -j 2 tldr
#RUN echo ARCH = -march=native >> CONFIG.mine
#RUN make mascot-party.x
#RUN mkdir -p Player-Data \
#        && echo 1 2 3 4 > Player-Data/Input-P0-0 \
#        && echo 1 2 3 4 > Player-Data/Input-P1-0
#
#CMD Scripts/mascot.sh tutorial

# online & offline
#RUN echo "MY_CFLAGS += -DINSECURE" >> CONFIG.mine
#RUN make -j 8 online
#RUN make -j 2 offline she-offline
#RUN ./Scripts/setup-online.sh


# shamir
#RUN make -j 2 shamir
#
## ring
#RUN Scripts/setup-ssl.sh 3
#RUN make -j 8 replicated-ring-party.x
#RUN mkdir -p Player-Data \
#        && echo 3 > Player-Data/Input-P0-0 \
#        && echo 4 > Player-Data/Input-P1-0 \
#        && echo 5 > Player-Data/Input-P2-0
#CMD /bin/sh -c Scripts/ring.sh mult3
