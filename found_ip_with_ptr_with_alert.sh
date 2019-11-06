#!/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
LOGFILE="/var/log/ip_with_ptr.log"
ACCLOG="/var/log/nginx.log"
ALERTCOUNT=500
ALERTMESSAGE="[CountAlert!]"
echo -e "\n==================================\n$(date +"%d.%m.%Y-%H:" --date="1 hours ago")\n==================================\n" >> $LOGFILE

for ip in $(grep $(date +"%d/%b/%Y:%H:" --date="1 hours ago") $ACCLOG | awk '{print $1}' | sort | uniq -d -c | sort -h| sort -nrk 1 | awk -F ' ' '$1 > 10 {print $2}'); do
COUNT=$(grep $(date +"%d/%b/%Y:%H:" --date="1 hours ago") $ACCLOG |grep $ip -c)
IP=$ip
HOST=$(host $ip)
PTR=${HOST##*' '}

if [ "$PTR" == "3(NXDOMAIN)" ]; then 
PTR="NOT FOUND"
fi
if [ "$PTR" == "2(SERVFAIL)" ]; then 
PTR="NOT FOUND"
fi
if [ "$COUNT" -ge  "$ALERTCOUNT" ]; then
COUNT="$(grep $(date +"%d/%b/%Y:%H:" --date="1 hours ago") $ACCLOG |grep $ip -c) $ALERTMESSAGE"
echo -e "count:\t$COUNT\tIP:\t$IP\tPTR:\t$PTR" >> /root/tmp/ips_resolving_with_alert.txt
else 
echo -e "count:\t$COUNT\tIP:\t$IP\tPTR:\t$PTR" >> /root/tmp/ips_resolving_with_alert.txt
fi
done

cat /root/tmp/ips_resolving_with_alert.txt >> $LOGFILE
