# Network Failover Script for Mac

The `failover.sh` script is a Bash script that automatically reorders the network services on a macOS computer so that if Ethernet connection looses access to the Internet, Wi-Fi becomes the primary network service. 
When the Ethernet connection to the Internet is restored, the script reorders the services so that the Ethernet becomes the primary network service again.
The script needs root privileges to reorder the network services.

## Usage

```bash
      sudo ./failover.sh [delay]
```
* `delay` is an optional argument that specifies the number of seconds between each check for Ethernet connectivity. Default value is 5.

To stop the script, press `Ctrl+C`.

## Why is this script needed?

When both Ethernet and Wi-Fi interfaces are connected, 
and the Ethernet interface is first in the network service order, 
macOS will not automatically use the Wi-Fi to access Internet if the Internet is not accessible from the Ethernet interface. 
This is a problem if the wired connection to the Internet is unstable, but you don't want to use the Wi-Fi connection all the time as it is usually slower than the wired connection. 



## Prerequisites

This script must be run as root to be able to reorder network services.
Ethernet and Wi-Fi interfaces must be configured and connected to a network. 


## Side Effects

When the script is stopped, the network services may be not in their original order.
Use a dedicated network location to run the script if the original order of the network services is important.
You can create a network location in `System preferences~>Network~>Location~>Edit Locations...~>...~>Duplicate Location`.
You can also restore the original order manually.


## Customization

Before running the script, you may customize the following variables according to your network settings:

*   `CHECK_DELAY`: The default time delay between each check for Ethernet connectivity (can be changed from the command line).
*   `SWITCH_FACTOR`: How much to increase the delay when in the failover mode. For example, if `CHECK_DELAY` is 5 seconds and `SWITCH_FACTOR` is 2, the delay will be 15 seconds when in the failover mode. This is to reduce the overhead when in the failover mode.
*   `ETHERNET_INTERFACE`: The name of the Ethernet interface. If an Ethernet interface with this name is not found in the network service order, the script will attempt to find another Ethernet interface.
*   `WIFI_INTERFACE`: The name of the Wi-Fi interface. If a Wi-Fi interface with this name is not found in the network service order, the script will attempt to find another Wi-Fi interface.


### Note

You can modify the IP addresses used for testing the Ethernet connection in `ethernet_not_working` and `ethernet_sure_not_working` functions. By default, the script pings `8.8.8.8` first and `1.1.1.1` if the previous ping fails.