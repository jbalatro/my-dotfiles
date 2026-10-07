#!/bin/sh

LOG_FILE=./log.txt
CUR_DATE=$(date)
LOGIN_USERS=$(who)
UPTIME=$(uptime)

1>>my_logs.txt

echo $CUR_DATE >> $LOG_FILE
echo $LOGIN_USERS >> $LOG_FILE
echo $UPTIME >> $LOG_FILE