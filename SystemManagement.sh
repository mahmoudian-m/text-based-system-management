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
