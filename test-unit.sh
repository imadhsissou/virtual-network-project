#/bin/bash

# Remove all containers / networks
sudo docker rm -f $(sudo docker ps -a -q)
sudo docker network rm $(docker network ls | grep "ovs" | awk '/ / { print $1 }')

# Create docker network bridges

# sudo docker network create -d bridge --subnet=192.168.0.0/24 --gateway=192.168.0.254 ovs_a
#sudo docker network create -d bridge --subnet=192.168.1.0/24 --gateway=192.168.1.254 ovs_b
#sudo docker network create -d bridge --subnet=192.168.2.0/24 --gateway=192.168.2.254 ovs_c

#Setting up namespace runtime dir
sudo mkdir -p /var/run/netns

# Creating ubuntu 16.04 containers
sudo docker run --rm --name backbone -t -d gns3/ipterm
sudo docker run --rm --name isp --net=none -td gns3/ipterm
sudo docker run --rm --name natA --net=none -td --cap-add=NET_ADMIN imadhsissou/networking-toolbox
sudo docker run --rm --name natB --net=none -td --cap-add=NET_ADMIN imadhsissou/networking-toolbox
sudo docker run --rm --name gtw --net=none -td gns3/ipterm

sudo docker run --rm --name host1 --net=none -td gns3/ipterm
sudo docker run --rm --name host2 --net=none -td gns3/ipterm

sudo docker run --rm --name host4 --net=none -td gns3/ipterm
sudo docker run --rm --name www --net=none -td gns3/ipterm

# Creating Open vSwitches

# OVS_A
sudo /vagrant/pipework/pipework ovs_a natA 192.168.0.254/24 2>/dev/null
sudo /vagrant/pipework/pipework ovs_a host1 192.168.0.10/24@192.168.0.254 2>/dev/null
sudo /vagrant/pipework/pipework ovs_a host2 192.168.0.20/24@192.168.0.254 2>/dev/null

# OVS_B
sudo /vagrant/pipework/pipework ovs_b natB 192.168.1.254/24 2>/dev/null
sudo /vagrant/pipework/pipework ovs_b host4 192.168.1.10/24@192.168.1.254 2>/dev/null

# OVS_C
sudo /vagrant/pipework/pipework ovs_c gtw 192.168.2.254/24 2>/dev/null
sudo /vagrant/pipework/pipework ovs_c www 192.168.2.10/24@192.168.2.254 2>/dev/null

function NATing {
	# usage e.g. NATing CONTANER natA nat1

	sudo docker exec $1 iptables -t nat -A POSTROUTING -o $2 -j MASQUERADE
}

function createNetns {
	# usage e.g. createNetns backbone
	#PS : container name is exactly the same as its 
	#     network namespace

	#Setting up container namespaces
	sudo unlink /var/run/netns/$1
	pid="$(sudo docker inspect --format '{{.State.Pid}}' $1)"
	sudo ln -s /proc/$pid/ns/net /var/run/netns/$1
}

function point2point {
	# usage e.g. point2point 

	#Create and add veths to the containers
	sudo ip link add $2 type veth peer name $4
	sudo ip link set $2 netns $1
	sudo ip link set $4 netns $3

}

function networkConf {
	# usage e.g. networkConf backbone bkn0 192.168.122.1/24 gw
	sudo ip netns exec $1 ifconfig $2 $3 up
	if [[ $4 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		sudo ip netns exec $1 route add default gw $4
	fi

	if [ $1 == "backbone" ]; then
		sudo ip netns exec $1 route add -net 10.0.15.0 netmask 255.255.255.252 gw 10.0.10.2 2>/dev/null
		sudo ip netns exec $1 route add -net 10.0.25.0 netmask 255.255.255.252 gw 10.0.10.2 2>/dev/null
	fi
}

function hostGW {
	#usage hostGW HOST gw
	# e.g. hostGW host1 192.168.0.1

	sudo docker exec $1 route add -net 0.0.0.0 netmask 0.0.0.0 gw $2
}

createNetns backbone
createNetns isp
createNetns gtw
createNetns natA
createNetns natB

point2point backbone bkn0 isp isp0
point2point backbone bkn1 gtw gtw1
point2point isp isp1 natA nat1
point2point isp isp2 natB nat2

networkConf backbone bkn0 10.0.10.1/30
networkConf backbone bkn1 10.0.20.1/30
networkConf isp isp0 10.0.10.2/30 10.0.10.1
networkConf isp isp1 10.0.15.1/30 
networkConf isp isp2 10.0.25.1/30 

networkConf natA nat1 10.0.15.2/30 10.0.15.1
networkConf natB nat2 10.0.25.2/30 10.0.25.1

networkConf gtw gtw1 10.0.20.2/30 10.0.20.1

NATing natA nat1
NATing natB nat2

# natA / natB are working fine.
# add natC device to mask 192.168.2.0/24 network : add iptables rules to allow services
# get started in services configuration ==> find a way to connect all containers to the internet (docker0 bridge)
# without destroying the current config !!!