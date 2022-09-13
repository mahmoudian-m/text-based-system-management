#!/usr/bin/env bash

#######################################################################
# Title      :    Text Based System Management
# Author     :    Mostafa Mahmoudian <mahmoudian.m1991@gmail.com>
# Date       :    2022-07-16
# Requires   :    dialog - root access
# Category   :    Text based terminal for TTY
#######################################################################
# Description
#   This script is a text based terminal management
#   it executes in on of TTYs of  debian based operating systems
#   It includes usable tools to manage operating system
#######################################################################
# Default Titles
VersionNumber=0.1
MainTitle="Main Menu"
BackgroundTitle="Text Based System Management"
SystemSectionName="Host Information"
SystemTitleName="System Information"
IPAddressSectionName="Network Addresses"
IPAddressTitleName="Network Interfaces"
NetworkConfigurationSectionName="Network Configuration"
NetworkConnectivitySectionName="PING Utility"
NetworkConnectivityTitleName="PING Utility"
ServiceManagementSectionName="Service Management"
SystemResourceSectionName="System Resources"
SystemResourceTitleName="System Resources"
HaltSectionName="Halt"
VersionSectionName="Halt"

trap '' 2

# Check Program Dependencies
declare -A package_list
package_list["dialog"]=["dialog"]
package_list["ifconfig"]=["net-tools"]
package_list["nmtui"]=["network-manager"]
check_dependencies() {
  issues_count=0
  for key in "${!package_list[@]}"; do
    if ! which "${key}" &>/dev/null; then
      echo -e "\e[1;31mDependencies Issue!! \e[0m
      This program needs  $key program.
      Hint: sudo apt-get install ${package_list[$key]}"
      ((issues_count = issues_count + 1))
    fi
  done
  if [[ ${issues_count} -ne 0 ]]; then
    exit 1
  fi
}
check_dependencies

# Check Root Access
if [[ $EUID -ne 0 ]]; then
  dialog --backtitle "${BackgroundTitle}" --colors --msgbox \
    "\Zb\Z1 Permission Denied!! \Zn\n\
 This Program have to be executed as a root." 7 55
  exit 1
fi

_temp="/tmp/answer.$$"
PN=$(basename "$0")
>$_temp
DVER=$(cat $_temp | head -1)

### create main menu using dialog
main_menu() {
  dialog --backtitle "$BackgroundTitle" --title "${MainTitle}" \
    --no-cancel \
    --menu "Move sing [UP] [DOWN], [Enter] to select" 19 100 13 \
    System "System Information" \
    IPAddress "Show IP Addresses" \
    Network/IP "Configure IP Addresses" \
    PING "Check Host Connectivity" \
    Services "Manage Services" \
    HTOP "Monitor System Resources" \
    Halt "Shutdown/Reboot System" \
    Version "Current Version" 2>$_temp

  opt=${?}
  if [ $opt != 0 ]; then
    rm $_temp
    exit
  fi
  menuitem=$(cat $_temp)
  case $menuitem in
  System) system ;;
  IPAddress) ip_address ;;
  Network/IP) network ;;
  PING) network_connectivity ;;
  Services) service_manager ;;
  HTOP) system_resources ;;
  Halt) halt ;;
  Version) version ;;
  '')
    rm $_temp
    exit
    ;;
  esac
}
while true; do
  main_menu
done
