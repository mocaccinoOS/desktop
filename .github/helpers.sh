#!/bin/bash

install_deps() {
    curl https://get.mocaccino.org/luet/get_luet_root.sh | sudo sh
    sudo luet install -y repository/mocaccino-extra-stable
    sudo luet install -y utils/edgevpn container/k3s container/kubectl
}

start_vpn() {
    install_deps
    echo "$EDGEVPN" | base64 -d > config.yaml
    sudo -E EDGEVPNCONFIG=config.yaml IFACE=edgevpn0 edgevpn > /dev/null 2>&1 &
}

wait_master() {
    while ! nc -z $MASTER 6443; do  
        echo "K3s server not ready yet.." 
        sleep 1
    done
}

start_jumpbox() {
    sudo luet install -y utils/k9s container/kubectl
}

prepare_jumpbox() {
    wait_master
    curl http://$MASTER:9091/k3s.yaml | sed 's/127\.0\.0\.1/10.1.0.20/g' > k3s.yaml
}

start_server() {
    while ! ip a | grep $ADDRESS ; do  
        echo "VPN not ready yet.." 
        sleep 1
    done
    sudo ip a
    
    (
    set +e
    while true; do 
    	
         sudo -E k3s server --flannel-iface=edgevpn0 --node-ip $IP --node-external-ip $IP 
    done
    ) &

    while ! nc -z localhost 6443; do  
        echo "K3s server not ready yet.." 
        sleep 1
    done
    while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do  
        echo "KUBECONFIG not available yet.." 
        sleep 1
    done

    sudo luet serve-repo --address $IP --dir /var/lib/rancher/k3s/server/ &
    sudo luet serve-repo --address $IP --port 9091 --dir /etc/rancher/k3s 
}

start_agent() {
    wait_master

    while ! nc -z $MASTER 9090; do  
        echo "certs not ready yet.." 
        sleep 1
    done
    
    (
    set +e
    while true; do 
         export K3S_TOKEN=$( curl --silent -L http://$MASTER:9090/node-token )

         echo "Node token $K3S_TOKEN"
         sudo -E k3s agent --server https://$MASTER:6443 --flannel-iface=edgevpn0 --node-ip $IP
    done
    )
}