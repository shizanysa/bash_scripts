#!/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
sender="root@server.io"
recepient="mail@email"
HOST=$(hostname)
date_for_log=$(date +"%d.%m.%Y %T")
subject="Bots list on $HOST : $date_for_log"
log_time="1 hours ago"
CURDATE=$(date +"%d.%m.%Y-%H:" --date="$log_time")
DATE=$(date +"%d.%m.%Y-%H:" --date='1 days ago')
DELDATE=$(date +"%d.%m.%Y-%H:" --date='1 days ago')
ALERTCOUNT=500
ALERTMESSAGE="[CountAlert!]"
LOGACC="/var/log/nginx.access.log"
#LOGACC="/tmp/tst.log"
AUTOLIMITS="/tmp/limits.tmp"
TMPLOG="/tmp/bots.log"
BOTLOGS="/tmp/bots2.log"
MAINLOGS="/tmp/main.log"
rm -f $TMPLOG $BOTLOGS $MAINLOGS /tmp/limits.tmp
cp /etc/nginx/conf.d/auto_limits.conf /tmp/limits.tmp
#echo -e "\n-----------\n-----------\n$date_for_log\n\nFound IP's:" >> $BOTLOGS
for IP in $(grep "$(date +'%d/%b/%Y:%H:' --date="$log_time")" $LOGACC |awk '{print $1}' | sort | uniq -d -c | sort -h | sort -nrk 1 | awk -F ' ' '$1 > 80 {print $2}'); do

  COUNT_ALL_IP=$(grep "$(date +'%d/%b/%Y:%H:' --date="$log_time")" $LOGACC| grep "$IP" -c)
  echo -e "count:\t$COUNT_ALL_IP\tIP:\t$IP" >> $TMPLOG
  BOTS=$(grep "$IP" "$LOGACC"| grep "$(date +'%d/%b/%Y:%H:' --date="$log_time")" |grep -v "service/service.php" -c)
  if [ "$BOTS" -eq "0" ]; then
    COUNT=$(grep "$IP" "$LOGACC" | grep "$(date +'%d/%b/%Y:%H:' --date="$log_time")" -c)
    HOSTS=$(host "$IP")
    PTR=${HOSTS##*' '}
    if [ "$PTR" == "3(NXDOMAIN)" ]; then
      PTR="NOT FOUND"
    elif [ "$PTR" == "2(SERVFAIL)" ]; then
      PTR="NOT FOUND"
    fi
    if [ "$COUNT" -ge  "$ALERTCOUNT" ]; then
      COUNT="$(grep "$IP" "$LOGACC"| grep "$(date +'%d/%b/%Y:%H:' --date="$log_time")" -c) $ALERTMESSAGE"
      echo -e "count:\t$COUNT\tIP:\t$IP\t\t\t\tPTR:\t$PTR" >> $BOTLOGS
      echo -e "$IP" >> $MAINLOGS
    else
    echo -e "count:\t$COUNT\t\t\t\tIP:\t$IP\t\t\t\tPTR:\t$PTR" >> $BOTLOGS
    echo -e "$IP" >> $MAINLOGS
    fi
  fi
done

if [ -f "$MAINLOGS" ]
then
  if grep -q "$DELDATE" /etc/nginx/conf.d/auto_limits.conf
    then
    MESSDEL=$(sed "/$DELDATE/ q; s/\/32 1;//g" /etc/nginx/conf.d/auto_limits.conf | sed "/$DELDATE/d")
    echo -e "\nIP's deleted from blacklist (older than $DATE): \n$MESSDEL\n" >> /var/log/nginx/bots_with_alert.log
    sed -i "1,/$DELDATE/d" $AUTOLIMITS
    fi
  awk '{print $1 "/32 1;"}' $MAINLOGS >> $AUTOLIMITS
  echo -e "### $CURDATE\n\n" >> "$AUTOLIMITS"
  UNIQ=$(awk '! a[$0]++' "$AUTOLIMITS")
  echo -e "$UNIQ\n" > $AUTOLIMITS
#  systemctl restart nginx
  ! nginx -t -q && exit 0
  MESSADD=$(cat $BOTLOGS)
  TOTAL=$(grep -v "### " $AUTOLIMITS -c)
  echo -e "\nIP's added to blacklist: \n$MESSADD\n\n$TOTAL total blocked IP's in nginx\n" >> $BOTLOGS
  message=$(echo -e "IP's deleted from blacklist (older than $DATE): \n$MESSDEL\n\n IP's added to blacklist: \n$MESSADD\n\n$TOTAL blocked IP's")
  echo "$message" | mailx -r "$sender" -s "$subject" "$recepient"
else
  echo -e "\nBots not found" >> $BOTLOGS
  if grep -q "$DELDATE" $AUTOLIMITS
  then
    MESSDEL=$(sed "/$DELDATE/ q; s/\/32 1;//g" $AUTOLIMITS | sed "/$DELDATE/d")
    echo -e "\nIP's deleted from blacklist (older than $DATE): \n$MESSDEL\n" >> $BOTLOGS
    sed -i "1,/$DELDATE/d" $AUTOLIMITS
    TOTAL=$(grep -v "### " $AUTOLIMITS -c)
    ! nginx -t -q && exit 0
    message=$(echo -e "IP's deleted from blacklist (older than $DATE): \n$MESSDEL\n\n $TOTAL blocked IP's")
    echo "$message" | mailx -r "$sender" -s "$subject" "$recepient"
  fi
fi
#cat $BOTLOGS | mailx -r "$sender" -s "$subject" "$recepient"
