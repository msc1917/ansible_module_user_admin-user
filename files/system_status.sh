#! /bin/bash

###
#
# Zeigt einige Statusdaten zum Host, wie Hostnamen, Aktiven Netzwerkadressen, Startzeit,
# Füllstand der Verzeichnisse an.
# Ist als Startinfo für die Terminals gedacht.
#
# Version 1.0    2021.02.24    Martin Schatz     First Version
# Version 1.1    2021.02.24    Martin Schatz     Added Progress-Bar
# Version 1.2    2021.03.04    Martin Schatz     Adapted terminal Width
# Version 1.3    2021.03.07    Martin Schatz     Added TB-Size
#
# Todos:
#   - Cleanup
#
###

# Check if Terminal is interactice:
if [ $(echo "${-}" | grep -vq "i" | echo ${?} ) -ne 0 ]
then
    exit 0
fi

# if [ -n ${COLUMNS} ]
# then
#     WINDOWSIZE=${COLUMNS}
# else
#     WINDOWSIZE=120
# fi

WINDOWSIZE=$(tput cols)

RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
DARKYELLOW='\033[0;33m'
NC='\033[0m' # No Color
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
        printf %${FREE}s |tr " " "-"    
        printf "|"    
    else    
        printf "| %-${FREE}s|" "ERROR"    
    fi
}

convertMB () {
    if echo "${1}" | grep -q "^[0-9][0-9]*$"
    then
        if [ ${1} -gt 1048576 ]
        then
            echo "$(expr ${1} \* 100 \/ 1048576 \/ 100).$(expr ${1} \* 100 \/ 1048576 % 100) TB"
        elif [ ${1} -gt 1024 ]
        then
            echo "$(expr ${1} \* 100 \/ 1024 \/ 100).$(expr ${1} \* 100 \/ 1024 % 100) GB"
        else
            echo -e "${1} MB\n"
        fi
    fi
    }

