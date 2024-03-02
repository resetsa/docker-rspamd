#!/usr/bin/env bash

# WARNING - basic requirement
# return exit code 0 - for spam or any error in work
# return exit code 1 - for not spam message (rspamd score is negative)

SPAM_EXITLEVEL=0
CLEAN_EXITLEVEL=1

LOGLEVEL_ERROR="ERROR"
LOGLEVEL_DEBUG="DEBUG"
LOGLEVEL_INFO="INFO"
LOG_DELIM="|"

RSPAMD_URL="http://localhost:11333/checkv2"
MAX_TIMEOUT=30
CONN_TIMEOUT=3

function usage {
  echo "Usage: $0 -m EML_FILE [-u RSPAMD_URL] [-d]"
  echo "Default:"
  echo "    RSPAMD_URL=http://localhost:11333/checkv2"
}

# for float calc
function calc {
    awk "BEGIN { print $*}";
}

# output log line
function printline {
    args=("$@")
    result=$LOG_DELIM
    # build output string
    for a in "${args[@]}"; do
        #printf "%s;%s;%s\n" "$@"
        #printf "%s%s" "${a}" $LOG_DELIM
        result="${result}${a}${LOG_DELIM}"
    done
    # print without first and last symbols
    printf "%s\n" "${result:1:-1}"
}

# log
function log {
    TIMESTAMP=$(date +"%d-%m-%Y %H:%M:%S.%N")
    LEVEL=$1
    shift
    MESSAGE=$*
    shift
    if [ "$LEVEL" == "$LOGLEVEL_DEBUG" ]; then
        if ! [ "$DEBUG" == "" ]; then
            printline "${TIMESTAMP}" "${LEVEL}" "${MESSAGE}"
        fi
        return
    fi
    printline "${TIMESTAMP}" "${LEVEL}" "${MESSAGE}"
}

function check_bin {
    PROG=$1
    if command -v "$PROG" &> /dev/null; then
        return 0
    fi
    return 1
}

function parse_param
{
	if [ -z "$1" ];then
		usage
        exit $SPAM_EXITLEVEL
	fi
	while getopts "m:u:d" opt; do
		case $opt in
		m)
    		FNAME=${OPTARG}
		;;
        d)  DEBUG=1
        ;;
        u)  RSPAMD_URL=${OPTARG}
        ;;
		*)
			usage
			exit $SPAM_EXITLEVEL
		;;
		esac
	done
}

START=$(date +%s.%N)
parse_param "$@"

# check file exist
log $LOGLEVEL_DEBUG "check $FNAME exist"
if ! [ -f "$FNAME" ]; then
  log $LOGLEVEL_ERROR "file ${FNAME} not exist"
  exit $SPAM_EXITLEVEL
fi

# check jq/curl/awk installed
for p in "curl" "jq" "awk"; do
    log $LOGLEVEL_DEBUG "check $p in path"
    if ! check_bin $p; then
        log $LOGLEVEL_ERROR "program $p not found"
        exit $SPAM_EXITLEVEL
    fi
done

# send req
log $LOGLEVEL_DEBUG "send request to $RSPAMD_URL"
REQ_START=$(date +%s.%N)
JSON=$(curl --data-binary @"$FNAME" "$RSPAMD_URL" -sS -k --max-time $MAX_TIMEOUT --connect-time $CONN_TIMEOUT 2>&1)
if [[ $? -ne 0 ]]; then
    log $LOGLEVEL_ERROR "$JSON"
    exit $SPAM_EXITLEVEL
fi
REQ_END=$(date +%s.%N)
REQ_RUNTIME=$(calc "$REQ_END-$REQ_START")
log $LOGLEVEL_DEBUG "result JSON: $JSON"

# get score
log $LOGLEVEL_DEBUG "compare score"
SCORE=$(echo "$JSON" | jq '.score - .required_score' 2>&1)
if [[ $? -ne 0 ]]; then
    log $LOGLEVEL_ERROR "$SCORE"
    exit $SPAM_EXITLEVEL
fi

# calc runtime 
END=$(date +%s.%N)
RUNTIME=$(calc "$END-$START")

# check score is negative - not spam
if [[ $SCORE == "-"* ]]; then
    log $LOGLEVEL_INFO "file $FNAME is not spam, score=$SCORE, runtime=${RUNTIME}s, req_runtime=${REQ_RUNTIME}s"
    exit $CLEAN_EXITLEVEL
fi

# else - spam
log $LOGLEVEL_INFO "file $FNAME is spam, score=$SCORE, runtime=${RUNTIME}s, req_runtime=${REQ_RUNTIME}s"
exit $SPAM_EXITLEVEL
