#!/usr/bin/env bash

print() {
  echo "[$(date)] $1"
}

# the '-u critical' ensure that the notification appears on the screen
notify() {
  print "notify $1: $2"
  notify-send -u critical "$1" "$2"
}

while true; do
  mins=20
  sleep_interval=$((60 * mins))
  print "cycle started with an interval of $mins mins"
  sleep "$sleep_interval"
  notify "eye break" "look at 6 meters for 20 sec"
  sleep "$sleep_interval"
  notify "eye break" "look at 6 meters for 20 sec"
  sleep "$sleep_interval"
  notify "body break" "walk for a few minutes"
done
