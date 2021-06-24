#!/bin/bash
chmod 4750 /usr/lib64/virtualbox/VirtualBoxVM
for each in /usr/lib64/virtualbox/VBox{SDL,Headless,Net{AdpCtl,DHCP,NAT}} ; do
		chmod 4750 ${each}
done
