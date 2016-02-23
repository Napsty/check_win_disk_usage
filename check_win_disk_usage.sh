#!/bin/bash
############################################################################
# check_win_disk_usage.sh
#
# Description:
# This script launches two different COUNTER checks on the target server.
# It uses the Windows perfomance output of 
# LogicalDisk(Letter:)\Disk Read Bytes/sec
# LogicalDisk(Letter:)\Disk Write Bytes/sec
#
# Author:     Claudio Kuenzler www.claudiokuenzler.com
# History:
# 20151127    Started script (based on check_win_net_usage.sh)
# 20160223    Do not try to auto-lookup plugin, use pluginlocation var
#############################################################################
# Set path to the location of your Nagios plugin (check_nt)
pluginlocation="/usr/lib/nagios/plugins"
#############################################################################
# Help
help="check_win_disk_usage.sh (c) 2015-2016 Claudio Kuenzler (GPLv2)\n
Usage: ./check_win_disk_usage.sh -H host [-p port] [-s password] -d driveletter
Requirements: check_nt plugin and NSClient++ installed on target server
\nOptions:\n-H Hostname of Windows server to check
-p Listening port of NSClient++ on target server (default 12489)
-s Password in case NSClient++ is set to use password
-d Name of drive, for example 'C:'
-o Choose output of value in KB, MB (default Byte)"
#############################################################################
# Check for people who need help - aren't we all nice ;-)
if [ "${1}" = "--help" -o "${#}" = "0" ];
       then
       echo -e "${help}";
       exit 1;
fi
#############################################################################
# Some people might forget to set the plugin path (pluginlocation)
if [ ! -x ${pluginlocation}/check_nt ]
then
echo "CRITICAL - Plugin check_nt not found in ${pluginlocation}"; exit 2
fi
#############################################################################
# Get user-given variables
while getopts "H:p:s:d:o:" Input;
do
       case ${Input} in
       H)      host=${OPTARG};;
       p)      port=${OPTARG};;
       s)      password=${OPTARG};;
       d)      drive=${OPTARG};;
       o)      output=${OPTARG};;
       *)      echo "Wrong option given. Please rtfm or launch --help"
               exit 1
               ;;
       esac
done
#############################################################################
# If port was given
if [[ -n ${port} ]]
then insertport=${port}
else insertport=12489
fi

# Verify drive parameter was set
if [[ -z ${drive} ]]; then echo "UNKNOWN - No drive letter given"; exit 3; fi
#############################################################################
# The checks itself (with password)
if [[ -n ${password} ]]
then
bytes_read=$(${pluginlocation}/check_nt -H ${host} -p ${insertport} -s ${password} -v COUNTER -l "\\LogicalDisk(${drive})\\Disk Read Bytes/sec")
bytes_write=$(${pluginlocation}/check_nt -H ${host} -p ${insertport} -s ${password} -v COUNTER -l "\\LogicalDisk(${drive})\\Disk Write Bytes/sec")
else
# Without password
bytes_read=$(${pluginlocation}/check_nt -H ${host} -p ${insertport} -v COUNTER -l "\\LogicalDisk(${drive})\\Disk Read Bytes/sec")
bytes_write=$(${pluginlocation}/check_nt -H ${host} -p ${insertport} -v COUNTER -l "\\LogicalDisk(${drive})\\Disk Write Bytes/sec")
fi

# Catch connection error
if !([  "$bytes_read" -eq "$bytes_read" ]) 2>/dev/null
then    echo "Network UNKNOWN: $bytes_read"
        exit 3
fi
if !([  "$bytes_write" -eq "$bytes_write" ]) 2>/dev/null
then    echo "Network UNKNOWN: $bytes_write"
        exit 3
fi

# In case KB or MB has been set in -o option
if [ -n "${output}" ]
then
        if [ "${output}" = "KB" ]
        then return_bytes_read=$(expr ${bytes_read} / 1024)
        return_bytes_write=$(expr ${bytes_write} / 1024)
        value="KBytes"
        elif [ "${output}" = "MB" ]
        then return_bytes_read=$(expr ${bytes_read} / 1024 / 1024)
        return_bytes_write=$(expr ${bytes_write} / 1024 / 1024)
        value="MBytes"
        fi
else
return_bytes_read=${bytes_read}
return_bytes_write=${bytes_write}
value="Bytes"
fi

# Output
echo "DISK I/O ${drive} OK - ${return_bytes_read} ${value} read/sec, ${return_bytes_write} ${value} write/sec|bytes_read=${bytes_read}B;;;; bytes_write=${bytes_write}B;;;;"
exit 0
