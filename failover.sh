#!/bin/bash

# This script will switch to a failover location if the ethernet connection is not working.
# It needs to be run as root, to be able to switch locations.

# Variables - Change these to suit your needs
CHECK_DELAY=${1:-"5"} # How often to check the connection, in seconds
SWITCH_FACTOR=2 # How much to increase the delay when in the failover mode
ETHERNET_INTERFACE="USB 10/100/1000 LAN" # The name of the ethernet interface - must exist in System Preferences > Network
WIFI_INTERFACE="Wi-Fi" # The name of the Wi-Fi interface - must exist in System Preferences > Network
# ORIGINAL_LOCATION="Automatic" # The name of the original location (that prefers Ethernet) - must exist in System Preferences > Network
# FAILOVER_LOCATION="Prefer WiFi" # The name of the failover location (that prefers Wi-Fi) - must be set up in System Preferences > Network

check_ping() {
    # check if one of 8 pings using Ethernet to the given IP address is successful
    # Change option -c 8 to change the number of pings if you want
    ping -c 8 -o -S${ETHERNET_IP} "$1" > /dev/null 2>&1
}

update_ethernet_ip() {
    # Get the current IP address of the ethernet interface using networksetup
    ETHERNET_IP=$(networksetup -getinfo "${ETHERNET_INTERFACE}" | grep "^IP address: " | awk '{print $3}')
}

get_network_order_array() {
    # output network service order as a list of interfaces 
    networksetup -listnetworkserviceorder | grep -E '^\([0-9]+\)' | sed -r 's/^\([0-9]+\) //'
}

check_ethernet_interface() {
    if ! get_network_order_array | grep -qFx "${ETHERNET_INTERFACE}"; then
        echo "[$(date)] ${ETHERNET_INTERFACE} is not in the network service order"
        # find a network service that contains the word Ethernet
        local IFS=$'\n'
        local SERVICES=($(get_network_order_array))
        for service in "${SERVICES[@]}"; do
            if networksetup -getinfo "${service}" | grep -q "Ethernet"; then
                ETHERNET_INTERFACE="${service}"
                update_ethernet_ip
                echo "     Found Ethernet service \"${ETHERNET_INTERFACE}\" with IP ${ETHERNET_IP}"
                break
            fi
        done
    fi
}

check_wifi_interface() {
    if ! get_network_order_array | grep -qFx "${WIFI_INTERFACE}"; then
        echo "[$(date)] ${WIFI_INTERFACE} is not in the network service order"
        # find a network service that contains the word Wi-Fi
        local IFS=$'\n'
        local SERVICES=($(get_network_order_array))
        for service in "${SERVICES[@]}"; do
            if networksetup -getinfo "${service}" | grep -q "Wi-Fi"; then
                WIFI_INTERFACE="${service}"
                echo "     Found Wi-Fi service \"${WIFI_INTERFACE}\""
                break
            fi
        done
    fi
}

ethernet_not_working() {
    # check if we can ping Google's DNS server
    # Change this to ping another server if you want
    ! check_ping 8.8.8.8
}

ethernet_sure_not_working() {
    # make sure ETHERNET_INTERFACE is in the network service order
    check_ethernet_interface
    # check if we can ping another server
    # Change this to ping another server if you want
    ! check_ping 1.1.1.1
}

# Set the initial state to not switched
SWITCHED=0


switch_to_failover() {
    check_wifi_interface
    echo "[$(date)] Failover to ${WIFI_INTERFACE}"
    ORDER=$(get_network_order_array)
    # get the network service order without the Wi-Fi interface in an array
    local IFS=$'\n'
    local MOD_ORDER=($(echo "${ORDER}" | grep -Fxv "${WIFI_INTERFACE}"))
    # move Wi-Fi to the top of the network service order
    networksetup -ordernetworkservices "${WIFI_INTERFACE}" "${MOD_ORDER[@]}"
    SWITCHED=1
}

switch_back() {
    if [ $SWITCHED -eq 1 ]; then
        echo "[$(date)] Switching back to ${ETHERNET_INTERFACE}"
        # get the network service order without the Ethernet interface in an array
        local IFS=$'\n'
        local MOD_ORDER=($(get_network_order_array | grep -Fxv "${ETHERNET_INTERFACE}"))
        # move Ethernet to the top of the network service order
        if networksetup -ordernetworkservices "${ETHERNET_INTERFACE}" "${MOD_ORDER[@]}" ; then 
          SWITCHED=0
        else 
          echo "      failed to switch back"
        fi
    else
        echo "      already switched back"
    fi
}

# Check if we in failover mode
already_switched() {
    # check if the current location is the failover location
    [ $SWITCHED -eq 1 ]
}


# cycle indefinitely
while sleep $((CHECK_DELAY * (1 + SWITCH_FACTOR*SWITCHED) )); do # increase the delay if we are in failover mode
    update_ethernet_ip
    # echo Ethernet IP: $ETHERNET_IP
    echo [$(date)] Checking connection
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

