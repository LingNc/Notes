package main

import (
	"crypto/rand"
	"fmt"
	"math/big"
)

func generatePassword(length int) string {
	chars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	res := make([]byte, length)
	for i := 0; i < length; i++ {
		num, _ := rand.Int(rand.Reader, big.NewInt(int64(len(chars))))
		res[i] = chars[num.Int64()]
	}
	return string(res)
}

func main() {
	fmt.Printf("username: %s\npassword: %s", generatePassword(20), generatePassword(50))
}
