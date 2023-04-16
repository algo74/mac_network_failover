#!/bin/bash

# This script will switch to a failover location if the ethernet connection is not working.
# It needs to be run as root, to be able to switch locations.

# Variables - Change these to suit your needs
CHECK_DELAY=${1:-"5"} # How often to check the connection, in seconds
ETHERNET_INTERFACE="USB 10/100/1000 LAN" # The name of the ethernet interface - must exist in System Preferences > Network
ORIGINAL_LOCATION="Automatic" # The name of the original location (that prefers Ethernet) - must exist in System Preferences > Network
FAILOVER_LOCATION="Prefer WiFi" # The name of the failover location (that prefers Wi-Fi) - must be set up in System Preferences > Network

check_ping() {
    # check if one of 8 pings using Ethernet to the given IP address is successful
    ping -c 8 -o -S${ETHERNET_IP} "$1" > /dev/null 2>&1
}

ethernet_not_working() {
    # check if we can ping Google's DNS server
    ! check_ping 8.8.8.8
}

ethernet_sure_not_working() {
    # check if we can ping another server
    ! check_ping 1.1.1.1
}

switch_to_failover() {
    # switch to the failover location
    echo -n "[$(date)] Failover to ${FAILOVER_LOCATION} -- "
    networksetup -switchtolocation "${FAILOVER_LOCATION}"
    echo -e "\xE2\x96\xA1" 
}

switch_back() {
    # switch back to the original location
    echo -n "[$(date)] Going back to ${ORIGINAL_LOCATION} -- "
    networksetup -switchtolocation "${ORIGINAL_LOCATION}"
    # output a square symbol to indicate that the switch is complete
    echo -e "\xE2\x96\xA1"
}

# Check if we in failover mode
already_switched() {
    # check if the current location is the failover location
    networksetup -getcurrentlocation | grep -q "${FAILOVER_LOCATION}"
}


# cycle indefinitely
while sleep "$CHECK_DELAY"; do
    # Get the current IP address of the ethernet interface using networksetup
    ETHERNET_IP=$(networksetup -getinfo "${ETHERNET_INTERFACE}" | grep "^IP address: " | awk '{print $3}')
    # echo Ethernet IP: $ETHERNET_IP

    # Check if the ethernet is working
    if ethernet_not_working; then
        if ethernet_sure_not_working; then
            # Ethernet is not working, so failover 
            if ! already_switched; then
                switch_to_failover
            fi
        fi
    else
        # Ethernet is working, so go back 
        if already_switched; then
            switch_back
        fi
    fi
done

