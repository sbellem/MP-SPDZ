package main

import (
	"fmt"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/initc3/MP-SPDZ/Scripts/hbswap/go/utils"
	"math/big"
	"net"
	"os"
)

func secretWithdraw(conn *ethclient.Client, auth *bind.TransactOpts, token common.Address, _amt string) {
	amt := utils.StrToBig(_amt)
	if amt.Cmp(big.NewInt(0)) == 0 {
		return
	}

	utils.SecretWithdraw(conn, auth, token, amt)

	utils.GetBalance(conn, token, auth.From)
}

func main() {
	user := os.Args[1]
	amtETH, amtTOK := os.Args[2], os.Args[3]

	// TODO set default to localhost
	hostname := os.Args[4]
	addrs, err := net.LookupIP(hostname)
	if err != nil {
		fmt.Println("Unknown host")
		// return err
		return
	}
	addr := addrs[0]
	fmt.Println("IP address: ", addr)
	//conn := utils.GetEthClient("HTTP://127.0.0.1:8545")
	conn := utils.GetEthClient(fmt.Sprintf("HTTP://%s:8545", addr))

	owner, _ := utils.GetAccount(fmt.Sprintf("account_%s", user))

	secretWithdraw(conn, owner, utils.EthAddr, amtETH)
	secretWithdraw(conn, owner, utils.TokenAddr, amtTOK)
}
