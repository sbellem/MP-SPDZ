FROM golang:buster

# TODO Work with go module mode
# SEE https://github.com/golang/go/wiki/Modules
# RUN go get -d -v github.com/ethereum/go-ethereum@cfbb969da
RUN go get -d -v github.com/ethereum/go-ethereum

WORKDIR $GOPATH/src/github.com/ethereum/go-ethereum
RUN git checkout cfbb969da

COPY Scripts/hbswap /go/src/github.com/initc3/MP-SPDZ/Scripts/hbswap

WORKDIR /go/src/github.com/initc3/MP-SPDZ/Scripts/hbswap

RUN go get -d -v ./...

ENTRYPOINT ["go", "run"]

CMD ["deploy/deploy.go", "eth.chain"]
