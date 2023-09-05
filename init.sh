#!/bin/bash

source .env

# Проверка наличия и создание расписания cron, скрипта sql
if [[ ! -f "/etc/cron.d/mmost-clean" ]] ; then
  echo "Make schedule.";
  echo "MAILTO=$EMAIL_ADMIN" > /etc/cron.d/mmost-clean;
  echo -e "$CRON_SCHED root cd $PWD && make mmost-clean\n" >> /etc/cron.d/mmost-clean
  printf "" > ./mmost-clean.sql
  while IFS= read -d \, -r val || [ -n "$val" ]; do
    channel_name=$(echo $val | awk -F: '{print $1}');
    clean_range=$(echo $val | awk -F: '{print $2}');
    echo "DELETE FROM posts WHERE channelid = (SELECT id FROM channels WHERE name = '$channel_name') AND createat < extract(epoch from (now() - interval '$clean_range'))::int8 * 1000;" >> ./mmost-clean.sql;
  done <<< "$CLEAN_RULES"
  echo "Done!"
  else
    echo "Schedule exist! Exit."
fi
