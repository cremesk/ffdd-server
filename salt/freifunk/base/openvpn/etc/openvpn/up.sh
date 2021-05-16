#!/usr/bin/env bash
### This file managed by Salt, do not edit by hand! ###

#cmd tun_dev tun_mtu link_mtu ifconfig_local ifconfig_remote
logger -t "ovpn up.sh" "cmd:$cmd dev:$dev tun_mtu:$tun_mtu link_mtu:$link_mtu ifconfig_local:$ifconfig_local ifconfig_remote:$ifconfig_remote"

#make a point-to-point connection with "route_vpn_gateway" because this was working for
#ovpn.to; Freie Netze e.V.;CyberGhost
ifconfig "$dev" "$ifconfig_local" dstaddr "$route_vpn_gateway" mtu "$tun_mtu"

m="${dev#vpn}"
ip route add default dev "$dev" via "$route_vpn_gateway" table gateway_pool metric "$m"

iptables -w -t nat -A POSTROUTING -o "$dev" -j SNAT --to-source "$ifconfig_local"

# add rule to mark icmp error packages that are generated locally and restrict it to
# this vpn IP.
# IP rules are used to forward icmp "frag needed" or other generated by local kernel for a specific connection.
# If not using this rule, icmp packages are forwared to local provider network (Hetzner), which might block interface
# because of wrong traffic
iptables -w -t mangle -A OUTPUT -p icmp --icmp-type fragmentation-needed -j MARK --set-mark 3333


#update gateway infos and routing tables, fast after openvpn open connection
#Run in background, else openvpn blocks. but avoid restarting ovpn by check-script
#if no connection could be made. this would produces a permanent fast restart loop of
#openvpn
/usr/local/bin/freifunk-gateway-check.sh &

BIND_FORWARDER_FILE="/etc/bind/vpn.forwarder.$dev"
# get DEFAULT_DNS
if [ -n "$(uci -qX get ffdd.sys.default_dns)" ]; then
	DEFAULT_DNS="$(uci -d '; ' -qX get ffdd.sys.default_dns);"
else
	DEFAULT_DNS="$(uci -d '; ' -qX get ffdd_sample.sys.default_dns);"
fi

# flush public_dns routing table
ip route flush table public_dns

# parse any other foreign options to setup DNS for bind9.
# all local resolv goes via /etc/resolv.conf.
# any other resolving come from freifunk network and are processed by bind9
# here I create a configuration fragment which is included in /etc/bind/named.conf.options
dns_list=''
for opt in ${!foreign_option_*};
do
	#print all remote option that should be set
	logger -t "ovpn up.sh" "$opt=${!opt}"

	x="${!opt}"
	# only consider IPv4 DNS
	if [ -n "$(echo "$x" | sed -n '/^dhcp-option DNS[ ]/p')" ]; then
		dns="${x#*dhcp-option DNS}"
		dns_list+="$dns;"

		# add public dns to routing table
		ip route add "$dns" dev "$dev" table public_dns
	fi

done

#write data
cat<<EOM >"$BIND_FORWARDER_FILE"
//updated at $(date) by $0
forwarders {
	$dns_list $DEFAULT_DNS
};
EOM

# correct forwarder file is selected by /usr/local/bin/freifunk-gateway-check.sh

#tell always "ok" to openvpn;else in case of errors of "ip route..." openvpn exits
exit 0
