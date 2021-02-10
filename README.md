# Virtual Network Project
This is multi-purpose project to experiment with Docker, ~~SDN~~ and Linux Networking

NOTE 1 : everything is automated, from building docker images to advanced network configuration, you'll be able to create this entire network with only ONE command : `vagrant up`

For now the Network looks like this : (no services yet)

![Imgur](http://i.imgur.com/jiKJphN.png)

## DONE

1) ~~Learn Docker Networking (docker network)~~
2) ~~Learn Linux Namespaces (ip netns)~~
3) ~~Create a two container Network (linked using a veth pair)~~
4) ~~(WAN) Create a larger Network (3 routers : BACKBONE, ISP and GATEWAY and 3 NAT devices)
   Manual ip configuration, static routing (OSPF Later), NAT configuration (IPTABLES rules)~~
5) ~~(LAN) Create an OVS (Open vSwitch), use Pipwork for configuration [found some troubles with native linux bridge]~~

## TODO

1) Error handling in Bash
2) Services configuration (Dockerfile)

* DNS    — port 53
* SSH    — port 22
* Telnet — port 23
* FTP    — port 21
* SMTP   — port 25
* POP3   — port 110
* POP3S  — port 995
* IMAP   — port 143
* IMAPS  — port 993
* HTTP   — port 80
* HTTPS  — port 443

3) Expand the network to a Multi-host environment (Docker Swarm Orchestration)
4) Explain the magic happening behind the network (VXLAN, MACVLAN, IPTABLES, GRE tunnels ...)
5) no idea what to do next,
   any suggestions ? ping me at imad.hsissou@edu.uca.ma or fb.com/imadhsissou
