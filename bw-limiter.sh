#!/bin/bash
# Main reference for this script:
# https://tldp.org/HOWTO/Adv-Routing-HOWTO/lartc.ratelimit.single.html

#------------------------------------------------------------------------------
# The name of the NIC to be used. Use ifconfig -a to detect your NIC.
NIC=eno1

# This is the limit in kbps. Please note that you must add the suffix 'kbit'.
CLASS_RATE_LIMIT_KBIT=1kbit

#------------------------------------------------------------------------------
usage()
{
	echo
	echo "Usage:"
	echo "bw-limiter.sh start|stop"
	echo
}

show_current_disciplines()
{
	echo "Current queueing disciplines:"
	tc qdisc show dev "$NIC"
}

# This clears any possible queueing class already present
clear_current_disciplines()
{
	echo "Clearing current classes"
	tc qdisc del dev "$NIC" root handle 1
}

# This adds a new queueing discipline. Parameters are a reference for TC internal computations.
# These should match quite closely your setup.
# Moreover, this adds a new class to the queueing discipline.
add_new_discipline_and_class()
{
	echo "Adding a new class based queue"
	tc qdisc add dev "$NIC" root handle 1: cbq avpkt 1500 bandwidth 1000mbit

	echo "Adding a new class"
	tc class add dev "$NIC" parent 1: classid 1:1 cbq rate "$CLASS_RATE_LIMIT_KBIT" allot 1500 prio 5 bounded isolated
}

# Add hosts to that class. IP address is verified for both src and dst addresses.
add_new_ip_address_to_class()
{
	local -r TARGET_IP="$1"
	echo "Adding IP = $TARGET_IP to the queueing discipline."

	tc filter add dev "$NIC" parent 1: protocol ip prio 16 u32 match ip src $TARGET_IP flowid 1:1
	tc filter add dev "$NIC" parent 1: protocol ip prio 16 u32 match ip dst $TARGET_IP flowid 1:1
}

#------------------------------------------------------------------------------
# Actual script

show_current_disciplines
if [[ "$1" == "start" ]]; then
	echo "START limiting."
	echo

	clear_current_disciplines
	add_new_discipline_and_class

	# add here more IP address to be limited.
	add_new_ip_address_to_class 10.10.10.10

elif [[ "$1" == "stop" ]]; then
	echo "STOP limiting."
	echo

	clear_current_disciplines
else
	usage
	exit 1
fi

