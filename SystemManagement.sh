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

#--------Shared Functions Section-----------#
gauge() {
  {
    for I in $(seq 1 100); do
      echo $I
      sleep 0.005
    done
    echo 100
  } | dialog --backtitle "${BackgroundTitle}- $1" \
    --gauge "Progress" 6 60 0
}
#--------System Section-----------#
system() {
  IFS=","
  system_info=($(hostnamectl | awk -F : 'gsub(/^[ \t]+/, "", $2) && NR==1||NR==6||NR==7||NR==8 {print $2","} '))
  uptime=$(uptime | cut -d "," -f 1 | sed 's/^ *//g')
  cpu_info=$(lscpu | awk -F : 'gsub(/^[ \t]+/, "", $2) && /Model name/{ print $2 } ' | tr -d '\t')
  memory_info=$(free -h | head -n 2 | tail -n 1 | tr -s ' ' ' ' | cut -d " " -f 2)
  IFS=$'\n'
  storages_size=($(lsblk | grep -e "disk" | tr -s " " " " | cut -d " " -f4))
  dialog --colors --backtitle "${BackgroundTitle}-${SystemSectionName}" \
    --title "${SystemTitleName}" \
    --msgbox "\Zb\Z1     Hostname:\Zn ${system_info[0]}\n\n\
     \Zb\Z1Uptime:\Zn ${uptime}\n\n\
     \Zb\Z1Operating System:\Zn${system_info[1]}\n\n\
     \Zb\Z1Kernel:\Zn${system_info[2]}\n\n\
     \Zb\Z1Architecture:\Zn${system_info[3]}\n\n\
     \Zb\Z1Processor:\Zn ${cpu_info}\n\n
     \Zb\Z1Storage:\Zn $(for index in "${!storages_size[@]}"; do
      echo "Disk""${index}: ""${storages_size[$index]}"
    done)\n\n\
     \Zb\Z1Installed RAM:\Zn ${memory_info}" 20 90

}
#--------IPAddress Section-----------#
get_interface_ip_address() {
  ifconfig "$1" | awk '{ print $2}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"
}
get_interface_ip_net_mask() {
  ifconfig "$1" | awk '{ print $4}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"
}
get_interface_ip_hardware() {
  ifconfig wlp0s20f3 | awk '{ print $2}' | grep -E -o "([0-9a-f]{2}:){5}.."
}
get_interface_ip_gateway() {
  ip route show default | awk -v interface="$1" '$0 ~ interface {print $3} '
}
show_interface_info() {
  if="$1"
  address="$2"
  netmask="$3"
  gateway="$4"
  hardware="$5"

  dialog --backtitle "${BackgroundTitle}- Interface Details" --colors --title "$if" \
    --msgbox "\Zb\Z1 IP Address:\Zn ${address:=-}\n\
 \Zb\Z1Netmask:\Zn ${netmask:=-}\n\
 \Zb\Z1Gateway:\Zn ${gateway:=-}\n\
 \Zb\Z1Physical Address:\Zn ${hardware:=-}" 10 50

}
get_interfaces() {
  ls /sys/class/net/
}
select_interface() {

  interfaces=()
  while IFS=' ' read -r line; do interfaces+=("$line" ""); done < <(get_interfaces)

  interface=$(dialog --stdout \
    --title "${IPAddressTitleName}" \
    --backtitle "${BackgroundTitle}-${IPAddressSectionName} " \
    --ok-label "Next" \
    --menu "Select an interface:" \
    20 30 30 \
    "${interfaces[@]}")
  echo $interface
}
ip_address() {
  if="$(select_interface)"
  if [ "$if" == "" ]; then
    return
  fi
  show_interface_info "$if" "$(get_interface_ip_address $if)" "$(get_interface_ip_net_mask $if)" "$(get_interface_ip_gateway $if)" "$(get_interface_ip_hardware $if)"
  ip_address
}
#--------Network Section-----------#
network() {
  nmtui
  gauge "${NetworkConfigurationSectionName}"
}
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
