#! /bin/bash

###
#
# Zeigt einige Statusdaten zum Host, wie Hostnamen, Aktiven Netzwerkadressen, Startzeit,
# Füllstand der Verzeichnisse an.
# Ist als Startinfo für die Terminals gedacht.
#
# Version 1.0    2021.02.24    Martin Schatz     First Version
# Version 1.1    2021.02.24    Martin Schatz     Added Progress-Bar
#
# Todos:
#   - Weite des Terminalfensters ausnutzen
#
###

# Check if Terminal is interactice:
if [ $(echo "${-}" | grep -vq "i" | echo ${?} ) -ne 0 ]
then
    exit 0
fi

if [ -n ${COLUMNS} ]
then
    WINDOWSIZE=${COLUMNS}
else
    WINDOWSIZE=120
fi

RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
DARKYELLOW='\033[0;33m'
NC='\033[0m' # No Color
figlet -f small $(hostname)
echo "-------------------------------------------+------------------------------------"
show_bar () {
# ${1} - Length of bar
# ${2} - Volume of 100%
# ${3} - Volume filled    
    if [ ${3} -le ${2} ]    
    then    
        FULL=$(expr ${1} \* ${3} \/ ${2} )    
        FREE=$(expr ${1} - ${FULL})    
        printf "|"    
        COUNTER=0    
        printf %${FULL}s |tr " " "="    
        printf %${FREE}s |tr " " "-";    
        printf "|"    
    else    
        printf "| %-${FREE}s|" "ERROR"    
    fi
}

convertMB () {
    if [ ${1} -gt 1024 ]
    then
        echo "$(expr ${1} \* 100 \/ 1024 \/ 100).$(expr ${1} \* 100 \/ 1024 % 100) GB"
    else
        echo "${1} MB"
    fi
    }

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
fs_data="$(df -m | grep -v "tmpfs")"
echo "$fs_data" | tail -$(expr $(echo "$fs_data" | wc -l) - 1 ) | while read LINE
do
    fs_mountpoint="$(echo ${LINE} | cut -f 1 -d " ")"
    fs_full="$(echo ${LINE} | cut -f 2 -d " ")"
    fs_used="$(echo ${LINE} | cut -f 3 -d " ")"
    fs_directory="$(echo ${LINE} | cut -f 6 -d " ")"
    printf "%-14s %10s %20s %-10s %14s\n" "${fs_mountpoint}" "$(convertMB ${fs_used})" "$(show_bar 26 ${fs_full} ${fs_used})" "$(convertMB ${fs_full})" "${fs_directory}"
done
echo "--------------------------------------------------------------------------------"