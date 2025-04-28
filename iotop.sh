#!/bin/bash

# iotop.sh - Version 1.0.1
# Customized I/O Monitoring Script with Loop and Debug modes (no external iotop command)

VERSION="1.0.1"

# Default values
device=""
interval=10
loop=1
all=1
show_empty=1
debug=0
CYCLE=1
MAX_CYCLE=-1

show_help() {
  echo -e "\nUsage: $0 [options]"
  echo -e "Options:"
  echo -e "  -d, --device DEVICE         Device to monitor (e.g., sda or pattern sd*)"
  echo -e "  -i, --interval SECONDS      Interval between updates (default: 10)"
  echo -e "  -l, --loop 0|1              Enable/disable looping mode (default: 1)"
  echo -e "  -a, --all 0|1               Show all entries or only active ones (default: 1)"
  echo -e "  -s, --show_empty 0|1        Show empty devices (default: 0)"
  echo -e "      --debug                 Enable debug mode (adds additional raw output)"
  echo -e "      --cycle NUMBER          Number of loops to run (default: -1 = endless)"
  echo -e "  -h, --help                  Show this help"
  echo -e "\nExample: $0 --device=sda --interval=2 --loop=1 --all=1 --cycle=5"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -d|--device)
      device="$2"
      shift; shift;
      ;;
    --device=*)
      device="${key#*=}"
      shift;
      ;;
    -i|--interval)
      interval="$2"
      shift; shift;
      ;;
    --interval=*)
      interval="${key#*=}"
      shift;
      ;;
    -l|--loop)
      loop="$2"
      shift; shift;
      ;;
    --loop=*)
      loop="${key#*=}"
      shift;
      ;;
    -a|--all)
      all="$2"
      shift; shift;
      ;;
    --all=*)
      all="${key#*=}"
      shift;
      ;;
    -s|--show_empty)
      show_empty="$2"
      shift; shift;
      ;;
    --show_empty=*)
      show_empty="${key#*=}"
      shift;
      ;;
    --debug)
      debug=1
      shift;
      ;;
    --cycle)
      MAX_CYCLE="$2"
      shift; shift;
      ;;
    --cycle=*)
      MAX_CYCLE="${key#*=}"
      shift;
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo -e "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Variables to store counters
declare -A reads
declare -A writes
declare -A bytes_read
declare -A bytes_written

format_number() {
  echo "$1" | sed ':a;s/\B\([0-9]\{3\}\>\)/.\1/;ta'
}

read_diskstats() {
  if [ -n "$device" ]; then
    grep -E "\b${device//\*/.*}\b" /proc/diskstats | sort -k3
  else
    sort -k3 /proc/diskstats
  fi
}

capture_stats() {
  while read -r major minor dev r_ios r_merges r_sectors r_ticks w_ios w_merges w_sectors w_ticks in_flight io_ticks time_in_queue; do
    if [[ "$dev" == "" ]]; then
      continue
    fi
    reads[$dev]=$r_ios
    writes[$dev]=$w_ios
    bytes_read[$dev]=$((r_sectors * 512 / 1024))
    bytes_written[$dev]=$((w_sectors * 512 / 1024))
  done < <(read_diskstats)
}

output_debug_diskstats() {
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') - DEBUG: DISKSTAT"
  read_diskstats | while read -r line; do
    echo -e "    $line"
  done
}

# Initial snapshot
capture_stats
if [ "$debug" == "1" ]; then
  output_debug_diskstats
fi

# Save old stats for the first comparison
declare -A old_reads=()
declare -A old_writes=()
declare -A old_bytes_read=()
declare -A old_bytes_written=()
for dev in "${!reads[@]}"; do
  old_reads[$dev]=${reads[$dev]}
  old_writes[$dev]=${writes[$dev]}
  old_bytes_read[$dev]=${bytes_read[$dev]}
  old_bytes_written[$dev]=${bytes_written[$dev]}
done

while true; do
  sleep "$interval"

  capture_stats

  if [ "$loop" == "1" ]; then
    clear
  fi

  echo -e "----------------------------------------"
  echo -e "-------- iotop.sh version $VERSION --------"
  echo -e "Device: ${device:-all}"
  echo -e "Interval: $interval seconds"
  echo -e "Loop mode: $loop / Cycle: $MAX_CYCLE / Round: $CYCLE"
  echo -e "All entries: $all"
  [ "$debug" == "1" ] && echo -e "Debug mode: ENABLED"
  # echo -e "----------------------------------------"

  if [ "$debug" == "1" ]; then
    output_debug_diskstats
  fi

  printf '%s\n' "--------------------------------------------------------------------------------------------------"
  printf "%-16s %12s %12s %15s %15s %10s %10s\n" "Device"  "Read/sec(KB)" "Write/Sec(KB)" "BytesRead(KB)" "BytesWritten(KB)" "ReadIO/s" "WriteIO/s"
  printf '%s\n' "--------------------------------------------------------------------------------------------------"

  for dev in $(printf "%s\n" "${!reads[@]}" | sort); do
    delta_reads=$(( reads[$dev] - old_reads[$dev] ))
    delta_writes=$(( writes[$dev] - old_writes[$dev] ))
    delta_bytes_read=$(( bytes_read[$dev] - old_bytes_read[$dev] ))
    delta_bytes_written=$(( bytes_written[$dev] - old_bytes_written[$dev] ))

    read_bps=$(( delta_bytes_read / interval ))
    write_bps=$(( delta_bytes_written / interval ))

    if [ "$show_empty" == "0" ] && [ "$delta_reads" -eq 0 ] && [ "$delta_writes" -eq 0 ]; then
      continue
    fi

    printf "%-16s %12s %12s %15s %15s %10s %10s\n" "$dev" "$(format_number $read_bps)" "$(format_number $write_bps)" "$(format_number $delta_bytes_read)" "$(format_number $delta_bytes_written)" "$(format_number $delta_reads)" "$(format_number $delta_writes)"
  done

  echo -e "--------------------------------------------------------------------------------------------------\n"

  for dev in "${!reads[@]}"; do
    old_reads[$dev]=${reads[$dev]}
    old_writes[$dev]=${writes[$dev]}
    old_bytes_read[$dev]=${bytes_read[$dev]}
    old_bytes_written[$dev]=${bytes_written[$dev]}
  done

  CYCLE=$((CYCLE+1))

  if [ "$MAX_CYCLE" -ne -1 ] && [ "$CYCLE" -gt "$MAX_CYCLE" ]; then
    break
  fi

done

exit 0
