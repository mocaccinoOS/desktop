// Small Init + Eudev for embedded
// Author: Ettore Di Giacinto
package main

import (
	"log"
	"syscall"
)

func PowerOff() {
	reboot(syscall.LINUX_REBOOT_CMD_POWER_OFF)
}

func Reboot() {
	reboot(syscall.LINUX_REBOOT_CMD_RESTART)
}

func Halt() {
	reboot(syscall.LINUX_REBOOT_CMD_HALT)
}

func reboot(code uint) {
	syscall.Sync()

	if err := syscall.Reboot(int(code)); err != nil {
		log.Fatal(err)
	}
}
