package main

import (
	"fmt"
	"github.com/initc3/MP-SPDZ/Scripts/hbswap/go/utils"
	"math/big"
	"net"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

func main() {
	user := os.Args[1]
	amtA, amtB := os.Args[2], os.Args[3]

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

	idxA, idxB := utils.TradePrep(conn, owner)

	cmd := exec.Command("python3", "Scripts/hbswap/python/client/req_inputmasks.py", strconv.Itoa(int(idxA)), amtA, strconv.Itoa(int(idxB)), amtB)
	stdout := utils.ExecCmd(cmd)
	maskedInputs := strings.Split(stdout[:len(stdout)-1], " ")

	maskedA := utils.StrToBig(maskedInputs[0])
	maskedB := utils.StrToBig(maskedInputs[1])

	tokenA := utils.EthAddr
	tokenB := utils.TokenAddr

	fmt.Printf("maskedInputs: %v\n", maskedInputs)
	utils.Trade(conn, owner, tokenA, tokenB, big.NewInt(idxA), big.NewInt(idxB), maskedA, maskedB)
}
