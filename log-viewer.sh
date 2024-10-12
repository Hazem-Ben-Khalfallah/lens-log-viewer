#!/bin/bash

FILE=""
lines=10

usage() {
    echo "usage: [-h] [FILE]"
    echo "Print the last 10 lines of each FILE to standard output. If the file contains Json log lines, it will format them into a human readable output."
    echo " -n, --lines  output the last NUM lines, instead of the last 10"
    echo " -h, --help   display this help and exit"
}

while [[ "$1" != "" ]]; do
    case $1 in
        -n | --lines )          shift
                                lines=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     FILE=$1
                                ;;
    esac
    shift
done

validateParams() {
  if [[ "$FILE" == "" && -t 0 ]]; then
        printf "\e[1m\e[31m You need to specify a file or pipe input.\e[0m\n"
        usage
        exit 1
    fi
}

format_step_array() {
  local step_array="$1"

  # Parse the stepArray and format each entry
  echo "$step_array" | jq -r '.[] | "\(.className)#\(.methodName):\(.lineNumber)"'
}

# Function to recursively print throwable causes
print_throwable() {
  local throwable="$1"
  
  # Extract the throwable details
  message=$(echo -e "$throwable" | jq -r '.formattedMessage // .message')
  formattedStepArray=$(echo "$throwable" | jq -r '.formattedStepArray')
  stepArray=$(echo "$throwable" | jq -r '.stepArray')

  # Print the throwable details with indentation
  echo -e "$message"

  if [ -n "$formattedStepArray" ] && [ "$formattedStepArray" != "null" ]; then
    echo -e "$formattedStepArray"
  fi

  if [ -n "$stepArray"  ]; then
    format_step_array "$stepArray"
  fi

  # Check if there is a cause
  local cause=$(echo "$throwable" | jq -c '.cause // empty')

  if [ -n "$cause" ] && [ "$cause" != "null" ]; then
    echo -e "\033[0;33mCaused by:\033[0m"
    print_throwable "$cause"
  fi
}

# Function to color the log level
color_log_level() {
  local level="$1"
  case "$level" in
    "ERROR") echo -e "\033[0;31m$level\033[0m" ;;  # Red for ERROR
    "WARN")  echo -e "\033[0;33m$level\033[0m" ;;  # Yellow for WARN
    "INFO")  echo -e "\033[0;32m$level\033[0m" ;;  # Green for INFO
    *)       echo "$level" ;;
  esac
}

# Function to format MDC as key-value pairs
format_mdc() {
  local mdc="$1"
  
  # Define the keys that should not be colored or bolded
  local excluded_keys=("eventId" "appId" "tenantId" "stepId" "sessionId" "timestamp" "traceId" "spanId")

  # Convert the MDC JSON object to a list of key-value pairs using jq
  local mdc_pairs=$(echo "$mdc" | jq -r 'to_entries | map("\(.key): \(.value)") | join(", ")')

  # Loop through each key-value pair and apply coloring and formatting
  echo "$mdc_pairs" | while IFS=, read -ra pairs; do
    for pair in "${pairs[@]}"; do
      key=$(echo "$pair" | cut -d':' -f1 | xargs)
      value=$(echo "$pair" | cut -d':' -f2- | xargs)
      
      # Check if the key is in the excluded list
      if [[ " ${excluded_keys[@]} " =~ " ${key} " ]]; then
        echo -n -e "\033[0;35m$key\033[0m: $value, "
      else
        # Apply bold and blue color for other keys
        echo -n -e "\033[0;34m$key\033[0m: $value, "
      fi
    done
    echo ""
  done
}

format_json_line() {
  local log_line="$1"
  local version timestamp level message mdc throwable formatted_message formatted_stack

  version=$(echo "$log_line" | jq -r '.version')
  timestamp=$(echo "$log_line" | jq -r '.timestamp')
  level=$(echo "$log_line" | jq -r '.level')
  message=$(echo "$log_line" | jq -r '.message')
  mdc=$(echo "$log_line" | jq -r '.mdc // empty')
  throwable=$(echo "$log_line" | jq -c '.throwable // empty')

  # Format and display the log entry
  echo -e "[$version] $timestamp $(color_log_level "$level") $message"

  # If MDC exists, format it as a comma-separated key-value pair line
  if [ -n "$mdc" ] && [ "$mdc" != "{}" ]; then
    formatted_mdc=$(format_mdc "$mdc")
    echo -e "\t--> context: $formatted_mdc"
  fi
  
  # If a throwable exists, print its details
  if [ -n "$throwable" ]; then
    echo -e "\033[0;33mThrowable:\033[0m:"
    print_throwable "$throwable"
  fi

  echo -e "\n"
}

process_input() {
    while read -r line; do
        if [[ "$line" == {* ]]; then
            format_json_line "$line"
        else
            echo "$line"
        fi
    done
}

validateParams


# Process input from either file or pipe
if [[ -n "$FILE" ]]; then
    # If file is provided, use tail and pipe it to process_input
    tail -f -n "$lines" "$FILE" | process_input
else
    # If input is piped, process stdin
    process_input
fi
