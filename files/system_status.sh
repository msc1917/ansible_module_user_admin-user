#! /bin/bash

###
#
# Zeigt einige Statusdaten zum Host, wie Hostnamen, Aktiven Netzwerkadressen, Startzeit,
# Füllstand der Verzeichnisse an.
# Ist als Startinfo für die Terminals gedacht.
#
# Version 1.0    2021.02.24    Martin Schatz
#
###

# Check if Terminal is interactice:
if [ $(echo "${-}" | grep -vq "i" | echo ${?} ) -ne 0 ]
then
        exit 0
fi

RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
DARKYELLOW='\033[0;33m'
NC='\033[0m' # No Color
figlet -f small $(hostname)
echo "-------------------------------------------+------------------------------------"
ip_list () {
        ip -br addr show | grep -v "^lo" | while read LINE
        do
                status="$(echo ${LINE} | cut -f 2 -d " ")"
                device="$(echo ${LINE} | cut -f 1 -d " ")"
                if [ "${status}" = "UP" ]
                then
                        status="[ONLINE]"
                elif [ "${status}" = "DOWN" ]
                then
                        printf "%6s ${RED}%-8s${NC} %-26s\n" "${device}" "[OFFLINE]"
                fi
                ip_addresses="$(echo ${LINE} | cut -f 3- -d " ")"
                for ip_address in ${ip_addresses}
                do
                        ip_address="$(echo "${ip_address}" | sed "s/\/[0-9][0-9]*$//")"
                        printf "%6s ${GREEN}%-8s${NC} %-27s\n" "${device}" "${status}" "${ip_address}"
                        status=""
                        device=""
                done
        done
        }
ip_addresses="$(ip_list)"
sys_started="       Started: $(uptime -s)"
date_now="           Now: $(date +"%Y-%m-%d %H:%M:%S")"
lines=$(echo "${ip_addresses}" | wc -l)
linecounter=0
echo "${ip_addresses}" | while read LINE
do
        show_line=$( expr ${lines} - ${linecounter} )
        linecounter=$( expr ${linecounter} + 1 )
        add_text=""
        case ${show_line} in
                2) add_text="${sys_started}";;
                1) add_text="${date_now}";;
        esac
        echo "$(echo "${ip_addresses}" | tail -${show_line} | head -1)| ${add_text}"
done
echo "-------------------------------------------+------------------------------------"
df -h | grep -v tmpfs