ip_list () {
    tmp_ip_list="$(ip -br addr show | grep -v "^lo")"

    len_status=0
    for status in $(echo "${tmp_ip_list}" | tr -s " " | cut -f 2 -d " ")
    do 
        if [ "${status}" = "UP" ]
        then
            status="[ONLINE]"
        elif [ "${status}" = "DOWN" ]
        then 
            status="[OFFLINE]"
        fi

        if [ ${#status} -gt ${len_status} ]
        then
            len_status=${#status}
        fi
    done

    len_device=0
    for device in $(echo "${tmp_ip_list}" | tr -s " " | cut -f 1 -d " ")
    do 
        if [ ${#device} -gt ${len_device} ]
        then
            len_device=${#device}
        fi
    done

    len_ip_address=0
    for ip_addresses in $(echo "${tmp_ip_list}" | tr -s " " | cut -f 3- -d " ")
    do 
        for ip_address in ${ip_addresses}
        do
            ip_address="$(echo "${ip_address}" | sed "s/\/[0-9][0-9]*$//")"
            if [ ${#ip_address} -gt ${len_ip_address} ]
            then
                len_ip_address=${#ip_address}
            fi
        done
    done

    echo "${tmp_ip_list}" | while read LINE 
    do 
        status="$(echo ${LINE} | cut -f 2 -d " ")"
        device="$(echo ${LINE} | cut -f 1 -d " ")"
        if [ "${status}" = "UP" ]
        then
            status="[ONLINE]"
        elif [ "${status}" = "DOWN" ]
        then 
            printf "%${len_device}s ${RED}%-${len_status}s${NC} %-${len_ip_address}s\n" "${device}" "[OFFLINE]"
        fi
        ip_addresses="$(echo ${LINE} | cut -f 3- -d " ")"
        for ip_address in ${ip_addresses}
        do
            ip_address="$(echo "${ip_address}" | sed "s/\/[0-9][0-9]*$//")"
            printf "%${len_device}s ${GREEN}%-${len_status}s${NC} %-${len_ip_address}s\n" "${device}" "${status}" "${ip_address}"
            status=""
            device=""
        done
    done 
    }

figlet -f small $(hostname)
printf %${COLUMNS}s |tr " " "-"

ip_addresses="$(ip_list)"
sys_started="Started: $(uptime -s)"
date_now="Now: $(date +"%Y-%m-%d %H:%M:%S")"
lines=$(echo "${ip_addresses}" | wc -l)
linecounter=0
echo "${ip_addresses}" | while read LINE
do
    show_line=$( expr ${lines} - ${linecounter} )
    linecounter=$( expr ${linecounter} + 1 )
    ip_address_line="$(echo "${ip_addresses}" | tail -${show_line} | head -1)"
    add_text=""
    second_column=$(expr ${WINDOWSIZE} - ${#ip_address_line} + 11)

    case ${show_line} in
        2) add_text="${sys_started}";;
        1) add_text="${date_now}";;
    esac
    echo "${ip_address_line}$(printf "%${second_column}s" "${add_text}")"
done


printf %${COLUMNS}s |tr " " "-"
fs_data="$(df -m | grep -v "tmpfs" | grep -v "^$" )"
fs_data="$(echo "${fs_data}" | tail -$(expr $(echo "$fs_data" | wc -l) - 1 ) | grep -v "^$" )"

len_fs_mountpoint=0
for fs_mountpoint in $(echo "${fs_data}" | tr -s " " | cut -f 1 -d " ")
do 
    if [ ${#fs_mountpoint} -gt ${len_fs_mountpoint} ]
    then
        len_fs_mountpoint=${#fs_mountpoint}
    fi
done

len_fs_full=0
for fs_full in $(echo "${fs_data}" | tr -s " " | cut -f 2 -d " ")
do 
    tmp_fs_full="$(convertMB ${fs_full})"
    if [ ${#tmp_fs_full} -gt ${len_fs_full} ]
    then
        len_fs_full=${#tmp_fs_full}
    fi
    # echo "fs_full: \"${fs_full}\" => tmp_fs_full: \"${tmp_fs_full}\" ... [${#tmp_fs_full}/${len_fs_full}]"
done

len_fs_used=0
for fs_used in $(echo "${fs_data}" | tr -s " " | cut -f 3 -d " ")
do 
    tmp_fs_used="$(convertMB ${fs_used})"
    if [ ${#tmp_fs_used} -gt ${len_fs_used} ]
    then
        len_fs_used=${#tmp_fs_used}
    fi
    # echo "fs_used: \"${fs_used}\" => tmp_fs_used: \"${tmp_fs_used}\" ... [${#tmp_fs_used}/${len_fs_used}]"
done

len_fs_directory=0
for fs_directory in $(echo "${fs_data}" | tr -s " " | cut -f 6 -d " ")
do 
    if [ ${#fs_directory} -gt ${len_fs_directory} ]
    then
        len_fs_directory=${#fs_directory}
    fi
done
tmp_textlength=$(expr ${len_fs_mountpoint} + ${len_fs_full} + ${len_fs_used} + ${len_fs_directory} + 8 )
len_fs_bar=$(expr ${WINDOWSIZE} - ${tmp_textlength} )

echo "$fs_data" | while read LINE
do
    fs_mountpoint="$(echo ${LINE} | cut -f 1 -d " " | sed "s/ $//")"
    fs_full="$(echo ${LINE} | cut -f 2 -d " " | sed "s/ $//")"
    fs_used="$(echo ${LINE} | cut -f 3 -d " " | sed "s/ $//")"
    fs_directory="$(echo ${LINE} | cut -f 6 -d " " | sed "s/ $//")"
    printf "%${len_fs_mountpoint}s  %-${len_fs_used}s %${len_fs_bar}s %${len_fs_full}s  %-${len_fs_directory}s\n" "${fs_mountpoint}" "$(convertMB ${fs_used})" "$(show_bar ${len_fs_bar} ${fs_full} ${fs_used})" "$(convertMB ${fs_full})" "${fs_directory}"
done

printf %${COLUMNS}s |tr " " "-"
