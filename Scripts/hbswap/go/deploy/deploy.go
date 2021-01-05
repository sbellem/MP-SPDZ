package main

import (
	"context"
	"fmt"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/initc3/MP-SPDZ/Scripts/hbswap/go/utils"
	"github.com/initc3/MP-SPDZ/Scripts/hbswap/go_bindings/hbswap"
	"github.com/initc3/MP-SPDZ/Scripts/hbswap/go_bindings/token"
	"log"
	"net"
	"os"
)

func DeployHbSwap(conn *ethclient.Client, auth *bind.TransactOpts) common.Address {
	log.Println("Deploying HbSwap contract...")

	hbswapAddr, tx, _, err := hbswap.DeployHbSwap(auth, conn)
	if err != nil {
		log.Fatalf("Failed to deploy HbSwap: %v", err)
	}

	receipt, err := utils.WaitMined(context.Background(), conn, tx, 0)
	if err != nil {
		log.Fatalf("Failed to WaitMined HbSwap: %v", err)
	}
	if receipt.Status == 0 {
		log.Fatalf("Transaction status: %x", receipt.Status)
	}

	log.Println("Deployed HbSwap contract at", hbswapAddr.Hex())

	return hbswapAddr
}

func DeployToken(conn *ethclient.Client, auth *bind.TransactOpts) common.Address {
	log.Println("Deploying Token contract...")

	tokenAddr, tx, _, err := token.DeployToken(auth, conn)
	if err != nil {
		log.Fatalf("Failed to deploy Token: %v", err)
	}

	receipt, err := utils.WaitMined(context.Background(), conn, tx, 0)
	if err != nil {
		log.Fatalf("Failed to WaitMined Token: %v", err)
	}
	if receipt.Status == 0 {
		log.Fatalf("Transaction status: %x", receipt.Status)
	}

	log.Println("Deployed Token contract at", tokenAddr.Hex())

	return tokenAddr
}

func main() {
	// TODO set default to localhost
	hostname := os.Args[1]
	addrs, err := net.LookupIP(hostname)
	if err != nil {
		fmt.Println("Unknown host")
		return
	}
	addr := addrs[0]
	fmt.Println("IP address: ", addr)
	conn := utils.GetEthClient(fmt.Sprintf("HTTP://%s:8545", addr))
	log.Println("connection: ", conn)
	owner, _ := utils.GetAccount("account_0")
	log.Println("owner: ", owner)
	DeployHbSwap(conn, owner)
	DeployToken(conn, owner)
}
