#/bin/bash

# Remove all containers / networks
sudo docker rm -f $(sudo docker ps -a -q)
sudo docker network rm $(docker network ls | grep "ovs" | awk '/ / { print $1 }')

# Create docker network bridges

sudo docker network create -d bridge --subnet=192.168.0.0/24 --gateway=192.168.0.254 ovs_a
sudo docker network create -d bridge --subnet=192.168.1.0/24 --gateway=192.168.1.254 ovs_b
sudo docker network create -d bridge --subnet=192.168.2.0/24 --gateway=192.168.2.254 ovs_c

#Setting up namespace runtime dir
sudo mkdir -p /var/run/netns

# Creating ubuntu 16.04 containers
sudo docker run --rm --name backbone -t -d gns3/ipterm
sudo docker run --rm --name isp --network none -td gns3/ipterm
sudo docker run --rm --name natA --net=ovs_a --ip 192.168.0.1 -td --cap-add=NET_ADMIN imadhsissou/networking-toolbox
sudo docker run --rm --name natB --net=ovs_b --ip 192.168.1.1 -td --cap-add=NET_ADMIN imadhsissou/networking-toolbox
sudo docker run --rm --name gtw --net=ovs_c --ip 192.168.2.1 -td gns3/ipterm

sudo docker run --rm --name host1 --net=ovs_a --ip 192.168.0.10 -td gns3/ipterm
sudo docker run --rm --name host2 --net=ovs_a --ip 192.168.0.20 -td gns3/ipterm

sudo docker run --rm --name host4 --net=ovs_b --ip 192.168.1.10 -td gns3/ipterm
sudo docker run --rm --name www --net=ovs_c --ip 192.168.2.10 -td gns3/ipterm

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

# hostGW host1 192.168.0.1
# hostGW host2 192.168.0.1

# hostGW host4 192.168.1.1

# hostGW www 192.168.2.1

#NATing natA nat1
#NATing natB nat2

sudo docker exec natA traceroute 10.0.20.2
sudo docker exec host1 traceroute 10.0.20.2